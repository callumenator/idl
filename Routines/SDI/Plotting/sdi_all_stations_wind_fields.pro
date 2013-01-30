
;\\ THE MAIN ENTRY POINT IS:
;\\ sdi_all_stations_wind_fields, ydn=ydn, $ ;\\ year daynumber e.g. '2012013'
;\\								  options=options, $ ;\\ struct of plot options, see code
;\\								  data_paths=data_paths, $ ;\\ array of paths to data
;\\								  time_range=time_range, $ ;\\ [min,max] decimal ut hours
;\\								  time_resolution=time_resolution, $ ;\\ in minutes
;\\								  monostatic=monostatic, $ ;\\ make monostatic plots
;\\								  bistatic=bistatic ;\\ make bistatic plots
;\\								  tristatic=tristatic ;\\ make tristatic plots
;\\								  allsky_image_path=allsky_image_path, $ ;\\ location of allsky images for this day
;\\								  pfisr_convection=pfisr_convection, $ ;\\ filename of pfisr convection data for this day
;\\								  plot_type=plot_type, $ ;\\ 'png' or 'eps'
;\\								  output_path=output_path ;\\ root directory for output, a
;\\														  ;\\ date subdir will be created


@resolve_nstatic_wind

;\\ GENERATE AN INTERPOLATED TIME AXIS - ASK FOR TIME RANGE IF DOING EPS
pro sdi_all_stations_wind_fields_timeset, sites, $
										  data, $
										  plot_type, $
										  time_range=time_range, $
										  time_resolution=time_resolution, $
										  new_time_axis=new_time_axis

	tags = tag_names(data)
	nsites = n_elements(sites)

	for i = 0, nsites - 1 do begin
		idx = (where(strmatch(tags, sites[i]) eq 1))[0]
		append, min(data.(idx).ut), t_starts
	 	append, max(data.(idx).ut), t_stops
	 	append, median( (data.(idx).ut - shift(data.(idx).ut, 1))[1:n_elements(data.(idx).ut)-1]), t_res
	endfor
	t_start = max(t_starts)
	t_stop = min(t_stops)

	if keyword_set(time_range) then begin
		t_start = time_range[0]
		t_stop = time_range[1]
	endif else begin
		;\\ FOR EPS PLOTS, ALLOW THE USER TO SELECT A TIME RANGE TO PLOT
		if plot_type eq 'eps' then begin
			valid_range = string(t_start, f='(f0.1)') + ' - ' + string(t_stop, f='(f0.1)')
			dummy = 0.0
			xvaredit, dummy, name = 'Start Time (hours UT) ' + valid_range
			t_start = dummy > t_start
			dummy = 0.0
			xvaredit, dummy, name = 'Stop Time (hours UT)' + valid_range
			t_stop = dummy < t_stop
			if t_stop lt t_start then begin
				print, 'Invalid time range'
				return
			endif
		endif
	endelse

	if not keyword_set(time_resolution) then begin
		t_res = min(t_res) ;\\ obs time resolution in hours
	endif else begin
	 	t_res = time_resolution / 60.
	endelse

	ntimes = floor((t_stop - t_start) / t_res)
	new_time_axis = (findgen(ntimes)/float(ntimes-1)) * (t_stop - t_start) + t_start
end
;\\ --------------------------------------------------------------------------------------------------


;\\ SET UP THE PAGE/WINDOW DEPENDING ON PLOT TYPE
pro sdi_all_stations_wind_fields_pageset, plot_type, $
										  background=background, $
										  map_opts=map_opts, $
										  done=done

	if not keyword_set(done) then begin

		if plot_type eq 'png' then begin
			window, 0, xs=map_opts.winx, ys=map_opts.winy
			!p.font = 0
			device, set_font='Ariel*18*Bold'

			map_opts.arrow_head_size = 8

			device, decompose=1
			tv, background, /true
			device, decompose=0

			return
		endif

		if plot_type eq 'eps' then begin
			eps, filename = map_opts.output_path + '\' + $
							map_opts.output_subdir + '\' + $
							map_opts.output_name, $
				xs=10, ys=10, /open

			map_opts.arrow_head_size = 125
			sdi_all_stations_wind_fields_makemap, plot_type, map_opts=map_opts
			return
		endif

	endif else begin

		if plot_type eq 'png' then begin
			!p.font = -1
			image = tvrd(/true)
			write_png, map_opts.output_path + '\' + $
					   map_opts.output_subdir + '\' + $
					   map_opts.output_name, image
			wdelete, 0
		endif

		if plot_type eq 'eps' then begin
			eps, /close
		endif

	endelse
