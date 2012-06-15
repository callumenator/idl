
;\\ Takes parameters describing the wind field, and lat and lon of desired
;\\ location, and returns meridional, zonal and vertical wind

;\\ params: fltarr(11): [lat0,lon0,u0,v0,w0,du/dx,du/dy,dv/dx,dv/dy,dw/dx,dw/dy]
function simulate_3component_windfield, params, lat, lon, alt

	;\\ Get distance from lat0, lon0, to lat, lon
	dflon = map_2points(params[1], params[0], lon, params[0], /meters, radius = 6300E3 + alt*1E3)/1000.
	dflat = map_2points(params[1], params[0], params[1], lat, /meters, radius = 6300E3 + alt*1E3)/1000.

	;\\ Choose x = longitude, y = latitude
	wind_u = params[2] + dflon*params[5] + dflat*params[6]
	wind_v = params[3] + dflon*params[7] + dflat*params[8]
	wind_w = params[4] + dflon*params[9] + dflat*params[10]

	;cnv_aacgm, lat, lon, alt, mlat, mlon, r, error
	;cnv_aacgm, params[0], params[1], alt, refmlat, refmlon, r, error
	;dfmlon = map_2points(refmlon, refmlat, mlon, refmlat, /meters, radius = 6300E3 + alt*1E3)/1000.
	;dfmlat = map_2points(refmlon, refmlat, refmlon, mlat, /meters, radius = 6300E3 + alt*1E3)/1000.

	;\\ Choose x = mag longitude, y = mag latitude
	;wind_u = params[2] + dfmlon*params[5] + dfmlat*params[6]
	;wind_v = params[3] + dfmlon*params[7] + dfmlat*params[8]
	;wind_w = params[4] + dfmlon*params[9] + dfmlat*params[10]

	return, {u:wind_u, v:wind_v, w:wind_w}
end


