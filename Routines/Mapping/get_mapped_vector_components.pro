
;\\ AZIMUTH SHOULD BE EAST OF NORTH

pro get_mapped_vector_components, mapStruct, baseLat, baseLon, magnitude, azimuth, $
								  mapXBase, mapYBase, mapXlen, mapYlen

	base_pos = [[baseLat], [baseLon]]
	ept = get_end_lat_lon(reform(base_pos(*,0)), reform(base_pos(*,1)), 1., azimuth)

	base = map_proj_forward(base_pos(*,1), base_pos(*,0), MAP_STRUCTURE=mapStruct)
	tip = map_proj_forward(ept(*,1), ept(*,0), MAP_STRUCTURE=mapStruct)

	xlen = tip(0,*) - base(0,*)
	ylen = tip(1,*) - base(1,*)
	az = atan(xlen,ylen)
	pxlen = magnitude*sin(az)
	pylen = magnitude*cos(az)

	mapXlen = pxlen
	mapYlen = pylen
	mapXBase = base(0,*)
	mapYBase = base(1,*)

end