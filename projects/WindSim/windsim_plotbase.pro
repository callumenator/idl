
pro windsim_plotbase, meta, $
					  fields, $
					  stn_colors, $
					  map=map, $
					  no_wind=no_wind, $
					  win_dims = wind_dims

	if not keyword_set(win_dims) then begin
		xs = 800
		ys = 800
	endif else begin
		xs = win_dims[0]
		ys = win_dims[1]
	endelse

	window, 0, xs = xs, ys = ys
	windsim_visualize_map, fields, map=map, center=[meta[0].latitude, meta[0].longitude], zoom=4
	overlay_geomag_contours, map, lon=10, lat=5, color=[0,255]
	windsim_visualize_intensity, fields, map=map, color=[3,100], thick = 2
	if not keyword_set(no_wind) then windsim_visualize_wind, fields, 240., map=map, color=[0,150]

	for s = 0, nels(meta) - 1 do begin
		plot_zonemap_on_map, 0,0,0,0, 240, 180 + meta[s].oval_angle, fov, $
							map, front_color=stn_colors[s], /fovEdge, meta=meta[s]
		plots, map_proj_forward(meta[s].longitude, meta[s].latitude, map=map), psym=7, $
				thick=5, color=stn_colors[s], /data
	endfor
end
