
;\\ THE MAIN ENTRY POINT IS:
;\\ sdi_all_stations_wind_fields, ydn=ydn, $ ;\\ year daynumber e.g. '2012013'
;\\ 							  lambda=lambda, $ ;\\ string containing lambda filter eg '630'
;\\								  options=options, $ ;\\ struct of plot options, see code
;\\								  data_paths=data_paths, $ ;\\ array of paths to data
;\\								  time_range=time_range, $ ;\\ [min,max] decimal ut hours
;\\								  time_resolution=time_resolution, $ ;\\ in minutes
;\\								  monostatic=monostatic, $ ;\\ make monostatic plots
;\\								  bistatic=bistatic, $ ;\\ make bistatic plots
;\\								  tristatic=tristatic, $ ;\\ make tristatic plots
;\\								  gradients=gradients, $ ;\\ calculate gradient profiles
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

	if plot_type eq 'png' then begin
		background = tvrd(/true)
	endif
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
function sdi_all_stations_wind_fields_blend_monostatic, geoZonal, $
			 									        geoMerid, $
											       		lat, $
											       		lon, $
											       		sigma=sigma

	;\\ Get an even grid of locations for blending, stay inside monostatic boundary
	if not keyword_set(sigma) then sigma = 0.8
	missing = -9999
	triangulate, lon, lat, tr, b
	grid_lat = trigrid(lon, lat, lat, tr, missing=missing, nx = 20, ny=20)
	grid_lon = trigrid(lon, lat, lon, tr, missing=missing, nx = 20, ny=20)
	use = where(grid_lon ne missing and grid_lat ne missing, nuse)

	ilats = grid_lat[use]
	ilons = grid_lon[use]
	zonal = ilats
	merid = ilats

	for locIdx = 0, nuse - 1 do begin
		latDist = (lat - ilats[locIdx])
		lonDist = (lon - ilons[locIdx])
		dist = sqrt(lonDist*lonDist + latDist*latDist)
		weight = exp(-(dist*dist)/(2*sigma*sigma))
		zonal[locIdx] = total(geoZonal * weight)/total(weight)
		merid[locIdx] = total(geoMerid * weight)/total(weight)
	endfor
	return, {lat:ilats, lon:ilons, zonal:zonal, merid:merid}

end
;\\ --------------------------------------------------------------------------------------------------


;\\ SAMPLE THE MONOSTATIC WIND GRADIENTS
function sdi_all_stations_wind_fields_sample_gradients, blend, $
														altitude, $
														resolution ;\\ [x pts, y pts]

	nx = resolution[0]+1
	ny = resolution[1]+1
	triangulate, blend.lon, blend.lat, tr, b
	grid_lat = trigrid(blend.lon, blend.lat, blend.lat, tr, missing=missing, nx=nx, ny=ny, extrap=b)
	grid_lon = trigrid(blend.lon, blend.lat, blend.lon, tr, missing=missing, nx=nx, ny=ny, extrap=b)
	grid_zon = trigrid(blend.lon, blend.lat, blend.zonal, tr, missing=missing, nx=nx, ny=ny, extrap=b)
	grid_mer = trigrid(blend.lon, blend.lat, blend.merid, tr, missing=missing, nx=nx, ny=ny, extrap=b)

	s = size(grid_zon, /dimensions)
	r = 6371.0

	dlatdy = (grid_lat - shift(grid_lat, 0, 1))[1:s[0]-1, 1:s[1]-1]
	dlondx = (grid_lon - shift(grid_lon, 1, 0))[1:s[0]-1, 1:s[1]-1]

	dx = (dlondx*!DTOR) * r*cos(grid_lat[1:s[0]-1, 1:s[1]-1]*!DTOR)
	dy = (dlatdy*!DTOR) * r

	dudx = (grid_zon - shift(grid_zon, 1, 0))[1:s[0]-1, 1:s[1]-1] / dx
	dudy = (grid_zon - shift(grid_zon, 0, 1))[1:s[0]-1, 1:s[1]-1] / dy
	dvdx = (grid_mer - shift(grid_mer, 1, 0))[1:s[0]-1, 1:s[1]-1] / dx
	dvdy = (grid_mer - shift(grid_mer, 0, 1))[1:s[0]-1, 1:s[1]-1] / dy

	return, {dudx:dudx, dudy:dudy, dvdx:dvdx, dvdy:dvdy, $
			 lat:grid_lat[1:s[0]-1, 1:s[1]-1], $
			 lon:grid_lon[1:s[0]-1, 1:s[1]-1] }
