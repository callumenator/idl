
;\\ Do a poly fit
pro MIWF_FitPoly, draw=draw

	common miwf_common, guiData, miscData


	if not keyword_set(draw) then begin
		order = 5.
		allLos = [0.]
		allSig = [0.]
		allAzi = [0.]
		allZen = [0.]
		allX = [0.]
		allY = [0.]
		for s = 0, miscData.nStations - 1 do begin

			expIndex = (*miscData.stnIndices[s])[miscData.timeIndex]
			meta = (*miscData.metaData[s])
			wind = (*miscData.windData[s])
			spek = (*miscData.spekDataX[s])

			diff = 180 - (winds[0].azimuths[2] - meta.oval_angle)
			azis = wind[0].azimuths + diff
			zens = wind[0].zeniths

			if s eq 0 then begin
				origin_lon = meta.longitude
				origin_lat = meta.latitude

				case meta.wavelength_nm of
					557.7: alt = 120.
					589.0: alt = 92.
					630.0: alt = 240.
					else: alt = 0.
				endcase
			endif

			dist = get_great_circle_length(zens, alt)
			endpt = get_end_lat_lon(meta.latitude, meta.longitude, dist, azis)
			delLon = fltarr(n_elements(endpt[*,0]))
			delLat = fltarr(n_elements(endpt[*,0]))
			for zz = 0, n_elements(endpt[*,0]) - 1 do begin
				delLon[zz] = map_2points(origin_lon, origin_lat, endpt[zz,1], origin_lat, /meters)/1000.
				delLat[zz] = map_2points(origin_lon, origin_lat, origin_lon, endpt[zz,0], /meters)/1000.
			endfor

			allLos = [allLos, reform(spek[expIndex].velocity)]
			allSig = [allSig, reform(spek[expIndex].sigma_velocity*meta.channels_to_velocity)]
			allAzi = [allAzi, reform(azis)]
			allZen = [allZen, reform(zens)]
			allX = [allX, delLon]
			allY = [allY, delLat]

		endfor

		polywind, allLos[1:*], allSig[1:*], allX[1:*], allY[1:*], allAzi[1:*], allZen[1:*], order, $
	       		  zonal, merid, vertical, sigzon, sigmer, sigver, quality, $
	       		  /horizontal_only

		polyFit = {origin_lat:origin_lat, $
				   origin_lon:origin_lon, $
				   alt:alt, $
				   zonal:zonal, $
				   merid:merid, $
				   order:order, $
				   sigzonal:sigzon, $
				   sigmerid:sigmer, $
				   quality:quality	}

		*miscData.polyFit = polyFit

	endif else begin

		loadct, 0, /silent
		step = 50
		for mx = 0, guiData.drawX - 1, step do begin
		for my = 0, guiData.drawY - 1, step do begin

			coords = convert_coord(mx, my, /device, /to_data)
			endpt = map_proj_inverse(coords[0], coords[1], map = *miscData.mapStructure)
			delLon = map_2points((*miscData.polyFit).origin_lon, (*miscData.polyFit).origin_lat, $
						endpt[0], (*miscData.polyFit).origin_lat, /meters)/1000.
			delLat = map_2points((*miscData.polyFit).origin_lon, (*miscData.polyFit).origin_lat, $
						(*miscData.polyFit).origin_lon, endpt[1], /meters)/1000.


			merid = (*miscData.polyFit).merid[0]
			zonal = (*miscData.polyFit).zonal[0]

			for oo = 1., (*miscData.polyFit).order do begin
				merid += (*miscData.polyFit).merid[2*oo - 1]*(delLon^oo) + (*miscData.polyFit).merid[2*oo]*(delLat^oo)
				zonal += (*miscData.polyFit).zonal[2*oo - 1]*(delLon^oo) + (*miscData.polyFit).zonal[2*oo]*(delLat^oo)
			endfor

			magnitude = sqrt(merid*merid + zonal*zonal)*miscData.vectorOpts.scale
			azimuth = atan(zonal, merid)/!DTOR

			get_mapped_vector_components, *miscData.mapStructure, endpt[1], endpt[0], $
										  magnitude, azimuth, $
										  mapXBase, mapYBase, mapXlen, mapYlen

			arrow, 	mapXBase-0.5*mapXLen, mapYBase-0.5*mapYLen, $
			   		mapXBase+0.5*mapXLen, mapYBase+0.5*mapYLen, $
			   		color = 150, thick = miscData.vectorOpts.thick, $
			   		solid = miscData.vectorOpts.solid, /data, $
			   		hsize = miscData.vectorOpts.hsize
		endfor
		endfor

	endelse

end