

;\\ Performs real-time plotting for DRTA

pro davis_real_time_analysis_plotter, data_path, plot_path, lambda, filter, plot_time, ndays, time_str=time_str


	loadct, 39, /silent
	window, 0, xs = 700, ys = 900
	erase, 255

	days_list = file_search(data_path, '*', count = days)

	js2ymds, dt_tm_tojs(systime(/ut)), y, m, d, s

	y = y
	dayno = ymd2dn(y, m, d)
	current_time = systime(/ut, /sec) / 3600.

	if keyword_set(time_str) then begin
		current_time = time_str.current_time
		y = time_str.year
		dayno =	time_str.dayno
	endif

	ndata = 0

	for dz = 0., ndays - 1 do begin

			dat = drta_make_time_series(data_path, y, dayno-dz, filter, lambda)

			ndata = ndata + dat.data
			if dat.data eq 0 then goto, DRTA_PLOTTER_SKIPDATE

			north 	= where(dat.directions.name eq 'North')
			south 	= where(dat.directions.name eq 'South')
			east 	= where(dat.directions.name eq 'East')
			west 	= where(dat.directions.name eq 'West')
			zenith 	= where(dat.directions.name eq 'Zenith')

			bounds = get_boundcoords_for_multiplots(4, [0.09, 0.05, 0.98, 0.98], 0.02)

			!p.multi = [0,1,4]
			!x.range = [current_time - plot_time, current_time + 2.]
			!y.style = 1
			!p.charsize = 2
			!p.charthick = 1
			if dz eq 1 then begin
				!p.noerase = 1
				for dirz = 0, n_elements(dat.directions) - 1 do begin
					*dat.directions(dirz).time = *dat.directions(dirz).time - 24.0*dz
				endfor
				dat.time_range = dat.time_range - 24.0
			endif

			;\\ Turn the direction winds into meridional and zonal winds
				*dat.directions(south).wind = *dat.directions(south).wind * (-1.0)
				*dat.directions(west).wind  = *dat.directions(west).wind * (-1.0)

				int_north = interpol(*dat.directions(north).wind, *dat.directions(north).time, (findgen(100)/100.)*(dat.time_range(1)-dat.time_range(0)) + dat.time_range(0))
				int_south = interpol(*dat.directions(south).wind, *dat.directions(south).time, (findgen(100)/100.)*(dat.time_range(1)-dat.time_range(0)) + dat.time_range(0))
				int_east  = interpol(*dat.directions(east).wind,  *dat.directions(east).time,  (findgen(100)/100.)*(dat.time_range(1)-dat.time_range(0)) + dat.time_range(0))
				int_west  = interpol(*dat.directions(west).wind,  *dat.directions(west).time,  (findgen(100)/100.)*(dat.time_range(1)-dat.time_range(0)) + dat.time_range(0))

				merid_time = (findgen(100)/100.)*(dat.time_range(1)-dat.time_range(0)) + dat.time_range(0)
				zonal_time = (findgen(100)/100.)*(dat.time_range(1)-dat.time_range(0)) + dat.time_range(0)
				merid_wind = (int_north + int_south)/2.
				zonal_wind = (int_east + int_west)/2.

			;\\ Get median intensity in all directions
				int_intens = fltarr(n_elements(merid_time), n_elements(dat.directions))
				ave_intens = fltarr(n_elements(merid_time))
				for n = 0, n_elements(dat.directions) - 1 do begin
					int_intens(*,n) = interpol(*dat.directions(n).intens, *dat.directions(n).time, merid_time)
				endfor
				for t = 0, n_elements(merid_time) - 1 do begin
					ave_intens(t) = median(int_intens(t,*))
				endfor


			plot, *dat.directions(north).time, *dat.directions(north).wind, color = 0, back = 255, yrange = [-300,300], thick = 3, /nodata, xstyle=5, $
					pos=bounds(3,*), ytitle='Meridional Wind (ms!E-1!N)', $
					title = string(dayno, f='(i3.3)') + '/' + string(y,f='(i4.4)') + ', !7k!X' + string(lambda, f='(f0.1)') + ' nm, Filter ' + string(filter, f='(i0)')
			oplot, [!x.range(0), !x.range(1)], [0,0], color = 0, thick = 2, line = 1
			oplot, *dat.directions(north).time, *dat.directions(north).wind, color = 50, thick = 1, psym = 1
			oplot, *dat.directions(north).time, *dat.directions(north).wind, color = 50, thick = 1, line = 1
			oplot, *dat.directions(south).time, *dat.directions(south).wind, color = 250, thick = 1, psym = 1
			oplot, *dat.directions(south).time, *dat.directions(south).wind, color = 250, thick = 1, line = 1
			oplot, merid_time, merid_wind, color = 0, thick = 3

			!p.color = 50 & errplot, *dat.directions(north).time, *dat.directions(north).wind - *dat.directions(north).wind_err, *dat.directions(north).wind + *dat.directions(north).wind_err
			!p.color = 250 & errplot, *dat.directions(south).time, *dat.directions(south).wind - *dat.directions(south).wind_err, *dat.directions(south).wind + *dat.directions(south).wind_err
			!p.color = 255

			plot, *dat.directions(east).time, *dat.directions(east).wind, color = 0, back = 255, yrange = [-300,300], thick = 3, /nodata, xstyle=5, $
					pos=bounds(2,*), ytitle='Zonal Wind (ms!E-1!N)'
			oplot, [!x.range(0), !x.range(1)], [0,0], color = 0, thick = 2, line = 1
			oplot, *dat.directions(east).time, *dat.directions(east).wind, color = 50, thick = 1, psym = 1
			oplot, *dat.directions(east).time, *dat.directions(east).wind, color = 50, thick = 1, line = 1
			oplot, *dat.directions(west).time, *dat.directions(west).wind, color = 250, thick = 1, psym = 1
			oplot, *dat.directions(west).time, *dat.directions(west).wind, color = 250, thick = 1, line = 1
			oplot, zonal_time, zonal_wind, color = 0, thick = 3

			!p.color = 50 & errplot, *dat.directions(east).time, *dat.directions(east).wind - *dat.directions(east).wind_err, *dat.directions(east).wind + *dat.directions(east).wind_err
			!p.color = 250 & errplot, *dat.directions(west).time, *dat.directions(west).wind - *dat.directions(west).wind_err, *dat.directions(west).wind + *dat.directions(west).wind_err
			!p.color = 255


			plot, *dat.directions(zenith).time, *dat.directions(zenith).wind, color = 0, back = 255, yrange = [-150,150], thick = 3, /nodata, xstyle=5, $
					pos=bounds(1,*), ytitle='Zenith Wind (ms!E-1!N)'
			oplot, [!x.range(0), !x.range(1)], [0,0], color = 0, thick = 2, line = 1
			oplot, *dat.directions(zenith).time, *dat.directions(zenith).wind, color = 50, thick = 1, psym = 1
			oplot, *dat.directions(zenith).time, *dat.directions(zenith).wind, color = 50, thick = 1, line = 1

			!p.color = 50 & errplot, *dat.directions(zenith).time, *dat.directions(zenith).wind - *dat.directions(zenith).wind_err, *dat.directions(zenith).wind + *dat.directions(zenith).wind_err
			!p.color = 255


			plot, *dat.directions(north).time, *dat.directions(north).intens, color = 0, back = 255, yrange = [0,7], thick = 3, /nodata, xstyle=5, pos=bounds(0,*), xtitle='UT Time (Hours)', $
				  ytitle = 'Relative Intensity', xtick_get = xvals, xtickint = 2
			oplot, *dat.directions(north).time, *dat.directions(north).intens, color = 50, thick = 1, psym = 1
			oplot, *dat.directions(north).time, *dat.directions(north).intens, color = 50, thick = 1, line = 1
			oplot, *dat.directions(south).time, *dat.directions(south).intens, color = 70, thick = 1, psym = 1
			oplot, *dat.directions(south).time, *dat.directions(south).intens, color = 70, thick = 1, line = 1
			oplot, *dat.directions(east).time, *dat.directions(east).intens, color = 90, thick = 1, psym = 1
			oplot, *dat.directions(east).time, *dat.directions(east).intens, color = 90, thick = 1, line = 1
			oplot, *dat.directions(west).time, *dat.directions(west).intens, color = 110, thick = 1, psym = 1
			oplot, *dat.directions(west).time, *dat.directions(west).intens, color = 110, thick = 1, line = 1
			oplot, *dat.directions(zenith).time, *dat.directions(zenith).intens, color = 120, thick = 1, psym = 1
			oplot, *dat.directions(zenith).time, *dat.directions(zenith).intens, color = 120, thick = 1, line = 1
			oplot, merid_time, ave_intens, color = 0, thick = 3

			xlt = where(xvals lt 0, nlt)
			while nlt gt 0 do begin
				xvals(xlt) = xvals(xlt) + 24
				xlt = where(xvals lt 0, nlt)
			endwhile
			axis, xaxis=0, xstyle=9, xtickname = string(xvals mod 24, f='(i0)'), xtickint = 2, color = 0

			!p.multi = 0
			!p.position = 0

			if dz eq ndays - 1 then !p.noerase = 0

	DRTA_PLOTTER_SKIPDATE:
	endfor

	if ndata eq 0 then begin
		xyouts, .35, .55, /normal, chart=2, chars = 2, 'NO DATA AVAILABLE', color = 0
	endif

	pic = tvrd(/true)
	filename = plot_path + string(y, f='(i4.4)') + '_' + string(dayno, f='(i3.3)') + '.png'

	write_png, filename, pic
	wdelete, 0


DRTA_RTA_PLOTTER_END:
end