end
;\\ --------------------------------------------------------------------------------------------------


;\\ PLOT BLENDED MONOSTATIC WINDS
pro sdi_all_stations_wind_fields_plot_blend, map, $
								 		     map_opts, $
											 blend, $
											 color=color

	if not keyword_set(color) then color = [100,0]

	magnitude = sqrt(blend.zonal*blend.zonal + blend.merid*blend.merid)*map_opts.scale
	azimuth = atan(blend.zonal, blend.merid) / !DTOR
	loadct, color[1], /silent
	for i = 0, n_elements(magnitude) - 1 do begin
		get_mapped_vector_components, map, blend.lat[i], blend.lon[i], $
								  	  magnitude[i], azimuth[i], x0, y0, xlen, ylen

		arrow, x0 - .5*xlen, y0 - .5*ylen, $
			   x0 + .5*xlen, y0 + .5*ylen, /data, $
			   color = color[0], $
			   hsize = map_opts.arrow_head_size
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


;\\ BLEND THE BISTATIC WINDS
function sdi_all_stations_wind_fields_blend_bistatic, bistaticFits, $
											       	  sigma=sigma

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
	triangulate, bi.lon, bi.lat, tr, b
	grid_lat = trigrid(bi.lon, bi.lat, bi.lat, tr, missing=missing, nx = 20, ny=20)
	grid_lon = trigrid(bi.lon, bi.lat, bi.lon, tr, missing=missing, nx = 20, ny=20)
	use = where(grid_lon ne missing and grid_lat ne missing, nuse)

	ilats = grid_lat[use]
	ilons = grid_lon[use]
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
		zonal[locIdx] = total(allZonal * weight)/total(weight)
		merid[locIdx] = total(allMerid * weight)/total(weight)
	endfor
	return, {lat:ilats, lon:ilons, zonal:zonal, merid:merid}

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

	catch, error
	if error ne 0 then begin
		catch, /cancel
		goto, SKIP_JPEG
	endif

	read_jpeg, list[match], allsky_image
	plot_allsky_on_map, map, allsky_image, 80., 23, 240., 65.13, -147.48, [map_opts.winx,map_opts.winy]
	SKIP_JPEG:
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
		n = interpol(reform(pfisr.vels.vest[0,i,keep]), ut, this_time)
		e = interpol(reform(pfisr.vels.vest[1,i,keep]), ut, this_time)
		mag = sqrt(n*n + e*e)*map_opts.scale
		azi = atan(e, n)/!dtor + 23
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


