
pro davis_vertical_statistical

	redo = 1

	if redo eq 1 then begin

		data = file_search(where_is('davis_data') + '*2011*', count = nfiles)

		for f = 0, nfiles - 1 do begin
			ts = 0


			filter = 1
			ts = drta_make_time_series( '', 0, 0, filter, 630.0, filename=data[f], /useLELdrift)

			if ts.data eq 0 then begin
				filter = 2
				ts = drta_make_time_series( '', 0, 0, filter, 630.0, filename=data[f], /useLELdrift)
				if ts.data eq 0 then begin
					print, file_basename(data[f]) + ' Missing'
					continue
				endif
			endif

			_ut = *ts.directions[0].time
			_vz = *ts.directions[0].wind
			_vze = *ts.directions[0].wind_err
			_in = *ts.directions[0].intens
			_chi = *ts.directions[0].chisq
			_snr = *ts.directions[0].snr

			_year = float(strmid(file_basename(data[f]), 0, 4))
			_day = float(strmid(file_basename(data[f]), 5, 3))

			_tmp = refit_davis_temperatures(_year, _day, /show, out_sky_fits = sky_fits, out_las_fits = las_fits)
			pts = where(sky_fits.title eq 'zenith')
			append, interpol(reform(_tmp[pts,0]), sky_fits[pts].ut, _ut), tmp

			pts = where(_ut gt 20 and _ut lt 25, npts)
			if npts lt 30 then continue
			if median(_vz[pts]) lt 30 then continue

			date = convert_js((*ts.directions[0].jstime)[0])
			cnd = get_geomag_conditions(date.yymmdd_string, /quick)
			_ap = interpol(cnd.mag.ap, findgen(24), _ut)
			if total(cnd.mag.ap) eq 0 then _ap[*] = -1

			append, _ut, ut
			append, _vz, vz
			append, _vze, vze
			append, _in, in
			append, _chi, chi
			append, _snr, snr
			append, _year, year
			append, _day, day
			append, _ap, ap

			heap_gc

			print, f, nfiles
			wait, 0.1

		endfor

		save, filename = 'c:\rsi\idlsource\newalaskacode\davis\largeverticalwind\alldata.idlsave', $
				ut, vz, vze, in, chi, snr, year, day, ap, tmp

	endif else begin

		restore, 'c:\rsi\idlsource\newalaskacode\davis\largeverticalwind\alldata.idlsave'

	endelse


	;loadct, 39, /silent
	;plot, [-200,200], [0, .2], /nodata
	;for i = 10, 26, 2 do begin
	;	pt = where(ut ge i and ut lt i + 2 and in lt .2 and in gt .1, npts)
	;	if npts lt 50 then continue
	;	h = histogram(vz[pt], bins = 8, loc = x)
	;	oplot, x, h/total(h), color = ((i-10)/16.)*200 + 50
	;endfor

	stop


end