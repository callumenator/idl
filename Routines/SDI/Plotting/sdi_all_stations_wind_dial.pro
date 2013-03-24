
pro sdi_all_stations_wind_dial, ydn=ydn, $
								lambda=lambda, $ ;\\ wavelength filter string, ie '630'
								use_data=use_data, $ ;\\ supply a data structure instead of calling meta_loader
								data_paths=data_paths, $
								time_range=time_range, $ ;\\ [min, max] limit data to a certain ut time range
								resolution=resolution, $ ;\\ array [mlt res, lat res]
								intens_factor=intens_factor, $ ;\\ Manually scale the (normalized) intensities by this number
								intens_scale=intens_scale, $ ;\\ Use this intensity range as a scale bar
								color_table=color_table, $ ;\\ Intensity color table
								color_top = color_top, $ ;\\ Use this top of the color table
								plot_type=plot_type, $ ;\\ 'png' or 'eps'
        						wind_scale=wind_scale, $ ;\\ [m/s, length of m/s]
								output_path=output_path ;\\ root directory for output, a date subdir will be created

	if not keyword_set(plot_type) then plot_type = 'png'
	if plot_type ne 'eps' and plot_type ne 'png' then plot_type = 'png'

	if not keyword_set(resolution) then resolution = [.5, 2] ;\\ mlt, latitude
	if not keyword_set(lambda) then lambda = '630'
	if not keyword_set(color_table) then color_table = 20
	if not keyword_set(color_top) then color_top = 250
	if not keyword_set(wind_scale) then wind_scale = [200., 60.] else wind_scale= float(wind_scale)


	if keyword_set(use_data) then begin
		data = use_data
	endif else begin
		meta_loader, data, ydn=ydn, raw_paths=data_paths, filter=['*'+lambda+'*']
	endelse

	look_for_sites = ['PKR', 'HRP', 'TLK', 'KTO']
	tags = tag_names(data)
	for i = 0, n_elements(look_for_sites) - 1 do begin
		match = where(tags eq look_for_sites[i], m_yn)
		if m_yn eq 1 then append, look_for_sites[i], sites
	endfor

	nsites = n_elements(sites)
	if nsites eq 0 then begin
		print, 'No site data found matching date. Aborting.'
		return
	endif

	;\\ COLLECTING DATA FROM EACH SITE
	for i = 0, nsites - 1 do begin
		idx = (where(strmatch(tags, sites[i]) eq 1))[0]
		time = data.(idx).ut
		meta = data.(idx).meta
		winds = data.(idx).winds
		speks = data.(idx).speks_dc

		if keyword_set(time_range) then begin
			keep = where(time ge time_range[0] and time le time_range[1], nkeep)
			if nkeep eq 0 then begin
				print, 'No points matching time range for site: ' + sites[i]
				continue
			endif
			time = time[keep]
			winds = winds[keep]
			speks = speks[keep]
		endif

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
			intens[*,t] = reform((speks.intensity)[*,t]) / scale
		endfor
		append, reform(winds.zonal_wind, nels(winds.zonal_wind)), allZonal
		append, reform(winds.meridional_wind, nels(winds.meridional_wind)), allMerid
		append, reform(speks.temperature, nels(speks.temperature)), allTemps
		append, reform(zn_mlt, nels(zn_mlt)), allMlt
		append, reform(zn_mlat, nels(zn_mlat)), allMlat
		append, reform(intens, nels(intens)), allIntens
		append, nels(intens), n_intens
		append, time, allTime
		append, meta, allMeta
	endfor

	;\\ OUTPUT PATH AND FILENAME
	if not keyword_set(output_path) then begin
		output_path = dialog_pickfile(/directory, title='Select Output Path')
	endif

	output_subdir = data.yymmdd_nosep
	file_mkdir, output_path + '\' + output_subdir + '\Dial\'
	output_name = 'Dial\All_Stations_Dial.' + plot_type

	case allMeta[0].wavelength_nm of
		630.0: altitude = 240.
		557.7: altitude = 120.
		else: altitude = -1
	endcase
	if altitude eq -1 then return

	;\\ PLOTTING
	if size(allMlt, /type) ne 0 then begin

		winx = 800.
		winy = 800.
		loadct, 0, /silent
		arrow_color = 0
		line_color = 100
		text_color = 0
		back_color = 255
		chars = .6

		;\\ Normalize intensities
			sdi_monitor_intensity_normalize, altitude, allMeta, allIntens, allTime, n_intens

		if plot_type eq 'png' then begin
			window, 0, xs=winx, ys=winy
			!p.font = 0
			arrow_head_size = 10
			arrow_thick = 2
			device, set_font='Ariel*20*Bold'
		endif

		if plot_type eq 'eps' then begin
			eps, filename = output_path + '\' + output_subdir + '\' + output_name, $
				 xs=10, ys=10, /open
			arrow_head_size = 125
			arrow_thick = 1
		endif

		plot, /nodata, [0, winx], [0, winy], pos = [0,0,1,1], xstyle=5, ystyle=5, $
			  color=0, back=back_color

		intBin_mlt = .125
		intBin_lat = .5
		bin2d, allMlt, allMlat, allIntens, [intBin_mlt, intBin_lat], int_outx, int_outy, aveIntens, /extrap
		bin2d, allMlt, allMlat, allZonal, resolution, outx, outy, aveZonal, /extrap
		bin2d, allMlt, allMlat, allMerid, resolution, outx, outy, aveMerid, /extrap

		aveMlt = aveZonal*0.
		aveMlat = aveZonal*0.
		for xx = 0, n_elements(outx) - 1 do aveMlat[xx,*] = outy
		for yy = 0, n_elements(outy) - 1 do aveMlt[*,yy] = outx

		width = winx*.85
		border = (winx/2.) - width
		mlat_range = [55, 90]
		radii = (1 - ((aveMlat - mlat_range[0]) / float((mlat_range[1] - mlat_range[0])))) * (width/2.)
		clock_angle = 90. * ((aveMlt - 12) / 6.) * !DTOR

		rotAngle = -1*(!PI - clock_angle)
		rotZonal = ((aveZonal*cos(rotAngle) - aveMerid*sin(rotAngle))/wind_scale[0])*wind_scale[1]
		rotMerid = ((aveZonal*sin(rotAngle) + aveMerid*cos(rotAngle))/wind_scale[0])*wind_scale[1]

		dialxcen = 0.5*winx
		dialycen = 0.5*winy

		;\\ Intensity background
			temp = aveIntens[sort(aveIntens)]
			nel = n_elements(temp)
			if keyword_set(intens_factor) then begin
				aveIntens /= temp[nel*.98 - 1]
				aveIntens *= intens_factor
			endif
			if keyword_set(intens_scale) then begin
				intensColor = bytscl(aveIntens, min=intens_scale[0], max=intens_scale[1], top=color_top)
			endif else begin
				intensColor = bytscl(aveIntens, min=temp[nel*.02], max=temp[nel*.98 - 1], top=color_top)
			endelse
			intensColor = smooth(intensColor, 5, /edge, /nan)

			if size(color_table, /type) eq 7 then begin
				load_color_table, color_table, /full
			endif else begin
				loadct, color_table, /silent
			endelse
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

				polyfill, [xpos0,xpos1,xpos2,xpos3], [ypos0,ypos1,ypos2,ypos3], /data, color=intensColor[ixx,iyy]
			endfor
			endfor

		;\\ Intensity background scale bar and note
			scbar = intarr(winx/(2.*3.), 15)
			for ssi = 0, 14 do scbar[*,ssi] = congrid(indgen(color_top), winx/(2.*3.), /interp)
			if plot_type eq 'png' then begin
				scbar = congrid(scbar, winx/3.3, 20)
				tv, scbar, (winx - (winx/3.3)) - 10, winy - 50, /data
			endif else begin
				tv, scbar, (winx - (winx/3.3)) - 10, winy - 50, /data, xs=winx/3.3, ys=25
			endelse
			loadct, 0, /silent
			device, set_font='Ariel*22*Bold'
			xyouts, winx, winy - 18, 'Intensity (arbitrary units)', $
					color=text_color, /data, align=1.05, chars=chars, chart=2

		plots, dialxcen + [-10,10], dialycen + [0,0], /data, thick = 2, color = line_color
		plots, dialxcen + [0,0], dialycen + [-10,10], /data, thick = 2, color = line_color

		circ = (findgen(331))*!DTOR
			for lat_circ = mlat_range[0], mlat_range[1], 5 do begin
				lat_circ_radius = (1 - ((lat_circ - mlat_range[0]) / float((mlat_range[1] - mlat_range[0])))) * (width/2.)
				plots, dialxcen - lat_circ_radius*sin(circ), $
					   dialycen + lat_circ_radius*cos(circ), $
					   color = 100, /data
				if lat_circ gt mlat_range[0] and lat_circ lt mlat_range[1] then begin
					label = string(lat_circ, f='(i0)')
					if lat_circ eq mlat_range[0] + 5 then begin
						xyouts, dialxcen, dialycen + lat_circ_radius, label +  ' MLAT', color=text_color, /data, $
								align=-.1, chars=chars, chart=2
					endif else begin
						xyouts, dialxcen, dialycen + lat_circ_radius, label, color=text_color, /data, $
								align=-.2, chars=chars, chart=2
					endelse
				endif
			endfor
			plots, [dialxcen, dialxcen], dialycen + [0, width/2.], color = 100, /data
			plots, dialxcen - [0, width/2.]*sin(330*!DTOR), $
				   dialycen + [0, width/2.]*cos(330*!DTOR), $
				   color = 100, /data

			ticks = findgen(23)*15 + 30
			for tck = 0, n_elements(ticks) - 1 do begin
				lcr = (1 - ((mlat_range[0] - mlat_range[0]) / float((mlat_range[1] - mlat_range[0])))) * (width/2.)
				x0 = dialxcen + lcr*sin(ticks[tck]*!dtor)
				y0 = dialycen + lcr*cos(ticks[tck]*!dtor)
				x1 = dialxcen + 1.03*lcr*sin(ticks[tck]*!dtor)
				y1 = dialycen + 1.03*lcr*cos(ticks[tck]*!dtor)
				plots, [x0,x1], [y0,y1], /data
			endfor

		lat_circ_radius = (1 - ((-3) / float((mlat_range[1] - mlat_range[0])))) * (width/2.)
		for mlt_clock = 6, 24, 6 do begin
			mlt_label_angle = 90. * ((mlt_clock - 12) / 6.) * !DTOR
			xpos = dialxcen - lat_circ_radius*sin(mlt_label_angle)
			ypos = dialycen + lat_circ_radius*cos(mlt_label_angle) - 8
			label = string(mlt_clock*100, f='(i04)')
			if mlt_clock eq 12 then label += ' MLT'
			xyouts, xpos, ypos, /data, label, color = text_color, align=.5, chars=chars, chart=2
		endfor


		xpos = dialxcen - radii*sin(clock_angle)
		ypos = dialycen + radii*cos(clock_angle)
		arrow, xpos - .0*rotZonal, $
			   ypos - .0*rotMerid, $
			   xpos + 1*rotZonal, $
			   ypos + 1*rotMerid, $
			   hsize = arrow_head_size, $
			   color = arrow_color, $
			   thick = arrow_thick, $
			   /data

		if plot_type eq 'png' then begin
			device, set_font='Ariel*20*Bold'
			xyouts, 5, winy-15, 'Average Vector Dial Plot', color = text_color, /data, chart=2
			xyouts, 5, winy-35, '(Magnetic Coordinates)', color = text_color, /data, chart=2
			xpos = 5
			ypos = winy-65
			mag = 200
			arrow, xpos, ypos, xpos + wind_scale[1]*mag/wind_scale[0], ypos, color = arrow_color, $
				   thick=2, hsize = arrow_head_size, /data
			xyouts, xpos, ypos + 8, string(wind_scale[0], f='(i0)') + ' m/s', color = text_color, /data, chart=2
		endif else begin
			xyouts, 10, winy-20, 'Average Vector Dial Plot', color = text_color, /data, chars=1.2*chars, chart=2
			xyouts, 10, winy-45, '(Magnetic Coordinates)', color = text_color, /data, chars=1.2*chars, chart=2
			xpos = 10
			ypos = winy-85
			mag = 200
			arrow, xpos, ypos, xpos + wind_scale[1]*mag/wind_scale[0], ypos, color = arrow_color, $
				   thick=2, hsize = arrow_head_size, /data
			xyouts, xpos, ypos + 12, string(wind_scale[0], f='(i0)') + ' m/s', color = text_color, /data, chars=1.2*chars, chart=2
		endelse

		if plot_type eq 'png' then begin
			!p.font = -1
			image = tvrd(/true)
			write_png, output_path + '\' + output_subdir + '\' + output_name, image
			wdelete, 0
		endif

		if plot_type eq 'eps' then begin
			eps, /close
		endif

	endif
end