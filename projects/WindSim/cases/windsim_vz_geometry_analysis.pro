
@windsim_vz_runner
@windsim_sample_fields

pro windsim_vz_cosine, X, A, F, pder

	F = a[0] + a[1]*cos((x - a[2])*!DTOR)

  	IF N_PARAMS() GE 4 THEN $
	   	pder = [[replicate(1.0, N_ELEMENTS(X))], [cos((x - a[2])*!DTOR)], [a[1]*sin((x - a[2])*!DTOR)*!DTOR]]

end


pro windsim_vz_geometry_analysis

	case_dir = where_is('windsim') + 'cases\vertical_wind_geometry\rotate\'

	files = file_search(case_dir + 'Data*.idlsave', count = nfiles)

	restore, files[0]
	stop

	pts = where(bi_fits.mangle lt 3 and $
				bi_fits.obsdot lt .5 and $
				max(bi_fits.overlap, dim=1) gt .1 and $
				bi_fits.stations[0] eq 'PKR' and $
				bi_fits.stations[1] eq 'HRP', nvz)

	tripts = where(tri_fits.obsdot lt .83 and max(tri_fits.overlap, dim=1) gt .1 and $
				   total(strmatch(tri_fits.stations, 'PKR') + $
					     strmatch(tri_fits.stations, 'HRP') + $
					     strmatch(tri_fits.stations, 'TLK'), 1) ne 3 , ntrivz)

	bi_dist = total(bi_fits[pts].cvDist, 1)
	tri_dist = total(tri_fits[tripts].cvDist, 1)


	if 0 then begin

		bivz = fltarr(nvz, 37, 11)
		trivz = fltarr(ntrivz, 37, 11)
		mag = findgen(11)*10 + 50
		ang = findgen(37)*10

		for a = 0, 360, 10 do begin

			files = file_search(case_dir + 'Data_ang_' + string(a, f='(i03)') + '*.idlsave', count = nfiles)

			for m = 0, nfiles - 1 do begin

				restore, files[m]
				bivz[*, a/10, m] = bi_fits[pts].mcomp
				trivz[*, a/10, m] = tri_fits[tripts].w
				print, a, m
				wait, 0.01
			endfor
		endfor

		save, filename = case_dir + 'analysis_temp.idlsave', bivz, trivz, mag, ang

	endif else begin

		restore, case_dir + 'analysis_temp.idlsave'

	endelse


	ang_coeffs = fltarr(nels(bivz[*,0,0]), nels(mag), 3)
	mag_coeffs = fltarr(nels(bivz[*,0,0]), 2)

	for j = 0, nels(bivz[*,0,0]) - 1 do begin
		for k = 0, nels(mag) - 1 do begin
			a = [0., 1, 0.]
			res = curvefit(ang, reform(bivz[j,*,k]), replicate(1, nels(ang)), a, function_name='windsim_vz_cosine')
			ang_coeffs[j,k,*] = a
		endfor

		mag_coeffs[j,*] = linfit(mag, ang_coeffs[j,*,1])
	endfor


	ang_coeffs_tri = fltarr(nels(trivz[*,0,0]), nels(mag), 3)
	mag_coeffs_tri = fltarr(nels(trivz[*,0,0]), 2)

	for j = 0, nels(trivz[*,0,0]) - 1 do begin
		for k = 0, nels(mag) - 1 do begin
			a = [0., 1, 0.]
			res = curvefit(ang, reform(trivz[j,*,k]), replicate(1, nels(ang)), a, function_name='windsim_vz_cosine')
			ang_coeffs_tri[j,k,*] = a
		endfor

		mag_coeffs_tri[j,*] = linfit(mag, ang_coeffs_tri[j,*,1])
	endfor


	x0 = total(tri_fits[tripts].cvDist,1)
	x1 = tri_fits[tripts].obsdot
	x2 = max(tri_fits[tripts].overlap, dim=1)
	x3 = (tri_fits[tripts].aziSum)
	x4 = (tri_fits[tripts].midvec[2])
	y = abs(reform(ang_coeffs_tri[*,0,1]))

	x0 = (x0-min(x0))/max(x0-min(x0))
	x1 = (x1-min(x1))/max(x1-min(x1))
	x2 = (x2-min(x2))/max(x2-min(x2))
	x3 = (x3-min(x3))/max(x3-min(x3))
	x4 = (x4-min(x4))/max(x4-min(x4))
	y = (y-min(y))/max(y-min(y))


	x = transpose([[x0],[x1],[x2],[x3],[x4]])
	cf = regress(x, y, yfit = curve)

	print, total(abs(curve-y))
	print, correlate(y, curve)*100

	f = cf[0]*x0 + cf[1]*x1 + cf[2]*x2 + cf[3]*x3 +cf[4]*x4
	plot, f, y, /xstyle, psym=6



	;\\ LOOK AT SOME REAL DATA

	filter = ['*2010*01*24*SKY*6300*', $
			  '*2010*04*02*SKY*6300*', $
			  '*2010*04*05*SKY*6300*', $
			  '*2010*04*07*SKY*6300*', $
			  '*2010*12*08*SKY*6300*']


	filter = ['*2010*04*05*6300*']

	dates = file_search(where_is('poker_data')+filter+'.nc', count = nfiles)

	for didx = 0, n_elements(dates) - 1 do begin

		meta_loader, out, filename=dates[didx], drift_type = 'both'
		if out.found.bi ne 1 then continue
		if out.found.obs eq 0 then continue

		bi = out.hrp_pkr_bi
		use_times = where(abs(bi[*,0].times[0] - bi[*,0].times[1]) le 5./60., nuse)
		bi = bi[use_times, *]

		use = where(bi[0,*].obsdot lt .5 and $
				abs(bi[0,*].mangle) lt 3 and $
				max(bi[0,*].overlap, dim=1) gt .1, n_vz)

		bi = bi[*,use]

		;u = median(out.pkr.winds.zonal_wind, dim=1)
		;v = median(out.pkr.winds.meridional_wind, dim=1)

		pkidx = (where(bi[0,0].stations eq 'PKR'))[0]
		hpidx = (where(bi[0,0].stations eq 'HRP'))[0]

		bivz_c = bi.mcomp
		for j = 0, nels(bi[0,*]) - 1 do begin
			loc_idx = j

			u = (out.pkr.winds.zonal_wind[bi[0,j].zones[pkidx]] + out.hrp.winds.zonal_wind[bi[0,j].zones[hpidx]])/2.
			v = (out.pkr.winds.meridional_wind[bi[0,j].zones[pkidx]] + out.hrp.winds.meridional_wind[bi[0,j].zones[hpidx]])/2.

			amplitude = sqrt(u*u + v*v)*mag_coeffs[loc_idx, 1]
			angle = atan(v,u)/!DTOR
			offset = interpol( ang_coeffs[loc_idx,0,0] + amplitude*cos((angle - ang_coeffs[loc_idx,0,2])*!DTOR), $
							   out.pkr.ut, bi[*, loc_idx].time)
			bivz_c[*,j] = bi[*,j].mcomp - offset

		endfor




		eps, filename = 'C:\cal\IDLSource\NewAlaskaCode\WindFit\WindSim\cases\vertical_wind_geometry\rotate\Vz_Offset_Correct\' + $
			 out.yymmdd_nosep + '.eps', xs = 10, ys = 12, /open

		loadct, 4, /silent
		!p.charsize = .7
		bounds = split_page(3, 1, row_gap = .25, bounds=[.1, .03, .98, 1])
		color = [48, 96, 144, 208]
		plot, [3,17], [-70,70], /xstyle, /ystyle, /nodata, xtitle = 'Time (UT)', ytitle = 'Vz (m/s)', $
			  title = 'Raw ' + out.yymmdd_str, pos = bounds[0,0,*]
		oplot, [3,17], [0,0], line=1
		for j = 0, 3 do begin
			vz = bi[*,j].mcomp
			vz = smooth_in_time(bi[*,j].time, vz, 1000, 10./60.)
			oplot, bi[*,j].time, vz, color=color[j]
		endfor

		plot, [3,17], [-70,70], /xstyle, /ystyle, /nodata, xtitle = 'Time (UT)', ytitle = 'Vz (m/s)', $
			  title = 'Offset Corrected ' + out.yymmdd_str, pos = bounds[1,0,*], /noerase
		oplot, [3,17], [0,0], line=1
		for j = 0, 3 do begin
			vz = bivz_c[*,j]
			vz = smooth_in_time(bi[*,j].time, vz, 1000, 10./60.)
			oplot, bi[*,j].time, vz, color=color[j]
		endfor

		plot, [3,17], [0,80], /xstyle, /ystyle, /nodata, xtitle = 'Time (UT)', ytitle = 'Spread (m/s)', $
			  title = 'Spread', pos = bounds[2,0,*], /noerase
		oplot, [3,17], [0,0], line=1
		rnge0 = max(bi.mcomp, dim=2) - min(bi.mcomp, dim=2)
		rnge0 = smooth_in_time(bi[*,0].time, rnge0, 1000, 10./60.)
		oplot, bi[*,0].time, rnge0, color = 0
		rnge1 = max(bivz_c, dim=2) - min(bivz_c, dim=2)
		rnge1 = smooth_in_time(bi[*,0].time, rnge1, 1000, 10./60.)
		oplot, bi[*,0].time, rnge1, color = 143

		sdev = fltarr(nels(bi[*,0].mcomp), 2)
		for k = 0, nels(bi[*,0].mcomp) - 1 do begin
			sdev[k,0] = stddev(bi[k,*].mcomp)
			sdev[k,1] = stddev(bivz_c[k,*])
		endfor

		eps, /close
		!p.charsize = 0

		append, (rnge0 - rnge1)/float(rnge0), diff
		append, sdev[*,0] - sdev[*,1], sdiff

	endfor

	stop

end

