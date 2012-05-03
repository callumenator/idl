
;\\ Interpolate a sky field (like an sdi temperature map) onto a map projection.
;\\ For each pixel in the map, this function calculates a pixel location in the field.
;\\ The mapping between window and field pixel is cached so repeated calls are fast.

pro plot_skyfield_on_map, meta, $
						  field, $ ;\\ (vector[nzones])
						  map, $ ;\\ map structure
						  dims, $ ;\\ window dimensions [x,y]
						  offset=offset, $ ;\\ device coords offset
						  scale, $ ;\\ [min, max]
						  scaleto=scaleto, $ ;\\ use this much of the color table
						  ctable=ctable, $
						  altitude=altitude, $
						  smooth_window=smooth_window, $ ;\\ optionally smooth it
						  flush_cache=flush_cache,$	;\\ force routine to recalculate the mapping
						  get_mapping=get_mapping, $ ;\\ return calculate the mapping in this variable
						  use_mapping=use_mapping, $ ;\\ use this mapping, instead of calculating a new one or using cached value
						  scale_bar_pos=scale_bar_pos, $ ;\\ device coords of scale bar center
						  scale_bar_dims=scale_bar_dims, $ ;\\ device dimensions of scale bar (oriented according to longest dimension)
						  scale_bar_alpha=scale_bar_alpha, $ ;\\ make the scale bar transparent?
						  alpha=alpha ;\\ for alpha blending with the image currently in the window

	COMMON Skyfield_Plot, cached_map

	if not keyword_set(altitude) then altitude = 240.
	if not keyword_set(offset) then offset = [0,0]
	if not keyword_set(scaleto) then scaleto = [0,255]

	tvlct, cr, cb, cg, /get
	if size(ctable, /type) ne 0 then loadct, ctable, /silent

	meta_copy = meta
	radii = [0.0, meta.zone_radii[0:meta.rings-1]]
	;\\ Pad out the outermost zones
	del = radii[n_elements(radii)-1] - radii[n_elements(radii)-2]
	meta_copy.zone_radii[meta.rings-1] += del
	get_zone_locations, meta_copy, altitude=altitude, zones=zones

	if keyword_set(smooth_window) then begin
		sdi3k_spacesmooth_fits, field, smooth_window, meta_copy, ([[zones.x], [zones.y]])
	endif

	n = 200
	xr = (findgen(n)/(n-1))*(max(zones.lon)-min(zones.lon)) + min(zones.lon)
	yr = (findgen(n)/(n-1))*(max(zones.lat)-min(zones.lat)) + min(zones.lat)


	;\\ Do we need to calculate the mapping
		recalc_map = 0
		if keyword_set(use_mapping) then begin
			cached_map = use_mapping
		endif else begin
			if keyword_set(flush_cache) or (size(cached_map, /type) eq 0) then recalc_map = 1
		endelse

	if recalc_map eq 1 then begin
		x_step_size = 2
		y_step_size = 2
		nx = dims[0]/x_step_size
		ny = dims[1]/y_step_size
		index_map = intarr(nx, ny, 2)
		for ix = 0, dims[0] - 1, x_step_size do begin
		for iy = 0, dims[1] - 1, y_step_size do begin
			cc = convert_coord(ix, iy, /device, /to_data)
			ll = map_proj_inverse(cc[0], cc[1], map=map)
			if finite(ll[0]) eq 0 or finite(ll[1]) eq 0 then begin
				index_map[ix/x_step_size,iy/y_step_size,*] = [-1,-1]
			endif else begin
				if ll[0] lt min(xr) or ll[0] gt max(xr) or $
				   ll[1] lt min(yr) or ll[1] gt max(yr) then begin
				   	index_map[ix/x_step_size,iy/y_step_size,*] = [-1,-1]
				endif else begin
					cx = interpol(findgen(n), xr, ll[0]) > 0
					cy = interpol(findgen(n), yr, ll[1]) > 0
					index_map[ix/x_step_size,iy/y_step_size,0] = cx < (n-1)
					index_map[ix/x_step_size,iy/y_step_size,1] = cy < (n-1)
				endelse
			endelse
		endfor
			wait, 0.001
		endfor
		neg_pts = congrid(index_map ne -1, dims[0], dims[1], 2)
		cached_map = congrid(index_map, dims[0], dims[1], 2)
		cached_map = cached_map * neg_pts
	endif

	if size(get_mapping, /type) ne 0 then begin
		get_mapping = cached_map
	endif

	triangulate, zones.lon, zones.lat, tr, b
	missing=-999
	field_map = trigrid(zones.lon, zones.lat, field, tr, xout=xr, yout=yr, /quintic, missing=missing)
	scaled_map = bytscl(field_map, min=scale[0], max=scale[1], top=scaleto[1]-scaleto[0]) + scaleto[0]

	if keyword_set(alpha) then begin
		current_image = tvrd(/true)
		erase, 0
	endif

	for ix = 0, dims[0] - 1 do begin
	for iy = 0, dims[1] - 1 do begin

		if cached_map[ix,iy,0] eq -1 or cached_map[ix,iy,1] eq -1 then continue
		map_val = field_map[cached_map[ix,iy,0],cached_map[ix,iy,1]]
		if map_val eq missing then continue

		plots, ix + offset[0], iy + offset[1], color=scaled_map[cached_map[ix,iy,0],cached_map[ix,iy,1]], $
			   /device, psym=3
	endfor
	endfor

	if keyword_set(scale_bar_pos) then begin

		if not keyword_set(scale_bar_dims) then scale_bar_dims = [20,256]
		if not keyword_set(scale_bar_alpha) then begin
			if keyword_set(alpha) then scale_bar_alpha = alpha else scale_bar_alpha = 1.0
		endif

		scbar = fltarr(scale_bar_dims)
		if scale_bar_dims[0] gt scale_bar_dims[1] then begin
			for j = 0, scale_bar_dims[1]-1 do scbar[*,j] = interpol(scaleTo, [0,scale_bar_dims[0]-1], findgen(scale_bar_dims[0]))
		endif else begin
			for j = 0, scale_bar_dims[0]-1 do scbar[j,*] = interpol(scaleTo, [0,scale_bar_dims[1]-1], findgen(scale_bar_dims[1]))
		endelse

		tv, scbar, scale_bar_pos[0] - scale_bar_dims[0]/2., scale_bar_pos[1] - scale_bar_dims[1]/2.
	endif

	if keyword_set(alpha) then begin
		overlay_image = tvrd(/true)
		alpha_map = float(reform(overlay_image[0,*,*]))
		pts = where(total(overlay_image, 1) eq 0, complement=blend, ncomp=nblend)
		if nblend ne 0 then alpha_map[blend] = alpha

		alpha3 = overlay_image
		alpha3 = [[alpha_map], [alpha_map], [alpha_map]]
		blend_image = alpha_blend(current_image, overlay_image, alpha3)

		device, decom=1
		tv, blend_image, /true
		device, decomp=0
	endif

	tvlct, cr, cb, cg
end