end
;\\ --------------------------------------------------------------------------------------------------


pro sdi_all_stations_wind_fields_coords, save=save, restore=restore
	common sdi_all_stations_wind_fields_coords, map, x, y, plt
	if keyword_set(save) then begin
		map = !map
		x = !x
		y = !y
		plt = !p
	endif
	if keyword_set(restore) then begin
		!map = map
		!x = x
		!y = y
		!p = plt
	endif
end


;\\ GENERATE THE MAP AND DO THE GEOMAGNETIC CONTOUR OVERLAY
pro sdi_all_stations_wind_fields_makemap, plot_type, background=background, map_opts=map_opts, out_map=out_map

	if plot_type eq 'png' then window, 0, xs=map_opts.winx, ys=map_opts.winy

	plot_simple_map, map_opts.lat, map_opts.lon, map_opts.zoom, 1, 1, map=out_map, $
					 backcolor=map_opts.ocean_color, $
					 continentcolor=map_opts.continent_color, $
					 outlinecolor=map_opts.outline_color, $
					 bounds=map_opts.bounds

	overlay_geomag_contours, out_map, longitude=10, latitude=5, color=map_opts.grid_color

	if plot_type eq 'png' then background = tvrd(/true)
end
;\\ --------------------------------------------------------------------------------------------------


;\\ DO THE SPATIAL INTERPOLATION OF THE WIND FIELD VECTORS
pro sdi_all_stations_wind_fields_spaceinterp, map, $
											  zone_info, $
											  magnitude, $
											  azimuth, $
											  n_samples, $
											  ix0=ix0, iy0=iy0, $
											  ixlen=ixlen, iylen=iylen, $
											  missing=missing

	get_mapped_vector_components, map, zone_info.lat, zone_info.lon, $
								  magnitude, azimuth, $
								  x0, y0, xlen, ylen

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

end
;\\ --------------------------------------------------------------------------------------------------


;\\ ADD ANNOTATIONS AND SCALE VECTORS TO THE MAP
pro sdi_all_stations_wind_fields_annotate, plot_type, $
										   map, $
										   map_opts, $
										   this_time

	;\\ ANNOTATIONS
	if plot_type eq 'png' then begin
		xyouts, 5, map_opts.winy - 20, time_str_from_decimalut(this_time) + ' UT', /device, color=map_opts.text_color
		xyouts, 5, map_opts.winy - 38, '200 m/s', /device, color=map_opts.text_color
		pos = convert_coord(5, map_opts.winy - 45, /device, /to_normal)
		plot_vector_scale_on_map, [pos[0,0], pos[1,0]], map, 200, map_opts.scale, $
								  90, headsize=map_opts.arrow_head_size, $
								  headthick=2, thick=2, color=[0,map_opts.text_color]
	endif else begin
		pos = convert_coord(100, map_opts.winy*15.3, /device, /to_normal)
		plot_vector_scale_on_map, [pos[0,0], pos[1,0]], map, 200, map_opts.scale, $
								  90, headsize=map_opts.arrow_head_size, $
								  headthick=2, thick=2, color=[0,map_opts.text_color]

		plot, /noerase, /nodata, [0,map_opts.winx], [0,map_opts.winy], pos=[0,0,1,1], xstyle=5, ystyle=5
		xyouts, 5, map_opts.winy - 20, time_str_from_decimalut(this_time) + ' UT', /data, $
				color=map_opts.text_color, chars=map_opts.chars, chart=2
		xyouts, 5, map_opts.winy - 40, '200 m/s', /data, $
				color=map_opts.text_color, chars=map_opts.chars, chart=2
	endelse
