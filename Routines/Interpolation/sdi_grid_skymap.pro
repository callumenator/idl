
pro sdi_grid_skymap, in_arr, $		;\\ arr [nzones]
					 in_lat_lon, $	;\\ arr [nzones, 2], lat, lon
					 grid_data, $
					 grid_lat, $
					 grid_lon, $
					 missing=missing, $
					 quintic=quintic, $
					 grid_pts=grid_pts	;\\ Number of grid points in each dimension, def. = 50

	if not keyword_set(missing) then missing = -999
	if not keyword_set(grid_pts) then grid_pts = 50.

	outy = (max(in_lat_lon[*,0]) - min(in_lat_lon[*,0]))*(findgen(grid_pts)/float(grid_pts-1)) + min(in_lat_lon[*,0])
	outx = (max(in_lat_lon[*,1]) - min(in_lat_lon[*,1]))*(findgen(grid_pts)/float(grid_pts-1)) + min(in_lat_lon[*,1])

	triangulate, in_lat_lon[*,1], in_lat_lon[*,0], tr, b

	grid_lat = trigrid(in_lat_lon[*,1], in_lat_lon[*,0], in_lat_lon[*,0], tr, xout=outx, yout=outy, missing=missing)
	grid_lon = trigrid(in_lat_lon[*,1], in_lat_lon[*,0], in_lat_lon[*,1], tr, xout=outx, yout=outy, missing=missing)
	if keyword_set(quintic) then begin
		grid_data = trigrid(in_lat_lon[*,1], in_lat_lon[*,0], in_arr, tr, xout=outx, yout=outy, /quintic, missing=missing)
	endif else begin
	 	grid_data = trigrid(in_lat_lon[*,1], in_lat_lon[*,0], in_arr, tr, xout=outx, yout=outy, missing=missing)
	endelse

end