;\\ PLOT GRADIENT PROFILES
pro sdi_all_stations_wind_fields_plotgrads, grads, $
											map_opts

	critical = -0.132 ;\\ vorticity below this is unstable

	for type = 0, 1 do begin ;\\ do separate monostatic and bistatic plots

		if type eq 0 then begin
			filename = map_opts.output_path + '\' + map_opts.output_subdir + '\' + $
					   map_opts.output_name + '_Monostatic.eps'
			dudx = (grads.m_dudx)[*,5:*]
			dudy = (grads.m_dudy)[*,5:*]
			dvdx = (grads.m_dvdx)[*,5:*]
			dvdy = (grads.m_dvdy)[*,5:*]
			lat =  (grads.mono_lat)[*,5:*]
			lon =  (grads.mono_lon)[*,5:*]
			;\\ Use monostatic lat range for bistatic also, for comparison
			mean_lat = total(lat, 1) / float(n_elements(lat[*,0]))
			lat_range = [min(mean_lat), max(mean_lat)]
		endif else begin
			filename = map_opts.output_path + '\' + map_opts.output_subdir + '\' + $
					   map_opts.output_name + '_Bistatic.eps'
			dudx = (grads.b_dudx)[*,5:*]
			dudy = (grads.b_dudy)[*,5:*]
			dvdx = (grads.b_dvdx)[*,5:*]
			dvdy = (grads.b_dvdy)[*,5:*]
			lat =  (grads.bi_lat)[*,5:*]
			lon =  (grads.bi_lon)[*,5:*]
			mean_lat = total(lat, 1) / float(n_elements(lat[*,0]))
		endelse

		eps, filename=filename, /open, xs = 12, ys=10

			loadct, 39, /silent
			gscale = [-.5,.5]

			vorticity = (dvdx - dudy)
			divergence = (dudx + dvdy)
			ut_range =  [min(grads.ut), max(grads.ut)]

			bounds = split_page(2,1, bounds = [.1,.1,.88,.96], row_gap=.15)
			plot, ut_range, lat_range, /xstyle, /ystyle, pos=bounds[0,0,*], xtickname=replicate(' ', 20), $
				  /nodata, title='Divergence', ytitle = 'Latitude', chart=1.5
			scale_to_range, divergence, gscale[0], gscale[1], div
			tv, div, ut_range[0], min(lat), xs=(ut_range[1]-ut_range[0]), ys=(max(lat)-min(lat)), /data
			plot, ut_range, lat_range, /xstyle, /ystyle, pos=bounds[0,0,*], /noerase, /nodata, xtickname=replicate(' ', 20)

			plot, ut_range, lat_range, /xstyle, /ystyle, pos=bounds[1,0,*], /noerase, /nodata, $
				  title='Vorticity', xtitle='Time (UT)', ytitle = 'Latitude', chart=1.5
			scale_to_range, vorticity, gscale[0], gscale[1], vor
			tv, vor, ut_range[0], min(lat), xs=(ut_range[1]-ut_range[0]), ys=(max(lat)-min(lat)), /data
			plot, ut_range, lat_range, /xstyle, /ystyle, pos=bounds[1,0,*], /noerase, /nodata

			contour, vorticity, grads.ut, mean_lat, /overplot, $
					 levels=[critical], pos=bounds[1,0,*], c_thick = 2, c_colors=[250]

			scale = fltarr(10,256)
			for i = 0, 9 do scale[i,*] = indgen(256)
			tv, scale, /normal, .9, .3, xs=.05, ys=.4
			xyouts, /normal, .925, .26, string(gscale[0], f='(f0.1)'), align=.5, chart=1.5
			xyouts, /normal, .925, .71, string(gscale[1], f='(f0.1)'), align=.5, chart=1.5

		eps, /close

	endfor ;\\ loop over plot type (mono, bi)
end
;\\ --------------------------------------------------------------------------------------------------