pro multiple_instrument_wind_fit_tester

	;\\ Map window size and zoom...
	winx = 1000.
	winy = 700.
	zoom = 7

	;\\ Vector arrow size multiplier...
	scaleFactor = 500.

	;\\ True wind vector plot resolution...
	xstep = 30
	ystep = 30

	triStaticColor = 100
	biStaticColor = 250
	vectorThick = 2.5
	vectorHSize = 9

	plotMono = 0
	plotBi = 0
	plotTri = 0

	;\\ Instrument locations...
		poker = [65.13, -147.48]
		kakto = [69.9, -143.7]
		gakona = [62.3, -145.3]
		toolik = [68.3, -149.5]

	;\\ Get the Poker metadata and winds strucs
		filename = 'C:\cal\IDLSource\CondeAnalysis\Poker_SDI\PKR 2010_267_Poker_630nm_Red_Sky_Date_09_24.nc'
		sdi3k_read_netcdf_data, filename, metadata=metadata, winds=winds

		pkrMeta = metadata

		gakMeta = metadata
		gakMeta.latitude = gakona[0]
		gakMeta.longitude = gakona[1]

		tooMeta = metadata
		tooMeta.latitude = toolik[0]
		tooMeta.longitude = toolik[1]

	;\\ Collected instrument data
		nStations = 3
		stationName = ['Poker', 'Gakona', 'Toolik']
		stationMetadata = [pkrMeta, gakMeta, tooMeta]
		stationWinds = ptrarr(nStations)
		stationWinds = [ptr_new(winds),ptr_new(winds),ptr_new(winds)]
		stationPos = fltarr(nStations, 2)
		stationPos[0,*] = poker
		stationPos[1,*] = gakona
		stationPos[2,*] = toolik
		stationColor = [50, 150, 200]

	;\\ Set up some arrays of structures to hold fit results
		monoFitStruc = {station:'', windCoords:'', lat:0.0, lon:0.0, zonal:0.0, merid:0.0, vertical:0.0}
		biFitStruc =   {stations:strarr(2), windCoords:'', lat:0.0, lon:0.0, lcomp:0.0, mcomp:0.0, $
					    laxis:[0.,0.,0.], maxis:[0.,0.,0.], langle:0.0, mangle:0.0}
		triFitStruc =  {stations:strarr(3), windCoords:'', lat:0.0, lon:0.0, zonal:0.0, merid:0.0, vertical:0.0}

	;\\ Path where zone overlap information is stored...
		overlapSavePath = 'c:\cal\idlsource\newalaskacode\windfit\'

	;\\ Set up a map...
		nth_dip_pole = [84.2, -124.0]
		sth_dip_pole = [-64.5, 137.7]
		nth_cgm_pole = [82.27, 276.97]
		sth_cgm_pole = [-74.25, 125.99]

		loadct, 1, /silent
		window, 0, xs = winx, ys = winy
		polyfill, /normal, [0,0,1,1], [0,1,1,0], color = 50

	;\\ Projection
		mapStruct = MAP_PROJ_INIT(2, CENTER_LATITUDE=mean(stationPos[*,0]), CENTER_LONGITUDE=mean(stationPos[*,1]))
		;mapStruct = MAP_PROJ_INIT(7, center_lat=poker[0]-40, center_lon=poker[1])

	;\\ Create a plot window using the UV Cartesian range.
		!p.noerase = 1
		xscale = mapStruct.uv_box[[0,2]]/(zoom*(winY/winX))
		yscale = mapStruct.uv_box[[1,3]]/zoom
		;yscale = mapStruct.uv_box[[1,3]]/zoom + 3.5E6
		PLOT, xscale, yscale, /NODATA, XSTYLE=5, YSTYLE=5, $
			  color=53, back=0, xticklen=.0001, yticklen=.0001, pos=[0,0,1,1]

		loadct, 0, /silent
		MAP_CONTINENTS, MAP_STRUCTURE=mapStruct, /hires, mlinethick=1, color=0, /fill_continents
		!p.noerase = 1
		MAP_CONTINENTS, MAP_STRUCTURE=mapStruct, /hires, mlinethick=1, color=200
		!p.noerase = 0

		MAP_GRID, MAP_STRUCTURE=mapStruct, glinestyle=1, color=200, londel=5, latdel=2, $
				  latlab = -147, lonlab = 65, label=1

		loadct, 39, /silent

	;\\ Define the true wind field paramaters
		params = fltarr(11)
		;params[0:10] = [poker[0], poker[1], -100, -150, 0, .2, -.1, 0, .3, 0, 0]
		params[0:10] = [poker[0], poker[1], 150, -50, 0, .2, -.3, 0, .5, 0, 0]
		;params[0:10] = [poker[0], poker[1], -100, 0, 0, 0, 0, 0, 0, 0, 0]

	;\\ Plot the simulated wind field
		loadct, 0, /silent
		for xx = xstep/2., winx - 1, xstep do begin
		for yy = ystep/2., winy - 1, ystep do begin

			dcoords = convert_coord(xx, yy, /device, /to_data)
			lonlat = map_proj_inverse(dcoords[0], dcoords[1], map_struct = mapStruct)
			wind = simulate_3component_windfield(params, lonlat[1], lonlat[0], 240)

			magnitude = sqrt(wind.u*wind.u + wind.v*wind.v)*scaleFactor
			azimuth = atan(wind.u, wind.v)/!DTOR

			get_mapped_vector_components, mapStruct, lonlat[1], lonlat[0], magnitude, azimuth, $
										  mapXBase, mapYBase, mapXlen, mapYlen

			arrow, mapXBase-0.5*mapXLen, mapYBase-0.5*mapYLen, $
				   mapXBase+0.5*mapXLen, mapYBase+0.5*mapYLen, color = 100, thick = .5, /solid, /data, hsize=6

		endfor
		endfor
		loadct, 39, /silent


	;\\ Calculate the measured los field from each instrument - note that each zone measures an average
	;\\ los due to its spatial extent
	monoFits = ptrarr(nStations)
	measuredLos = ptrarr(nStations)
	verticalWind = 0
	for s = 0, nStations - 1 do begin

		measuredLos[s] = ptr_new(fltarr(stationMetadata[s].nzones))
		noise = randomu(systime(/sec), stationMetadata.nzones)*20. - 10.

		rads = [0,stationMetadata[s].zone_radii[0:stationMetadata[s].rings-1]]/100.
	    secs = stationMetadata[s].zone_sectors[0:stationMetadata[s].rings-1]
	    azis = (*stationWinds[s])[0].azimuths + 2*stationMetadata[s].oval_angle
	    zens = (*stationWinds[s])[0].zeniths
	    ring = get_zone_rings(zens)

		for z = 0, n_elements(zens) - 1 do begin

			;\\ Coords of zone center
			dist = get_great_circle_length(zens[z], 240)
			endpt = get_end_lat_lon(stationPos[s,0], stationPos[s,1], dist, azis[z])
			mapPt = map_proj_forward(endPt[1], endPt[0], map_struc = mapStruct)
			;if s eq 0 then xyouts, mapPt[0], mapPt[1], string(z, f='(i0)'), color = 155, chart = 1

			;\\ The old way, one sample per zone, at the center
			;	wind = simulate_3component_windfield(params, endpt[0], endpt[1], 240)
			;	dirX = sin(zens[z]*!dtor)*sin(azis[z]*!dtor)
			;	dirY = sin(zens[z]*!dtor)*cos(azis[z]*!dtor)
			;	dirZ = cos(zens[z]*!dtor)

			;	magMeasured = dirX*wind.u + dirY*wind.v + dirZ*wind.w
			;	measuredLos[s,z] = magMeasured


			zenWidth = (rads[ring[z]+1] - rads[ring[z]])*stationMetadata[s].sky_fov_deg
			azWidth = 360. / secs[ring[z]]

			nZenSamples = 10.
			nAziSamples = 20.

			zoneWindLos = fltarr(nZenSamples, nAziSamples)
			for zns = 0., nZenSamples - 1 do begin
			for azs = 0., nAziSamples - 1 do begin

				if z eq 0 then begin
					subZen = zenWidth*zns/(nZenSamples-1)
					subAzi = 360.*azs/(nAziSamples-1)
				endif else begin
					subZen = zens[z] - zenWidth/2. + zenWidth*zns/(nZenSamples-1)
					subAzi = azis[z] - azWidth/2. + azWidth*azs/(nAziSamples-1)
				endelse
				dist = get_great_circle_length(subZen, 240)
				endpt = get_end_lat_lon(stationPos[s,0], stationPos[s,1], dist, subAzi)

				;mapPt = map_proj_forward(endPt[1], endPt[0], map_struc = mapStruct)
				;plots, mapPt[0], mapPt[1], psym=1, sym=.3, color = stationColor[s], /data

				wind = simulate_3component_windfield(params, endpt[0], endpt[1], 240)
				dirX = sin(subZen*!dtor)*sin(subAzi*!dtor)
				dirY = sin(subZen*!dtor)*cos(subAzi*!dtor)
				dirZ = cos(subZen*!dtor)

				magMeasured = dirX*wind.u + dirY*wind.v + dirZ*wind.w
				zoneWindLos[zns, azs] = magMeasured

			endfor
			endfor
			(*measuredLos[s])[z] = mean(zoneWindLos) + noise[z]

			xcomp = (*measuredLos[s])[z]*sin(zens[z]*!dtor)*dirX
			ycomp = (*measuredLos[s])[z]*sin(zens[z]*!dtor)*dirY
			magnitude = sqrt(xcomp*xcomp + ycomp*ycomp)*scaleFactor
			azimuth = atan(xcomp, ycomp)/!DTOR

			get_mapped_vector_components, mapStruct, endPt[0], endPt[1], magnitude, azimuth, $
										  mapXBase, mapYBase, mapXlen, mapYlen

			;arrow, mapXBase-0.5*mapXLen, mapYBase-0.5*mapYLen, $
			;	   mapXBase+0.5*mapXLen, mapYBase+0.5*mapYLen, $
			;	   color = stationColor[s]/2., thick = 2, /solid, /data, hsize = 8
		endfor

		;\\ Calculate the fourier fit(s)
			monoFits[s] = ptr_new(replicate(monoFitStruc, stationMetadata[s].nzones))
			goodZones = indgen(stationMetadata[s].nzones)
			windfit = field_fit( reform(*measuredLos[s] - verticalWind*cos(zens*!dtor))/sin(zens*!dtor), $
								 azis, 240*tan(zens*!dtor), ring, secs, goodZones, /fourier)
			for zz = 0, stationMetadata[s].nzones - 1 do begin
				dist = get_great_circle_length(zens[zz], 240)
				endpt = get_end_lat_lon(stationPos[s,0], stationPos[s,1], dist, azis[zz])
				(*monoFits[s])[zz].windCoords = 'Mag'
				(*monoFits[s])[zz].lat = endpt[0]
				(*monoFits[s])[zz].lon = endpt[1]
				(*monoFits[s])[zz].zonal = windFit.hx[zz]
				(*monoFits[s])[zz].merid = windFit.hy[zz]
			endfor


		;\\ Plot the fitted wind field(s)
		loadct, 39, /silent
		for z = 0, n_elements(zens) - 1 do begin
			dist = get_great_circle_length(zens[z], 240)
			endpt = get_end_lat_lon(stationPos[s,0], stationPos[s,1], dist, azis[z])

			xcomp = windfit.hx[z]
			ycomp = windfit.hy[z]
			magnitude = sqrt(xcomp*xcomp + ycomp*ycomp)*scaleFactor
			azimuth = atan(xcomp, ycomp)/!DTOR

			get_mapped_vector_components, mapStruct, endPt[0], endPt[1], magnitude, azimuth, $
										  mapXBase, mapYBase, mapXlen, mapYlen

			if plotMono eq 1 then begin
				arrow, mapXBase-0.5*mapXLen, mapYBase-0.5*mapYLen, $
					   mapXBase+0.5*mapXLen, mapYBase+0.5*mapYLen, $
					   color = stationColor[s], thick = vectorThick, /solid, /data, hsize = vectorHSize
			endif

		endfor
	endfor


	;\\ Do the bi-static inversions
	if nStations ge 2 then begin
		nStationPairs = factorial(nStations) / (factorial(2) * factorial(nStations - 2))
		biFits = ptrarr(nStationPairs)
		cnt = 0
		for st1 = 0, nStations - 1 do begin
		for st2 = st1+1, nStations - 1 do begin

			s1Data = {metadata:stationMetadata[st1], winds:(*stationWinds[st1])}
			s2Data = {metadata:stationMetadata[st1], winds:(*stationWinds[st2])}

			;\\ See if an overlap file already exists...
			restoredOverlap = 0
			stnName = stationName[[st1,st2]]
			stnName = stnName[sort(stnName)]
			saveName = overlapSavePath + 'BiStaticOverlap_' + stnName[0] + '_' + stnName[1] + '.saved'
			if file_test(saveName) then begin
				restore, saveName
				restoredOverlap = 1
			endif

			;\\ If no saved file exists, calculate bi-static pairs anew...
			if restoredOverlap eq 0 then begin
				npairs = long(stationMetadata[st1].nzones) * long(stationMetadata[st1].nzones)
				bipairs = intarr(npairs, 2)
				bioverlaps = fltarr(npairs, 2)
				pcount = 0
				for s1z = 0, stationMetadata[st1].nzones-1 do begin
					for s2z = 0, stationMetadata[st1].nzones-1 do begin
						percentage_zone_overlap, [s1Data, s2Data], [s1z, s2z], overlap, polygonRes=3, maxSeparation=5
						bipairs[pcount, *] = [s1z, s2z]
						bioverlaps[pcount, *] = overlap
						pcount ++
					endfor
					print, s1z
					wait, 0.0001
				endfor

				;\\ Make a structure to hold the overlap info, and save it...
				zone_overlap = {stationNames:stationName[[st1,st2]], $
								stationLatitudes:stationPos[[st1,st2],0], $
								stationLongitudes:stationPos[[st1,st2],1], $
								date_created_yymmdd_ut:js_to_yymmdd(dt_tm_tojs(systime(/ut))), $
								date_created_js_ut:dt_tm_tojs(systime(/ut)), $
								npairs:npairs, $
								pairs:bipairs, $
								overlaps:bioverlaps}

				;\\ Choose a filename with stations ordered alphabetically for easier retrieval
				stnName = stationName[[st1,st2]]
				stnName = stnName[sort(stnName)]

				saveName = 'BiStaticOverlap_' + stnName[0] + '_' + stnName[1] + '.saved'
				save, filename = 'c:\cal\idlsource\newalaskacode\windfit\'+saveName, zone_overlap
			endif

			;\\ Get the index into the zone_overlap array
			st1_index = (where(zone_overlap.stationNames eq stationName[st1]))[0]
			st2_index = (where(zone_overlap.stationNames eq stationName[st2]))[0]
			if st1_index eq -1 or st2_index eq -1 then stop	;\\ Something has gone wrong!

			;\\ For each pair, resolve the l and m wind components
			pts = where(min(zone_overlap.overlaps, dimension=2) gt 0.2, nBiPts)
			bierr = fltarr(nBiPts)
			biFits[cnt] = ptr_new(replicate(biFitStruc, nBiPts))
			st1Azis = (*stationWinds[st1])[0].azimuths + 2*stationMetadata[st1].oval_angle
	    	st1Zens = (*stationWinds[st1])[0].zeniths
	    	st2Azis = (*stationWinds[st2])[0].azimuths + 2*stationMetadata[st2].oval_angle
	    	st2Zens = (*stationWinds[st2])[0].zeniths
	    	pairs = zone_overlap.pairs
			for overlapIndex = 0, nBiPts - 1 do begin

				p = pts[overlapIndex]
				;plot_zonemap_on_map, stationPos[st1,0], stationPos[st1,1], rads, secs, 240, 158, 75, $
				;					 mapStruct, onlyTheseZones=[pairs[p,st1_index]], front_color=stationcolor[cnt]
				;plot_zonemap_on_map, stationPos[st2,0], stationPos[st2,1], rads, secs, 240, 158, 75, $
				;					 mapStruct, onlyTheseZones=[pairs[p,st2_index]], front_color=stationcolor[cnt]


				;\\ Get the mean location of the bi-static point (is this step dodgy?)
				st1_dist = get_great_circle_length(st1Zens[pairs[p,st1_index]], 240)
				st1_endpt = get_end_lat_lon(stationPos[st1,0], stationPos[st1,1], st1_dist, st1Azis[pairs[p,st1_index]])
				st2_dist = get_great_circle_length(st2Zens[pairs[p,st2_index]], 240)
				st2_endpt = get_end_lat_lon(stationPos[st2,0], stationPos[st2,1], st2_dist, st2Azis[pairs[p,st2_index]])

				meanPt = [mean([st1_endpt[0], st2_endpt[0]]), mean([st1_endpt[1], st2_endpt[1]])]

				resolve_nStatic_wind, meanPt[0], meanPt[1], $
								      reform(stationPos[[st1, st2],0]), reform(stationPos[[st1, st2],1]), $
								  	  [st1Zens[pairs[p,st1_index]], st2Zens[pairs[p,st2_index]]], $
								  	  [st1Azis[pairs[p,st1_index]], st2Azis[pairs[p,st2_index]]], $
								  	  [(*measuredLos[st1])[pairs[p,st1_index]], $
								  	   (*measuredLos[st2])[pairs[p,st2_index]] ], $
								  	  [0,0], $
								  	  outWind, $
								  	  outErr, $
								  	  outInfo

				;\\ Store the fit results
					(*biFits[cnt])[overlapIndex].stations = stationName[[st1,st2]]
					(*biFits[cnt])[overlapIndex].lat = meanPt[0]
					(*biFits[cnt])[overlapIndex].lon = meanPt[1]
					(*biFits[cnt])[overlapIndex].lcomp = outwind[0]
					(*biFits[cnt])[overlapIndex].mcomp = outwind[1]
					(*biFits[cnt])[overlapIndex].laxis = outInfo.laxis
					(*biFits[cnt])[overlapIndex].maxis = outInfo.maxis
					(*biFits[cnt])[overlapIndex].langle = outInfo.langle
					(*biFits[cnt])[overlapIndex].mangle = outInfo.mangle

				;\\ Assume a zero vertical wind, and resolve north and east components...
					north1 = outwind[0]*cos(outInfo.lAngle*!dtor)
					east1 = outwind[0]*sin(outInfo.lAngle*!dtor)
					horiz = (outwind[1] - 0.0*cos(outInfo.mAngle*!dtor))/sin(outInfo.mAngle*!dtor)
					north2 = horiz*sin(-1*outInfo.lAngle*!dtor)
					east2 = horiz*cos(-1*outInfo.lAngle*!dtor)

					magnitude = sqrt((north1+north2)^2 + (east1+east2)^2)*scalefactor
					azimuth = atan(east1+east2, north1+north2)/!DTOR

					get_mapped_vector_components, mapStruct, meanPt[0], meanPt[1], magnitude, azimuth, $
												  mapXBase, mapYBase, mapXlen, mapYlen

					if abs(outInfo.mangle) gt 15 then begin
						if plotBi eq 1 then begin
							arrow, mapXBase-0.5*mapXLen, mapYBase-0.5*mapYLen, $
								   mapXBase+0.5*mapXLen, mapYBase+0.5*mapYLen, $
							   	   color = biStaticColor, thick = vectorThick, /solid, /data, hsize = vectorHSize
						endif
					endif

					trueWind = simulate_3component_windfield(params, meanpt[0], meanpt[1], 240)
					lcomp = dotp([trueWind.u,trueWind.v,trueWind.w], outInfo.laxis)
					mcomp = dotp([trueWind.u,trueWind.v,trueWind.w], outInfo.maxis)
					bierr[overlapIndex] = (lcomp - outwind[0])^2 + (mcomp - outwind[1])^2

			endfor
			cnt++
		endfor
		endfor
		print, mean(bierr)
	endif

	;\\ Do the tri-static inversions
	if nStations ge 3 then begin
		nStationTris = factorial(nStations) / (factorial(3) * factorial(nStations - 3))
		triFits = ptrarr(nStationTris)
		cnt = 0
		for st1 = 0, nStations - 1 do begin
		for st2 = st1+1, nStations - 1 do begin
		for st3 = st2+1, nStations - 1 do begin

			s1Data = {metadata:stationMetadata[st1], winds:(*stationWInds[st1])}
			s2Data = {metadata:stationMetadata[st2], winds:(*stationWInds[st2])}
			s3Data = {metadata:stationMetadata[st3], winds:(*stationWInds[st3])}

			;\\ See if a tri-static overlap file already exists...
			restoredOverlap = 0
			stnName = stationName[[st1,st2,st3]]
			stnName = stnName[sort(stnName)]
			saveName = overlapSavePath + 'TriStaticOverlap_' + stnName[0] + '_' + stnName[1] + $
					   '_' + stnName[2] + '.saved'

			if file_test(saveName) eq 1 then begin
				restore, saveName
				restoredOverlap = 1
			endif

			;\\ If no saved file exists, calculate tri-static 'pairs' anew...
			if restoredOverlap eq 0 then begin

				;\\ Setup arrays...
				npairs = long(stationMetadata[st1].nzones)*$
						 long(stationMetadata[st2].nzones)*$
						 long(stationMetadata[st3].nzones)
				tripairs = intarr(npairs, 3)
				trioverlaps = fltarr(npairs, 3)

				;\\ Check to see if the there is a bi-static overlap file for stations 2 and 3,
				;\\ to narrow down the search a bit...
				stnName = stationName[[st2,st3]]
				stnName = stnName[sort(stnName)]
				saveName = overlapSavePath + 'BiStaticOverlap_' + stnName[0] + '_' + stnName[1] + '.saved'

				if file_test(saveName) eq 1 then begin

					restore, saveName
					pts = where(zone_overlap.overlaps[*,0] ne 0 and zone_overlap.overlaps[*,1] ne 0, npts)
					st2_index = (where(zone_overlap.stationNames eq stationName[st2]))[0]
					st3_index = (where(zone_overlap.stationNames eq stationName[st3]))[0]
					st23_pairs = zone_overlap.pairs[pts,*]
					nst23_pairs = n_elements(st23_pairs[*,0])

					pcount = 0L
					for s1z = 0, stationMetadata[st1].nzones-1 do begin				;\\ Loop through all st1 zones...
						for st23_index = 0, nst23_pairs - 1 do begin	;\\ But only through pairs of st2 and st3...
							s2z = st23_pairs[st23_index,st2_index]
							s3z = st23_pairs[st23_index,st3_index]
							percentage_zone_overlap, [s1Data, s2Data, s3Data], [s1z, s2z, s3z], overlap, polygonRes=3, maxSeparation=5
							tripairs[pcount, *] = [s1z, s2z, s3z]
							trioverlaps[pcount, *] = overlap
							pcount ++
							print, s1z, s2z, s3z, overlap
						endfor
						wait, 0.0001
					endfor

				endif else begin

					;\\ If no other data exists, test all triples (sloooow)...
					pcount = 0L
					for s1z = 0, stationMetadata[st1].nzones-1 do begin
						for s2z = 0, stationMetadata[st2].nzones-1 do begin
							for s3z = 0, stationMetadata[st3].nzones-1 do begin
								percentage_zone_overlap, [s1Data, s2Data, s3Data], [s1z, s2z, s3z], overlap, polygonRes=3, maxSeparation=5
								tripairs[pcount, *] = [s1z, s2z, s3z]
								trioverlaps[pcount, *] = overlap
								pcount ++
								print, s1z, s2z, s3z, overlap
							endfor
							wait, 0.001
						endfor
					endfor
				endelse

				;\\ Make a structure t ohold the overlap info, and save it...
				zone_overlap = {stationNames:stationName[[st1,st2,st3]], $
								stationLatitudes:stationPos[[st1,st2,st3],0], $
								stationLongitudes:stationPos[[st1,st2,st3],1], $
								date_created_yymmdd_ut:js_to_yymmdd(dt_tm_tojs(systime(/ut))), $
								date_created_js_ut:dt_tm_tojs(systime(/ut)), $
								npairs:npairs, $
								pairs:tripairs, $
								overlaps:trioverlaps}

				;\\ Choose a filename with stations ordered alphabetically for easier retrieval
				stnName = stationName[[st1,st2,st3]]
				stnName = stnName[sort(stnName)]

				saveName = 'TriStaticOverlap_' + stnName[0] + '_' + stnName[1] + '_' + stnName[2] + '.saved'
				save, filename = 'c:\cal\idlsource\newalaskacode\windfit\'+saveName, zone_overlap
			endif

			;\\ Get the index into the zone_overlap array
			st1_index = (where(zone_overlap.stationNames eq stationName[st1]))[0]
			st2_index = (where(zone_overlap.stationNames eq stationName[st2]))[0]
			st3_index = (where(zone_overlap.stationNames eq stationName[st3]))[0]
			if st1_index eq -1 or st2_index eq -1 or st3_index eq -1 then stop	;\\ Something has gone wrong!

			nonZeroOverlap = where(total(zone_overlap.overlaps, 2) ne 0, nNonZero)

			triErr = fltarr(nNonZero)
			triFits[cnt] = ptr_new(replicate(triFitStruc, nNonZero))
			st1Azis = (*stationWinds[st1])[0].azimuths + 2*stationMetadata[st1].oval_angle
	    	st1Zens = (*stationWinds[st1])[0].zeniths
	    	st2Azis = (*stationWinds[st2])[0].azimuths + 2*stationMetadata[st2].oval_angle
	    	st2Zens = (*stationWinds[st2])[0].zeniths
	    	st3Azis = (*stationWinds[st3])[0].azimuths + 2*stationMetadata[st3].oval_angle
	    	st3Zens = (*stationWinds[st3])[0].zeniths
			for overlapIndex = 0L, nNonZero - 1 do begin

				p = nonZeroOverlap[overlapIndex]
				if min(zone_overlap.overlaps[p,*]) lt 0.15 then continue

				pairs = zone_overlap.pairs
				;plot_zonemap_on_map, stationPos[st1,0], stationPos[st1,1], rads, secs, 240, 158, 75, $
				;					 mapStruct, onlyTheseZones=[pairs[p,st1_index]], front_color=stationcolor[st1], $
				;					 lineThick=2.5
				;plot_zonemap_on_map, stationPos[st2,0], stationPos[st2,1], rads, secs, 240, 158, 75, $
				;					 mapStruct, onlyTheseZones=[pairs[p,st2_index]], front_color=stationcolor[st2], $
				;					 lineThick=2.5
				;plot_zonemap_on_map, stationPos[st3,0], stationPos[st3,1], rads, secs, 240, 158, 75, $
				;					 mapStruct, onlyTheseZones=[pairs[p,st3_index]], front_color=stationcolor[st3], $
				;					 lineThick=2.5

				;\\ Get the mean location of the tri-static point (is this step dodgy?)
				st1_dist = get_great_circle_length(st1Zens[pairs[p,st1_index]], 240)
				st1_endpt = get_end_lat_lon(stationPos[st1,0], stationPos[st1,1], st1_dist, st1Azis[pairs[p,st1_index]])
				st2_dist = get_great_circle_length(st2Zens[pairs[p,st2_index]], 240)
				st2_endpt = get_end_lat_lon(stationPos[st2,0], stationPos[st2,1], st2_dist, st2Azis[pairs[p,st2_index]])
				st3_dist = get_great_circle_length(st3Zens[pairs[p,st3_index]], 240)
				st3_endpt = get_end_lat_lon(stationPos[st3,0], stationPos[st3,1], st3_dist, st3Azis[pairs[p,st3_index]])

				meanPt = [mean([st1_endpt[0], st2_endpt[0], st3_endpt[0]]), mean([st1_endpt[1], st2_endpt[1], st3_endpt[1]])]

				diff1 = (st1_endpt[0]-meanPt[0])^2 + (st1_endpt[1]-meanPt[1])^2
				diff2 = (st2_endpt[0]-meanPt[0])^2 + (st2_endpt[1]-meanPt[1])^2
				diff3 = (st3_endpt[0]-meanPt[0])^2 + (st3_endpt[1]-meanPt[1])^2

				resolve_nStatic_wind, meanPt[0], meanPt[1], $
								      reform(stationPos[[st1, st2, st3],0]), reform(stationPos[[st1, st2, st3],1]), $
								  	  [st1Zens[pairs[p,st1_index]], $
								  	   st2Zens[pairs[p,st2_index]], $
								  	   st3Zens[pairs[p,st3_index]]], $
								  	  [st1Azis[pairs[p,st1_index]], $
								  	   st2Azis[pairs[p,st2_index]], $
								  	   st3Azis[pairs[p,st3_index]]], $
								  	  [(*measuredLos[st1])[pairs[p,st1_index]], $
								  	   (*measuredLos[st2])[pairs[p,st2_index]], $
								  	   (*measuredLos[st3])[pairs[p,st3_index]] ], $
								  	  [0,0,0], $
								  	  outWind, $
								  	  outErr, $
								  	  outInfo

				;\\ Store the fit results
					(*triFits[cnt])[overlapIndex].stations = stationName[[st1,st2,st3]]
					(*triFits[cnt])[overlapIndex].windCoords = 'Geo'
					(*triFits[cnt])[overlapIndex].lat = meanPt[0]
					(*triFits[cnt])[overlapIndex].lon = meanPt[1]
					(*triFits[cnt])[overlapIndex].zonal = outwind[0]
					(*triFits[cnt])[overlapIndex].merid = outwind[1]
					(*triFits[cnt])[overlapIndex].vertical = outwind[2]

				trueWind = simulate_3component_windfield(params, meanPt[0], meanPt[1], 240)
				triErr[overlapIndex] = (trueWind.u - outwind[0])^2. + $
							(trueWind.v - outwind[1])^2. + $
							(trueWind.w - outwind[2])^2.

				magnitude = sqrt(outwind[0]*outwind[0] + outwind[1]*outwind[1])*scalefactor
				azimuth = atan(outwind[0], outwind[1])/!DTOR

				get_mapped_vector_components, mapStruct, meanPt[0], meanPt[1], magnitude, azimuth, $
											  mapXBase, mapYBase, mapXlen, mapYlen

				if min(outInfo.coplanar) gt 10 then begin
					if plotTri eq 1 then begin

						arrow, mapXBase-0.5*mapXLen, mapYBase-0.5*mapYLen, $
							   mapXBase+0.5*mapXLen, mapYBase+0.5*mapYLen, $
							   color = triStaticColor, thick = vectorThick, /solid, /data, hsize = vectorHSize
					endif
					;plots, map_proj_forward(st1_endpt[1], st1_endpt[0], map=mapStruct), color = 100, psym=1, thick=2, sym=.5
					;plots, map_proj_forward(st2_endpt[1], st2_endpt[0], map=mapStruct), color = 180, psym=1, thick=2, sym=.5
					;plots, map_proj_forward(st3_endpt[1], st3_endpt[0], map=mapStruct), color = 230, psym=1, thick=2, sym=.5

					;plots, mapXBase, mapYBase, $
					;	   color = 30, thick = 2, psym=4, /data
				endif

				;if overlapIndex eq 28 then stop
				;if triErr[overlapIndex] gt 100000 then stop

			endfor
		endfor
		endfor
		endfor
		print, mean(triErr)
	endif

	plots, map_proj_forward(stationPos[0:nStations-1, 1], stationPos[0:nStations-1, 0], map=mapStruct), $
			   /data, color = 255, psym=4, sym=1.5, thick=14
	plots, map_proj_forward(stationPos[0:nStations-1, 1], stationPos[0:nStations-1, 0], map=mapStruct), $
			   /data, color = 0, psym=4, sym=1.5, thick=12
	plots, map_proj_forward(stationPos[0:nStations-1, 1], stationPos[0:nStations-1, 0], map=mapStruct), $
			   /data, color = stationColor, psym=4, sym=1.5, thick=10


	;\\ Concat results
		allMonoFits = [monoFitStruc]
		for k = 0, n_elements(monoFits) - 1 do allMonoFits = [allMonoFits, *monoFits[k]]
		allMonoFits = allMonoFits[1:*]

		allBiFits = [biFitStruc]
		for k = 0, n_elements(biFits) - 1 do allBiFits = [allBiFits, *biFits[k]]
		allBiFits = allBiFits[1:*]

		allTriFits = [triFitStruc]
		for k = 0, n_elements(triFits) - 1 do allTriFits = [allTriFits, *triFits[k]]
		alltriFits = alltriFits[1:*]


	;\\ Begin iterating
	gridx = 100.
	gridy = 100.
	iterMax = 4
	verticalWind = fltarr(gridx, gridy)
	for iter = 0, iterMax - 1 do begin

		;\\ Interpolate Monostatic Fits...
			missingVal = -9999
			monolon = allMonoFits.lon
			monolat = allMonoFits.lat
			limits = [min(monolon), min(monolat), max(monolon), max(monolat)]

			xout = (findgen(gridx)/(gridx-1))*(limits[2]-limits[0]) + limits[0]
			yout = (findgen(gridy)/(gridy-1))*(limits[3]-limits[1]) + limits[1]
			triangulate, monolon, monolat, Tr, B

			zonal = allMonoFits.zonal
			merid = allMonoFits.merid

			monoZonalGrid = trigrid(monolon, monolat, zonal, Tr, missing=missingVal, xout=xout, yout=yout, /quintic)
			monoMeridGrid = trigrid(monolon, monolat, merid, Tr, missing=missingVal, xout=xout, yout=yout, /quintic)

			;triangulate, lon, lat, Tr, B, sphere=s, /degrees, fvalue=zonal
			;grid = trigrid(zonal, sphere=s, [2.,2.], [-180.,-90.,178.,90.]	, /degrees)

		;\\ Interpolate Bistatic Fits...
			keepBiFits = where(allBiFits.mAngle gt 15, nBiFits)
			bilon = allBiFits[keepBiFits].lon
			bilat = allBiFits[keepBiFits].lat
			triangulate, bilon, bilat, Tr, B

			zonal = fltarr(nBiFits)
			merid = fltarr(nBiFits)
			for kk = 0L, nBiFits - 1 do begin
				k = keepBiFits[kk]

				lat = allBiFits[k].lat
				lon = allBiFits[k].lon
				sqDiff = (lon-xout)*(lon-xout) + (lat-yout)*(lat-yout)
				closest = (where(sqDiff eq min(sqDiff)))[0]
				vz = verticalWind[closest, closest]
				print, vz

				north1 = allBiFits[k].lcomp*cos(allBiFits[k].lAngle*!dtor)
				east1 = allBiFits[k].lcomp*sin(allBiFits[k].lAngle*!dtor)
				horiz = (allBiFits[k].mcomp - vz*cos(allBiFits[k].mAngle*!dtor))/sin(allBiFits[k].mAngle*!dtor)
				north2 = horiz*sin(-1*allBiFits[k].lAngle*!dtor)
				east2 = horiz*cos(-1*allBiFits[k].lAngle*!dtor)
				merid[kk] = north1 + north2
				zonal[kk] = east1 + east2
			endfor

			biZonalGrid = trigrid(bilon, bilat, zonal, Tr, missing=missingVal, xout=xout, yout=yout, /quintic)
			biMeridGrid = trigrid(bilon, bilat, merid, Tr, missing=missingVal, xout=xout, yout=yout, /quintic)

			meridBlended = fltarr(gridx, gridy)
			zonalBlended = fltarr(gridx, gridy)

			monoPts = array_indices(monoZonalGrid, where(monoZonalGrid ne missingVal))
			biPts = array_indices(biZonalGrid, where(biZonalGrid ne missingVal))

			;\\ Loop through and produce a blended windfield
			for xx = 0, gridx - 1 do begin
				for yy = 0, gridy - 1 do begin

					monoMissing = 0
					biMissing = 0

					if monoZonalGrid[xx,yy] eq missingVal then monoMissing = 1
					if biZonalGrid[xx,yy] eq missingVal then biMissing = 1

					if monoMissing eq 1 and biMissing eq 1 then begin
						meridBlended[xx,yy] = missingVal
						zonalBlended[xx,yy] = missingVal
						continue
					endif

					if monoMissing eq 0 or biMissing eq 0 then begin
						;clon = xout[xx]
						;clat = yout[yy]

						;monoDist = min((clon-monoLon)*(clon-monoLon) + (clat-monoLat)*(clat-monoLat))
						;biDist = min((clon-biLon)*(clon-biLon) + (clat-biLat)*(clat-biLat))

						monoDiffs = ( (xx-monoPts[0,*])*(xx-monoPts[0,*]) + (yy-monoPts[1,*])*(yy-monoPts[1,*]) )
						biDiffs = ( (xx-biPts[0,*])*(xx-biPts[0,*]) + (yy-biPts[1,*])*(yy-biPts[1,*]) )

						monoPtUse = [monoPts[0, (where(monoDiffs eq min(MonoDiffs)))[0]], monoPts[1, (where(monoDiffs eq min(MonoDiffs)))[0]]]
						biPtUse = [biPts[0, (where(biDiffs eq min(BiDiffs)))[0]], biPts[1, (where(biDiffs eq min(BiDiffs)))[0]]]
						monoDist = min(monoDiffs)
						biDist = min(biDiffs)

						monoFalloff = 200.
						biFalloff = 50.
						monoWeight = 1.0*exp(-(monoDist*monoDist)/monoFalloff)
						biWeight = 2.0*exp(-(biDist*biDist)/biFalloff)

						monoWeightNorm = monoWeight / (monoWeight + biWeight)
						biWeightNorm = biWeight / (monoWeight + biWeight)

						meridBlended[xx,yy] = monoMeridGrid[monoPtUse[0], monoPtUse[1]]*monoWeightNorm + biMeridGrid[biPtUse[0], biPtUse[1]]*biWeightNorm
						zonalBlended[xx,yy] = monoZonalGrid[monoPtUse[0], monoPtUse[1]]*monoWeightNorm + biZonalGrid[biPtUse[0], biPtUse[1]]*biWeightNorm

					endif
				endfor
				wait, 0.0001
			endfor


			;\\ Calculate the horizontal divergence, use this to generate a vertical wind estimate
			scaleHeight = 40.	;\\ kilometers
			for xx = 1, gridx - 1 do begin
				for yy = 1, gridy - 1 do begin

					if meridBlended[xx,yy] eq missingVal or $
					   meridBlended[xx-1,yy] eq missingVal or $
					   meridBlended[xx,yy-1] eq missingVal then continue

					delMerid_x = meridBlended[xx,yy] - meridBlended[xx-1,yy]
					delMerid_y = meridBlended[xx,yy] - meridBlended[xx,yy-1]
					delZonal_x = zonalBlended[xx,yy] - zonalBlended[xx-1,yy]
					delZonal_y = zonalBlended[xx,yy] - zonalBlended[xx,yy-1]

					xdist = map_2points(xout[xx], yout[yy], xout[xx-1], yout[yy], /meters)/1000.
					ydist = map_2points(xout[xx], yout[yy], xout[xx], yout[yy-1], /meters)/1000.

					dudx = delZonal_x / xdist
					dudy = delZonal_y / ydist
					dvdx = delMerid_x / xdist
					dvdy = delMerid_y / ydist

					verticalWind[xx,yy] = scaleHeight*total(dudx + dvdy)

				endfor
			endfor
			;windScale = [-100,100]
			;scale_to_range, verticalWind, windScale[0], windScale[1], vz, missing=[missingVal, 128]


			;\\ Display the final blended windfield
			for xx = 0, gridx - 1, 5 do begin
			for yy = 0, gridy - 1, 5 do begin

				if meridBlended[xx,yy] eq missingVal then continue

				magnitude = sqrt(meridBlended[xx,yy]^2 + zonalBlended[xx,yy]^2)*scaleFactor
				azimuth = atan(zonalBlended[xx,yy], meridBlended[xx,yy])/!dtor
				get_mapped_vector_components, mapStruct, yout[yy], xout[xx], magnitude, azimuth, $
											  mapXBase, mapYBase, mapXlen, mapYlen

				arrow, mapXBase-0.5*mapXLen, mapYBase-0.5*mapYLen, $
					   mapXBase+0.5*mapXLen, mapYBase+0.5*mapYLen, $
					   color = 50 + iter*50, thick = vectorThick, /solid, /data, hsize = vectorHSize
			endfor
			endfor

	endfor

	stop
end