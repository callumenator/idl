
@resolve_nstatic_wind

pro sdi_monitor_multistatic

	common sdi_monitor_common, global, persistent

	if ptr_valid(persistent.zonemaps) eq 0 then return
	if ptr_valid(persistent.snapshots) eq 0 then return

	base_geom = widget_info(global.tab_id[4], /geometry)
	widget_control, draw_ysize=1000, draw_xsize = 1000, global.draw_id[4]
	widget_control, get_value = wset_id, global.draw_id[4]
	wset, wset_id
	erase, 0

	show_zonemaps = 0
	show_bistatic = 1
	show_tristatic = 0
	scale= 5E2

	tseries = file_search('c:\rsi\idl\routines\sdi\monitor\timeseries\*' + $
							['HRP','PKR','TLK'] + '*6300*', count = nseries)

	allMeta = ptrarr(nseries, /alloc)
	allSeries = ptrarr(nseries, /alloc)
	allTImeInfo = replicate({dayno:0, js_min:0D, js_max:0D}, nseries)
	for i = 0, nseries - 1 do begin
		restore, tseries[i]
		find_contiguous, js2ut(series.start_time) mod 24, 3., blocks, n_blocks=nb, /abs
		ts_0 = blocks[nb-1,0]
		ts_1 = blocks[nb-1,1]
		series = series[ts_0:ts_1]
		*allSeries[i] = series
		*allMeta[i] = meta[0]

		js2ymds, series.start_time, y, m, d, s
		if (max(d) - min(d)) gt 0 then begin
			print, 'A contiguous block from more than 1 day was detected!'
			return
		endif

		allTimeInfo[i].dayno = ymd2dn(y[0], m[0], d[0])
		allTimeInfo[i].js_min = min((series.start_time + series.end_time)/2.)
		allTimeInfo[i].js_max = max((series.start_time + series.end_time)/2.)
	endfor

	;\\ Find a recent time that all sites can be interpolated to
	common_time = min(allTimeInfo.js_max) - 10.*3600
	js2ymds, common_time, cmn_y, cmn_m, cmn_d, cmn_s

	allWinds = ptrarr(nseries, /alloc)
	allWindErrs = ptrarr(nseries, /alloc)

	for i = 0, nseries - 1 do begin

			series = (*allSeries[i])
			metadata = (*allMeta[i])
			sdi_monitor_format, {metadata:metadata, series:series}, $
								meta = meta, $
								spek = speks, $
								zone_centers = zcen

			nobs = n_elements(speks)
			sdi3k_drift_correct, speks, meta, /data_based, /force
			sdi3k_remove_radial_residual, meta, speks, parname='VELOCITY'
    		speks.velocity *= meta.channels_to_velocity
    		speks.sigma_velocity *= meta.channels_to_velocity
    		posarr = speks.velocity
    		sdi3k_timesmooth_fits,  posarr, 1.1, meta
    		sdi3k_spacesmooth_fits, posarr, 0.03, meta, zcen
    		speks.velocity = posarr
    		speks.velocity -= total(speks[1:nobs-2].velocity[0])/n_elements(speks[1:nobs-2].velocity[0])

			sdi_time_interpol, speks.velocity, $
							   (speks.start_time + speks.end_time)/2., $
							   common_time, $
							   winds

			sdi_time_interpol, speks.sigma_velocity, $
							   (speks.start_time + speks.end_time)/2., $
							   common_time, $
							   wind_errors

			*allMeta[i] = meta
			*allWinds[i] = winds
			*allWindErrs[i] = wind_errors
	endfor


	altitude = 240.
	n_sites = nseries

	;\\ ######## Bistatic ########
	for stn0 = 0, n_sites - 1 do begin
	for stn1 = stn0 + 1, n_sites - 1 do begin

		fit_bistatic, *allMeta[stn0], *allMeta[stn1], $
				  	  *allWinds[stn0], *allWinds[stn1], $
				  	  *allWindErrs[stn0], *allWindErrs[stn1], $
				  	  altitude, $
				  	  fit = fit

		append, fit, bistaticFits
		append, {stn0:(*allMeta[stn0]).site_code, $
				 stn1:(*allMeta[stn1]).site_code }, bistaticPairs

	endfor
	endfor


	;\\ ######## Tristatic ########
	for stn0 = 0, n_sites - 1 do begin
	for stn1 = stn0 + 1, n_sites - 1 do begin
	for stn2 = stn1 + 1, n_sites - 1 do begin

		fit_tristatic, *allMeta[stn0], *allMeta[stn1], *allMeta[stn2], $
				  	   *allWinds[stn0], *allWinds[stn1], *allWinds[stn2], $
				  	   *allWindErrs[stn0], *allWindErrs[stn1], *allWindErrs[stn2], $
				  	   altitude, $
				  	   fit = fit

		append, fit, tristaticFits
		append, {stn0:(*allMeta[stn0]).site_code, $
				 stn1:(*allMeta[stn1]).site_code, $
				 stn2:(*allMeta[stn2]).site_code }, tristaticPairs

	endfor
	endfor
	endfor

	plot_simple_map, median(bistaticFits.lat), median(bistaticFits.lon), 9, 1, 1, map=map, $
					 backcolor=[0,0], continentcolor=[50,0], $
					 outlinecolor=[90,0], bounds = bounds

	overlay_geomag_contours, map, longitude=10, latitude=5, color=[0, 100]

	if show_zonemaps eq 1 then begin
		for i = 0, nseries - 1 do begin
			plot_zonemap_on_map, 0, 0, 0, 0, 240., $
								 180 + (*allMeta[i]).oval_angle, $
								 0, map, meta=*allMeta[i], front_color = 150, $
								 lineThick=.5, ctable=0
		endfor
	endif

	tvlct, red, gre, blu, /get
	loadct, 39, /silent


	;\\ Overlay Bistatic Winds
	if show_bistatic eq 1 then begin
		use = where(max(bistaticFits.overlap, dim=1) gt .2 and $
					bistaticFits.obsdot lt .8 and $
					bistaticFits.mangle gt 30 and $
					bistaticFits.merr/bistaticFits.mcomp lt .5 and $
					bistaticFits.lerr/bistaticFits.lcomp lt .5, nuse )

		if (nuse gt 0) then begin
			bistaticFits = bistaticFits[use]

			for i = 0, nuse - 1 do begin

				outWind = project_bistatic_fit(bistaticFits[i], 0)

				magnitude = sqrt(outWind[0]*outWInd[0] + outWind[1]*outWind[1]) * scale
				azimuth = atan(outWind[0], outWind[1]) / !DTOR

				get_mapped_vector_components, map, bistaticFits[i].lat, bistaticFits[i].lon, $
											  magnitude, azimuth, x0, y0, xlen, ylen

				arrow, x0, y0, x0 + xlen, y0 + ylen, /data, color = 255, hsize = 8

			endfor
		endif
	endif


	;\\ Overlay Tristatic Winds
	if show_tristatic eq 1 then begin
		use = where(max(tristaticFits.overlap, dim=1) gt .01 and $
					tristaticFits.obsdot lt .8 and $
					tristaticFits.uerr/tristaticFits.u lt .5 and $
					tristaticFits.verr/tristaticFits.v lt .5, nuse )

		if (nuse gt 0) then begin
			tristaticFits = tristaticFits[use]

			for i = 0, nuse - 1 do begin

				outWind = [tristaticFits[i].u, tristaticFits[i].v]

				magnitude = sqrt(outWind[0]*outWInd[0] + outWind[1]*outWind[1]) * scale
				azimuth = atan(outWind[0], outWind[1]) / !DTOR

				get_mapped_vector_components, map, tristaticFits[i].lat, tristaticFits[i].lon, $
											  magnitude, azimuth, x0, y0, xlen, ylen

				arrow, x0, y0, x0 + xlen, y0 + ylen, /data, color = 150, hsize = 8

			endfor
		endif
	endif


	;\\ Scale arrow
	plot_vector_scale_on_map, [.01, .92], map, 200, scale, 0, thick = 2, headthick = 2
	!p.font = 0
	device, set_font='Ariel*17*Bold'
	xyouts, .01, .98, 'Bistatic Winds', /normal
	xyouts, .01, .955, time_str_from_decimalut(js2ut(common_time)) + ' UT', /normal
	xyouts, .01, .93, '200 m/s', /normal
	!p.font = -1

	tvlct, red, gre, blu
	ptr_free, allSeries, allMeta
end
