

pro fit_bistatic, meta1, meta2, $
				  wind1, wind2, $
				  wind_err1, wind_err2, $
				  altitude, $
				  fit=fit	;\\ Out

	biFitStruc =   {stations:strarr(2), $
					windCoords:'', $
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
				    cvDist:[0D,0D], $
				    zones:[0,0], $
				    overlap:[0.,0.] }

	stationName = [meta1.site_code, meta2.site_code]

	st1 = 0
	st2 = 1
	zone_overlaps, stationName[[st1,st2]], $
	   			   altitude, $
				   [meta1, meta2], $
				   zone_overlap, $
				   /bistatic


	;\\ Get the index into the zone_overlap array
	st1_index = (where(zone_overlap.stationNames eq stationName[st1]))[0]
	st2_index = (where(zone_overlap.stationNames eq stationName[st2]))[0]
	if st1_index eq -1 or st2_index eq -1 then stop	;\\ Something has gone wrong!

	;\\ For each pair, resolve the l and m wind components
	pts = where(max(zone_overlap.overlaps, dimension=2) gt 0, nBiPts)
	if nBiPts eq 0 then return

	subBiFits = replicate(biFitStruc, nBiPts)

	get_zone_locations, meta1, zones=zones, altitude=altitude
	st1Lats = zones.lat
	st1Lons = zones.lon
	st1Azis = zones.mid_azi
	st1Zens = zones.mid_zen
	get_zone_locations, meta2, zones=zones, altitude=altitude
	st2Lats = zones.lat
	st2Lons = zones.lon
	st2Azis = zones.mid_azi
	st2Zens = zones.mid_zen

	pairs = zone_overlap.pairs


	s1LosWind = wind1
	s1LosErr = wind_err1
	s2LosWind = wind2
	s2LosErr = wind_err2

	for overlapIndex = 0, nBiPts - 1 do begin

		p = pts[overlapIndex]

		;\\ Get the mean location of the bi-static point (is this step dodgy?)
		st1_endpt = [st1Lats[pairs[p,st1_index]], st1Lons[pairs[p,st1_index]]]
		st2_endpt = [st2Lats[pairs[p,st2_index]], st2Lons[pairs[p,st2_index]]]

		meanPt = [mean([st1_endpt[0], st2_endpt[0]]), mean([st1_endpt[1], st2_endpt[1]])]

		st1_dist = map_2points(st1_endpt[1], st1_endpt[0], meanPt[1], meanPt[0], /meters)/1000.
		st2_dist = map_2points(st2_endpt[1], st2_endpt[0], meanPt[1], meanPt[0], /meters)/1000.


		resolve_nStatic_wind, meanPt[0], meanPt[1], $
						      [st1Lats[0], st2Lats[0]], $
						      [st1Lons[0], st2Lons[0]], $
						  	  [st1Zens[pairs[p,st1_index]], st2Zens[pairs[p,st2_index]]], $
						  	  [st1Azis[pairs[p,st1_index]], st2Azis[pairs[p,st2_index]]], $
						  	  [altitude, altitude], $
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
					alt:altitude, $
					cvDist:[st1_dist, st2_dist], $
					zones:zone_overlap.pairs[p,[st1_index, st2_index]], $
					overlap:zone_overlap.overlaps[p,[st1_index, st2_index]] }

     	subBiFits[overlapIndex] = fitStruc

	endfor	;\\ Overlap index loop

	fit = subBiFits

end