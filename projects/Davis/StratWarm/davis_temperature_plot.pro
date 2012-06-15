
pro davis_temperature_plot

	period_start = [2010, 5, 1]
	period_end = [2010, 10, 1]

	dayno_start = ymd2dn(period_start[0], period_start[1], period_start[2])
	dayno_end = ymd2dn(period_end[0], period_end[1], period_end[2])

	davisPath = 'c:\cal\FPSData\Davis\'
	allFiles = file_search(davisPath, '*', count = nfiles)

	year = float(strmid(file_basename(allFiles), 0, 4))
	day = float(strmid(file_basename(allFiles), 5, 3))
	use = where(year ge period_start[0] and year le period_end[0] and $
				day ge dayno_start and day le dayno_end, nUse)


;		tempPtrs = ptrarr(nUse)
;		timePtrs = ptrarr(nUse)
;		for u = 0, nUse - 1 do begin
;
;			restore, allFiles[use[u]]
;
;			timeProx = day[use[u]] + sky.ut / 24.
;			temps = refit_davis_temperatures( year[use[u]], day[use[u]])
;
;			tempPtrs[u] = ptr_new(temps)
;			timePtrs[u] = ptr_new(timeProx)
;
;			wait, 0.001
;			print, u, nUse
;		endfor


	restore, 'C:\cal\IDLSource\NewAlaskaCode\Davis\StratWarm\Temperatures_Saved.idlsave'

	temps = [0.]
	times = [0.]
	msis = [0.]
	for k = 0, n_elements(tempPtrs) - 1 do begin
		temps = [temps, (*tempPtrs[k])[*,0]]
		times = [times, (*timePtrs[k])[*,0]]
		day = fix((*timePtrs[k])[0,0])

		conds = get_geomag_conditions(ydn_to_yymmdd(2010, day), /quick)
		model = get_msis2000_params(day, 15*3600., 240, -68.5, 78, conds.mag.f107, conds.mag.f107, conds.mag.apmean)

		msis = [msis, replicate(model.temp, n_elements((*tempPtrs[k])[*,0]))]
	endfor

	smTemps = smooth_in_time(times, temps, n_elements(temps)*5, 3)


	;\\ Setup a plot

	loadct, 39, /silent
	xrange = [dayno_start, dayno_end]
	yrange = [300, 1500]
	plot, /nodata, [0,0], xrange = xrange, yrange = yrange, chars = 1.5, chart = 1.5, $
		  /xstyle, /ystyle, xtitle = 'Day Number', ytitle = 'Temperature (K)', color = 0, back = 255

	oplot, times, temps, psym=3, color = 0
	oplot, times, smTemps, color = 250, thick = 3
	oplot, times, msis, color = 50, thick = 3
	plots, [182, 182], yrange, noclip=0, thick=3, color = 150
	plots, [242, 242], yrange, noclip=0, thick=3, color = 150

	xyouts, /data, 125, 1400, '3-Day Smoothed Davis Temperature (630.0 nm)', color = 250, chart = 1.5, chars = 1.5
	xyouts, /data, 125, 1350, 'NRLMSISE-00 Temperature', color = 50, chart = 1.5, chars = 1.5

	stop

end