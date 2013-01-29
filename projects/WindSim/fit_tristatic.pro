
pro fit_tristatic, meta1, meta2, meta3, $
				   wind1, wind2, wind3, $
				   wind_err1, wind_err2, wind_err3, $
				   altitude, $
				   fit=fit	;\\ Out

	triFitStruc =  {stations:strarr(3), $
					windCoords:'', $
					losWinds:[0.0, 0.0, 0.0], $
					lat:0.0, $
					lon:0.0, $
					u:0.0D, $
					v:0.0D, $
					w:0.0D, $
					uerr:0.0D, $
					verr:0.0D, $
					werr:0.0D, $
				    alt:0.0, $
				    obsDot:0.0, $
				    aziSum:0.0, $
				    midVec:[0.,0.,0.], $
				    losvec1:[0.,0.,0.], $
				    losvec2:[0.,0.,0.], $
				    losvec3:[0.,0.,0.], $
				    cvDist:[0D,0D,0D], $
				    zones:[0,0,0], $
				    overlap:[0.,0.,0.] }

	stationName = [meta1.site_code, meta2.site_code, meta3.site_code]

	st1 = 0
	st2 = 1
	st3 = 2

	zone_overlaps, altitude, $
				   [meta1, meta2, meta3], $
				   zone_overlap, $
				   /tristatic


	;\\ Get the index into the zone_overlap array
	st1_index = (where(zone_overlap.stationNames eq stationName[st1]))[0]
	st2_index = (where(zone_overlap.stationNames eq stationName[st2]))[0]
	st3_index = (where(zone_overlap.stationNames eq stationName[st3]))[0]
	if st1_index eq -1 or st2_index eq -1 or st3_index eq -1 then stop	;\\ Something has gone wrong!

	;\\ For each triple, resolve the u, v, and w wind components
	pts = where(max(zone_overlap.overlaps, dimension=2) gt 0, nTriPts)
	if nTriPts eq 0 then return

	subTriFits = replicate(triFitStruc, nTriPts)


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
	get_zone_locations, meta3, zones=zones, altitude=altitude
	st3Lats = zones.lat
	st3Lons = zones.lon
	st3Azis = zones.mid_azi
	st3Zens = zones.mid_zen

	pairs = zone_overlap.pairs

	s1LosWind = wind1
	s1LosErr = wind_err1
	s2LosWind = wind2
	s2LosErr = wind_err2
	s3LosWind = wind3
	s3LosErr = wind_err3

	for overlapIndex = 0, nTriPts - 1 do begin

		p = pts[overlapIndex]

		;\\ Get the mean location of the bi-static point (is this step dodgy?)
		st1_endpt = [st1Lats[pairs[p,st1_index]], st1Lons[pairs[p,st1_index]]]
		st2_endpt = [st2Lats[pairs[p,st2_index]], st2Lons[pairs[p,st2_index]]]
		st3_endpt = [st3Lats[pairs[p,st3_index]], st3Lons[pairs[p,st3_index]]]

		meanPt = [mean([st1_endpt[0], st2_endpt[0], st3_endpt[0]]), $
				  mean([st1_endpt[1], st2_endpt[1], st3_endpt[1]])]

		st1_dist = map_2points(st1_endpt[1], st1_endpt[0], meanPt[1], meanPt[0], /meters)/1000.
		st2_dist = map_2points(st2_endpt[1], st2_endpt[0], meanPt[1], meanPt[0], /meters)/1000.
		st3_dist = map_2points(st3_endpt[1], st3_endpt[0], meanPt[1], meanPt[0], /meters)/1000.


		resolve_nStatic_wind, meanPt[0], meanPt[1], $
						      [st1Lats[0], st2Lats[0], st3Lats[0]], $
						      [st1Lons[0], st2Lons[0], st3Lons[0]], $
						  	  [st1Zens[pairs[p,st1_index]], st2Zens[pairs[p,st2_index]], st3Zens[pairs[p,st3_index]]], $
						  	  [st1Azis[pairs[p,st1_index]], st2Azis[pairs[p,st2_index]], st3Azis[pairs[p,st3_index]]], $
						  	  [altitude, altitude, altitude], $
						  	  [s1LosWind[pairs[p,st1_index]], $
						  	   s2LosWind[pairs[p,st2_index]], $
						  	   s3LosWind[pairs[p,st3_index]]], $
						  	  [s1LosErr[pairs[p,st1_index]], $
						  	   s2LosErr[pairs[p,st2_index]], $
						  	   s3LosErr[pairs[p,st3_index]]], $
						  	  outWind, $
						  	  outErr, $
						  	  outInfo, /assume

		;\\ Store the fit results
		fitStruc = {stations:stationName[[st1,st2,st3]], $
					windCoords:'Local', $
					losWinds:[s1LosWind[pairs[p,st1_index]], $
					  	   	  s2LosWind[pairs[p,st2_index]], $
					  	   	  s3LosWind[pairs[p,st3_index]]], $
					lat:meanPt[0], $
					lon:meanPt[1], $
					u:outwind[0], $
					v:outwind[1], $
					w:outwind[2], $
					uerr:outErr[0], $
					verr:outErr[1], $
					werr:outErr[2], $
					alt:altitude, $
					obsDot:outinfo.obsdot, $
					aziSum:outinfo.aziSum, $
					midVec:outinfo.midVec, $
					losvec1:outinfo.losvec1, $
				    losvec2:outinfo.losvec2, $
				    losvec3:outinfo.losvec3, $
					cvDist:[st1_dist, st2_dist, st3_dist], $
					zones:zone_overlap.pairs[p,[st1_index, st2_index, st3_index]], $
					overlap:zone_overlap.overlaps[p,[st1_index, st2_index, st3_index]] }

     	subTriFits[overlapIndex] = fitStruc

	endfor	;\\ Overlap index loop

	fit = subTriFits

end