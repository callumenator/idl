
;\\ Plot the current windfields
pro sdi_monitor_windfields, oldest_snapshot=oldest_snapshot	;\\ Oldest snapshot time in days

	common sdi_monitor_common, global, persistent
	common sdi_monitor_windfields_common, lastrunId, $ ;\\ to see if we have new data or not
										  lastSaveTime ;\\ for low freq saves

	if not keyword_set(oldest_snapshot) then oldest_snapshot = 1E9
	if size(persistent, /type) eq 0 then return
	if ptr_valid(persistent.zonemaps) eq 0 then return
	if ptr_valid(persistent.snapshots) eq 0 then return
	if size(lastSaveTime, /type) eq 0 then lastSaveTime = systime(/sec) - 1E5

	print, 'PROCESSING WINDFIELDS'

	;\\ Color map
		color_map = {wavelength:[5577, 6300, 6328, 7320, 8430], $
						 ctable:[  39,   39,   39,    2,    2], $
					 	  color:[ 150,  250,  190,  143,  207]}


	;\\ Get the array of zonemap info
		zonemaps = *persistent.zonemaps

	;\\ Count up unique sites and snapshots
		snapshots = *persistent.snapshots
		day_diff = (dt_tm_tojs(systime(/ut)) - snapshots.end_time) / (24.*60.*60.)
		young = where(day_diff le oldest_snapshot, n_young)
		if n_young eq 0 then return	;\\ Something should happen here - eg blank image, etc

		snapshots = snapshots[young]

		fitted = where(ptr_valid(snapshots.fits) eq 1, n_fitted)
		if n_fitted eq 0 then return

		snapshots = snapshots[fitted]

	;\\ UT day range of interest (the current UT day for now, since obs from Alaska don't span days)
		current_ut_day = dt_tm_fromjs(dt_tm_tojs(systime(/ut)), format='doy$')
		ut_day_range = [current_ut_day, current_ut_day]
		current_day_ut_range = [24, 0]

	;\\ Fit the winds first, then plot
	count_valid = 0
	max_time_range = [100, -100]
	winds = ptrarr(n_fitted)
	thisrunId = ''
	for i = 0, n_fitted - 1 do begin

		if snapshots[i].wavelength ne 6300 then continue

		ts_name = global.home_dir + '\Timeseries\' + strupcase(snapshots[i].site_code) + $
				  '_' + string(snapshots[i].wavelength, f='(i04)') + '_timeseries.idlsave'

		if file_test(ts_name) eq 0 then continue

		restore, ts_name
		oMeta = meta ;\\ save a copy of this, for when we save winds back to time series file


		;\\ Deduce altitude
			case snapshots[i].wavelength of
				6300: altitude = 240.
				5577: altitude = 120.
				else: altitude = -1
			endcase
			if altitude eq -1 then continue


			thisrunId += snapshots[i].site_code + string(snapshots[i].start_time, f='(i0)')


		;\\ Find contiguous data within ut_day_range
			js2ymds, series.start_time, syear, smonth, sday, ssec
			daynos = ymd2dn(syear, smonth, sday)
			slice = where(daynos ge ut_day_range[0] and daynos le ut_day_range[1], nsliced)
			if nsliced eq 0 then continue
			series = series[slice]

			find_contiguous, js2ut(series.start_time) mod 24, 3., blocks, n_blocks=nb, /abs
			ts_0 = blocks[nb-1,0]
			ts_1 = blocks[nb-1,1]
			series = series[ts_0:ts_1]

			sdi_monitor_format, {metadata:meta, series:series}, metadata=meta, spek=var, zone_centers=zcen
			if meta.latitude lt 0 then continue

		;\\ Flatfield
			sdi3k_auto_flat, meta, flat_field, /use_database, use_path = 'c:\rsi\idl\routines\sdi\monitor\timeseries\offsets\'
			for iix = 0, n_elements(var) - 1 do var[iix].velocity -= flat_field

		;\\ Replace any spectral fits with really bad fits with interpolated data:
		    chilim = 1.8
		    if abs(meta.wavelength_nm - 557.7) lt 1. then chilim = 5.
		    posarr = var.velocity
		    bads  = where(var.chi_squared ge chilim or  var.signal2noise le 200. or abs(var.velocity) ge 1200., nn)
		    if nn gt 0 then begin
		       setweight = 0.*posarr + 1.
		       setweight[bads] = 0.
		       smarr = posarr
		       sdi3k_spacesmooth_fits, smarr, 0.10, meta, zcen, setweight=setweight
		       sdi3k_timesmooth_fits,  smarr, 2.50, meta, setweight=setweight
		       posarr[bads] = smarr[bads]
               smdif = posarr - smarr
               dummy = moment(smdif, sdev=stdv)
               bads  = where(abs(smdif) gt 4.*stdv, nnbb)
		       if nnbb gt 0 then posarr[bads] = smarr[bads]
		       var.velocity = posarr
		    endif


		;\\ Windfit settings
			dvdx_assumption = 'dv/dx=zero'
			wind_settings = {time_smoothing: 1.4, $
	                   		 space_smoothing: 0.03, $
	                   		 dvdx_assumption: dvdx_assumption, $
	                       	 algorithm: 'Fourier_Fit', $
	                   		 assumed_height: altitude, $
	                         geometry: 'none'}

			nobs = n_elements(var)
			if nobs lt 5 then continue
			sdi3k_drift_correct, var, meta, /data_based, /force
			sdi3k_remove_radial_residual, meta, var, parname='VELOCITY'

    		var.velocity *= meta.channels_to_velocity
    		var.sigma_velocity *= meta.channels_to_velocity
    		posarr = var.velocity

			sdi3k_timesmooth_fits,  posarr, 1.1, meta
		    pos2arr = posarr

		    sdi3k_spacesmooth_fits, posarr,      0.03, meta, zcen
		    sdi3k_spacesmooth_fits, pos2arr, 1.5*0.03, meta, zcen
		    var.velocity = posarr
		    var.velocity(0) = reform(pos2arr(0,*))
			var.velocity -= total(var(1:nobs-2).velocity(0))/n_elements(var(1:nobs-2).velocity(0))

    		sdi3k_fit_wind, var, meta, /dvdx_zero, windfit, wind_settings, zcen

			;\\ Save data back into time series file
			series.winds.zonal = windfit.zonal_wind
			series.winds.merid = windfit.meridional_wind
			save, ts_name, oMeta, series

			zonalWind = reform((windfit.zonal_wind)[*,nobs-1])
			meridWind = reform((windfit.meridional_wind)[*,nobs-1])

			angle = (-1.0)*meta.oval_angle*!DTOR
			geoZonalWind = zonalWind*cos(angle) - meridWind*sin(angle)
			geoMeridWind = zonalWind*sin(angle) + meridWind*cos(angle)


			medZonal = median(windfit.zonal_wind, dim=1)
			zonalHi = max(windfit.zonal_wind, dim=1)
			zonalLo = min(windfit.zonal_wind, dim=1)
			medMerid = median(windfit.meridional_wind, dim=1)
			meridHi = max(windfit.meridional_wind, dim=1)
			meridLo = min(windfit.meridional_wind, dim=1)
			time = js2ut(0.5*(var.start_time + var.end_time))

			cnv_series = convert_js(var.start_time)
			taxis = cnv_series.dayno + cnv_series.sec/(24.*3600.)


			;\\ ------------------------- Dial plot info -------------------------
				get_zone_locations, meta, zones=mag_zones, /mag, altitude=240
				mlt = time + 12.8
				mlat = mag_zones.lat
				zn_mlt_offset = (mag_zones.lon - mag_zones[0].lon) * (24./360.)

				nt = nels(time)
				bin, mlat, mlat, .5, bin_lat, yy, /ymedian
				nl = nels(bin_lat)
				nz = meta.nzones

				zn_mlt = fltarr(nz, nt)
				zn_mlat = fltarr(nz, nt)
				for t = 0, nt - 1 do begin
					zn_mlat[*,t] = mlat
					zn_mlt[*,t] = mlt[t] + zn_mlt_offset
				endfor
				append, reform(windfit.zonal_wind, nels(windfit.zonal_wind)), allZonal
				append, reform(windfit.meridional_wind, nels(windfit.meridional_wind)), allMerid
				append, reform(var.temperature, nels(var.temperature)), allTemps
				append, reform(zn_mlt, nels(zn_mlt)), allMlt
				append, reform(zn_mlat, nels(zn_mlat)), allMlat
			;\\ ------------------------- End dial plot info ---------------------


			if min(time) lt max_time_range[0] then max_time_range[0] = min(time) - .5
			if max(time) gt max_time_range[1] then max_time_range[1] = max(time) + .5

			get_zone_locations, meta, zones=zinfo, altitude = altitude

			;\\ Make the latest winds available via global.shared.recent_monostatic_winds
				append, geoZonalWind, allMonoZonal
				append, geoMeridWind, allMonoMerid
				append, zinfo.lat, allMonoLat
				append, zinfo.lon, allMonoLon


			wind_struc = {meta:meta, $
						  zinfo:zinfo, $
						  start_time:snapshots[i].start_time, $
						  end_time:snapshots[i].end_time, $
						  zonal:geoZonalWind, $
						  merid:geoMeridWind, $
						  medMerid:medMerid, $
						  meridHi:meridHi, $
						  meridLo:meridLo, $
						  medZonal:medZonal, $
						  zonalHi:zonalHi, $
						  zonalLo:zonalLo, $
						  time:time, $
						  taxis:taxis }

			winds[i] = ptr_new(wind_struc)
			count_valid ++
	endfor

	;\\ Do we have new data, or can we skip this run?
		if (size(lastrunId, /type) ne 0) then begin
			if (lastrunId eq thisrunId) then goto, MONITOR_WINDFIELDS_END
		endif
		lastrunId = thisrunId




	;\\ Share the monostatic winds
	if size(allMonoZonal, /type) ne 0 then begin
		*global.shared.recent_monostatic_winds = {geoZonal:allMonoZonal, $
												  geoMerid:allMonoMerid, $
												  lat:allMonoLat, $
												  lon:allMonoLon }
	endif

	if count_valid eq 0 then goto, MONITOR_WINDFIELDS_END



	;########### Begin geo-mapped windfields #########

	;\\ Set draw geometry
		base_geom = widget_info(global.tab_id[3], /geometry)
		widget_control, draw_ysize=1000, draw_xsize = 1000, global.draw_id[3]
		widget_control, get_value = wset_id, global.draw_id[3]
		wset, wset_id
		loadct, 39, /silent
		erase, 0

	;\\ Map options
		lat = 65
		lon = -147
		zoom = 5.5
		winx = 1000
		winy = 1000

		bounds = [0,.5, .5, 1]
		scale = 1E3

		plot_simple_map, lat, lon, zoom, 1, 1, map=map, $
						 backcolor=[0,0], continentcolor=[50,0], $
						 outlinecolor=[90,0], bounds = bounds
		overlay_geomag_contours, map, longitude=10, latitude=5, color=[0, 100]
		loadct, 0, /silent
		plots, /normal, [0,1], [.5,.5], color=100
		plots, /normal, [.5,.5], [.5,1], color=100

		;\\ Plot windfields
			site_count = 0
			!p.font = 0
			device, set_font='Ariel*17*Bold'
			xyouts, 5, winy - 15*(site_count+1), 'Vector Wind ' + dt_tm_fromjs(dt_tm_tojs(systime(/ut)), format='Y$/doy$'), /device, color=255
			time = time_str_from_decimalut(total((bin_date(systime(/ut)))[[3,4,5]] * [1, 1./60., 1./3600.]))
			xyouts, 5, winy - 15*(site_count+2), 'Current Time: ' + time + ' UT', /device, color=255

			for i = 0, n_fitted - 1 do begin
				if ptr_valid(winds[i]) eq 0 then continue

				wnd = *winds[i]

				case wnd.meta.site_code of
					'PKR': begin
						color = 150
						ctable = 39
					end
					'HRP': begin
						color = 100
						ctable = 39
					end
					'TLK': begin
						color = 230
						ctable = 39
					end
					else: begin
						color = 0
						ctable = 0
					end
				endcase

				zonal = wnd.zonal
				merid = wnd.merid
				tol = 10.

				magnitude = sqrt(zonal*zonal + merid*merid)*scale
				azimuth = atan(zonal, merid)/!DTOR

				use = where(abs(magnitude - median(magnitude)) lt tol*meanabsdev(magnitude, /median), n_use)
				if n_use eq 0 then continue

				get_mapped_vector_components, map, wnd.zinfo[use].lat, wnd.zinfo[use].lon, $
											  magnitude[use], azimuth[use], $
										  	  x0, y0, xlen, ylen

				n_samples = 100
				xr = [min(x0), max(x0)]
				yr = [min(y0), max(y0)]
				x_interp = (findgen(n_samples)/float(n_samples-1))*(xr[1]-xr[0]) + xr[0]
				y_interp = (findgen(n_samples)/float(n_samples-1))*(yr[1]-yr[0]) + yr[0]

				triangulate, x0, y0, tr, b
				ix0 = trigrid(x0, y0, x0, tr, xout=x_interp, yout=y_interp, extrap=b)
				iy0 = trigrid(x0, y0, y0, tr, xout=x_interp, yout=y_interp, extrap=b)
				ixlen = trigrid(x0, y0, xlen, tr, xout=x_interp, yout=y_interp, missing=-9999, extrap=b)
				iylen = trigrid(x0, y0, ylen, tr, xout=x_interp, yout=y_interp, missing=-9999, extrap=b)
				missing = ix0
				missing[*] = 0
				miss = where(ixlen eq -9999, n_miss)
				if n_miss gt 0 then missing[miss] = 1

				use = where(missing ne 1, n_use)
				if n_use eq 0 then continue

				case wnd.meta.site_code of
					'xPKR': begin
						radii = [0, .2, .4, .6, .8, .99]
						azis =  [1,  6,  8, 15, 20, 25]
					end
					'xHRP': begin
						radii = [0, .142, .285, .428, .57, .714, .857, .99]
						azis =  [1,  6,  10,  18, 20,  25, 30, 40]
					end
					else: begin
						radii = [0, .2, .4, .59, .78, .95]
						azis =  [1,  6,  8, 15, 20, 25]
					end
				endcase

				loadct, ctable, /silent

				for ir = 0, n_elements(radii) - 1 do begin
				for ia = 0, 360, (360./azis[ir]) do begin
					x = (n_samples/2.)*(1 + radii[ir]*cos(ia*!dtor)) > 0
					y = (n_samples/2.)*(1 + radii[ir]*sin(ia*!dtor)) > 0
					x = x < n_samples - 1
					y = y < n_samples - 1

					if missing[x,y] eq 1 then continue

					arrow, ix0[x,y] - 0.5*ixlen[x,y], $
						   iy0[x,y] - 0.5*iylen[x,y], $
						   ix0[x,y] + 0.5*ixlen[x,y], $
						   iy0[x,y] + 0.5*iylen[x,y], $
						   /data, color=color, hsize=8

					;xarrow, ix0[x,y] - 0.5*ixlen[x,y], $
					;	    iy0[x,y] - 0.5*iylen[x,y], $
					;	    ix0[x,y] + 0.5*ixlen[x,y], $
					;	    iy0[x,y] + 0.5*iylen[x,y], $
					;		color=color, $
					;		ctable=ctable, /data, $
					;		shaft=.5E4, $
					;		head_len=3E4, $
					;		head_width=3E4
				endfor
				endfor

				time = time_str_from_decimalut(js2ut((wnd.start_time + wnd.end_time)/2.))
				info_string = wnd.meta.site + ': ' + time + ' UT'
				xyouts, 5, winy - 15*(site_count+3), info_string, /device, color=color

				site_count ++
			endfor


			xyouts, 5, winy - 15*(site_count+4), '200 m/s', /device, color=255
			!p.font = -1
			pos = convert_coord(5, winy - 15*(site_count+4) - 10, /device, /to_normal)
			plot_vector_scale_on_map, [pos[0,0], pos[1,0]], map, 200, scale, $
								  90, headsize=10, headthick=2, thick=2, color=[0,255]

	;########### End geo-mapped windfields #########


	;########### Begin ave dial plot #########

		if size(allMlt, /type) ne 0 then begin

			polyfill, [.5, .5, 1, 1], [.5, 1, 1, .5], /normal, color=0

			!p.font = 0
			device, set_font='Ariel*15*Bold'

			scale = 0.3
			bin2d, allMlt, allMlat, allTemps, [.25, 1], outx, outy, aveTemps, /extrap
			bin2d, allMlt, allMlat, allZonal, [.5, 2], outx, outy, aveZonal, /extrap
			bin2d, allMlt, allMlat, allMerid, [.5, 2], outx, outy, aveMerid, /extrap


			aveMlt = aveZonal*0.
			aveMlat = aveZonal*0.
			for xx = 0, n_elements(outx) - 1 do aveMlat[xx,*] = outy
			for yy = 0, n_elements(outy) - 1 do aveMlt[*,yy] = outx

			width = (winx/2.)*.85
			border = (winx/2.) - width
			mlat_range = [55, 90]
			radii = (1 - ((aveMlat - mlat_range[0]) / float((mlat_range[1] - mlat_range[0])))) * (width/2.)
			clock_angle = 90. * ((aveMlt - 12) / 6.) * !DTOR

			rotAngle = -1*(!PI - clock_angle)
			rotZonal = (aveZonal*cos(rotAngle) - aveMerid*sin(rotAngle))*scale
			rotMerid = (aveZonal*sin(rotAngle) + aveMerid*cos(rotAngle))*scale

			dialxcen = 0.5*winx + width/2. + border/2.
			dialycen = 0.5*winy + width/2. + border/2.
			loadct, 0, /silent
			plots, dialxcen + [-10,10], dialycen + [0,0], /device, thick = 2, color = 100
			plots, dialxcen + [0,0], dialycen + [-10,10], /device, thick = 2, color = 100

			circ = (30 + findgen(331))*!DTOR
			for lat_circ = mlat_range[0], mlat_range[1], 5 do begin
				lat_circ_radius = (1 - ((lat_circ - mlat_range[0]) / float((mlat_range[1] - mlat_range[0])))) * (width/2.)
				plots, dialxcen - lat_circ_radius*sin(circ), $
					   dialycen + lat_circ_radius*cos(circ), $
					   color = 100, /device
				if lat_circ gt mlat_range[0] and lat_circ lt mlat_range[1] then begin
					label = string(lat_circ, f='(i0)')
					if lat_circ eq mlat_range[0] + 5 then label += ' MLAT'
					xyouts, dialxcen, dialycen + lat_circ_radius, label, color = 100, /device, align=1.1
				endif
			endfor
			plots, [dialxcen, dialxcen], dialycen + [0, width/2.], color = 100, /device
			plots, dialxcen - [0, width/2.]*sin(30*!DTOR), $
				   dialycen + [0, width/2.]*cos(30*!DTOR), $
				   color = 100, /device

			lat_circ_radius = (1 - ((-3) / float((mlat_range[1] - mlat_range[0])))) * (width/2.)
			for mlt_clock = 6, 24, 6 do begin
				mlt_label_angle = 90. * ((mlt_clock - 12) / 6.) * !DTOR
				xpos = dialxcen - lat_circ_radius*sin(mlt_label_angle)
				ypos = dialycen + lat_circ_radius*cos(mlt_label_angle) - 8
				label = string(mlt_clock*100, f='(i04)')
				if mlt_clock eq 12 then label += ' MLT'
				xyouts, xpos, ypos, /device, label, color = 100, align=.5
			endfor


			xpos = dialxcen - radii*sin(clock_angle)
			ypos = dialycen + radii*cos(clock_angle)
			arrow, xpos - .0*rotZonal, $
				   ypos - .0*rotMerid, $
				   xpos + 1*rotZonal, $
				   ypos + 1*rotMerid, $
				   hsize = 5

			device, set_font='Ariel*17*Bold'
			xyouts, winx/2. + 5, winy-15, 'Average Vector Dial Plot', color = 250, /device
			xyouts, winx/2. + 5, winy-30, '(Magnetic Coordinates)', color = 250, /device
			xpos = winx/2. + 5
			ypos = winy-55
			mag = 200
			arrow, xpos, ypos, xpos + scale*mag, ypos, color = 250, thick=2, hsize = 10
			xyouts, xpos, ypos + 8, '200 m/s', color = 250, /device

			;tvlct, red, gre, blu, /get
			;loadct, 39, /silent
			;tvscl, congrid(aveTemps, winx/3., winy/6., /interp), 3*winx/4. - winx/6, winy/2 + 10
			;tvlct, red, gre, blu

			!p.font = -1
		endif

	;########### End ave dial plot #########


	;\\ Plot median wind timeseries
	yrange = [-250, 250]
	blank = replicate(' ', 20)
	max_time_range[1] += (5 - (max_time_range[1]-max_time_range[0]) > 1)

	if total(global.shared.temperature_time_axis) ne 0.0 then $
		max_time_range = global.shared.temperature_time_axis

	for pass = 0, 1 do begin

		bounds = [.1, .27, .98, .46]
		!p.font = 0
		device, set_font='Ariel*17*Bold'
		xyouts, 5, .485*winy, 'Median Wind Timeseries ' + $
			dt_tm_fromjs(dt_tm_tojs(systime(/ut)), format='Y$/doy$'), /device, color=255
		!p.font = -1
		if pass eq 0 then begin
				plot, max_time_range, [0,1], /xstyle, /ystyle, yrange=yrange, /nodata, pos=bounds, /noerase, xminor=8, xtickint = 2./24., $
				  ytitle = 'Mag. Zonal (m/s)' , xtitle = 'Time (UT)', yticklen=.003, chars=1.5, xtick_get = xvals, xtickname=blank

			oplot, max_time_range, [0,0], line=1

   			xtickname = time_str_from_decimalut((xvals mod 1) * 24., /noseconds)
			axis, xaxis=0, xtickname = blank, /xstyle, xrange=max_time_range, xtitle = 'Time (UT)', $
				  chars = 1.5, xminor=8, xtickint = 2./24.

		endif else begin
			plot, max_time_range, [0,1], xstyle=5, ystyle=5, yrange=yrange, /nodata, pos=bounds, /noerase, xtickint = 2./24.
		endelse

		site_count = 0
		for i = 0, n_fitted - 1 do begin
			if ptr_valid(winds[i]) eq 0 then continue

			wnd = *winds[i]

			case wnd.meta.site_code of
				'PKR': begin
					color = 150
					ctable = 39
				end
				'HRP': begin
					color = 100
					ctable = 39
				end
				'TLK': begin
					color = 230
					ctable = 39
				end
				else: begin
					color = 0
					ctable = 0
				end
			endcase

			if pass eq 0 then begin
				loadct, 0, /silent
				if n_elements(wnd.time) gt 1 then $
					errplot, wnd.taxis, wnd.zonalLo, wnd.zonalHi, color=50, width=.00001, noclip=0
				loadct, ctable, /silent

				!p.font = 0
				device, set_font='Ariel*17*Bold'
				xyouts, max_time_range[0] + site_count*0.05*(max_time_range[1]-max_time_range[0]), $
						yrange[1] + 0.03*(yrange[1]-yrange[0]), wnd.meta.site_code, color=color, /data
				!p.font = -1
			endif else begin
				loadct, ctable, /silent
				if n_elements(wnd.time) gt 1 then $
					oplot, wnd.taxis, wnd.medZonal, color=color, psym=-6, sym=.2, thick=.5
			endelse

			site_count ++
		endfor


		bounds = [.1, .06, .98, .26]
		if pass eq 0 then begin
			plot, max_time_range, [0,1], /xstyle, /ystyle, yrange=yrange, /nodata, pos=bounds, /noerase, xminor=8, xtickint = 2./24., $
				  ytitle = 'Mag. Merid (m/s)' , xtitle = 'Time (UT)', yticklen=.003, chars=1.5, xtick_get = xvals, xtickname=blank

			oplot, max_time_range, [0,0], line=1

			xtickname = time_str_from_decimalut((xvals mod 1) * 24., /noseconds)
			axis, xaxis=0, xtickname = xtickname, /xstyle, xrange=max_time_range, xtitle = 'Time (UT)', $
				  chars = 1.5, xminor=8, xtickint = 2./24.

		endif else begin
			plot, max_time_range, [0,1], xstyle=5, ystyle=5, yrange=yrange, /nodata, pos=bounds, /noerase, xtickint = 2./24.
			oplot, max_time_range, [0,0], line=1
		endelse


		for i = 0, n_fitted - 1 do begin
			if ptr_valid(winds[i]) eq 0 then continue

			wnd = *winds[i]

			case wnd.meta.site_code of
				'PKR': begin
					color = 150
					ctable = 39
				end
				'HRP': begin
					color = 100
					ctable = 39
				end
				'TLK': begin
					color = 230
					ctable = 39
				end
				else: begin
					color = 0
					ctable = 0
				end
			endcase

			if pass eq 0 then begin
				loadct, 0, /silent
				if n_elements(wnd.time) gt 1 then $
					errplot, wnd.taxis, wnd.meridLo, wnd.meridHi, color=50, width=.00001, noclip=0
			endif else begin
				loadct, ctable, /silent
				if n_elements(wnd.time) gt 1 then $
					oplot, wnd.taxis, wnd.medMerid, color=color, psym=-6, sym=.2, thick=0.5

			endelse
		endfor

	endfor ;\\ pass loop

	;\\ Save a copy of the image
	if 0 then begin ;\\ currently disabled, disk fills up
		if systime(/sec) - lastSaveTime gt 15.*60. then begin
			datestamp = dt_tm_fromjs(dt_tm_tojs(systime(/ut)), format='Y$0n$0d$')
			timestamp = dt_tm_fromjs(dt_tm_tojs(systime(/ut)), format='h$m$s$')
			toplevel = global.home_dir + '\SavedImages\' + datestamp + '\Windfields\'
			fname = toplevel + 'Realtime_Windfields_' + timestamp + '.png'
			file_mkdir, toplevel
			write_png, fname, tvrd(/true)
			lastSaveTime = systime(/sec)
		endif
	endif

	img = tvrd(/true)
	dims = size(img, /dimensions)

	;\\ Save a copy of the dial plot
	portion = img[*,dims[1]/2:dims[1]-1, dims[2]/2:dims[2]-1]
	year = dt_tm_fromjs(dt_tm_tojs(systime(/ut)), format='Y$')
	fname = 'c:\users\SDI\SDIPlots\' + year + '_AllStations_6300\Wind_Dial_Plot\'
	date = dt_tm_fromjs(dt_tm_tojs(systime(/ut)), format='Y$_DOYdoy$')
	fname += 'Wind_Dial_Plot_AllStations_' + date + '_6300.png'
	file_mkdir, file_dirname(fname)
	write_png, fname, portion

	;\\ Save a copy of the wind time series
	portion = img[*,*,0:dims[2]/2]
	year = dt_tm_fromjs(dt_tm_tojs(systime(/ut)), format='Y$')
	fname = 'c:\users\SDI\SDIPlots\' + year + '_AllStations_6300\Wind_Summary\'
	date = dt_tm_fromjs(dt_tm_tojs(systime(/ut)), format='Y$_DOYdoy$')
	fname += 'Wind_Summary_Plot_AllStations_' + date + '_6300.png'
	file_mkdir, file_dirname(fname)
	write_png, fname, portion


	MONITOR_WINDFIELDS_END:
	ptr_free, winds


end