end
;\\ --------------------------------------------------------------------------------------------------

;\\ PLOT THE MONOSTATIC WINDS FROM EACH STATION ON THE SAME MAP
pro sdi_all_stations_wind_fields_plotmonostatic, map, $
											     map_opts, $
											     zonal, $
											     merid, $
											     zone_info, $
											     ctable, $
											     color

	tol = 10.
	n_samples = 100
	magnitude = sqrt(zonal*zonal + merid*merid)*map_opts.scale
	azimuth = atan(zonal, merid)/!DTOR

	use = where(abs(magnitude - median(magnitude)) lt tol*meanabsdev(magnitude, /median), n_use)
	if n_use eq 0 then return

	sdi_all_stations_wind_fields_spaceinterp, map, $
									  		  zone_info[use], $
									  		  magnitude[use], $
									  		  azimuth[use], $
									  		  n_samples, $
									  		  ix0=ix0, iy0=iy0, $
									  		  ixlen=ixlen, iylen=iylen, $
									  		  missing=missing

	use = where(missing ne 1, n_use)
	if n_use eq 0 then return

	loadct, ctable, /silent

	radii = [0, .2, .4, .59, .78, .95]
	azis =  [1,  6,  8, 15, 20, 25]

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
			   /data, color=color, hsize=map_opts.arrow_head_size

	endfor
	endfor
end
;\\ --------------------------------------------------------------------------------------------------

;\\ BLEND THE MONOSTATIC WINDS FROM ALL STATIONS
pro sdi_all_stations_wind_fields_plotmonoblend, map, $
											    map_opts, $
											    geoZonal, $
											    geoMerid, $
											    lat, $
											    lon

	magnitude = sqrt(geoZonal*geoZonal + geoMerid*geoMerid) * map_opts.scale
	azimuth = atan(geoZonal, geoMerid) / !DTOR

	;\\ Get an even grid of locations for blending, stay inside monostatic boundary
	missing = -9999
	triangulate, lon, lat, tr, b
	grid_lat = trigrid(lon, lat, lat, tr, missing=missing, nx = 20, ny=20)
	grid_lon = trigrid(lon, lat, lon, tr, missing=missing, nx = 20, ny=20)
	use = where(grid_lon ne missing and grid_lat ne missing, nuse)
	ilats = grid_lat[use]
	ilons = grid_lon[use]

	loadct, map_opts.blend_color[1], /silent
	for locIdx = 0, nuse - 1 do begin

		latDist = (lat - ilats[locIdx])
		lonDist = (lon - ilons[locIdx])
		dist = sqrt(lonDist*lonDist + latDist*latDist)

		sigma = .8
		weight = exp(-(dist*dist)/(2*sigma*sigma))
		zonal = total(geoZonal * weight)/total(weight)
		merid = total(geoMerid * weight)/total(weight)

		magnitude = sqrt(zonal*zonal + merid*merid)*map_opts.scale
		azimuth = atan(zonal, merid) / !DTOR

		get_mapped_vector_components, map, ilats[locIdx], ilons[locIdx], $
								  	  magnitude, azimuth, x0, y0, xlen, ylen

		arrow, x0 - .5*xlen, y0 - .5*ylen, $
			   x0 + .5*xlen, y0 + .5*ylen, /data, $
			   color = map_opts.blend_color[0], hsize = map_opts.arrow_head_size
	endfor
end
;\\ --------------------------------------------------------------------------------------------------


;\\ FIT BISTATIC WIND VECTORS
function sdi_all_stations_wind_fields_fitbistatic, altitude, $
									 	   		   allMeta, $
											   	   allWinds, $
											   	   AllWindErrs

	sdi_all_stations_wind_fields_coords, /save
	nsites = n_elements(allMeta)
	bistaticFits = 0

	if nsites ge 2 then begin
		;\\ Do the bistatic fitting
		for stn0 = 0, nsites - 1 do begin
		for stn1 = stn0 + 1, nsites - 1 do begin
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
	endif

	sdi_all_stations_wind_fields_coords, /restore
	return, bistaticFits
