

@resolve_nstatic_wind


;\\ Show the generated wind field
pro windsim_visualize_wind, fields, altitude, $
							map=map, $
							color=color, $
							thick=thick, $
							scale=scale

	if not keyword_set(map) then windsim_visualize_map, fields, map=map
	if not keyword_set(color) then color = [0,0]
	if not keyword_set(scale) then scale = 1E3

	loadct, color[0], /silent

	dims = size(fields.wind_u, /dimensions)

	for xx = 0, dims[0] - 1, 10 do begin
	for yy = 0, dims[1] - 1, 10 do begin
		ux = interpol(fields.wind_u[xx,yy,*], fields.alt, altitude)
		uy = interpol(fields.wind_v[xx,yy,*], fields.alt, altitude)
		mag = sqrt(ux*ux + uy*uy)*scale
		azi = atan(ux, uy)/!DTOR
		get_mapped_vector_components, map, fields.lat[yy], fields.lon[xx], mag, azi, $
								  	  xb, yb, xl, yl


		arrow, xb, yb, xb+xl, yb+yl, /data, color = color[1], hsize=8, thick=thick

	endfor
	endfor
end


;\\ Show the sampled line-of-sight winds
pro windsim_visualize_los, samples, $
						   map=map, $
						   color=color, $
						   thick=thick, $
						   scale=scale

	if not keyword_set(color) then color = [0,0]
	if not keyword_set(scale) then scale = 1E3

	loadct, color[0], /silent
	alt = 240.

	for zz = 0, nels(samples.zones) - 1 do begin
		ux = samples.zones[zz].los_unit_vec[0]*samples.zones[zz].los
		uy = samples.zones[zz].los_unit_vec[1]*samples.zones[zz].los

		;ux = samples.zones[zz].u
		;uy = samples.zones[zz].v

		mag = sqrt(ux*ux + uy*uy)*scale
		azi = atan(ux, uy)/!DTOR
		ll = get_end_lat_lon(samples.meta.latitude, samples.meta.longitude, $
							 get_great_circle_length(samples.zones[zz].mid_zen, alt), $
							 samples.zones[zz].mid_az)
		get_mapped_vector_components, map, ll[0], ll[1], mag, azi, $
									  	  xb, yb, xl, yl
		arrow, xb, yb, xb+xl, yb+yl, /data, color = color[1], hsize = 8, thick=thick
		;xyouts, xb, yb, /data, string(zz, f='(i0)'), color=color[1], align=.5
	endfor
end


;\\ Show the monostatic wind fits
pro windsim_visualize_mono, fits, $
							map=map, $
							color=color, $
							thick=thick, $
							scale=scale

	if not keyword_set(color) then color = [0,0]
	if not keyword_set(scale) then scale = 1E3

	loadct, color[0], /silent
	alt = 240.

	for zz = 0, nels(fits.u) - 1 do begin
		ux = fits[zz].u
		uy = fits[zz].v
		mag = sqrt(ux*ux + uy*uy)*scale
		azi = atan(ux, uy)/!DTOR
		get_mapped_vector_components, map, fits[zz].lat, fits[zz].lon, mag, azi, $
									  	  xb, yb, xl, yl
		arrow, xb, yb, xb+xl, yb+yl, /data, color = color[1], hsize = 8, thick=thick
	endfor
end


