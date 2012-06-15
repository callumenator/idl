@resolve_nstatic_wind
@windsim_sample_fields

pro windsim_wave_analysis

	noise_dir = 'Noise00\'
	case_dir = where_is('windsim') + 'cases\waves\' + noise_dir
	data = file_search(case_dir + 'Data_*.idlsave', count=nfiles)
	restore, data[0]


	bi_use = where(bi_fits.obsdot lt .83 and max(bi_fits.overlap, dim=1) gt .1 and $
					bi_fits.mangle lt 4, nbi_use)


	tri_use = where(tri_fits.obsdot lt .83 and max(tri_fits.overlap, dim=1) gt .1 and $
				total(strmatch(tri_fits.stations, 'PKR') + $
					  strmatch(tri_fits.stations, 'HRP') + $
					  strmatch(tri_fits.stations, 'TLK'), 1) ne 3 , ntri_use)


	if file_test(case_dir + 'Mono_Los.idlsave') then begin
		restore, case_dir + 'Mono_Los.idlsave'
	endif else begin

		count = 0
		for k = 0, 3 do begin
			count += meta[k].nzones
			append, samples[k].zones.lat, lat
			append, samples[k].zones.lon, lon
		endfor


		los = findgen(nfiles, count)
		bi_w = fltarr(nfiles, nbi_use)
		for j = 0, nfiles - 1 do begin

			restore, data[j]

			for k = 0, 3 do begin
				append, samples[k].zones.los, sub_los
			endfor

			los[j,*] = sub_los

			sub_los = ''
			print, j
			wait, .1
		endfor

		ord = sort(lat)
		lat = lat[ord]
		lon = lon[ord]
		los = los[*, ord]

		save, filename=case_dir + 'Mono_Los.idlsave', lat, lon, los, count

	endelse


	hwid = 10
	lags = findgen(20)

	time = findgen(nfiles)
	use = where(time gt min(time) + hwid and time lt max(time) - hwid, nuse)
	lag = fltarr(count, nuse)

	for t = 0, nuse - 1 do begin

		tidx = use[t]
		this_time = time[tidx]
		tpts = where(time ge this_time - hwid and time le this_time + hwid)
		if t eq 0 then tpts0 = tpts

		los0 = los[tpts0, 0]

		for k = 0, count - 1 do begin

			losz = los[tpts, k]
			xcorr = c_correlate(losz, los0, lags)
			pt = (where(xcorr eq max(xcorr)))[0]
			lag[k,t] = lags[pt]

		endfor

	endfor

	window, 0, xs=500, ys=500
	loadct, 4, /silent
	triangulate, lon, lat, tr, b
	for t = 0, nuse - 1 do begin

		res = smooth(trigrid(lon, lat, lag[*,t], tr, /quintic), 3, /edge)
		scale_to_range, res, 0, 20, ores
		tv, congrid(ores, 500, 500, /interp)

		img = tvrd(/true)
		write_png, 'c:\cal\presentations\researchsummary\pics\wave_sim\' $
					+ string(t, f='(i03)') + '.png', img

	endfor

	stop

end