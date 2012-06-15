
;\\ ZmapData is an array of structures of type:
;\\ {metadata:, winds:}, with fields containing structures returned by Mark's netcdf reader.
;\\ Number of elements of the array correspond to 2-way or 3-way overlap test (for bi-static or tri-static obs).
;\\ Zones is an integer array of the 2 or 3 zone numbers to test for overlap.
pro percentage_zone_overlap, zmapData, $
							 zones, $
							 altitude, $
							 outOverlap, $					;\\ vector of percentage of zone are common to the group
							 fullFOV=fullFOV, $				;\\ estimate the overlap of the whole field of view (all zones)
							 polygonRes = polygonRes, $		;\\ default is 1, which is 4 vertices. 2 gives 8 vertices, etc.
							 showZones=showZones, $			;\\ show zones on a map
							 captureImages=captureImages, $	;\\ capture png sequence for a movie
							 captureImageEps=captureImageEps, $	;\\ capture eps
							 maxSeparation=maxSeparation	;\\ if separation is larger than this (in degrees) overlap test is skipped

	if not keyword_set(polygonRes) then polygonRes = 1
	polygonRes = float(polygonRes)

	gridx=100
	gridy=100
	alt = altitude

	if keyword_set(showZones) then begin
		window, 3, xs = 1000, ys = 500
		loadct, 0, /silent
		erase, 255
		bounds = [500./1000., 0, 1000./1000., 500./500.]
		plot_simple_map, zmapData[0].metadata.latitude, zmapData[0].metadata.longitude, $
						7, 500, 500, map=map, bounds=bounds, $
						backColor=[255, 0], continentColor=[200,0], outlineColor=[0,0]

		for s = 0, 1 do begin
			plot_zonemap_on_map, zmapData[s].metadata.latitude, zmapData[s].metadata.longitude, $
								 [0,zmapData[s].metadata.zone_radii[0:zmapData[s].metadata.rings-1]]/100., $
								 zmapData[s].metadata.zone_sectors[0:zmapData[s].metadata.rings-1], $
								 alt, 180 + zmapData[s].metadata.oval_angle, $
								 zmapData[s].metadata.SKY_FOV_DEG, map, $
								 ctable = 0, back_color=150, front_color=150, linethick=.5
		endfor

		loadct, 39, /silent
	endif



	nZones = n_elements(zones)
	znLats = fltarr(nZones, polygonRes*4)
	znLons = fltarr(nZones, polygonRes*4)
	zGrids = fltarr(nZones, gridx, gridy)


	;\\ First check for max separation keyword
	if keyword_set(maxSeparation) then begin
		cenPos = fltarr(nZones, 2)
		for z = 0, nZones - 1 do begin
			diff = 180 - (zmapData[z].winds[0].azimuths[2] - zmapData[z].metadata.oval_angle)
			azis = zmapData[z].winds[0].azimuths + diff
		    zens = zmapData[z].winds[0].zeniths

			cenPos[z,*] = get_end_lat_lon(zmapData[z].metadata.latitude, zmapData[z].metadata.longitude, $
												  get_great_circle_length(zens[zones[z]], alt), azis[zones[z]])
		endfor
		if nZones eq 2 then begin
			diff = (cenPos[0,0]-cenPos[1,0])*(cenPos[0,0]-cenPos[1,0]) + $
				   (cenPos[0,1]-cenPos[1,1])*(cenPos[0,1]-cenPos[1,1])
			if diff gt maxSeparation*maxSeparation then begin
				outOverlap = [0.,0.]
				return
			endif
		endif else begin
			diff12 = (cenPos[0,0]-cenPos[1,0])*(cenPos[0,0]-cenPos[1,0]) + $
				   	 (cenPos[0,1]-cenPos[1,1])*(cenPos[0,1]-cenPos[1,1])
			diff13 = (cenPos[0,0]-cenPos[2,0])*(cenPos[0,0]-cenPos[2,0]) + $
				   	 (cenPos[0,1]-cenPos[2,1])*(cenPos[0,1]-cenPos[2,1])
			diff23 = (cenPos[1,0]-cenPos[2,0])*(cenPos[1,0]-cenPos[2,0]) + $
				   	 (cenPos[1,1]-cenPos[2,1])*(cenPos[1,1]-cenPos[2,1])
			if diff12 gt maxSeparation*maxSeparation or $
			   diff13 gt maxSeparation*maxSeparation or $
			   diff23 gt maxSeparation*maxSeparation then begin
				outOverlap = [0.,0.,0.]
				return
			endif
		endelse
	endif

	if keyword_set(fullFOV) then begin
		nZones = n_elements(zmapData)
		zones = intarr(nZones)
	endif

	for z = 0, nZones - 1 do begin

		rads = [0,zmapData[z].metadata.zone_radii[0:zmapData[z].metadata.rings-1]]/100.
	    secs = zmapData[z].metadata.zone_sectors[0:zmapData[z].metadata.rings-1]

		diff = 180 - (zmapData[z].winds[0].azimuths[2] - zmapData[z].metadata.oval_angle)
	    azis = zmapData[z].winds[0].azimuths + diff
    	zens = zmapData[z].winds[0].zeniths
		stLat = zmapData[z].metadata.latitude
		stLon = zmapData[z].metadata.longitude
		rings = get_zone_rings(zens)
		zn = zones[z]

		azWidth = 360./secs[rings[zn]]
		znWidth = (rads[rings[zn]+1] - rads[rings[zn]])*zmapData[z].metadata.SKY_FOV_DEG


		if keyword_set(fullFOV) then znWidth = max(rads)*zmapData[z].metadata.SKY_FOV_DEG

		if zn ne 0 then begin

			counter = 0
			for edge = 0, 3 do begin

				case edge of
					0: begin
						for vert = 0., polygonRes - 1 do begin
							vPos = get_end_lat_lon(stLat, stLon, $
								   get_great_circle_length(zens[zn] - (znWidth/2.) + vert*znWidth/polygonRes, alt), $
								   azis[zn]-azWidth/2.)
							znLats[z,counter] = vPos[0]
							znLons[z,counter] = vPos[1]
							counter++
						endfor
					end
					1: begin
						for vert = 0., polygonRes - 1 do begin
							vPos = get_end_lat_lon(stLat, stLon, $
								   get_great_circle_length(zens[zn] + (znWidth/2.), alt), $
								   azis[zn] - (azWidth/2.) + vert*azWidth/polygonRes)
							znLats[z,counter] = vPos[0]
							znLons[z,counter] = vPos[1]
							counter++
						endfor
					end
					2: begin
						for vert = 0., polygonRes - 1 do begin
							vPos = get_end_lat_lon(stLat, stLon, $
								   get_great_circle_length(zens[zn] + (znWidth/2.) - vert*znWidth/polygonRes, alt), $
								   azis[zn]+azWidth/2.)
							znLats[z,counter] = vPos[0]
							znLons[z,counter] = vPos[1]
							counter++
						endfor
					end
					3: begin
						for vert = 0., polygonRes - 1 do begin
							vPos = get_end_lat_lon(stLat, stLon, $
								   get_great_circle_length(zens[zn] - (znWidth/2.), alt), $
								   azis[zn] + (azWidth/2.) - vert*azWidth/polygonRes)
							znLats[z,counter] = vPos[0]
							znLons[z,counter] = vPos[1]
							counter++
						endfor
					end
				endcase

			endfor

		endif else begin

			counter = 0
			for k = 0, polygonRes*4 - 1 do begin
				vPos = get_end_lat_lon(stLat, stLon, get_great_circle_length(zens[zn] + znWidth, alt), k*360./(polygonRes*4))
				znLats[z,counter] = vPos[0]
				znLons[z,counter] = vPos[1]
				counter++
			endfor
		endelse

		if keyword_set(showZones) then begin
			xy = map_proj_forward([reform(znLons[z,*]), reform(znLons[z,0])], $
								  [reform(znLats[z,*]), reform(znLats[z,0])], map=map)
			plots, /data, xy, thick = 2, color = 50 + z*200
		endif
	endfor

	xrange = [min(znLons),max(znLons)]
	yrange = [min(znLats),max(znLats)]

	window, 2, xs = gridx, ys = gridy
	gridzWindow = !d.window
	for z = 0, nZones - 1 do begin
		plot, [0,0], [0,0], xrange = xrange, yrange = yrange, xstyle=5, ystyle=5, pos = [0,0,1,1]
		polyfill, znLons[z,*], znLats[z,*]
		zGrids[z,*,*] = tvrd()
	endfor

	if nZones eq 2 then begin
		ptsz1 = where(zGrids[0,*,*] eq 255, npts1)
		ptsz2 = where(zGrids[1,*,*] eq 255, npts2)
		ptsCommon = where(zGrids[0,*,*] eq 255 and zGrids[1,*,*] eq 255, npts)
		pOf1 = float(npts) / npts1
		pOf2 = float(npts) / npts2
		outOverlap = [pOf1, pOf2]
	endif

	if nZones eq 3 then begin
		ptsz1 = where(zGrids[0,*,*] eq 255, npts1)
		ptsz2 = where(zGrids[1,*,*] eq 255, npts2)
		ptsz3 = where(zGrids[2,*,*] eq 255, npts3)
		ptsCommon = where(zGrids[0,*,*] eq 255 and $
						  zGrids[1,*,*] eq 255 and $
						  zGrids[2,*,*] eq 255, npts)
		pOf1 = float(npts) / npts1
		pOf2 = float(npts) / npts2
		pOf3 = float(npts) / npts3
		outOverlap = [pOf1, pOf2, pOf3]
	endif

	if keyword_set(showZones) then begin
		wset, 3
		plot, [0,0], [0,0], xrange = xrange, yrange = yrange, xstyle=5, ystyle=5, $
			  pos = [0,0,.5,1], /noerase, color = 0, back = 255
		loadct, 39, /silent
		for z = 0, nZones - 1 do begin
			polyfill, znLons[z,*], znLats[z,*], color = 50 + z*200, /data
		endfor
		if npts gt 0 then begin
			ai = array_indices(reform(zGrids[0,*,*]), ptsCommon)
			for j = 0L, npts - 1 do plots, ai[0,j]*(500./gridx), ai[1,j]*(500./gridy), psym=3, /device, color = 190
		endif
		for z = 0, nZones - 1 do begin
			plots, [reform(znLons[z,*]), znLons[z,0]], [reform(znLats[z,*]), znLats[z,0]], color = 0, thick = 3, /data
			plots, [reform(znLons[z,*]), znLons[z,0]], [reform(znLats[z,*]), znLats[z,0]], color = 255, thick = 1, /data
		endfor
		!p.font = 0
		device, set_font="Ariel*22*Bold"
		xyouts, .51, .08, 'Overlap: ' + string(outOverlap[0]*100, f='(f0.1)') + $
					'% of Zone A' , color = 50, /normal
		xyouts, .51, .03, 'Overlap: ' + string(outOverlap[1]*100, f='(f0.1)') + $
					'% of Zone B' , color = 250, /normal
		!p.font = -1
		plots, /normal, [.001, .001, .999, .999, .001], [.001, .999, .999, .001, .001], color = 0, thick = 3
		plots, /normal, [.5, .5], [0, 1], color = 0, thick = 3

		if keyword_set(captureImages) then begin
			pic = tvrd(/true)
			write_png, 'C:\cal\IDLSource\NewAlaskaCode\TempZoneOverlapPics\Overlap_' + $
						string(zones[0], f='(i03)') + '_' + string(zones[1], f='(i03)') + '.png', pic

			;\\ Make extra copies of the picture if there is an overlap, so the movie lingers on the overlap frame...
			if total(outOverlap) ne 0 then begin
				for ee = 0, 10 do begin
					write_png, 'C:\cal\IDLSource\NewAlaskaCode\TempZoneOverlapPics\Overlap_' + $
						string(zones[0], f='(i03)') + '_' + string(zones[1], f='(i03)') + $
							'_' + string(ee, f='(i02)') + '.png', pic
				endfor
			endif
		endif
	endif
	wdelete, gridzWindow


	if keyword_set(captureImageEps) and min(outoverlap) gt .1 then begin
		!p.font = -1
		fname = 'C:\cal\IDLSource\NewAlaskaCode\TempZoneOverlapPics\Overlap_' + $
						string(zones[0], f='(i03)') + '_' + string(zones[1], f='(i03)') + '.eps'
		set_plot, 'ps'
		device, filename = fname, /encaps, /color, bit = 8, xs = 10, ys = 5

		bounds = [.5, 0, 1, 1]
		plot_simple_map, zmapData[0].metadata.latitude, zmapData[0].metadata.longitude, $
						7, 500, 500, map=map, bounds=bounds, $
						backColor=[255, 0], continentColor=[200,0], outlineColor=[0,0]

		for s = 0, 1 do begin
			plot_zonemap_on_map, zmapData[s].metadata.latitude, zmapData[s].metadata.longitude, $
								 [0,zmapData[s].metadata.zone_radii[0:zmapData[s].metadata.rings-1]]/100., $
								 zmapData[s].metadata.zone_sectors[0:zmapData[s].metadata.rings-1], $
								 alt, 180 + zmapData[s].metadata.oval_angle, $
								 zmapData[s].metadata.SKY_FOV_DEG, map, $
								 ctable = 0, back_color=150, front_color=150, linethick=.5
		endfor

		for s = 0, 1 do begin
			plot_zonemap_on_map, zmapData[s].metadata.latitude, zmapData[s].metadata.longitude, $
								 [0,zmapData[s].metadata.zone_radii[0:zmapData[s].metadata.rings-1]]/100., $
								 zmapData[s].metadata.zone_sectors[0:zmapData[s].metadata.rings-1], $
								 alt, 180 + zmapData[s].metadata.oval_angle, $
								 zmapData[s].metadata.SKY_FOV_DEG, map, $
								 ctable = 39, back_color=0, front_color=50 + s*200, linethick=2, onlythesezones = [zones[s]]
		endfor



		plot, [0,0], [0,0], xrange = xrange, yrange = yrange, xstyle=1, ystyle=1, $
			  pos = [0.12,0.18,.49,.97], /noerase, color = 0, back = 255, xtitle = 'Longitude (deg.)', $
			  ytitle = 'Latitude (deg.)', chars = .7, chart = 2, xtickint = 1, ytickint = .5

		loadct, 0, /silent
		for xx = 0, 99, 2 do begin
			plots, xrange[[0,0]] + xx*.01*(xrange[1]-xrange[0]), yrange, color = 100, /data
			plots, xrange, yrange[[0,0]] + xx*.01*(yrange[1]-yrange[0]), color = 100, /data
		endfor

		loadct, 39, /silent
		for z = 0, nZones - 1 do begin
			polyfill, znLons[z,*], znLats[z,*], color = 50 + z*200, /data
		endfor
		if npts gt 0 then begin
			ai = array_indices(reform(zGrids[0,*,*]), ptsCommon)
			for j = 0L, npts - 1 do plots, ai[0,j]*(xrange[1]-xrange[0])*.01 + xrange[0], $
										   ai[1,j]*(yrange[1]-yrange[0])*.01 + yrange[0], $
										   psym=6, /data, color = 190, sym=.05, thick = 2
		endif
		for z = 0, nZones - 1 do begin
			plots, [reform(znLons[z,*]), znLons[z,0]], [reform(znLats[z,*]), znLats[z,0]], color = 0, thick = 3, /data
			plots, [reform(znLons[z,*]), znLons[z,0]], [reform(znLats[z,*]), znLats[z,0]], color = 255, thick = 1, /data
		endfor

		xyouts, .51, .08, 'Overlap: ' + string(outOverlap[0]*100, f='(f0.1)') + $
					'% of Zone A' , color = 50, /normal, chars = .7, chart = 2
		xyouts, .51, .03, 'Overlap: ' + string(outOverlap[1]*100, f='(f0.1)') + $
					'% of Zone B' , color = 250, /normal, chars = .7, chart = 2

		plots, /normal, [.001, .001, .998, .998, .001], [.001, .993, .993, .001, .001], color = 0, thick = 3
		plots, /normal, [.5, .5], [0, 1], color = 0, thick = 3

		device, /close
		set_plot, 'win'



	endif

