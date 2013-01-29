
@percentage_zone_overlap

;\\ Fit bistatic winds
pro MIWF_FitBiStatic, force_restore = force_restore, $
					  force_redo = force_redo

	common miwf_common, guiData, miscData

	if miscData.nStations lt 2 then return

		biFitStruc =   {stations:strarr(2), $
						windCoords:'', $
						times:[0.D, 0.D], $
						time:0D, $
						losWinds:[0.0, 0.0], $
						lat:0.0, $
						lon:0.0, $
						lcomp:0.0D, $
						mcomp:0.0D, $
						lerr:0.0D, $
						merr:0.0D, $
					    laxis:fltarr(3), $
					    maxis:fltarr(3), $
					    naxis:fltarr(3), $
					    langle:0.0, $
					    mangle:0.0, $
					    midDist:0.0, $
					    obsDot:0.0, $
					    obsVecLo:fltarr(3), $
					    obsVecHi:fltarr(3), $
					    alt:0.0, $
					    zones:[0,0], $
					    overlap:[0.,0.], $
					    temperature:[0.,0.], $
					    intensity:[0.,0.]}

		stationName = strarr(miscData.nStations)
		stationPos = fltarr(miscData.nStations, 2)
		for s = 0, miscData.nStations - 1 do begin
			stationName[s] = (*miscData.metaData[s]).site_code
			stationPos[s,*] = [(*miscData.metaData[s]).latitude, (*miscData.metaData[s]).longitude]
		endfor


		;\\ Check for saved data...
		dateStr = date_str_from_js((*miscData.windData[0])[0].start_time[0], /forfile)
		stnName = stationName[sort(stationName)]
		fitSaveName = miscData.savedDataPath + 'BiStaticFits_'
		for k = 0, miscData.nStations - 1 do begin
			fitSaveName += stnName[k] + '_'
		endfor
		fitSaveName += dateStr + '.saved'
		if not keyword_set(force_redo) then begin
			if file_test(fitSaveName) eq 1 then begin
				if not keyword_set(force_restore) then begin
					yn = dialog_message('Restore Saved Fit Data: ' + file_basename(fitSaveName) + '?', /question)
					if yn eq 'Yes' then begin
						restore, fitSaveName
						*miscData.biFits = allBiFits
						return
					endif
				endif
				if keyword_set(force_restore) then begin
					restore, fitSaveName
					*miscData.biFits = allBiFits
					return
				endif
			endif
		endif

		nStationPairs = float(factorial(miscData.nStations) / (factorial(2) * factorial(miscData.nStations - 2)))
		biFits = ptrarr(nStationPairs, /alloc)
		stnPairCount = 0

		cnt = 0
		for st1 = 0, miscData.nStations - 1 do begin
		for st2 = st1+1, miscData.nStations - 1 do begin

			case (*miscData.metadata[st1]).wavelength_nm of
				557.7: alt1 = 120.
				589.0: alt1 = 92.
				630.0: alt1 = 240.
				else: alt1 = 0.
			endcase
			case (*miscData.metadata[st2]).wavelength_nm of
				557.7: alt2 = 120.
				589.0: alt2 = 92.
				630.0: alt2 = 240.
				else: alt2 = 0.
			endcase
			if alt1 ne alt2 then continue

			calculate_zone_overlaps, alt1, $
									 [miscData.metaData[st1], miscData.metaData[st2]], $
									 [miscData.windData[st1], miscData.windData[st2]], $
									 zone_overlap, $
									 /bistatic

			;\\ Get the index into the zone_overlap array
			st1_index = (where(zone_overlap.stationNames eq stationName[st1]))[0]
			st2_index = (where(zone_overlap.stationNames eq stationName[st2]))[0]
			if st1_index eq -1 or st2_index eq -1 then stop	;\\ Something has gone wrong!

			;\\ For each pair, resolve the l and m wind components
			pts = where(max(zone_overlap.overlaps, dimension=2) gt 0, nBiPts)
			if nBiPts eq 0 then return
			subBiFits = replicate(biFitStruc, n_elements(*miscData.allTimes), nBiPts)

			diff = 180 - ( (*miscData.windData[st1])[0].azimuths[2] - (*miscData.metaData[st1]).oval_angle)
			st1Azis = (*miscData.windData[st1])[0].azimuths + diff
	    	st1Zens = (*miscData.windData[st1])[0].zeniths
	    	diff = 180 - ( (*miscData.windData[st2])[0].azimuths[2] - (*miscData.metaData[st2]).oval_angle)
	    	st2Azis = (*miscData.windData[st2])[0].azimuths + diff
	    	st2Zens = (*miscData.windData[st2])[0].zeniths
	    	pairs = zone_overlap.pairs


			for tIndex = 0, n_elements(*miscData.allTimes) - 1 do begin

				s1expIndex = (*miscData.stnIndices[st1])[tIndex]
				s2expIndex = (*miscData.stnIndices[st2])[tIndex]

				MIWF_GetInterpolates, st1, tIndex, st1Interps
				MIWF_GetInterpolates, st2, tIndex, st2Interps
				s1LosWind = st1Interps.los
				s1LosErr = st1Interps.sigma_los * (*miscData.metaData[st1]).channels_to_velocity
				s2LosWind = st2Interps.los
				s2LosErr = st2Interps.sigma_los * (*miscData.metaData[st2]).channels_to_velocity

				for overlapIndex = 0, nBiPts - 1 do begin

					p = pts[overlapIndex]

					;\\ Get the mean location of the bi-static point (is this step dodgy?)
					st1_dist = get_great_circle_length(st1Zens[pairs[p,st1_index]], alt1)
					st1_endpt = get_end_lat_lon(stationPos[st1,0], stationPos[st1,1], st1_dist, st1Azis[pairs[p,st1_index]])
					st2_dist = get_great_circle_length(st2Zens[pairs[p,st2_index]], alt1)
					st2_endpt = get_end_lat_lon(stationPos[st2,0], stationPos[st2,1], st2_dist, st2Azis[pairs[p,st2_index]])

					meanPt = [mean([st1_endpt[0], st2_endpt[0]]), mean([st1_endpt[1], st2_endpt[1]])]

					resolve_nStatic_wind, meanPt[0], meanPt[1], $
									      reform(stationPos[[st1, st2],0]), reform(stationPos[[st1, st2],1]), $
									  	  [st1Zens[pairs[p,st1_index]], st2Zens[pairs[p,st2_index]]], $
									  	  [st1Azis[pairs[p,st1_index]], st2Azis[pairs[p,st2_index]]], $
									  	  [alt1, alt2], $
									  	  [s1LosWind[pairs[p,st1_index]], $
									  	   s2LosWind[pairs[p,st2_index]]], $
									  	  [s1LosErr[pairs[p,st1_index]], $
									  	   s2LosErr[pairs[p,st2_index]]], $
									  	  outWind, $
									  	  outErr, $
									  	  outInfo, /assume

					;\\ Store the fit results
						fitStruc = {stations:stationName[[st1,st2]], $
									windCoords:'Local', $
									times:[(*miscData.stnTimes[st1])[tIndex], (*miscData.stnTimes[st2])[tIndex]], $
									time:(*miscData.allTimes)[tIndex], $
									losWinds:[s1LosWind[pairs[p,st1_index]], $
									  	   	  s2LosWind[pairs[p,st2_index]]], $
									lat:meanPt[0], $
									lon:meanPt[1], $
									lcomp:outwind[0], $
									mcomp:outwind[1], $
									lerr:outErr[0], $
									merr:outErr[1], $
									laxis:outInfo.laxis, $
									maxis:outInfo.maxis, $
									naxis:outInfo.naxis, $
									langle:outInfo.langle, $
									mangle:outInfo.mangle, $
									midDist:outInfo.midDist, $
									obsDot:outInfo.obsDot, $
									obsVecLo:outInfo.obsVecLo, $
									obsVecHi:outInfo.obsVecHi, $
									alt:alt1, $
									zones:zone_overlap.pairs[p,[st1_index, st2_index]], $
									overlap:zone_overlap.overlaps[p,[st1_index, st2_index]], $
									temperature:[(*miscData.spekData[st1])[s1ExpIndex].temperature[zone_overlap.pairs[p,st1_index]], $
												 (*miscData.spekData[st2])[s2ExpIndex].temperature[zone_overlap.pairs[p,st2_index]]], $
									intensity:[(*miscData.spekData[st1])[s1ExpIndex].intensity[zone_overlap.pairs[p,st1_index]] / $
											   float((*miscData.spekData[st1])[s1ExpIndex].end_time[0] - (*miscData.spekData[st1])[s1ExpIndex].start_time[0]), $
											   (*miscData.spekData[st2])[s2ExpIndex].intensity[zone_overlap.pairs[p,st2_index]] / $
											   float((*miscData.spekData[st2])[s2ExpIndex].end_time[0] - (*miscData.spekData[st2])[s2ExpIndex].start_time[0])]}
						subBiFits[tIndex, overlapIndex] = fitStruc

				endfor	;\\ Overlap index loop
				cnt++

				;\\ Update the progress bar
				MIWF_UpdateProgress, (float(stnPairCount + 1) + (tIndex + 1))/ (nStationPairs + n_elements(*miscData.allTimes)), $
								 'Stations ' + string(st1+1,f='(i0)') + ' & ' + string(st2+1,f='(i0)') + $
								 ', Time Index: ' + string(tIndex,f='(i0)')

			endfor	;\\ Time index loop

			*biFits[stnPairCount] = subBiFits

			stnPairCount ++
		endfor	;\\ st2 loop
		endfor	;\\ st1 loop

		;\\ Concatenate all the subBiFits arrays...
		nFits = 0
		for k = 0, nStationPairs - 1 do nFits += n_elements( (*biFits[k])[0,*] )
		allBiFits = replicate(biFitStruc, n_elements(*miscData.allTimes), nFits)

		startIdx = 0
		for k = 0, nStationPairs - 1 do begin
			allBiFits[*, startIdx: startIdx + n_elements((*biFits[k])[0,*]) - 1] = (*biFits[k])[*,*]
		endfor

		*miscData.biFits = allBiFits

		;\\ Save bi-static fits to the savedDataPath
			save, filename = fitSaveName, allBiFits, /compress

		;\\ Clear the progress bar
			MIWF_UpdateProgress, /reset
end