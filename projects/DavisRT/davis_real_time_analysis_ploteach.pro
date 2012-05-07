



pro davis_real_time_analysis_ploteach, data_path, $
									   plot_path, $
									   lambda, $
									   filter, $
									   year = year, $
									   dayno = dayno, $
									   windowID = windowID, $
									   nosave=nosave


	if data_path eq '' then data_path = 'e:\davisreduced\'
	if plot_path eq '' then plot_path = 'c:\cal\idlsource\davisrtnew\drta\plots\'

	if keyword_set(year) and not keyword_set(dayno) then begin
		days_list = file_search(data_path, string(year, f='(i0)') + '_*', count = ndays)
	endif
	if not keyword_set(year) and keyword_set(dayno) then begin
		days_list = file_search(data_path, '*_' + string(dayno, f='(i03)'), count = ndays)
	endif
	if keyword_set(year) and keyword_set(dayno) then begin
		days_list = file_search(data_path, string(year, f='(i0)') + '_' + string(dayno, f='(i03)'), count = ndays)
	endif
	if not keyword_set(year) and not keyword_set(dayno) then begin
		days_list = file_search(data_path, '*', count = ndays)
	endif

	for dz = 0., ndays - 1 do begin

		y = float(strmid(file_basename(days_list(dz)),0,4))
		dayno = float(strmid(file_basename(days_list(dz)),5,3))

		if lambda eq 630.0 then height = 240.
		if lambda eq 557.7 then height = 120.

		dat = drta_make_time_series(data_path, y, dayno, filter, lambda)

		if dat.data eq 0 then begin
			print, 'No Data'
			goto, SKIP_DRTA_PLOTEACH
		endif

		north 	= where(dat.directions.name eq 'North')
		south 	= where(dat.directions.name eq 'South')
		east 	= where(dat.directions.name eq 'East')
		west 	= where(dat.directions.name eq 'West')
		zenith 	= where(dat.directions.name eq 'Zenith')

		nnn = dat.directions(north).ndata
		nns = dat.directions(south).ndata
		nne = dat.directions(east).ndata
		nnw = dat.directions(west).ndata
		nnz = dat.directions(zenith).ndata

		if nnn lt 5 or nns lt 5 or nne lt 5 or nnz lt 5 then begin
			print, 'Num < 5'
			goto, SKIP_DRTA_PLOTEACH
		endif

		angs = *dat.directions(north).zen_ang
		hist = histogram(angs, loc = zang)
		keep_ang = zang(where(hist eq max(hist)))
		keep_ang = keep_ang(0)

		nth_p = (where(*dat.directions(north).zen_ang eq keep_ang))
		sth_p = (where(*dat.directions(south).zen_ang eq keep_ang))
		est_p = (where(*dat.directions(east).zen_ang eq keep_ang))
		if nnw gt 0 then wst_p = (where(*dat.directions(west).zen_ang eq keep_ang))
		zth_p = (where(*dat.directions(zenith).zen_ang eq 0))

		nth_wind = *dat.directions(north).wind
		sth_wind = *dat.directions(south).wind*(-1.0)
		est_wind = *dat.directions(east).wind
		if nnw gt 0 then wst_wind = *dat.directions(west).wind*(-1.0)
		zth_wind = *dat.directions(zenith).wind

		nth_winderr = *dat.directions(north).wind_err
		sth_winderr = *dat.directions(south).wind_err
		est_winderr = *dat.directions(east).wind_err
		if nnw gt 0 then wst_winderr = *dat.directions(west).wind_err
		zth_winderr = *dat.directions(zenith).wind_err

		nth_time = *dat.directions(north).time
		sth_time = *dat.directions(south).time
		est_time = *dat.directions(east).time
		if nnw gt 0 then wst_time = *dat.directions(west).time
		zth_time = *dat.directions(zenith).time

		nth_intens = *dat.directions(north).intens
		sth_intens = *dat.directions(south).intens
		est_intens = *dat.directions(east).intens
		if nnw gt 0 then wst_intens = *dat.directions(west).intens
		zth_intens = *dat.directions(zenith).intens

		nth_temp = *dat.directions(north).temp
		sth_temp = *dat.directions(south).temp
		est_temp = *dat.directions(east).temp
		if nnw gt 0 then wst_temp = *dat.directions(west).temp
		zth_temp = *dat.directions(zenith).temp

		nnn = n_elements(nth_p)
		nns = n_elements(sth_p)
		nne = n_elements(est_p)
		if nnw gt 0 then nnw = n_elements(wst_p)
		nnz = n_elements(zth_p)

		if nnn lt 5 or nns lt 5 or nne lt 5 or nnz lt 5 then begin
			print, 'Num < 5'
			goto, SKIP_DRTA_PLOTEACH
		endif

		;\\ Get HWM and MSIS
			ydn2md, y, dayno, mn, dy
			yymmdd = string(y-2000, f='(i2.2)') + string(mn, f='(i2.2)') + string(dy, f='(i2.2)')
			conds = get_geomag_conditions(yymmdd)
			secs = fltarr(100)
			for hj = 0, 99 do secs(hj) = (dat.time_range(0) + ((dat.time_range(1) - dat.time_range(0))/100.)*hj)*3600.
			hwm = get_hwm_wind(long(y+dayno), secs, height, -68.577, 77.967, conds.mag.f107, conds.mag.f107, $
							  [conds.mag.apmean, conds.mag.apmean], 0)
			msis = get_msis2000_params(long(dayno), secs, height, -68.577, 77.967, conds.mag.f107, conds.mag.f107, $
										conds.mag.apmean)


		loadct, 39, /silent
		if keyword_set(windowID) then begin
			wset, windowID
		endif else begin
			window, 0, xs = 700, ys = 900
		endelse
		erase, 255

		bounds = get_boundcoords_for_multiplots(5, [0.09, 0.05, 0.98, 0.98], 0.02)

		!p.multi = [0,1,5]
		!x.range = [DAT.TIME_RANGE(0), DAT.TIME_RANGE(1)]
		!y.style = 1
		!p.charsize = 2
		!p.charthick = 1

			;\\ Get average merid and zonal winds

				int_north = interpol(nth_wind(nth_p), nth_time(nth_p), (findgen(100)/100.)*(dat.time_range(1)-dat.time_range(0)) + dat.time_range(0))
				int_south = interpol(sth_wind(sth_p), sth_time(sth_p), (findgen(100)/100.)*(dat.time_range(1)-dat.time_range(0)) + dat.time_range(0))
				int_east  = interpol(est_wind(est_p), est_time(est_p),  (findgen(100)/100.)*(dat.time_range(1)-dat.time_range(0)) + dat.time_range(0))
				if nnw gt 0 then int_west  = interpol(wst_wind(wst_p), wst_time(wst_p),  (findgen(100)/100.)*(dat.time_range(1)-dat.time_range(0)) + dat.time_range(0))

				merid_time = (findgen(100)/100.)*(dat.time_range(1)-dat.time_range(0)) + dat.time_range(0)
				zonal_time = (findgen(100)/100.)*(dat.time_range(1)-dat.time_range(0)) + dat.time_range(0)
				merid_wind = (int_north + int_south)/2.
				if nnw gt 0 then zonal_wind = (int_east + int_west)/2. else zonal_wind = int_east

			;\\ Get median intensity in all directions
				int_intens = fltarr(n_elements(merid_time), n_elements(dat.directions))
				ave_intens = fltarr(n_elements(merid_time))

				int_nintens = interpol(nth_intens(nth_p), nth_time(nth_p), merid_time)
				int_sintens = interpol(sth_intens(sth_p), sth_time(sth_p), merid_time)
				int_eintens = interpol(est_intens(est_p), est_time(est_p), merid_time)
				if nnw gt 0 then int_wintens = interpol(wst_intens(wst_p), wst_time(wst_p), merid_time)
				int_zintens = interpol(zth_intens(zth_p), zth_time(zth_p), merid_time)

				for t = 0, n_elements(merid_time) - 1 do begin
					if nnw gt 0 then ave_intens(t) = median([int_nintens(t),int_sintens(t),int_eintens(t),int_wintens(t),int_zintens(t)]) $
						else ave_intens(t) = median([int_nintens(t),int_sintens(t),int_eintens(t),int_zintens(t)])
				endfor


			plot, nth_time(nth_p), nth_wind(nth_p), color = 0, back = 255, yrange = [-250,250], thick = 3, /nodata, xstyle=5, $
					pos=bounds(4,*), ytitle='Meridional Wind (ms!E-1!N)', /ystyle, $
					title = string(dayno, f='(i3.3)') + '/' + string(y,f='(i4.4)') + $
						   	', !7k!X' +	string(lambda, f='(f0.1)') + $
						   	' nm, Filter ' + string(filter, f='(i0)') + $
							' Zenith Angle: ' + string(keep_ang, f='(f0.1)')
			oplot, [!x.range(0), !x.range(1)], [0,0], color = 0, thick = 2, line = 1
			oplot, secs/3600., hwm(*,0), color = 0, thick = 2
			oplot, nth_time(nth_p), nth_wind(nth_p), color = 50, thick = 1, psym = 1
			oplot, nth_time(nth_p), nth_wind(nth_p), color = 50, thick = 1, line = 1
			oplot, sth_time(sth_p), sth_wind(sth_p), color = 250, thick = 1, psym = 1
			oplot, sth_time(sth_p), sth_wind(sth_p), color = 250, thick = 1, line = 1
			oplot, merid_time, merid_wind, color = 0, thick = 3

			!p.color = 50 & errplot, nth_time(nth_p), nth_wind(nth_p) - nth_winderr(nth_p), nth_wind(nth_p) + nth_winderr(nth_p)
			!p.color = 250 & errplot, sth_time(sth_p), sth_wind(sth_p) - sth_winderr(sth_p), sth_wind(sth_p) + sth_winderr(sth_p)
			!p.color = 255

			plot, est_time(est_p), est_wind(est_p), color = 0, back = 255, yrange = [-250,250], thick = 3, /nodata, xstyle=5, $
					pos=bounds(3,*), ytitle='Zonal Wind (ms!E-1!N)', /ystyle
			oplot, [!x.range(0), !x.range(1)], [0,0], color = 0, thick = 2, line = 1
			oplot, secs/3600., hwm(*,1), color = 0, thick = 2
			oplot, est_time(est_p), est_wind(est_p), color = 50, thick = 1, psym = 1
			oplot, est_time(est_p), est_wind(est_p), color = 50, thick = 1, line = 1
			if nnw gt 0 then oplot, wst_time(wst_p), wst_wind(wst_p), color = 250, thick = 1, psym = 1
			if nnw gt 0 then oplot, wst_time(wst_p), wst_wind(wst_p), color = 250, thick = 1, line = 1
			oplot, zonal_time, zonal_wind, color = 0, thick = 3

			!p.color = 50 & errplot, est_time(est_p), est_wind(est_p) - est_winderr(est_p), est_wind(est_p) + est_winderr(est_p)
			if nnw gt 0 then begin
				!p.color = 250 & errplot, wst_time(wst_p), wst_wind(wst_p) - wst_winderr(wst_p), wst_wind(wst_p) + wst_winderr(wst_p)
			endif
			!p.color = 255

			plot, zth_time(zth_p), zth_wind(zth_p), color = 0, back = 255, yrange = [-150,150], thick = 3, /nodata, xstyle=5, $
					pos=bounds(2,*), ytitle='Zenith Wind (ms!E-1!N)', /ystyle
			oplot, [!x.range(0), !x.range(1)], [0,0], color = 0, thick = 2, line = 1
			oplot, zth_time(zth_p), zth_wind(zth_p), color = 50, thick = 1, psym = 1
			oplot, zth_time(zth_p), zth_wind(zth_p), color = 50, thick = 1, line = 1

			!p.color = 50 & errplot, zth_time(zth_p), zth_wind(zth_p) - zth_winderr(zth_p), zth_wind(zth_p) + zth_winderr(zth_p)
			!p.color = 255

			plot, nth_time(nth_p), nth_temp(nth_p), color = 0, back = 255, yrange = [300,1200], thick = 3, /nodata, xstyle=5, $
					pos=bounds(1,*), ytitle='Temperature (K)', /ystyle
			oplot, secs/3600., msis.temp, color = 0, thick = 2
			oplot, nth_time(nth_p), nth_temp(nth_p), color = 50, thick = 1, line = 1
			oplot, nth_time(nth_p), nth_temp(nth_p), color = 50, thick = 1, psym = 1
			oplot, est_time(est_p), est_temp(est_p), color = 50, thick = 1, line = 1
			oplot, est_time(est_p), est_temp(est_p), color = 50, thick = 1, psym = 1
			oplot, sth_time(sth_p), sth_temp(sth_p), color = 250, thick = 1, line = 1
			oplot, sth_time(sth_p), sth_temp(sth_p), color = 250, thick = 1, psym = 1
			if nnw gt 0 then oplot, wst_time(wst_p), wst_temp(wst_p), color = 250, thick = 1, line = 1
			if nnw gt 0 then oplot, wst_time(wst_p), wst_temp(wst_p), color = 250, thick = 1, psym = 1
			oplot, zth_time(zth_p), zth_temp(zth_p), color = 150, thick = 1, line = 1
			oplot, zth_time(zth_p), zth_temp(zth_p), color = 150, thick = 1, psym = 1


			plot, nth_time(nth_p), nth_temp(nth_p), color = 0, back = 255, yrange = [0,7], thick = 3, /nodata, xstyle=5, $
					pos=bounds(0,*), xtitle='UT Time (Hours)',ytitle = 'Relative Intensity', xtick_get = xvals, xtickint = 2
			oplot, secs/3600., msis.temp, color = 0, thick = 2
			oplot, nth_time(nth_p), nth_intens(nth_p), color = 50, thick = 1, line = 1
			oplot, nth_time(nth_p), nth_intens(nth_p), color = 50, thick = 1, psym = 1
			oplot, est_time(est_p), est_intens(est_p), color = 50, thick = 1, line = 1
			oplot, est_time(est_p), est_intens(est_p), color = 50, thick = 1, psym = 1
			oplot, sth_time(sth_p), sth_intens(sth_p), color = 250, thick = 1, line = 1
			oplot, sth_time(sth_p), sth_intens(sth_p), color = 250, thick = 1, psym = 1
			if nnw gt 0 then oplot, wst_time(wst_p), wst_intens(wst_p), color = 250, thick = 1, line = 1
			if nnw gt 0 then oplot, wst_time(wst_p), wst_intens(wst_p), color = 250, thick = 1, psym = 1
			oplot, zth_time(zth_p), zth_intens(zth_p), color = 150, thick = 1, line = 1
			oplot, zth_time(zth_p), zth_intens(zth_p), color = 150, thick = 1, psym = 1
			oplot, merid_time, ave_intens, color = 0, thick = 3

			xlt = where(xvals lt 0, nlt)
			while nlt gt 0 do begin
				xvals(xlt) = xvals(xlt) + 24
				xlt = where(xvals lt 0, nlt)
			endwhile
			axis, xaxis=0, xstyle=9, xtickname = string(xvals mod 24, f='(i0)'), xtickint = 2, color = 0

			!p.multi = 0
			!p.position = 0


			if not keyword_set(nosave) then begin
				pic = tvrd(/true)
				filename = plot_path + file_basename(days_list(dz)) + '_' + $
						   string(lambda,f='(f0.1)') + 'nm_Filter_' + string(filter,f='(i0)') + '.png'
				write_png, filename, pic
				print, filename
			endif

	SKIP_DRTA_PLOTEACH:
	wait, 0.01
	endfor

end