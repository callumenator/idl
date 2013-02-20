
;\\ Plot the current windfields
pro sdi_monitor_windfields, timeseries=timeseries, $ ;\\ time series directory
							wavelength=wavelength, $ wavelength in angstrom
							save_name=save_name

	whoami, dir, file

 	if not keyword_set(timeseries) then timeseries = dir + '\timeseries\'
 	if not keyword_set(wavelength) then wavelength = 6300

	;\\ Color map
		color_map = {wavelength:[5577, 6300, 6328, 7320, 8430], $
						 ctable:[  39,   39,   39,    2,    2], $
					 	  color:[ 150,  250,  190,  143,  207]}

	;\\ UT day range of interest (the current UT day for now, since obs from Alaska don't span days)
		current_ut_day = dt_tm_fromjs(dt_tm_tojs(systime(/ut)), format='doy$')
		ut_day_range = [current_ut_day, current_ut_day]
		current_day_ut_range = [24, 0]

	;\\ This is to get the same time range as the temperature plot
		allTs = file_search(timeseries + '\*{HRP,PKR,TLK,KTO,MAW}*_timeseries.idlsave', count=nseries)

	;\\ Fit the winds first, then plot
		count_valid = 0
		time_of_most_recent = 0 ;\\ track most recent, to reject old wind fields from plotting
		winds = ptrarr(nseries)
		for i = 0, nseries - 1 do begin

			tries = 0
			catch, error
			if error ne 0 then begin
				if tries lt 3 then begin
					wait, 2. & tries ++
				endif else begin
					catch, /cancel & return
				endelse
			endif
			restore, allTs[i]
			catch, /cancel

			;\\ Find contiguous data within ut_day_range
				js2ymds, series.start_time, y, m, d, s
				curr_year =float( dt_tm_fromjs(dt_tm_tojs(systime(/ut)), format='Y$'))
				keep = where(y eq curr_year, nkeep)
				if nkeep gt 0 then series = series[keep] else continue

				daynos = ymd2dn(y, m, d)
				slice = where(daynos ge ut_day_range[0] and daynos le ut_day_range[1], nsliced)
				if (nsliced ge 2) then begin
					temp_ut = s[slice]/3600.
					if (min(temp_ut) lt current_day_ut_range[0]) then current_day_ut_range[0] = min(temp_ut)
					if (max(temp_ut) gt current_day_ut_range[1]) then current_day_ut_range[1] = max(temp_ut)
				endif else begin
					continue
				endelse

			if meta.wavelength ne wavelength then continue
			series = series[slice]


			;\\ Deduce altitude
				case meta.wavelength of
					6300: altitude = 240.
					5577: altitude = 120.
					else: altitude = -1
				endcase
				if altitude eq -1 then continue

				sdi_monitor_format, {metadata:meta, series:series}, metadata=meta, spek=var, zone_centers=zcen
				if meta.latitude lt 0 then continue

			;\\ Flatfield
				sdi3k_auto_flat, meta, flat_field, /use_database
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
	    		vz = var.velocity[0]
				sdi3k_timesmooth_fits,  posarr, 1.1, meta
			    sdi3k_spacesmooth_fits, posarr, 0.03, meta, zcen

			    var.velocity = posarr
			    var.velocity[0] = reform(vz)
			   	var.velocity -= total(var(1:nobs-2).velocity(0))/n_elements(var(1:nobs-2).velocity(0))
	    		sdi3k_fit_wind, var, meta, /dvdx_zero, windfit, wind_settings, zcen

				;\\ Save data back into time series file -- not done anymore
				series.winds.zonal = windfit.zonal_wind
				series.winds.merid = windfit.meridional_wind


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
				if (max(time)) gt time_of_most_recent then time_of_most_recent = max(time)

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
					intens = fltarr(nz, nt)
					scale = pixels_per_zone(meta, /relative)
					for t = 0, nt - 1 do begin
						zn_mlat[*,t] = mlat
						zn_mlt[*,t] = mlt[t] + zn_mlt_offset
						intens[*,t] = reform((series.fits.area)[*,t]) / scale
					endfor
					append, reform(windfit.zonal_wind, nels(windfit.zonal_wind)), allZonal
					append, reform(windfit.meridional_wind, nels(windfit.meridional_wind)), allMerid
					append, reform(var.temperature, nels(var.temperature)), allTemps
					append, reform(zn_mlt, nels(zn_mlt)), allMlt
					append, reform(zn_mlat, nels(zn_mlat)), allMlat
					append, reform(intens, nels(intens)), allIntens
					append, nels(intens), n_intens
				;\\ ------------------------- End dial plot info ---------------------


				get_zone_locations, meta, zones=zinfo, altitude = altitude

				;\\ Make the latest winds available via save file
					append, geoZonalWind, allMonoZonal
					append, geoMeridWind, allMonoMerid
					append, zinfo.lat, allMonoLat
					append, zinfo.lon, allMonoLon
					append, max(var.start_time), allMonoMaxTime

				wind_struc = {meta:meta, $
							  zinfo:zinfo, $
							  start_time:series.start_time, $
							  end_time:series.end_time, $
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

	if count_valid eq 0 then goto, MONITOR_WINDFIELDS_END
	winds = winds[where(ptr_valid(winds) eq 1, n_fitted)]

	;\\ Save the combined monostatic winds
		monostatic = {zonal:allMonoZonal, $
					  merid:allMonoMerid, $
					  lat:allMonoLat, $
					  lon:allMonoLon, $
					  time:max(allMonoMaxTime)}
		save, filename = dir + 'latest_monostatic_' + string(wavelength, f='(i04)') + '.idlsave', monostatic

	;\\ Create a window
		window, /free, xs=1000, ys=1000, /pixmap
		wid = !D.WINDOW
		loadct, 39, /silent
		erase, 0


	;\\----------------------------- Begin geo-mapped windfields -----------------------------

	;\\ Map options
		lat = 65
		lon = -147
		if wavelength eq 6300 then begin
			zoom = 5.5
			label_locs = [[60.2,-77],[70.2,-76]]
			label_orients = [-5, -5]
		endif else begin
			zoom = 7.5
			label_locs = [[60.2,-85],[70.2,-86]]
			label_orients = [-15, -15]
		endelse
		winx = 1000
		winy = 1000
		bounds = [0,.5, .5, 1]
		scale = 1E3

		plot_simple_map, lat, lon, zoom, 1, 1, map=map, $
						 backcolor=[0,0], continentcolor=[50,0], $
						 outlinecolor=[90,0], bounds = bounds
		overlay_geomag_contours, map, longitude=10, latitude=5, color=[0, 100], $
								 label_loc=label_locs, label_names=['60','70'] + '!9%!3 MLAT', $
								 label_color=[0,150], label_orient=label_orients

		loadct, 0, /silent
		plots, /normal, [0,1], [.5,.5], color=100
		plots, /normal, [.5,.5], [.5,1], color=100

		;\\ Plot windfields
			site_count = 0
			!p.font = 0
			device, set_font='Ariel*17*Bold'
			xyouts, 5, winy - 15*(site_count+1), string(wavelength/10., f='(f0.1)') + 'nm Vector Wind ' + $
					dt_tm_fromjs(dt_tm_tojs(systime(/ut)), format='Y$/doy$'), /device, color=255
			time = time_str_from_decimalut(total((bin_date(systime(/ut)))[[3,4,5]] * [1, 1./60., 1./3600.]))
			xyouts, 5, winy - 15*(site_count+2), 'Current Time: ' + time + ' UT', /device, color=255

			for i = 0, n_fitted - 1 do begin

				wnd = *winds[i]

				;\\ Reject wind fields that are more than half an hour older than
				;\\ the most recent wind field
				if (time_of_most_recent - max(wnd.time)) gt 0.5 then continue

				case wnd.meta.site_code of
					'PKR': begin & color = 150 & ctable = 39 & end
					'HRP': begin & color = 100 & ctable = 39 & end
					'TLK': begin & color = 230 & ctable = 39 & end
					'KTO': begin & color = 200 & ctable = 39 & end
					else: begin & color = 0 & ctable = 0 & end
				endcase

				zonal = wnd.zonal
				merid = wnd.merid
				magnitude = sqrt(zonal*zonal + merid*merid)*scale
				azimuth = atan(zonal, merid)/!DTOR

				tol = 10.
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

				radii = [0, .2, .4, .59, .78, .95]
				azis =  [1,  6,  8, 15, 20, 25]

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
				endfor
				endfor

				time = time_str_from_decimalut(max(js2ut((wnd.start_time + wnd.end_time)/2.)))
				info_string = wnd.meta.site + ': ' + time + ' UT'
				xyouts, 5, winy - 15*(site_count+3), info_string, /device, color=color
				site_count ++
			endfor

			xyouts, 5, winy - 15*(site_count+4), '200 m/s', /device, color=255
			!p.font = -1
			pos = convert_coord(5, winy - 15*(site_count+4) - 10, /device, /to_normal)
			plot_vector_scale_on_map, [pos[0,0], pos[1,0]], map, 200, scale, $
								  90, headsize=10, headthick=2, thick=2, color=[0,255]

	;\\----------------------------- End geo-mapped windfields -----------------------------



	;\\----------------------------- Begin dial plot -----------------------------

		if size(allMlt, /type) ne 0 then begin

			;\\ Normalize intensities
			;\\ Need them in order of HRP, PKR, TLK, ...
			for kk = 0, n_elements(winds) - 1 do begin
				append, (*winds[kk]).meta, intensMeta
				append, (*winds[kk]).time, allTime
			endfor

;			u = intensMeta.site_code[uniq(intensMeta.site_code[sort(intensMeta.site_code)])]
;			base = [0, n_intens]
;			for kk = 0, n_elements(u) - 1 do begin
;				pt = (where(intensMeta.site_code eq u[kk]))[0]
;				intens = allIntens[base[pt]:base[pt] + n_intens[pt]]
;				append, intensMeta[pt], _iMeta
;				append, intens, _iIntens
;				append, n_intens[pt], _iN
;				append, (*winds[pt]).time, _iTime
;			endfor

			if n_elements(winds) gt 1 then sdi_monitor_intensity_normalize, altitude, intensMeta, allIntens, allTime, n_intens

			polyfill, [.5, .5, 1, 1], [.5, 1, 1, .5], /normal, color=0

			!p.font = 0
			device, set_font='Ariel*15*Bold'

			scale = 0.3
			intBin_mlt = .125
			intBin_lat = .5
			bin2d, allMlt, allMlat, allIntens, [intBin_mlt, intBin_lat], int_outx, int_outy, aveIntens, /extrap
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
			dialycen = 0.5*winy + width/2. + border/2. - 15

			;\\ Intensity background
			aveIntens = smooth(aveIntens, 5, /edge, /nan)
			temp = aveIntens[sort(aveIntens)]
			nel = n_elements(temp)
			intensColor = bytscl(aveIntens, min=temp[nel*.02], max=temp[nel*.98 - 1], top=250)
			loadct, 4, /silent
			tvlct, r, g, b, /get
			tvlct, r*.7, g*.7, b*.7
			for ixx = 0, n_elements(int_outx) - 1 do begin
			for iyy = 0, n_elements(int_outy) - 1 do begin

				i_lat = int_outy[iyy]
				i_mlt = int_outx[ixx]
				i_radii = (1 - (( (i_lat) - mlat_range[0]) / float((mlat_range[1] - mlat_range[0])))) * (width/2.)
				i_clock_angle = 90. * (((i_mlt) - 12) / 6.) * !DTOR

				int_dx = ((intBin_mlt/1.8) / 24.)*360.*!DTOR
				int_dy = ((intBin_lat/1.8) / float((mlat_range[1] - mlat_range[0]))) * (width/2.)

				xpos0 = dialxcen - (i_radii - int_dy)*sin(i_clock_angle - int_dx)
				ypos0 = dialycen + (i_radii - int_dy)*cos(i_clock_angle - int_dx)

				xpos1 = dialxcen - (i_radii + int_dy)*sin(i_clock_angle - int_dx)
				ypos1 = dialycen + (i_radii + int_dy)*cos(i_clock_angle - int_dx)

				xpos2 = dialxcen - (i_radii + int_dy)*sin(i_clock_angle + int_dx)
				ypos2 = dialycen + (i_radii + int_dy)*cos(i_clock_angle + int_dx)

				xpos3 = dialxcen - (i_radii - int_dy)*sin(i_clock_angle + int_dx)
				ypos3 = dialycen + (i_radii - int_dy)*cos(i_clock_angle + int_dx)

				polyfill, [xpos0,xpos1,xpos2,xpos3], [ypos0,ypos1,ypos2,ypos3], /device, color=intensColor[ixx,iyy]
			endfor
			endfor

			;\\ Intensity background scale bar and note
			scbar = intarr(winx/(2.*3.), 15)
			for ssi = 0, 14 do scbar[*,ssi] = congrid(indgen(256), winx/(2.*3.), /interp)
			tv, scbar, winx - 1.05*(winx/(2.*3.)), winy - 45, /device
			loadct, 0, /silent
			device, set_font='Ariel*14*Bold'
			xyouts, winx, winy - 15, $
					'Intensity (arbitrary scale derived!Cfrom current available data)', $
					color = 250, /device, align=1.05

			device, set_font='Ariel*17*Bold'
			plots, dialxcen + [-10,10], dialycen + [0,0], /device, thick = 2, color = 100
			plots, dialxcen + [0,0], dialycen + [-10,10], /device, thick = 2, color = 100

			circ = (findgen(331))*!DTOR
			for lat_circ = mlat_range[0], mlat_range[1], 5 do begin
				lat_circ_radius = (1 - ((lat_circ - mlat_range[0]) / float((mlat_range[1] - mlat_range[0])))) * (width/2.)
				plots, dialxcen - lat_circ_radius*sin(circ), $
					   dialycen + lat_circ_radius*cos(circ), $
					   color = 100, /device
				if lat_circ gt mlat_range[0] and lat_circ lt mlat_range[1] then begin
					label = string(lat_circ, f='(i0)')
					if lat_circ eq mlat_range[0] + 5 then begin
						xyouts, dialxcen, dialycen + lat_circ_radius, label +  ' MLAT', color = 100, /device, align=-.1
					endif else begin
						xyouts, dialxcen, dialycen + lat_circ_radius, label, color = 100, /device, align=-.2
					endelse
				endif
			endfor
			plots, [dialxcen, dialxcen], dialycen + [0, width/2.], color = 100, /device
			plots, dialxcen - [0, width/2.]*sin(330*!DTOR), $
				   dialycen + [0, width/2.]*cos(330*!DTOR), $
				   color = 100, /device

			lat_circ_radius = (1 - ((-3) / float((mlat_range[1] - mlat_range[0])))) * (width/2.)
			for mlt_clock = 6, 24, 6 do begin
				mlt_label_angle = 90. * ((mlt_clock - 12) / 6.) * !DTOR
				xpos = dialxcen - lat_circ_radius*sin(mlt_label_angle)
				ypos = dialycen + lat_circ_radius*cos(mlt_label_angle) - 8
				label = string(mlt_clock*100, f='(i04)')
				if mlt_clock eq 12 then label += ' MLT'
				if mlt_clock eq 12 then ypos -= 5
				if mlt_clock eq 24 then ypos += 10
				xyouts, xpos, ypos, /device, label, color = 100, align=.5
			endfor

			xpos = dialxcen - radii*sin(clock_angle)
			ypos = dialycen + radii*cos(clock_angle)
			arrow, xpos - .0*rotZonal, $
				   ypos - .0*rotMerid, $
				   xpos + 1*rotZonal, $
				   ypos + 1*rotMerid, $
				   hsize = 5

			xyouts, winx/2. + 5, winy-15, string(wavelength/10., f='(f0.1)') + 'nm Average Vector Dial Plot', color = 250, /device
			xyouts, winx/2. + 5, winy-30, '(Magnetic Coordinates)', color = 250, /device
			xpos = winx/2. + 5
			ypos = winy-55
			mag = 200
			arrow, xpos, ypos, xpos + scale*mag, ypos, color = 250, thick=2, hsize = 10
			xyouts, xpos, ypos + 8, '200 m/s', color = 250, /device

			!p.font = -1
		endif

	;\\----------------------------- End dial plot -----------------------------


	;\\----------------------------- Begin time series -----------------------------
	yrange = [-250, 250]
	blank = replicate(' ', 20)
	cnv_current = convert_js(dt_tm_tojs(systime(/ut)))
	frac_day = cnv_current.dayno + cnv_current.sec/(24.*3600.)
	if (current_day_ut_range[1] - current_day_ut_range[0]) lt 5 then $
		current_day_ut_range[0] -= 5

	current_day_ut_range[1] += 1

	if current_day_ut_range[1] lt current_day_ut_range[0] then begin
		time_range = current_ut_day + [0,5]/24.
	endif else begin
		time_range = current_ut_day + current_day_ut_range/24.
	endelse

	max_time_range = time_range


	for pass = 0, 1 do begin

		bounds = [.1, .27, .98, .46]
		!p.font = 0
		device, set_font='Ariel*17*Bold'
		xyouts, 5, .485*winy, string(wavelength/10., f='(f0.1)') + 'nm  Median Wind Timeseries ' + $
				dt_tm_fromjs(dt_tm_tojs(systime(/ut)), format='Y$/doy$'), /device, color=255
		!p.font = -1
		if pass eq 0 then begin
				plot, max_time_range, [0,1], /xstyle, /ystyle, yrange=yrange, /nodata, pos=bounds, /noerase, xminor=8, xtickint = 2./24., $
				  ytitle = 'Mag. Zonal (m/s)' , yticklen=.003, chars=1.5, xtick_get = xvals, xtickname=blank

			oplot, max_time_range, [0,0], line=1
   			xtickname = time_str_from_decimalut((xvals mod 1) * 24., /noseconds)
			axis, xaxis=0, xtickname = blank, /xstyle, xrange=max_time_range, $
				  chars = 1.5, xminor=8, xtickint = 2./24.
		endif else begin
			plot, max_time_range, [0,1], xstyle=5, ystyle=5, yrange=yrange, /nodata, pos=bounds, /noerase, xtickint = 2./24.
		endelse

		site_count = 0
		for i = 0, n_fitted - 1 do begin

			wnd = *winds[i]

			case wnd.meta.site_code of
				'PKR': begin & color = 150 & ctable = 39 & end
				'HRP': begin & color = 100 & ctable = 39 & end
				'TLK': begin & color = 230 & ctable = 39 & end
				'KTO': begin & color = 200 & ctable = 39 & end
				else: begin & color = 0 & ctable = 0 & end
			endcase

			if pass eq 0 then begin
				loadct, 0, /silent
				if n_elements(wnd.time) gt 1 then errplot, wnd.taxis, wnd.zonalLo, wnd.zonalHi, color=50, width=.00001, noclip=0
				loadct, ctable, /silent

				!p.font = 0
				device, set_font='Ariel*17*Bold'
				xyouts, max_time_range[0] + site_count*0.05*(max_time_range[1]-max_time_range[0]), $
						yrange[1] + 0.03*(yrange[1]-yrange[0]), wnd.meta.site_code, color=color, /data
				!p.font = -1
			endif else begin
				loadct, ctable, /silent

				find_contiguous, wnd.time, 30./60., blocks, n_blocks=nb, /abs
				for bidx = 0, nb - 1 do begin
					ts_0 = blocks[bidx,0]
					ts_1 = blocks[bidx,1]
					x_ut = wnd.taxis[ts_0:ts_1]
					y_wn = wnd.medZonal[ts_0:ts_1]
					if n_elements(x_ut) lt 2 then continue
					oplot, x_ut, y_wn, color=color, psym=-6, sym=.2, thick=.5
				endfor

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

			wnd = *winds[i]

			case wnd.meta.site_code of
				'PKR': begin & color = 150 & ctable = 39 & end
				'HRP': begin & color = 100 & ctable = 39 & end
				'TLK': begin & color = 230 & ctable = 39 & end
				'KTO': begin & color = 200 & ctable = 39 & end
				else: begin & color = 0 & ctable = 0 & end
			endcase

			if pass eq 0 then begin
				loadct, 0, /silent
				if n_elements(wnd.time) gt 1 then errplot, wnd.taxis, wnd.meridLo, wnd.meridHi, color=50, width=.00001, noclip=0
			endif else begin
				loadct, ctable, /silent

				find_contiguous, wnd.time, 30./60., blocks, n_blocks=nb, /abs
				for bidx = 0, nb - 1 do begin
					ts_0 = blocks[bidx,0]
					ts_1 = blocks[bidx,1]
					x_ut = wnd.taxis[ts_0:ts_1]
					y_wn = wnd.medMerid[ts_0:ts_1]
					if n_elements(x_ut) lt 2 then continue
					oplot, x_ut, y_wn, color=color, psym=-6, sym=.2, thick=.5
				endfor

			endelse
		endfor

	endfor ;\\ pass loop

	;\\----------------------------- End time series -----------------------------


	img = tvrd(/true)
	if keyword_set(save_name) then write_png, save_name, img
	wdelete, wid

	dims = size(img, /dimensions)
	lambda = string(wavelength, f='(i04)')

	;\\ Save a copy of the dial plot
		portion = img[*,dims[1]/2:dims[1]-1, dims[2]/2:dims[2]-1]
		year = dt_tm_fromjs(dt_tm_tojs(systime(/ut)), format='Y$')
		fname = 'c:\users\SDI\SDIPlots\' + year + '_AllStations_' + lambda + '\Wind_Dial_Plot\'
		date = dt_tm_fromjs(dt_tm_tojs(systime(/ut)), format='Y$_DOYdoy$')
		fname += 'Wind_Dial_Plot_AllStations_' + date + '_' + lambda + '.png'
		file_mkdir, file_dirname(fname)
		write_png, fname, portion

	;\\ Save a copy of the wind time series
		portion = img[*,*,0:dims[2]/2]
		year = dt_tm_fromjs(dt_tm_tojs(systime(/ut)), format='Y$')
		fname = 'c:\users\SDI\SDIPlots\' + year + '_AllStations_' + lambda + '\Wind_Summary\'
		date = dt_tm_fromjs(dt_tm_tojs(systime(/ut)), format='Y$_DOYdoy$')
		fname += 'Wind_Summary_Plot_AllStations_' + date + '_' + lambda + '.png'
		file_mkdir, file_dirname(fname)
		write_png, fname, portion

MONITOR_WINDFIELDS_END:
	ptr_free, winds

end