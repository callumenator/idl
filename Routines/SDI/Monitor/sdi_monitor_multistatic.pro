
@resolve_nstatic_wind

;\\ Grab the latest allsky camera image
pro sdi_monitor_grab_allsky, maxElevation, error=error

	error = 0
	time = bin_date(systime(/ut))
	jd = js2jd(dt_tm_tojs(systime()))
	ut_fraction = (time(3)*3600. + time(4)*60. + time(5)) / 86400.
	sidereal_time = lmst(jd, ut_fraction, 0) * 24.
	sunpos, jd, RA, Dec
	sun_lat = Dec
	sun_lon = RA - (15. * sidereal_time)
	ll2rb, (station_info('pkr')).glon, (station_info('pkr')).glat, sun_lon, sun_lat, range, azimuth
	sun_elevation = refract(90 - (range * !radeg))
	if sun_elevation lt maxElevation then begin

		catch, error_status

	   ;\\ Catch errors retrieving allsky image
	   	if error_status ne 0 then begin
	    	print, 'Error retrieving allsky image'
	    	catch, /cancel
	    	error = 1
	    	return
	   	endif

		;\\ Copy the allsky image from the URL to a local file
		dummy = webget('http://optics.gi.alaska.edu/realtime/latest/pkr_latest_rgb.jpg', $
						copyfile = 'c:\rsi\idl\routines\sdi\monitor\latest_allsky.jpeg')
	endif
end


;\\ BLEND THE BISTATIC WINDS
function sdi_monitor_blend, bistaticFits, $
				       	  	sigma=sigma, $
							maxDist=maxDist

	;\\ Get an even grid of locations for blending, stay inside bistatic boundary
	use = where(max(bistaticFits.overlap, dim=1) gt .1 and $
				bistaticFits.obsdot lt .8 and $
				bistaticFits.mangle gt 25 and $
				abs(bistaticFits.mcomp) lt 500 and $
				abs(bistaticFits.lcomp) lt 500 and $
				bistaticFits.merr/bistaticFits.mcomp lt .3 and $
				bistaticFits.lerr/bistaticFits.lcomp lt .3, nbi )
	if nbi lt 5 then return, 0

	if not keyword_set(sigma) then sigma = 0.8
	bi = bistaticFits[use]
	missing = -9999

	;triangulate, bi.lon, bi.lat, tr, b
	;grid_lat = trigrid(bi.lon, bi.lat, bi.lat, tr, missing=missing, nx = 15, ny=15)
	;grid_lon = trigrid(bi.lon, bi.lat, bi.lon, tr, missing=missing, nx = 15, ny=15)
	;use = where(grid_lon ne missing and grid_lat ne missing, nuse)

	ilats = bi.lat
	ilons = bi.lon
	nuse = nbi
	zonal = ilats
	merid = ilats

	allZonal = fltarr(nbi)
	allMerid = fltarr(nbi)
	for i = 0, nbi - 1 do begin
		outWind = project_bistatic_fit(bi[i], 0)
		allZonal[i] = outWind[0]
		allMerid[i] = outWind[1]
	endfor
	for locIdx = 0, nuse - 1 do begin
		latDist = (bi.lat - ilats[locIdx])
		lonDist = (bi.lon - ilons[locIdx])
		dist = sqrt(lonDist*lonDist + latDist*latDist)
		weight = exp(-(dist*dist)/(2*sigma*sigma))
		if keyword_set(maxDist) then begin
			if (min(dist) gt maxDist) then useIt = 0 else useIt = 1
		endif else begin
			useIt = 1
		endelse
		if (useIt eq 1) then begin
			zonal[locIdx] = total(allZonal * weight)/total(weight)
			merid[locIdx] = total(allMerid * weight)/total(weight)
		endif else begin
			zonal[locIdx] = -999
			merid[locIdx] = -999
		endelse
	endfor

	keep = where(zonal ne -999, nkeep)
	return, {lat:ilats[keep], lon:ilons[keep], zonal:zonal[keep], merid:merid[keep]}

end
;\\ --------------------------------------------------------------------------------------------------



