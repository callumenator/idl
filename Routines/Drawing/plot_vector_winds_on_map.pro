
;\\ Plots an exposure of SDI winds given a map projection

pro plot_vector_winds_on_map, meta, $			;\\ sdi3k metadata structure
							  winds, $			;\\ sdi3k wind structure or structure with {zonal_wind:arr[nz], meridional_wind:arr[nz],
							  					;\\											zeniths:arr[nz], azimuths:arr[nz]}
							  map, $
							  altitude=altitude, $
							  color=color, $	;\\ [ctable, color]
							  thick=thick, $
							  solid=solid, $
							  headsize=headsize, $
							  headthick=headthick, $
							  scale=scale, $
							  even_sample=even_sample, $
							  sample_azi=sample_azi, $
							  sample_rad=sample_rad, $
							  clip=clip, $
							  dont_center_vector=dont_center_vector, $	;\\ Use the vector tail as the base point
							  rotate_angle=rotate_angle	;\\ Angle in degrees *counter-clockwise*

	if not keyword_set(scale) then scale = 1E3
	if not keyword_set(altitude) then altitude = 240
	if not keyword_set(color) then color = [0, 255]
	if not keyword_set(thick) then thick = 1
	if not keyword_set(headthick) then headthick = 1
	if not keyword_set(headsize) then headsize = 10

	;\\ Store current color table
	tvlct, red, gre, blue, /get

	zonal = winds.zonal_wind
	merid = winds.meridional_wind

	;\\ Rotate if required
	if keyword_set(rotate_angle) then begin
		r_zonal = zonal*cos(rotate_angle*!dtor) - merid*sin(rotate_angle*!dtor)
		r_merid = zonal*sin(rotate_angle*!dtor) + merid*cos(rotate_angle*!dtor)
	endif else begin
		r_zonal = zonal
		r_merid = merid
	endelse

	zonal = r_zonal
	merid = r_merid

	;\\ Get zone lats/lons
	;diff = 180 - (winds[0].azimuths[2] - meta.oval_angle)
	;get_zone_lat_lon, indgen(meta.nzones), meta, winds, lat, lon, $
	;				  aziPlus=diff, useAltitude=altitude

	get_zone_locations, meta, altitude=altitude, zones=zones
	lat = zones.lat
	lon = zones.lon

	;\\ Get FOV edge lat/lons
	edge_ll = get_end_lat_lon(meta.latitude, meta.longitude, $
							  get_great_circle_length(replicate(meta.sky_fov_deg*max(meta.zone_radii/100.), 360), altitude), $
							  findgen(360))

	if keyword_set(even_sample) then begin

		yy = (max(edge_ll[*,0]) - min(edge_ll[*,0]))*findgen(50)/50 + min(edge_ll[*,0])
		xx = (max(edge_ll[*,1]) - min(edge_ll[*,1]))*findgen(50)/50 + min(edge_ll[*,1])


		triangulate, lon, lat, tr, b
		missing = -999
		outz = trigrid(lon, lat, zonal, tr, xout=xx, yout=yy, /quintic, missing=missing, extrap=b)
		outm = trigrid(lon, lat, merid, tr, xout=xx, yout=yy, /quintic, missing=missing, extrap=b)
		outlat = trigrid(lon, lat, lat, tr, xout=xx, yout=yy, missing=missing, extrap=b)
		outlon = trigrid(lon, lat, lon, tr, xout=xx, yout=yy, missing=missing, extrap=b)

		if keyword_set(sample_azi) and keyword_set(sample_rad) then begin
			naz = sample_azi
			rad = sample_rad*25.
		endif else begin
			naz = [5, 10, 15, 20, 30]
			rad = [4., 8., 13., 18., 23.]
		endelse

		dl = abs(outlat - meta.latitude) + abs(outlon - meta.longitude)
		cn = array_indices(outlat, (where(dl eq min(dl)))[0])

		nshown = 0
		zonal = [0.]
		merid = [0.]
		lat = [0.]
		lon = [0.]
		for ring = 0, n_elements(rad) - 1 do begin
			if naz[ring] eq 0 then continue
			ang = (361*findgen(naz[ring])/float(naz[ring]))*!dtor
			subSampX = cn[0] + rad[ring]*cos(ang)
			subSampY = cn[1] + rad[ring]*sin(ang)

			zonal = [zonal, interpolate(outz, subsampX, subsampY)]
			merid = [merid, interpolate(outm, subsampX, subsampY)]
			lat = [lat, interpolate(yy, subsampY)]
			lon = [lon, interpolate(xx, subsampX)]

			nshown += n_elements(subSampX)
		endfor

		lat = lat[1:*]
		lon = lon[1:*]
		zonal = zonal[1:*]
		merid = merid[1:*]

	endif

	magnitude = sqrt(zonal^2 + merid^2)*scale
	azimuth = atan(zonal, merid)/!dtor
	get_mapped_vector_components, map, lat, lon, magnitude, azimuth, $
							  	  mapXBase, mapYBase, mapXlen, mapYlen


	if keyword_set(clip) then begin
		pts = where(mapXBase gt map.uv_box[0]/(1.1*map_zoom) and $
					mapXBase lt map.uv_box[2]/(1.1*map_zoom) and $
					mapYBase gt map.uv_box[1]/(1.1*map_zoom) and $
					mapYBase lt map.uv_box[3]/(1.1*map_zoom), in_map)

		if in_map gt 0 then begin
			mapXBase = mapXBase[pts]
			mapYBase = mapYBase[pts]
			mapXLen = mapXLen[pts]
			mapYLen = mapYLen[pts]
		endif else begin
			tvlct, red, gre, blue
			return
		endelse
	endif

	loadct, color[0], /silent
	if keyword_set(dont_center_vector) then begin
		arrow, mapXBase, $
			   mapYBase, $
			   mapXBase + mapXLen, $
			   mapYBase + mapYLen, $
			   color = color[1], /data, $
			   hsize = headsize, hthick = headthick, $
			   thick = thick, $
			   solid=solid
	endif else begin
		arrow, mapXBase - .5*mapXLen, $
			   mapYBase - .5*mapYLen, $
			   mapXBase + .5*mapXLen, $
			   mapYBase + .5*mapYLen, $
			   color = color[1], /data, $
			   hsize = headsize, hthick = headthick, $
			   thick = thick, $
			   solid=solid
    endelse

	;\\ Reload original color table
	tvlct, red, gre, blue

end