end
;\\ --------------------------------------------------------------------------------------------------


;\\ PLOT BISTATIC WIND VECTORS OVERLAID ONTO AN AVERAGE BLEND OF MONOSTATIC WINDS
pro sdi_all_stations_wind_fields_plotbistatic, map, $
											   map_opts, $
											   bistaticFits

	use = where(max(bistaticFits.overlap, dim=1) gt .1 and $
			bistaticFits.obsdot lt .8 and $
			bistaticFits.mangle gt 25 and $
			abs(bistaticFits.mcomp) lt 500 and $
			abs(bistaticFits.lcomp) lt 500 and $
			bistaticFits.merr/bistaticFits.mcomp lt .3 and $
			bistaticFits.lerr/bistaticFits.lcomp lt .3, nuse )

	if (nuse le 0) then return

	biFits = bistaticFits[use]
	loadct, map_opts.bistatic_color[1], /silent

	for i = 0, nuse - 1 do begin
		outWind = project_bistatic_fit(biFits[i], 0)
		magnitude = sqrt(outWind[0]*outWind[0] + outWind[1]*outWind[1]) * map_opts.scale
		azimuth = atan(outWind[0], outWind[1]) / !DTOR

		get_mapped_vector_components, map, biFits[i].lat, biFits[i].lon, $
									  magnitude, azimuth, x0, y0, xlen, ylen

		arrow, x0 - .5*xlen, y0 - .5*ylen, $
			   x0 + .5*xlen, y0 + .5*ylen, $
			   color = map_opts.bistatic_color[0], $
			   hsize = map_opts.arrow_head_size, $
			   /data
	endfor

end
;\\ --------------------------------------------------------------------------------------------------


;\\ FIT TRISTATIC WIND VECTORS
function sdi_all_stations_wind_fields_fittristatic, altitude, $
												    allMeta, $
												    allWinds, $
												    AllWindErrs

	sdi_all_stations_wind_fields_coords, /save
	nsites = n_elements(allMeta)
	tristaticFits = 0

	if nsites ge 3 then begin
		;\\ Tristatic fitting
		for stn0 = 0, nsites - 1 do begin
		for stn1 = stn0 + 1, nsites - 1 do begin
		for stn2 = stn1 + 1, nsites - 1 do begin

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

	sdi_all_stations_wind_fields_coords, /restore
	return, tristaticFits
end
;\\ --------------------------------------------------------------------------------------------------


;\\ PLOT TRISTATIC WIND VECTORS OVERLAID ONTO AN AVERAGE BLEND OF MONOSTATIC WINDS
pro sdi_all_stations_wind_fields_plottristatic, map, $
											    map_opts, $
											    tristaticFits

	use = where(max(tristaticFits.overlap, dim=1) gt .2 and $
				tristaticFits.obsdot lt .7 and $
				sqrt(tristaticFits.v*tristaticFits.v + tristaticFits.u*tristaticFits.u) lt 300 and $
				tristaticFits.uerr/tristaticFits.u lt .3 and $
				tristaticFits.verr/tristaticFits.v lt .3, nuse )

	use = where(max(tristaticFits.overlap, dim=1) gt .2)
	if (nuse eq 0) then return
	triFits = tristaticFits[use]

	loadct, map_opts.tristatic_color[1], /silent
	for i = 0, nuse - 1 do begin

		outWind = [triFits[i].u, triFits[i].v]
		magnitude = sqrt(outWind[0]*outWInd[0] + outWind[1]*outWind[1]) * map_opts.scale
		azimuth = atan(outWind[0], outWind[1]) / !DTOR

		get_mapped_vector_components, map, triFits[i].lat, triFits[i].lon, $
									  magnitude, azimuth, x0, y0, xlen, ylen

		arrow, x0, y0, x0 + xlen, y0 + ylen, $
			   color = map_opts.tristatic_color[0], $
			   hsize = map_opts.arrow_head_size, $
			   /data
	endfor
end
;\\ --------------------------------------------------------------------------------------------------


