
pro plot_vector_scale_on_map, pos, $ ;\\ Normal coordinates
							  map, $
							  mag, $
							  scale, $
							  azi, $
							  headsize=headsize, $
							  headthick=headthick, $
							  thick=thick, $
							  solid=solid, $
							  color=color		;\\ [ctable, color index]

	if not keyword_set(headthick) then headthick = 1
	if not keyword_set(headsize) then headsize = 9
	if not keyword_set(thick) then thick = 1
	if size(color, /type) eq 0 then color = [0, 255]

	;\\ Vector scale arrow
	base_coords = convert_coord(pos[0], pos[1], /normal, /to_data)
	base_coords = map_proj_inverse(base_coords[0], base_coords[1], map_struc = map)
	mag = mag*scale
	get_mapped_vector_components, map, base_coords[1], base_coords[0], mag, azi, $
	 						  	  mapXBase, mapYBase, mapXlen, mapYlen

	length = sqrt(mapXLen*mapXLen + mapYLen*mapYLen)
	p0 = convert_coord(mapXBase,mapYBase, /data, /to_normal)
	p1 = convert_coord(mapXBase+length,mapYBase, /data, /to_normal)
	xlen = p1[0]-p0[0]

	tvlct, red, gre, blue, /get
	loadct, color[0], /silent
	arrow, pos[0], pos[1], pos[0] + xlen, pos[1], hsize = headsize, thick = thick, $
		color = color[1], /normal, solid=solid, hthick=headthick
	tvlct, red, gre, blue
end