;\\ Show bistatic wind fits
pro windsim_visualize_bi, fits, $
						  map=map, $
						  color=color, $
						  thick=thick, $
						  scale=scale, $
						  max_obsdot=max_obsdot, $
						  min_zenang=min_zenang, $
						  max_zenang=max_zenang, $
						  min_overlap=min_overlap, $
						  step=step

	if not keyword_set(color) then color = [0,0]
	if not keyword_set(scale) then scale = 1E3
	if not keyword_set(max_obsdot) then max_obsdot = 1.0
	if not keyword_set(min_zenang) then min_zenang = 0
	if not keyword_set(max_zenang) then max_zenang = 100.
	if not keyword_set(min_overlap) then min_overlap = 0.
	if not keyword_set(step) then step = 1

	loadct, color[0], /silent
	alt = 240.

	for zz = 0, nels(fits) - 1, step do begin

		if max(fits[zz].overlap) lt min_overlap then continue
		if fits[zz].obsdot gt max_obsdot then continue
		if fits[zz].mangle gt max_zenang then continue
		if fits[zz].mangle lt min_zenang then continue

		fitxy = project_bistatic_fit(fits[zz], 0., err=err)

		ux = fitxy[0]
		uy = fitxy[1]
		mag = sqrt(ux*ux + uy*uy)*scale
		azi = atan(ux, uy)/!DTOR

		get_mapped_vector_components, map, fits[zz].lat, fits[zz].lon, mag, azi, $
									  xb, yb, xl, yl
		arrow, xb, yb, xb+xl, yb+yl, /data, color = color[1], hsize = 8, thick=thick
	endfor
end


;\\ Show the tristatic wind fits
pro windsim_visualize_tri, fits, $
							map=map, $
							color=color, $
							thick=thick, $
							scale=scale, $
							max_obsdot=max_obsdot, $
							min_overlap=min_overlap, $
							step=step

	if not keyword_set(color) then color = [0,0]
	if not keyword_set(scale) then scale = 1E3
	if not keyword_set(max_obsdot) then max_obsdot = 1.0
	if not keyword_set(min_overlap) then min_overlap = 0.0
	if not keyword_set(step) then step = 1

	loadct, color[0], /silent

	for zz = 0, nels(fits) - 1, step do begin

		if fits[zz].obsDot gt max_obsdot then continue
		if max(fits[zz].overlap) lt min_overlap then continue

		if total(strmatch(fits[zz].stations, 'PKR')) eq 1 and $
		   total(strmatch(fits[zz].stations, 'HRP')) eq 1 and $
		   total(strmatch(fits[zz].stations, 'TLK')) eq 1 then continue

		ux = fits[zz].u
		uy = fits[zz].v
		mag = sqrt(ux*ux + uy*uy)*scale
		azi = atan(ux, uy)/!DTOR
		get_mapped_vector_components, map, fits[zz].lat, fits[zz].lon, mag, azi, $
								  	  xb, yb, xl, yl
		arrow, xb, yb, xb+xl, yb+yl, /data, color = color[1], hsize=8, thick=thick
	endfor
end


;\\ Show the intensity as a contour overlay
pro windsim_visualize_intensity, fields, map=map, color=color, thick=thick

	if not keyword_set(color) then color = [0,0]

	if size(fields.emission_ctr, /n_elements) eq 1 then return

	xy = fields.emission_ctr
	info = fields.emission_ifo
	loadct, color[0], /silent

	for i = 0, (nels(info) - 1 ) do begin
	   s = [indgen(info(i).n), 0]
	   path = xy(*,info(i).offset + s )
	   lats = reform(path[1,*])
	   lons = reform(path[0,*])
	   lats = interpolate(lats, nels(lats)*(findgen(50)/49.))
	   lons = interpolate(lons, nels(lons)*(findgen(50)/49.))
	   ord = sort(lons)
	   lats = lats[ord]
	   lons = lons[ord]
	   plots, map_proj_forward(lons, lats, map=map), /data, color = color[1], thick=thick
	endfor
end


pro windsim_visualize_map, fields, map=map, center=center, zoom=zoom, nodraw=nodraw

	if not keyword_set(center) then begin
		lat = mean(fields.lat)
		lon = mean(fields.lon)
	endif else begin
		lat = center[0]
		lon = center[1]
	endelse

	if not keyword_set(zoom) then zoom = 8

	plot_simple_map, lat, lon, zoom, 1, 1, map=map, nodraw=nodraw, $
					 backColor=[0, 0], continentColor=[100,0]
end