;\\ OVERLAY AN ALLSKY IMAGE ONTO THE MAP
pro sdi_all_stations_wind_fields_plotallsky, map, $
											 map_opts, $
									  	     image_path, $
											 this_time

	list = file_search(image_path, '*.jpeg', count = nfiles)
	time = float(strmid( file_basename(list), 23, 2)) + $
	 	   float(strmid( file_basename(list), 25, 2))*(1./60.) + $
	 	   float(strmid( file_basename(list), 27, 2))*(1./3600.)

	diff = abs(this_time - time)
	match = (where(diff eq min(diff)))[0]

	read_jpeg, list[match], allsky_image
	plot_allsky_on_map, map, allsky_image, 80., 23, 240., 65.13, -147.48, [map_opts.winx,map_opts.winy]
end
;\\ --------------------------------------------------------------------------------------------------


;\\ OVERLAY AN ALLSKY IMAGE ONTO THE MAP
pro sdi_all_stations_wind_fields_plotpfisr, map, $
											map_opts, $
											pfisr, $
											this_time, $
											this_dayno

	keep = where(pfisr.time.doy eq this_dayno, nkeep)
	if nkeep eq 0 then return

	ut = (total(pfisr.time.decimal, 1)/2.)[keep] ;\\ mean start-end time
	if (this_time lt min(ut)) or (this_time gt max(ut)) then return

	nt = n_elements(ut)
	loadct, map_opts.pfisr_color[1], /silent
	mlon = (station_info('pkr')).mlon
	for i = 0, n_elements(pfisr.vels.emag[*,0]) - 1 do begin
		mag = interpol(reform(pfisr.vels.vmag[i,keep]), ut, this_time)
		azi = interpol(reform(pfisr.vels.vdir[i,keep]), ut, this_time) ;\\ degrees north of east
		cnv_aacgm, pfisr.vels.maglatitude[0,i], mlon, 240, glat, glon, r, error, /geo

		get_mapped_vector_components, map, glat, glon, $
									  mag, azi, x0, y0, xlen, ylen

		arrow, x0, y0, x0 + xlen, y0 + ylen, $
			   color = map_opts.pfisr_color[0], $
			   hsize = map_opts.arrow_head_size, $
			   /data
	endfor

end
;\\ --------------------------------------------------------------------------------------------------


