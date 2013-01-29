
pro sdi_all_stations_wind_dial, ydn=ydn, $
								data_paths=data_paths, $
								time_range=time_range, $ ;\\ [min, max] limit data to a certain ut time range
								resolution=resolution, $ ;\\ array [mlt res, lat res]
								plot_type=plot_type, $ ;\\ 'png' or 'eps'
								output_path=output_path ;\\ root directory for output, a date subdir will be created

	if not keyword_set(plot_type) then plot_type = 'png'
	if plot_type ne 'eps' and plot_type ne 'png' then plot_type = 'png'

	if not keyword_set(resolution) then resolution = [.5, 2] ;\\ mlt, latitude

	meta_loader, data, ydn=ydn, raw_paths=data_paths

	sites = ['PKR', 'HRP', 'TLK']
	tags = tag_names(data)
	nsites = total( [total(strmatch(tags, sites[0])), $
					 total(strmatch(tags, sites[1])), $
					 total(strmatch(tags, sites[2])) ] )

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
		for t = 0, nt - 1 do begin
			zn_mlat[*,t] = mlat
			zn_mlt[*,t] = mlt[t] + zn_mlt_offset
		endfor
		append, reform(winds.zonal_wind, nels(winds.zonal_wind)), allZonal
		append, reform(winds.meridional_wind, nels(winds.meridional_wind)), allMerid
		append, reform(speks.temperature, nels(speks.temperature)), allTemps
		append, reform(zn_mlt, nels(zn_mlt)), allMlt
		append, reform(zn_mlat, nels(zn_mlat)), allMlat
	endfor

	;\\ OUTPUT PATH AND FILENAME
	if not keyword_set(output_path) then begin
		output_path = dialog_pickfile(/directory, title='Select Output Path')
	endif

	output_subdir = data.yymmdd_nosep
	file_mkdir, output_path + '\' + output_subdir + '\Dial\'
	output_name = 'Dial\All_Stations_Dial.' + plot_type

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

		scale = 0.3
		;bin2d, allMlt, allMlat, allTemps, [.25, 1], outx, outy, aveTemps, /extrap
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
		rotZonal = (aveZonal*cos(rotAngle) - aveMerid*sin(rotAngle))*scale
		rotMerid = (aveZonal*sin(rotAngle) + aveMerid*cos(rotAngle))*scale

		dialxcen = 0.5*winx
		dialycen = 0.5*winy
		plots, dialxcen + [-10,10], dialycen + [0,0], /data, thick = 2, color = line_color
		plots, dialxcen + [0,0], dialycen + [-10,10], /data, thick = 2, color = line_color

		circ = (30 + findgen(331))*!DTOR
		for lat_circ = mlat_range[0], mlat_range[1], 5 do begin
			lat_circ_radius = (1 - ((lat_circ - mlat_range[0]) / float((mlat_range[1] - mlat_range[0])))) * (width/2.)
			plots, dialxcen - lat_circ_radius*sin(circ), $
				   dialycen + lat_circ_radius*cos(circ), $
				   color = line_color, /data
			if lat_circ gt mlat_range[0] and lat_circ lt mlat_range[1] then begin
				label = string(lat_circ, f='(i0)')
				if lat_circ eq mlat_range[0] + 5 then label += ' MLAT'
				xyouts, dialxcen, dialycen + lat_circ_radius, label, $
						color = text_color, /data, align=1.1, chars=chars, chart=2
			endif
		endfor
		plots, [dialxcen, dialxcen], dialycen + [0, width/2.], color = line_color, /data
		plots, dialxcen - [0, width/2.]*sin(30*!DTOR), $
			   dialycen + [0, width/2.]*cos(30*!DTOR), $
			   color = line_color, /data

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
			arrow, xpos, ypos, xpos + scale*mag, ypos, color = arrow_color, $
				   thick=2, hsize = arrow_head_size, /data
			xyouts, xpos, ypos + 8, '200 m/s', color = text_color, /data, chart=2
		endif else begin
			xyouts, 10, winy-20, 'Average Vector Dial Plot', color = text_color, /data, chars=1.2*chars, chart=2
			xyouts, 10, winy-45, '(Magnetic Coordinates)', color = text_color, /data, chars=1.2*chars, chart=2
			xpos = 10
			ypos = winy-85
			mag = 200
			arrow, xpos, ypos, xpos + scale*mag, ypos, color = arrow_color, $
				   thick=2, hsize = arrow_head_size, /data
			xyouts, xpos, ypos + 12, '200 m/s', color = text_color, /data, chars=1.2*chars, chart=2
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