pro sdi_monitor_multistatic, datafile=datafile, $ snapshot/zonemap save file
							 timeseries=timeseries, $ ;\\ time series directory
							 save_name=save_name ;\\ save a png to this filename

	whoami, dir, file

 	if not keyword_set(datafile) then datafile = dir + '\persistent.idlsave'
 	if not keyword_set(timeseries) then timeseries = dir + '\timeseries\'

 	if file_test(datafile) eq 0 then return
	tries = 0
	catch, error
	if error ne 0 then begin
		if tries lt 3 then begin
			wait, 2. & tries ++
		endif else begin
			catch, /cancel & return
		endelse
	endif
	restore, datafile
	catch, /cancel

	if ptr_valid(persistent.snapshots) eq 0 then return
	if ptr_valid(persistent.zonemaps) eq 0 then return
	if size(*persistent.snapshots, /type) eq 0 then return
	if size(*persistent.zonemaps, /type) eq 0 then return

	snapshots = *persistent.snapshots 	;\\ array of snapshot structs
	zonemaps = *persistent.zonemaps		;\\ array of zonemap structs

	;\\ Multistatic time-series save file
		saved_data = dir + '\timeseries\Multistatic_timeseries.idlsave'
		have_saved_data = file_test(saved_data)
		if (have_saved_data eq 1) then restore, saved_data

	;\\ Options
		show_zonemaps = 0
		show_bistatic = 1
		show_tristatic = 1
		show_monostatic = 1
		scale= 5E2

	;\\ Create a window
		window, /free, xs=600, ys=800, /pixmap
		wid = !D.WINDOW
		loadct, 39, /silent
		erase, 0

	;\\ UT day range of interest (the current UT day for now, since obs from Alaska don't span days)
		current_ut_day = dt_tm_fromjs(dt_tm_tojs(systime(/ut)), format='doy$')
		ut_day_range = [current_ut_day, current_ut_day]

	;\\ If saved data were restored, slice it so we only have the current ut day
		if have_saved_data eq 1 then begin
			js2ymds, bistatic_vz_times, y, m, d, s
			daynos = ymd2dn(y, m, d)
			slice = where(daynos ge ut_day_range[0] and daynos le ut_day_range[1], nsliced)
			if nsliced eq 0 then begin
				have_saved_data = 0
			endif else begin
				bistatic_vz = bistatic_vz[slice]
				bistatic_vz_times = bistatic_vz_times[slice]
			endelse
		endif

		tseries = file_search(timeseries + '*' + ['HRP','PKR','TLK'] + '*6300*timeseries*', count = nseries)

	;\\ Run through the series
		for i = 0, nseries - 1 do begin
			restore, tseries[i]

			;\\ Get contiguous data inside ut_day_range
			js2ymds, series.start_time, y, m, d, s
			daynos = ymd2dn(y, m, d)
			slice = where(daynos ge ut_day_range[0] and daynos le ut_day_range[1], nsliced)
			if nsliced eq 0 then continue
			series = series[slice]

			find_contiguous, js2ut(series.start_time) mod 24, 3., blocks, n_blocks=nb, /abs
			ts_0 = blocks[nb-1,0]
			ts_1 = blocks[nb-1,1]
			series = series[ts_0:ts_1]

			append, ptr_new(series), allSeries
			append, ptr_new(meta[0]), allMeta
			append,{dayno:ymd2dn(y[0], m[0], d[0]), $
					js_min:min((series.start_time + series.end_time)/2.), $
					js_max:max((series.start_time + series.end_time)/2.) }, allTimeInfo
		endfor

		nseries = n_elements(allMeta)
		if nseries eq 0 then goto, END_MULTISTATIC


	;\\ Find a recent time that all sites can be interpolated to
		common_time = min(allTimeInfo.js_max) - 60.
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
				if nobs lt 5 then goto, END_MULTISTATIC
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
	if nseries ge 2 then begin
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

		;\\ Append the vertical wind data to the multistatic timeseries
		bivz = where(max(bistaticFits.overlap, dim=1) gt .1 and $
					 	 bistaticFits.obsdot lt .6 and $
					 	 bistaticFits.mangle lt 4, nbivz)

		if nbivz gt 0 then begin
			save_this_one = 0
			if have_saved_data eq 1 then begin
				if bistatic_vz_times[n_elements(bistatic_vz_times)-1] ne common_time then save_this_one = 1
			endif else begin
				save_this_one = 1
			endelse

			if save_this_one eq 1 then begin
				append, bistaticFits[bivz], bistatic_vz
				append, replicate(common_time, nbivz), bistatic_vz_times
				save, filename = saved_data, bistatic_vz, bistatic_vz_times
			endif
		endif
	endif


	;\\ ######## Tristatic ########
	if nseries ge 3 then begin
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
	endif


	;\\ Nominal values of middle lat and lon, refined depending on available info
	midLat = 65.
	midLon = -147.
	mono_filename = dir + 'latest_monostatic_6300.idlsave'
	if file_test(mono_filename) eq 1 then begin
		restore, mono_filename
		midLat = mean(monostatic.lat)
		midLon = mean(monostatic.lon)
	endif else begin
		if size(bistaticFits, /type) ne 0 then begin
			midLat = median(bistaticFits.lat)
			midLon = median(bistaticFits.lon)
		endif
	endelse

	erase, 0
	plot_simple_map, midLat, midLon, 8, 1, 1, map=map, $
					 backcolor=[0,0], continentcolor=[50,0], $
					 outlinecolor=[90,0], bounds = [0,.25,1,1]

	;\\ Allsky image (only get if sun elevation is below -8 to avoid saturation)
	sdi_monitor_grab_allsky, -8, error=error
	print, 'MULTISTATIC ALLSKY ERROR: ', error
	if (error eq 1) or file_test(dir + '\latest_allsky.jpeg') eq 0 then begin
		allsky_image = fltarr(3,512,512)
	endif else begin
		read_jpeg, dir + '\latest_allsky.jpeg', allsky_image
	endelse
	plot_allsky_on_map, map, allsky_image, 80., 23, 240., 65.13, -147.48, [600,800], /webimage

	overlay_geomag_contours, map, longitude=10, latitude=5, color=[0, 100]

	if show_zonemaps eq 1 then begin
		for i = 0, nseries - 1 do begin
			plot_zonemap_on_map, 0, 0, 0, 0, 240., $
								 180 + (*allMeta[i]).oval_angle, $
								 0, map, meta=*allMeta[i], front_color = 0, $
								 lineThick=.5, ctable=0
		endfor
	endif


	;\\ Plot small circles around station locations
	loadct, 39, /silent
	for i = 0, nseries - 1 do begin
		xy = map_proj_forward((*allMeta[i]).longitude, (*allMeta[i]).latitude, map=map)
		circ = findgen(361)*!DTOR
		plots, /data, xy[0] + 1.5E4*cos(circ), xy[1] + 1.5E4*sin(circ), thick=1, color = 190
	endfor

	!p.font = 0
	device, set_font='Ariel*17*Bold'


	;\\ Show monostatic winds for context
	if show_monostatic eq 1 then begin

		loadct, 0, /silent
		if file_test(mono_filename) eq 0 then goto, SKIP_MONO_BLEND

		if abs(monostatic.time - common_time) lt 5*3600. then begin

			mono = monostatic
			magnitude = sqrt(mono.zonal*mono.zonal + mono.merid*mono.merid) * scale
			azimuth = atan(mono.zonal, mono.merid) / !DTOR

			;\\ Get an even grid of locations for blending, stay inside monostatic boundary
			missing = -9999
			triangulate, mono.lon, mono.lat, tr, b
			grid_lat = trigrid(mono.lon, mono.lat, mono.lat, tr, missing=missing, nx = 20, ny=20)
			grid_lon = trigrid(mono.lon, mono.lat, mono.lon, tr, missing=missing, nx = 20, ny=20)
			use = where(grid_lon ne missing and grid_lat ne missing, nuse)
			ilats = grid_lat[use]
			ilons = grid_lon[use]

			for locIdx = 0, nuse - 1 do begin

				latDist = (mono.lat - ilats[locIdx])
				lonDist = (mono.lon - ilons[locIdx])
				dist = sqrt(lonDist*lonDist + latDist*latDist)

				sigma = 1.0
				weight = exp(-(dist*dist)/(2*sigma*sigma))
				zonal = total(mono.zonal * weight)/total(weight)
				merid = total(mono.merid * weight)/total(weight)

				magnitude = sqrt(zonal*zonal + merid*merid)*scale
				azimuth = atan(zonal, merid) / !DTOR
				get_mapped_vector_components, map, ilats[locIdx], ilons[locIdx], $
										  	  magnitude, azimuth, x0, y0, xlen, ylen
				arrow, x0 - .5*xlen, y0 - .5*ylen, $
					   x0 + .5*xlen, y0 + .5*ylen, /data, color = 100, hsize = 8
			endfor
		endif

		SKIP_MONO_BLEND:
		loadct, 39, /silent
	endif

	;\\ Overlay Bistatic Winds
	if show_bistatic eq 1 and size(bistaticFits, /type) ne 0 then begin

		biBlend = sdi_monitor_blend(bistaticFits, sigma=.3, maxDist=.5)

		magnitude = sqrt(biBlend.zonal*biBlend.zonal + biBlend.merid*biBlend.merid)*scale
		azimuth = atan(biBlend.zonal, biBlend.merid) / !DTOR

		for i = 0, n_elements(magnitude) - 1 do begin
				get_mapped_vector_components, map, biBlend.lat[i], biBlend.lon[i], $
											  magnitude[i], azimuth[i], x0, y0, xlen, ylen
				arrow, x0 - .5*xlen, y0 - .5*ylen, $
					   x0 + .5*xlen, y0 + .5*ylen, /data, color = 255, hsize = 8
		endfor

		;\\ Show bistatic vz locations
		if nbivz gt 0 then begin
			order = sort(bistaticFits[bivz].lat)
			xy = map_proj_forward(bistaticFits[bivz[order]].lon, bistaticFits[bivz[order]].lat, map=map)
			xyouts, xy[0,*], xy[1,*], string(indgen(nbivz) + 1, f='(i0)'), align=.5, color = 90, /data
		endif

	endif


	;\\ Scale arrow
	plot_vector_scale_on_map, [.01, .92], map, 200, scale, 0, thick = 2, headthick = 2
	xyouts, .01, .98, 'Bistatic Winds ' + dt_tm_fromjs(dt_tm_tojs(systime(/ut)), format='Y$/doy$'), /normal
	xyouts, .01, .955, time_str_from_decimalut(cmn_s/3600.) + ' UT', /normal
	xyouts, .01, .93, '200 m/s', /normal

	;\\ Explain plotting symbols
	loadct, 0, /silent
	xyouts, .99, .27, 'Mean Monostatic Winds', /normal, color = 100, align=1
	loadct, 39, /silent
	xyouts, .99, .288, 'Station Locations', /normal, color = 190, align=1
	xyouts, .99, .252, 'Bistatic Vertical Wind Locations', /normal, color = 90, align=1


	;\\ Testing vz timeseries
	loadct, 0, /silent
	polyfill, [0,0,1,1], [0,.25,.25,0], color = 0, /normal

	bi_times = js2ut(bistatic_vz_times)
	times = get_unique(bi_times)
	lats = get_unique(bistatic_vz.lat)

	for ii = 0, n_elements(lats) - 1 do begin
		pts = where(bistatic_vz.lat eq lats[ii], npts)
		append, bistatic_vz[pts].mcomp - median(bistatic_vz[pts].mcomp), bvz
		append, bi_times[pts], btm
		append, bistatic_vz[pts].lat, blt
	endfor

	bin2d, btm, blt, bvz, [8./60., .8], outx, outy, outz, /extrap

	!p.font = -1
	timeRange = [min(outx),max(outx)]
	plotTimeRange = [timeRange[0], timeRange[1]]
	if (plotTimeRange[1]-plotTimeRange[0]) lt 5 then plotTimeRange[1] += 5 - (plotTimeRange[1]-plotTimeRange[0])
	latRange = [min(outy),max(outy)]
	vzPos =  [.08, .05, .9, .2]
	vzScale = [-100,100]
	plot, plotTimeRange, latRange, /nodata, /xstyle, /ystyle, pos=vzPos, /noerase

	scale_to_range, outz, vzScale[0], vzScale[1], oz, scaleMiddle=0
 	crds = convert_coord(timeRange, latRange, /data, /to_device)
	outImage = congrid(oz, crds[0,1]-crds[0,0], crds[1,1]-crds[1,0], interp=-.8)
	load_color_table, 'pertct2.ctable'
	tv, outImage, timeRange[0], latRange[0], /data

	;\\ Scale bar
		cbar = intarr(15, 256)
		for cc = 0, 14 do cbar[cc,*] = indgen(256)
		tv, congrid(cbar, 15, 100, /interp), .93, .065, /normal
		loadct, 39, /silent
		xyouts, .94, .04, string(vzScale[0],f='(i0)'), color=255, /normal, align=.5
		xyouts, .94, .2, string(vzScale[1],f='(i0)'), color=255, /normal, align=.5
		xyouts, .97, .13, 'Vz (m/s)', color=255, /normal, align=.5, orientation=-90

	plot, plotTimeRange, latRange, /nodata, /xstyle, /ystyle, title='Bistatic Vertical Wind', $
		  ytitle = 'Latitude', xtitle = 'UT TIme', pos=vzPos, /noerase


	;\\ Overlay Tristatic Winds
	if show_tristatic eq 1 and size(tristaticFits, /type) ne 0 then begin
		use = where(max(tristaticFits.overlap, dim=1) gt .2 and $
					tristaticFits.obsdot lt .7 and $
					sqrt(tristaticFits.v*tristaticFits.v + tristaticFits.u*tristaticFits.u) lt 300 and $
					tristaticFits.uerr/tristaticFits.u lt .3 and $
					tristaticFits.verr/tristaticFits.v lt .3, nuse )

		if (nuse gt 0) then begin
			triFits = tristaticFits[use]
			for i = 0, nuse - 1 do begin
				outWind = [triFits[i].u, triFits[i].v]
				magnitude = sqrt(outWind[0]*outWInd[0] + outWind[1]*outWind[1]) * scale
				azimuth = atan(outWind[0], outWind[1]) / !DTOR
				get_mapped_vector_components, map, triFits[i].lat, triFits[i].lon, $
											  magnitude, azimuth, x0, y0, xlen, ylen
				arrow, x0, y0, x0 + xlen, y0 + ylen, /data, color = 150, hsize = 8
			endfor
		endif
	endif

	!p.font = -1

	img = tvrd(/true)
	if keyword_set(save_name) then write_png, save_name, img
	wdelete, wid

	END_MULTISTATIC:
	if (size(allSeries, /type) ne 0) then ptr_free, allSeries, allMeta
end