;\\ MAIN ENTRY POINT
pro sdi_all_stations_wind_fields, ydn=ydn, $
								  options=options, $ ;\\ struct of plot options, see code
								  data_paths=data_paths, $
								  time_range=time_range, $ ;\\ [min,max] decimal ut hours
								  time_resolution=time_resolution, $ ;\\ in minutes
								  monostatic=monostatic, $ ;\\ make monostatic plots
								  bistatic=bistatic, $ ;\\ make bistatic plots
								  tristatic=tristatic, $ ;\\ make bistatic plots
								  allsky_image_path=allsky_image_path, $ ;\\ location of allsky images for this day
								  pfisr_convection=pfisr_convection, $ ;\\ filename of pfisr convection data for this day
								  plot_type=plot_type, $ ;\\ 'png' or 'eps'
								  output_path=output_path ;\\ root directory for output, a date subdir will be created

	device, decompose=0
	set_plot, 'win'
	if keyword_set(pfisr_convection) then aacgmidl

	if not keyword_set(plot_type) then plot_type = 'png'
	if plot_type ne 'eps' and plot_type ne 'png' then plot_type = 'png'
	if not keyword_set(monostatic) and $
	   not keyword_set(bistatic) and $
	   not keyword_set(tristatic) then return

	;\\ GET SDI DATA
	meta_loader, data, ydn=ydn, raw_paths=data_paths

	sites = ['PKR', 'HRP', 'TLK']
	tags = tag_names(data)
	nsites = total( [total(strmatch(tags, sites[0])), $
					 total(strmatch(tags, sites[1])), $
					 total(strmatch(tags, sites[2])) ] )

	;\\ GET PFISR DATA (IF REQUESTED)
	if keyword_set(pfisr_convection) then begin
		if file_test(pfisr_convection) then begin
			pfisr_hdf_read, pfisr_convection, pfisr_convection_data, /convection
		endif
	endif

	if keyword_set(bistatic) or keyword_set(tristatic) then begin
		allMeta = ptrarr(nsites, /alloc)
		allWinds = ptrarr(nsites, /alloc)
		allWindErrs = ptrarr(nsites, /alloc)
	endif

	;\\ SET UP A TIME AXIS TO INTERPOLATE TO
	sdi_all_stations_wind_fields_timeset, sites, $
										  data, $
										  plot_type, $
										  time_range=time_range, $
										  time_resolution=time_resolution, $
										  new_time_axis=new_time_axis

	;\\ OUTPUT PATH AND FILENAME
	if not keyword_set(output_path) then $
		output_path = dialog_pickfile(/directory, title='Select Output Path')

	output_subdir = data.yymmdd_nosep
	file_mkdir, output_path + '\' + output_subdir
	if keyword_set(monostatic) then file_mkdir, output_path + '\' + output_subdir + '\Monostatic\'
	if keyword_set(bistatic) then file_mkdir, output_path + '\' + output_subdir + '\Bistatic\'
	if keyword_set(tristatic) then file_mkdir, output_path + '\' + output_subdir + '\Tristatic\'

	if not keyword_set(options) then begin
		map_opts = {lat:65,	$
					lon:-147, $
					zoom:5.5, $
					scale:1E3, $
					continent_color:[50,0], ocean_color:[0,0], $
					outline_color:[90,0], grid_color:[0, 100], $
					bounds:[0,0,1,1], $
					arrow_head_size:5, $
					winx:600, $
					winy:600, $
					text_color:255, $
					chars:0.7, $
					output_path:output_path, $
					output_subdir:output_subdir, $
					output_name:'', $
					bistatic_color:[255, 0], $
					tristatic_color:[255, 0], $
					blend_color:[100, 0], $
					pfisr_color:[50, 39]}
	endif else begin
		map_opts = options
	endelse


	;\\ For PNG, store a copy of the map (since it is slow). EPS needs to redo each time
	sdi_all_stations_wind_fields_makemap, plot_type, background=background, map_opts=map_opts, out_map=map

	for time_index = 0, n_elements(new_time_axis) - 1 do begin

		this_time = new_time_axis[time_index]
		map_opts.output_name = '\Monostatic\All_Stations_WindFields_' + time_str_from_decimalut(this_time, /forfile) $
					 		 + '.' + plot_type

		;\\ PLOTTING
		if keyword_set(monostatic) then $
			sdi_all_stations_wind_fields_pageset, plot_type, background=background, map_opts=map_opts

		loadct, 0, /silent
		for i = 0, nsites - 1 do begin

			idx = (where(strmatch(tags, sites[i]) eq 1))[0]
			time = data.(idx).ut
			meta = data.(idx).meta
			winds = data.(idx).winds
			speks = data.(idx).speks_dc

			case meta.wavelength_nm of
				630.0: altitude = 240.
				557.7: altitude = 120.
				else: altitude = -1
			endcase
			if altitude eq -1 then continue
			get_zone_locations, meta, zones=zinfo, altitude=altitude
			sdi_time_interpol, winds.zonal_wind, time, this_time, zonalWind
			sdi_time_interpol, winds.meridional_wind, time, this_time, meridWind

			angle = (-1.0)*meta.oval_angle*!DTOR
			zonal = zonalWind*cos(angle) - meridWind*sin(angle)
			merid = zonalWind*sin(angle) + meridWind*cos(angle)

			if keyword_set(bistatic) or keyword_set(tristatic) then begin
				append, zonal, allMonoZonal
				append, merid, allMonoMerid
				append, zinfo.lat, allMonoLat
				append, zinfo.lon, allMonoLon
			endif

			case meta.site_code of
				'PKR': begin & color = 150 & ctable = 39 & end
				'HRP': begin & color = 100 & ctable = 39 & end
				'TLK': begin & color = 230 & ctable = 39 & end
				else: begin  & color = 0   & ctable = 0  & end
			endcase

			if keyword_set(monostatic) then $
				sdi_all_stations_wind_fields_plotmonostatic, map, map_opts, zonal, merid, $
															 zinfo, ctable, color

			;\\ STORE MULTISTATIC INFO IF DOING THESE
			if keyword_set(bistatic) or keyword_set(tristatic) then begin
				sdi_time_interpol, speks.velocity, time, this_time, _winds
				sdi_time_interpol, speks.sigma_velocity, time, this_time, _wind_errors
				*allMeta[i] = meta
				*allWinds[i] = _winds
				*allWindErrs[i] = _wind_errors
			endif

		endfor ;\\ loop over sites

		;\\ OVER-PLOT PFISR CONVECTION IF REQUESTED
		if size(pfisr_convection_data, /type) ne 0 then $
				sdi_all_stations_wind_fields_plotpfisr, map, map_opts, pfisr_convection_data, this_time, data.dayno

		if keyword_set(monostatic) then begin
			sdi_all_stations_wind_fields_annotate, plot_type, map, map_opts, this_time
			sdi_all_stations_wind_fields_pageset, plot_type, map_opts=map_opts, /done
		endif


		;\\ PLOT BISTATIC IF REQUESTED
		if keyword_set(bistatic) then begin
			map_opts.output_name = '\Bistatic\All_Stations_Bistatic' + time_str_from_decimalut(this_time, /forfile) $
						 		 + '.' + plot_type

			fits = sdi_all_stations_wind_fields_fitbistatic(altitude, allMeta, allWinds, AllWindErrs)

			sdi_all_stations_wind_fields_pageset, plot_type, background=background, $
												  map_opts=map_opts

			if keyword_set(allsky_image_path) then $
				sdi_all_stations_wind_fields_plotallsky, map, map_opts, allsky_image_path, this_time

			sdi_all_stations_wind_fields_plotmonoblend, map, map_opts, allMonoZonal, $
											   		    allMonoMerid, allMonoLat, allMonoLon

			sdi_all_stations_wind_fields_plotbistatic, map, map_opts, fits

			sdi_all_stations_wind_fields_annotate, plot_type, map, map_opts, this_time
			sdi_all_stations_wind_fields_pageset, plot_type, map_opts=map_opts, /done

			;\\ OVER-PLOT PFISR CONVECTION IF REQUESTED
			if size(pfisr_convection_data, /type) ne 0 then $
				sdi_all_stations_wind_fields_plotpfisr, map, map_opts, pfisr_convection_data, this_time, data.dayno
		endif


		;\\ PLOT TRISTATIC IF REQUESTED
		if keyword_set(tristatic) then begin
			map_opts.output_name = '\Tristatic\All_Stations_Tristatic' + time_str_from_decimalut(this_time, /forfile) $
						 		 + '.' + plot_type

			fits = sdi_all_stations_wind_fields_fittristatic(altitude, allMeta, allWinds, AllWindErrs)

			sdi_all_stations_wind_fields_pageset, plot_type, background=background, $
												  map_opts=map_opts

			if keyword_set(allsky_image_path) then $
				sdi_all_stations_wind_fields_plotallsky, map, map_opts, allsky_image_path, this_time

			sdi_all_stations_wind_fields_plotmonoblend, map, map_opts, allMonoZonal, $
											   		    allMonoMerid, allMonoLat, allMonoLon

			sdi_all_stations_wind_fields_plottristatic, map, map_opts, fits

			sdi_all_stations_wind_fields_annotate, plot_type, map, map_opts, this_time
			sdi_all_stations_wind_fields_pageset, plot_type, map_opts=map_opts, /done

			;\\ OVER-PLOT PFISR CONVECTION IF REQUESTED
			if size(pfisr_convection_data, /type) ne 0 then $
				sdi_all_stations_wind_fields_plotpfisr, map, map_opts, pfisr_convection_data, this_time, data.dayno
		endif

		;\\ CLEAR SOME APPENDER ARRAYS
		allMonoZonal = ''
		allMonoMerid = ''
		allMonoLon = ''
		allMonoLat = ''

		wait, 0.1
	endfor ;\\ loop through times


	if keyword_set(bistatic) then begin
		ptr_free, allMeta, allWinds, allWindErrs
	endif

end