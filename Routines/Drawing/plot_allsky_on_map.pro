
pro plot_allsky_on_map, map, $
						image, $
						fov, $
						azi_plus, $
						altitude, $
						latitude, $
						longitude, $
						dims, $ ;\\ window dimensions
						center=center, $
						border=border, $
						mask_radius=mask_radius, $
						true=true, $
						offset=offset

	COMMON Allsky_Plot, cached_map

	dim = size(image, /dimensions)

	if not keyword_set(center) then center = dim/2.
	if not keyword_set(offset) then offset = [0,0]
	if not keyword_set(border) then border = [0,0,0,0]
	if not keyword_set(mask_radius) then mask_radius = 1E6

	if keyword_set(true) then begin
		img = image[*, border[0]:dim[0]-border[2]-1, border[1]:dim[1]-border[3]-1]
	endif else begin
		img = image[border[0]:dim[0]-border[2]-1, border[1]:dim[1]-border[3]-1]
	endelse


	xs = 5
	ys = 5
	latlon = findgen(dim[0]/xs + 1, dim[1]/ys + 1, 2)
	for xx = 0, dim[0] - 1, xs do begin
	for yy = 0, dim[1] - 1, ys do begin

		xd = float((xx-center[0]))
		yd = float((yy-center[1]))

		dd = sqrt(xd*xd + yd*yd)

		zen = float(fov)*dd/max(dim/2.)
		azi = atan(xd, yd)/!DTOR + azi_plus

		ll = get_end_lat_lon(latitude, longitude, $
							get_great_circle_length(zen, altitude), azi)

		if dd gt mask_radius then latlon[xx/xs,yy/ys,*] = [-999, 0] else latlon[xx/xs,yy/ys,*] = ll

	endfor
	endfor

	xr = [min(latlon[*,*,1]), max(latlon[*,*,1])]
	yr = [min(latlon[*,*,0]), max(latlon[*,*,0])]

	latlon = congrid(latlon, dim[0], dim[1], 2, /interp)

	recalc_map = 1
	if recalc_map eq 1 then begin
		x_step_size = 5
		y_step_size = 5
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
					;cx = interpol(findgen(n), xr, ll[0]) > 0
					;cy = interpol(findgen(n), yr, ll[1]) > 0

					diff = abs(ll[0] - latlon[*,*,1]) + abs(ll[1] - latlon[*,*,0])
					pt = (where(diff eq min(diff)))[0]
					pt_idx = array_indices(latlon, pt)
					cx = pt_idx[0]
					cy = pt_idx[1]
					if diff[pt] lt .2 then begin
						index_map[ix/x_step_size,iy/y_step_size,0] = cx
						index_map[ix/x_step_size,iy/y_step_size,1] = cy
					endif else begin
					 	index_map[ix/x_step_size,iy/y_step_size,0] = -1
						index_map[ix/x_step_size,iy/y_step_size,1] = -1
					endelse
				endelse
			endelse
		endfor
			wait, 0.001
		endfor
		neg_pts = congrid(index_map ne -1, dims[0], dims[1], 2)
		cached_map = congrid(index_map, dims[0], dims[1], 2)
		cached_map = cached_map * neg_pts
	endif

	scaled_map = bytscl(img)

	for ix = 0, dims[0] - 1 do begin
	for iy = 0, dims[1] - 1 do begin

		if cached_map[ix,iy,0] eq -1 or cached_map[ix,iy,1] eq -1 then continue
		map_val = img[cached_map[ix,iy,0],cached_map[ix,iy,1]]

		plots, ix + offset[0], iy + offset[1], color=scaled_map[cached_map[ix,iy,0],cached_map[ix,iy,1]], $
			   /device, psym=3
	endfor
	endfor

	stop

end