;\\ MAIN ENTRY POINT
pro sdi_all_stations_wind_fields, ydn=ydn, $
								  lambda=lambda, $
								  options=options, $ ;\\ struct of plot options, see code
								  data_paths=data_paths, $
								  time_range=time_range, $ ;\\ [min,max] decimal ut hours
								  time_resolution=time_resolution, $ ;\\ in minutes
								  monostatic=monostatic, $ ;\\ make monostatic plots
								  bistatic=bistatic, $ ;\\ make bistatic plots
								  tristatic=tristatic, $ ;\\ make bistatic plots
								  gradients=gradients, $ ;\\ calculate gradient profiles, return in this variable
								  allsky_image_path=allsky_image_path, $ ;\\ location of allsky images for this day
								  pfisr_convection=pfisr_convection, $ ;\\ filename of pfisr convection data for this day
								  plot_type=plot_type, $ ;\\ 'png' or 'eps'
								  output_path=output_path ;\\ root directory for output, a date subdir will be created

	set_plot, 'win'
	device, decompose=0
	if keyword_set(pfisr_convection) then aacgmidl

	if not keyword_set(plot_type) then plot_type = 'png'
	if plot_type ne 'eps' and plot_type ne 'png' then plot_type = 'png'
	if not keyword_set(lambda) then lambda = '630'

	;\\ GET SDI DATA
	meta_loader, data, ydn=ydn, raw_paths=data_paths, filter=['*'+lambda+'*']

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

	;\\ GET PFISR DATA (IF REQUESTED)
	if keyword_set(pfisr_convection) then begin
		if file_test(pfisr_convection) then begin
			pfisr_hdf_read, pfisr_convection, pfisr_convection_data, /convection
		endif
	endif

	if keyword_set(bistatic) or $
	   keyword_set(tristatic) or $
	   arg_present(gradients) then begin
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

	output_subdir = data.yymmdd_nosep + '\' + lambda
	file_mkdir, output_path + '\' + output_subdir
	if keyword_set(monostatic) 	then file_mkdir, output_path + '\' + output_subdir + '\Monostatic\'
	if keyword_set(bistatic) 	then file_mkdir, output_path + '\' + output_subdir + '\Bistatic\'
	if keyword_set(tristatic) 	then file_mkdir, output_path + '\' + output_subdir + '\Tristatic\'
	if arg_present(gradients) 	then file_mkdir, output_path + '\' + output_subdir + '\Gradients\'

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
					mono_blend_color:[100, 0], $
					bi_blend_color:[130, 8], $
					pfisr_color:[190, 39], $
					site_colors:[{site_code:'PKR', color:[150,39]}, $
								 {site_code:'TLK', color:[230,39]}, $
								 {site_code:'HRP', color:[100,39]}, $
								 {site_code:'KTO', color:[190,39]}  ]}
	endif else begin
		map_opts = options
	endelse


	;\\ For PNG, store a copy of the map (since it is slow). EPS needs to redo each time
	sdi_all_stations_wind_fields_makemap, plot_type, background=background, map_opts=map_opts, out_map=map

	;\\ STORE GRADIENT PROFILES
	if arg_present(gradients) then begin
		;\\ DERIVED FROM MONOSTATIC BLENDED WIND FIELDS
		m_dudx = fltarr(n_elements(new_time_axis), 50)
		m_dudy = fltarr(n_elements(new_time_axis), 50)
		m_dvdx = fltarr(n_elements(new_time_axis), 50)
		m_dvdy = fltarr(n_elements(new_time_axis), 50)
		;\\ DERIVED FROM BISTATIC BLENDED WIND FIELDS
		b_dudx = fltarr(n_elements(new_time_axis), 50)
		b_dudy = fltarr(n_elements(new_time_axis), 50)
		b_dvdx = fltarr(n_elements(new_time_axis), 50)
		b_dvdy = fltarr(n_elements(new_time_axis), 50)
	endif

	for time_index = 0, n_elements(new_time_axis) - 1 do begin

		this_time = new_time_axis[time_index]
		map_opts.output_name = '\Monostatic\All_Stations_WindFields_' + time_str_from_decimalut(this_time, /forfile) $
					 		 + '.' + plot_type

		;\\ PLOTTING
		if keyword_set(monostatic) then $
			sdi_all_stations_wind_fields_pageset, plot_type, background=background, map_opts=map_opts

		if keyword_set(allsky_image_path) then $
				sdi_all_stations_wind_fields_plotallsky, map, map_opts, allsky_image_path, this_time

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

			if keyword_set(bistatic) or keyword_set(tristatic) or arg_present(gradients) then begin
				append, zonal, allMonoZonal
				append, merid, allMonoMerid
				append, zinfo.lat, allMonoLat
				append, zinfo.lon, allMonoLon
			endif

			;\\ GET SITE COLOR AND CTABLE
				c_idx = where(strupcase(map_opts.site_colors.site_code) eq $
							  strupcase(meta.site_code), y_idx)
				if y_idx eq 0 then begin
					color = 255
					ctable = 0
				endif else begin
					color = map_opts.site_colors[c_idx[0]].color[0]
					ctable = map_opts.site_colors[c_idx[0]].color[1]
				endelse

			if keyword_set(monostatic) then $
				sdi_all_stations_wind_fields_plotmonostatic, map, map_opts, zonal, merid, $
															 zinfo, ctable, color

			;\\ STORE MULTISTATIC INFO
			if keyword_set(bistatic) or $
			   keyword_set(tristatic) or $
			   arg_present(gradients) then begin
				sdi_time_interpol, speks.velocity*meta.channels_to_velocity, time, this_time, _winds
				sdi_time_interpol, speks.sigma_velocity*meta.channels_to_velocity, time, this_time, _wind_errors
				*allMeta[i] = meta
				*allWinds[i] = _winds
				*allWindErrs[i] = _wind_errors
			endif

		endfor ;\\ loop over sites

		;\\ OVER-PLOT PFISR CONVECTION IF REQUESTED
		if size(pfisr_convection_data, /type) ne 0 then $
				sdi_all_stations_wind_fields_plotpfisr, map, map_opts, pfisr_convection_data, this_time, data.dayno

		;\\ FINALIZE THE MONOSTATIC PLOT
		if keyword_set(monostatic) then begin
			sdi_all_stations_wind_fields_annotate, plot_type, map, map_opts, this_time
			sdi_all_stations_wind_fields_pageset, plot_type, map_opts=map_opts, /done
		endif

		;\\ IF DOING MULTISTATIC, BLEND THE MONOSTATICS WINDS
		if keyword_set(bistatic) or keyword_set(tristatic) or arg_present(gradients) then begin
			mono_blend = sdi_all_stations_wind_fields_blend_monostatic(allMonoZonal, allMonoMerid, allMonoLat, allMonoLon)

			if arg_present(gradients) then begin
				mono_grads = sdi_all_stations_wind_fields_sample_gradients(mono_blend, altitude, [50,50])
				m_dudx[time_index, *] = median(mono_grads.dudx, dimension=1)
				m_dudy[time_index, *] = median(mono_grads.dudy, dimension=1)
				m_dvdx[time_index, *] = median(mono_grads.dvdx, dimension=1)
				m_dvdy[time_index, *] = median(mono_grads.dvdy, dimension=1)
			endif
		endif


		if keyword_set(bistatic) or arg_present(gradients) then begin
			bistaticFits = sdi_all_stations_wind_fields_fitbistatic(altitude, allMeta, allWinds, AllWindErrs)
			bi_blend = sdi_all_stations_wind_fields_blend_bistatic(bistaticFits)
		endif

		;\\ PLOT BISTATIC WINDS IF REQUESTED
		if keyword_set(bistatic) then begin
			map_opts.output_name = '\Bistatic\All_Stations_Bistatic' + $
				time_str_from_decimalut(this_time, /forfile) + '.' + plot_type

			sdi_all_stations_wind_fields_pageset, plot_type, background=background, map_opts=map_opts

			if keyword_set(allsky_image_path) then $
				sdi_all_stations_wind_fields_plotallsky, map, map_opts, allsky_image_path, this_time

			sdi_all_stations_wind_fields_plot_blend, map, map_opts, mono_blend, color=map_opts.mono_blend_color
			sdi_all_stations_wind_fields_plot_blend, map, map_opts, bi_blend, color=map_opts.bi_blend_color
			sdi_all_stations_wind_fields_plotbistatic, map, map_opts, bistaticFits

			sdi_all_stations_wind_fields_annotate, plot_type, map, map_opts, this_time
			sdi_all_stations_wind_fields_pageset, plot_type, map_opts=map_opts, /done

			;\\ OVER-PLOT PFISR CONVECTION IF REQUESTED
			if size(pfisr_convection_data, /type) ne 0 then $
				sdi_all_stations_wind_fields_plotpfisr, map, map_opts, pfisr_convection_data, this_time, data.dayno
		endif

		if arg_present(gradients) then begin
			bi_grads = sdi_all_stations_wind_fields_sample_gradients(bi_blend, altitude, [50,50])
			b_dudx[time_index, *] = median(bi_grads.dudx, dimension=1)
			b_dudy[time_index, *] = median(bi_grads.dudy, dimension=1)
			b_dvdx[time_index, *] = median(bi_grads.dvdx, dimension=1)
			b_dvdy[time_index, *] = median(bi_grads.dvdy, dimension=1)
		endif


		;\\ PLOT TRISTATIC IF REQUESTED
		if keyword_set(tristatic) then begin
			map_opts.output_name = '\Tristatic\All_Stations_Tristatic' + $
				time_str_from_decimalut(this_time, /forfile) + '.' + plot_type

			fits = sdi_all_stations_wind_fields_fittristatic(altitude, allMeta, allWinds, AllWindErrs)

			sdi_all_stations_wind_fields_pageset, plot_type, background=background, map_opts=map_opts

			if keyword_set(allsky_image_path) then $
				sdi_all_stations_wind_fields_plotallsky, map, map_opts, allsky_image_path, this_time

			sdi_all_stations_wind_fields_plot_blend, map, map_opts, mono_blend, color=map_opts.mono_blend_color
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

		wait, 0.005
		print, time_index + 1, n_elements(new_time_axis)
	endfor ;\\ loop through times


	if keyword_set(bistatic) or keyword_set(tristatic) then begin
		ptr_free, allMeta, allWinds, allWindErrs
	endif

	if arg_present(gradients) then begin
		map_opts.output_name = '\Gradients\All_Stations_Gradients'
		gradients = {ut:new_time_axis, $
					 m_dudx:m_dudx, $
					 m_dudy:m_dudy, $
					 m_dvdx:m_dvdx, $
					 m_dvdy:m_dvdy, $
					 b_dudx:b_dudx, $
					 b_dudy:b_dudy, $
					 b_dvdx:b_dvdx, $
					 b_dvdy:b_dvdy, $
					 mono_lat:mono_grads.lat, mono_lon:mono_grads.lon, $
					 bi_lat:bi_grads.lat, bi_lon:bi_grads.lon}
		sdi_all_stations_wind_fields_plotgrads, gradients, map_opts
	endif

end