end



pro calculate_zone_overlaps, stationNames, $
							 altitude, $
							 metaArr, $			;\\ Ptr array
							 windArr, $			;\\ Ptr array
							 zone_overlap, $	;\\ Out
							 bistatic=bistatic, $
							 tristatic=tristatic, $
							 no_save=no_save, $
							 force_redo = force_redo


	if keyword_set(bistatic) then begin

		;\\ See if an overlap file already exists...
			restoredOverlap = 0
			stnName = stationNames
			stnName = stnName[sort(stnName)]
			saveName = where_is('zone_overlaps') + 'BiStaticOverlap_' + stnName[0] + '_' + stnName[1] + '_' + string(altitude, f='(i0)') + '.saved'
			if file_test(saveName) and not keyword_set(force_redo) then begin
				restore, saveName
				restoredOverlap = 1
			endif

			s1Data = {metadata:(*metaArr[0]), winds:(*windArr[0])[0]}
			s2Data = {metadata:(*metaArr[1]), winds:(*windArr[1])[0]}

			get_zone_lat_lon, indgen(s1Data.metadata.nzones), s1Data.metadata, s1Data.winds, s1Lat, s1Lon, $
					  				aziPlus=(180 - (s1Data.winds[0].azimuths[2] - s1Data.metadata.oval_angle)), $
					  				useAltitude=altitude
			get_zone_lat_lon, indgen(s2Data.metadata.nzones), s2Data.metadata, s2Data.winds, s2Lat, s2Lon, $
					  				aziPlus=(180 - (s2Data.winds[0].azimuths[2] - s2Data.metadata.oval_angle)), $
					  				useAltitude=altitude


			;\\ If no saved file exists, calculate bi-static pairs anew...
			if restoredOverlap eq 0 then begin
				npairs = long((*metaArr[0]).nzones) * long((*metaArr[1]).nzones)
				bipairs = intarr(npairs, 2)
				bioverlaps = fltarr(npairs, 2)
				bicenters = fltarr(npairs, 2)
				pcount = 0
				for s1z = 0, (*metaArr[0]).nzones-1 do begin
					for s2z = 0, (*metaArr[1]).nzones-1 do begin
						percentage_zone_overlap, [s1Data, s2Data], [s1z, s2z], altitude, overlap, polygonRes=3, maxSeparation=5, /captureImageEps
						bipairs[pcount, *] = [s1z, s2z]
						bioverlaps[pcount, *] = overlap
						bicenters[pcount,*] = [.5*(s1Lat[s1z]+s2Lat[s2z]), .5*(s1Lon[s1z]+s2Lon[s2z])]
						pcount ++
					endfor
					print, s1z
					wait, 0.0001
				endfor

				;\\ Make a structure to hold the overlap info, and save it...
				zone_overlap = {stationNames:stationNames, $
								stationLatitudes:[s1Data.metadata.latitude,s2Data.metadata.latitude], $
								stationLongitudes:[s1Data.metadata.longitude,s2Data.metadata.longitude], $
								date_created_yymmdd_ut:js_to_yymmdd(dt_tm_tojs(systime(/ut))), $
								date_created_js_ut:dt_tm_tojs(systime(/ut)), $
								npairs:npairs, $
								pairs:bipairs, $
								overlaps:bioverlaps, $
								centers:bicenters}

				;\\ Choose a filename with stations ordered alphabetically for easier retrieval and include altitude;
				;\\ Eventually might have to come up with some date restrictions, in case orientations (etc.) are changed
				if not keyword_set(no_save) then begin
					saveName = 'BiStaticOverlap_' + stnName[0] + '_' + stnName[1] + '_' + string(altitude, f='(i0)') + '.saved'
					save, filename = where_is('zone_overlaps') + saveName, zone_overlap
				endif
			endif
	endif


	if keyword_set(tristatic) then begin

		;\\ See if an overlap file already exists...
			restoredOverlap = 0
			stnName = stationNames
			stnName = stnName[sort(stnName)]
			saveName = where_is('zone_overlaps') + 'TriStaticOverlap_' + stnName[0] + '_' + stnName[1] + $
						'_' + stnName[2] + '_' + string(altitude, f='(i0)') + '.saved'
			if file_test(saveName) and not keyword_set(force_redo) then begin
				restore, saveName
				restoredOverlap = 1
			endif

		;\\ Rely on the existence of bistatic overlap files for all pairs, to find the triple intersection of zones.
		;\\ Would take way too long to search all possible triples...
			ov_array = ptrarr(3)
			idx = 0
			for i0 = 0, 2 do begin
				for i1 = i0 + 1, 2 do begin
					names = stationNames[[i0,i1]]
					names = names[sort(names)]
					saveName = where_is('zone_overlaps') + 'BiStaticOverlap_' + names[0] + '_' + names[1] + '_' + string(altitude, f='(i0)') + '.saved'
					if file_test(saveName) then	restore, saveName else stop
					ov_array[idx] = ptr_new(zone_overlap)
					idx++
				endfor
			endfor

			cut1 = where(max((*ov_array[0]).overlaps, dim=2) gt 0, ncut1)
			list = [[0,0,0]]
			for pp = 0, ncut1 - 1 do begin
				zns = (*ov_array[0]).pairs[cut1[pp],*]
				idx01_0 = (where((*ov_array[0]).stationNames eq stationNames[0]))[0]
				idx01_1 = (where((*ov_array[0]).stationNames eq stationNames[1]))[0]


				ovs02 = (*ov_array[1])
				nz = where(max(ovs02.overlaps, dim=2) gt 0, ngt)
				if ngt gt 0 then begin
					pairs02 = ovs02.pairs[nz, *]
					idx02_0 = (where(ovs02.stationNames eq stationNames[0]))[0]
					idx02_2 = (where(ovs02.stationNames eq stationNames[2]))[0]
					match = where(pairs02[*,idx02_0] eq zns[idx01_0], nmatch)
					if nmatch gt 1 then begin
						for mm = 0, nmatch - 1 do list = [[list], [zns[0], zns[1], pairs02[match[mm], idx02_2]]]
					endif
				endif

				ovs12 = (*ov_array[2])
				nz = where(max(ovs12.overlaps, dim=2) gt 0, ngt)
				if ngt gt 0 then begin
					pairs12 = ovs12.pairs[nz, *]
					idx12_1 = (where(ovs12.stationNames eq stationNames[1]))[0]
					idx12_2 = (where(ovs12.stationNames eq stationNames[2]))[0]
					match = where(pairs12[*,idx12_1] eq zns[idx01_1], nmatch)
					if nmatch gt 1 then begin
						for mm = 0, nmatch - 1 do list = [[list], [zns[0], zns[1], pairs12[match[mm], idx12_2]]]
					endif
				endif
			endfor
			if n_elements(list[0,*]) eq 1 then stop
			list = list[*,1:*]



			s1Data = {metadata:(*metaArr[0]), winds:(*windArr[0])[0]}
			s2Data = {metadata:(*metaArr[1]), winds:(*windArr[1])[0]}
			s3Data = {metadata:(*metaArr[2]), winds:(*windArr[2])[0]}

			get_zone_lat_lon, indgen(s1Data.metadata.nzones), s1Data.metadata, s1Data.winds, s1Lat, s1Lon, $
					  				aziPlus=(180 - (s1Data.winds[0].azimuths[2] - s1Data.metadata.oval_angle)), $
					  				useAltitude=altitude
			get_zone_lat_lon, indgen(s2Data.metadata.nzones), s2Data.metadata, s2Data.winds, s2Lat, s2Lon, $
					  				aziPlus=(180 - (s2Data.winds[0].azimuths[2] - s2Data.metadata.oval_angle)), $
					  				useAltitude=altitude
			get_zone_lat_lon, indgen(s3Data.metadata.nzones), s3Data.metadata, s3Data.winds, s3Lat, s3Lon, $
					  				aziPlus=(180 - (s3Data.winds[0].azimuths[2] - s3Data.metadata.oval_angle)), $
					  				useAltitude=altitude


			;\\ If no saved file exists, calculate tri-static pairs anew...
			if restoredOverlap eq 0 then begin

				npairs = n_elements(list[0,*])
				tripairs = intarr(npairs, 3)
				trioverlaps = fltarr(npairs, 3)
				tricenters = fltarr(npairs, 2)
				pcount = 0

				;for s1z = 0, (*metaArr[0]).nzones-1 do begin
				;for s2z = 0, (*metaArr[1]).nzones-1 do begin
				;for s3z = 0, (*metaArr[2]).nzones-1 do begin

				for pp = 0, n_elements(list[0,*]) - 1 do begin
					s1z = list[0,pp]
					s2z = list[1,pp]
					s3z = list[2,pp]
					percentage_zone_overlap, [s1Data, s2Data, s3Data], [s1z, s2z, s3z], altitude, overlap, polygonRes=3, maxSeparation=5
					tripairs[pcount, *] = [s1z, s2z, s3z]
					trioverlaps[pcount, *] = overlap
					tricenters[pcount,*] = [(1./3.)*(s1Lat[s1z]+s2Lat[s2z]+s3Lat[s3z]), $
											(1./3.)*(s1Lon[s1z]+s2Lon[s2z]+s3Lon[s3z])]
					pcount ++
					print, pp
					wait, 0.001
				endfor

				;\\ Make a structure to hold the overlap info, and save it...
				zone_overlap = {stationNames:stationNames, $
								stationLatitudes:[s1Data.metadata.latitude,s2Data.metadata.latitude,s3Data.metadata.latitude], $
								stationLongitudes:[s1Data.metadata.longitude,s2Data.metadata.longitude, s3Data.metadata.longitude], $
								date_created_yymmdd_ut:js_to_yymmdd(dt_tm_tojs(systime(/ut))), $
								date_created_js_ut:dt_tm_tojs(systime(/ut)), $
								npairs:npairs, $
								pairs:tripairs, $
								overlaps:trioverlaps, $
								centers:tricenters}

				;\\ Choose a filename with stations ordered alphabetically for easier retrieval and include altitude;
				;\\ Eventually might have to come up with some date restrictions, in case orientations (etc.) are changed
				if not keyword_set(no_save) then begin
					saveName = 'TriStaticOverlap_' + stnName[0] + '_' + stnName[1] + '_' + stnName[2] + '_' + string(altitude, f='(i0)') + '.saved'
					save, filename = where_is('zone_overlaps') + saveName, zone_overlap
				endif
			endif
	endif


end




