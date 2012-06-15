
pro test_nstatic

	poker = [65.13, -147.48]
	kakto = [69.9, -143.7]
	gakona = [62.3, -145.3]
	toolik = [68.3, -149.5]

	trueWind = [-50., 100., 80.]

	;pkrAzi = 90.
	;pkrZen = 45.
	pkrAzi = -100.
	pkrZen = 40.
	platlon = get_end_lat_lon(poker[0], poker[1], get_great_circle_length(pkrZen, 240), pkrAzi)

	res = map_2points(gakona[1], gakona[0], platlon[1], platlon[0])
	gkrAzi = res[1]
	gkrZen = 51.
	glatlon = get_end_lat_lon(gakona[0], gakona[1], get_great_circle_length(gkrZen, 240), gkrAzi)

	res = map_2points(toolik[1], toolik[0], platlon[1], platlon[0])
	tkrAzi = res[1]
	;tkrZen = 65.5
	tkrzen = 60.
	tlatlon = get_end_lat_lon(toolik[0], toolik[1], get_great_circle_length(tkrZen, 240), tkrAzi)

	cvLat = platlon[0]
	cvLon = platlon[1]

	inLats = [poker[0], gakona[0], toolik[0]]
	inLons = [poker[1], gakona[1], toolik[1]]
	inZens = [pkrZen, gkrZen, tkrZen]

	winx = 1000.
	winy = 700.
	zoom = 7.
	window, 0, xs = winx, ys = winy
	plot_simple_map, inLats[0], inLons[0], zoom, winx, winy, map=map, /grid

	loadct, 39, /silent
	loc = map_proj_forward([platlon[1], glatlon[1], tlatlon[1], inLons], [platlon[0], glatlon[0], tlatlon[0], inLats], map=map)
	plots, /data, loc, psym=4, sym=2, thick = 2, color = [50, 85, 100, 150, 180, 200]

	nStations = n_elements(inLats)
	obsAzi = fltarr(nStations)
	obsZen = fltarr(nStations)
	obsVec = fltarr(nStations, 3)
	measLos = fltarr(nStations)
	for s = 0, nStations - 1 do begin
		res = map_2points( cvLon, cvLat, inLons[s], inLats[s])
		obsAzi[s] = (res[1] + 180)*!dtor
		obsZen[s] = (inZens[s] - 0*res[0])*!dtor
		obsVec[s,*] = [sin(obsAzi[s])*sin(obsZen[s]), cos(obsAzi[s])*sin(obsZen[s]), cos(obsZen[s])]
		measLos[s] = dotp(reform(obsVec[s,*]), trueWind)
	endfor

	alts = [240., 240., 240.]

	ns = 2
	resolve_nStatic_wind, cvLat, cvLon, inLats[0:ns-1], inLons[0:ns-1], inZens[0:ns-1], obsAzi[0:ns-1]/!dtor, alts[0:ns-1], $
						  measLos[0:ns-1], abs(measLos[0:ns-1])*.1, outWindcart, outErrcart, bistaticAxescart

	print, measLos
	print, 'OutWind Cartesian: ', outwindcart

	l_zen = [cos(cvLat*!dtor)*cos(cvLon*!dtor), $
			 cos(cvLat*!dtor)*sin(cvLon*!dtor), $
			 sin(cvLat*!dtor)]
	l_zon = [-sin(cvLon*!dtor), $
			  cos(cvLon*!dtor), $
			  0]
	l_mer = [-sin(cvLat*!dtor)*cos(cvLon*!dtor), $
			 -sin(cvLat*!dtor)*sin(cvLon*!dtor), $
			  cos(cvLat*!dtor)]

	wind = outwindCart
	axes = bistaticaxescart
	local_out = [outwindCart[0]*dotp(l_zon, axes.laxis) + outwindCart[1]*dotp(l_zon, axes.maxis), $
				 outwindCart[0]*dotp(l_mer, axes.laxis) + outwindCart[1]*dotp(l_mer, axes.maxis), $
				 outwindCart[0]*dotp(l_zen, axes.laxis) + outwindCart[1]*dotp(l_zen, axes.maxis) ]
	stop
end





;\\ Return the spherical unit vectors in cartesian basis
function get_unit_spherical, lat, lon
	;\\ Unit Radial Vector
	rho = [cos(lat*!dtor)*cos(lon*!dtor), $
		   cos(lat*!dtor)*sin(lon*!dtor), $
		   sin(lat*!dtor)]
	;\\ Unit Elevation Vector - Meridional (+ north)
	theta = [-sin(lat*!dtor)*cos(lon*!dtor), $
			 -sin(lat*!dtor)*sin(lon*!dtor), $
			 cos(lat*!dtor)]
	;\\ Unit Azimuthal Vector - Zonal (+ east)
	phi = [-sin(lon*!dtor), $
			cos(lon*!dtor), $
			0]
	return, {zenith:rho, merid:theta, zonal:phi}
end







;\\ Calculate parameters for the bistatic inversion - put los vectors in the plane, etc.
pro calculate_bistatic_params, cvLat, cvLon, lats, lons, azis, zens, alts, outParams, $
							   assume_direct_los=assume_direct_los

	if lats[0] gt lats[1] then begin
		minIdx = 1
		maxIdx = 0
	endif else begin
		minIdx = 0
		maxIdx = 1
	endelse

	st1_dist = get_great_circle_length(zens[0], alts[0])
	st1_endpt = get_end_lat_lon(lats[0], lons[0], st1_dist, azis[0])
	st2_dist = get_great_circle_length(zens[1], alts[1])
	st2_endpt = get_end_lat_lon(lats[1], lons[1], st2_dist, azis[1])
	meanPt = [mean([st1_endpt[0], st2_endpt[0]]), mean([st1_endpt[1], st2_endpt[1]])]

	earthRad = 6371.

	loc = fltarr(3, 2)		;\\ station locations in cartesian
	obsDir = fltarr(3, 2)	;\\ obs los directions in cartesian
	for s = 0, 1 do begin
		loc[*,s] = [cos(Lats[s]*!dtor)*cos(Lons[s]*!dtor), $
				 	cos(Lats[s]*!dtor)*sin(Lons[s]*!dtor), $
				 	sin(Lats[s]*!dtor)]

		dir = [sin(Zens[s]*!dtor)*sin(Azis[s]*!dtor), $
			   sin(Zens[s]*!dtor)*cos(Azis[s]*!dtor), $
			   cos(Zens[s]*!dtor)]

		units = get_unit_spherical(Lats[s], Lons[s])

		zondiff = units.zonal * dir[0]
		merdiff = units.merid * dir[1]
		zendiff = units.zenith * dir[2]
		losVec = zondiff + merdiff + zendiff
		losVec = losVec / norm(losVec)
		obsDir[*,s] = losVec
	endfor

	locCV = [(1 + (Alts[0]/earthRad))*cos(cvLat*!dtor)*cos(cvLon*!dtor), $
			 (1 + (Alts[0]/earthRad))*cos(cvLat*!dtor)*sin(cvLon*!dtor), $
			 (1 + (Alts[0]/earthRad))*sin(cvLat*!dtor)]

	los = fltarr(3, 2)
	for s = 0, 1 do begin
		if keyword_set(assume_direct_los) then begin
			;\\ This assumes the los is directly into the common-volume
			los[*,s] = locCV - loc[*,s]
			los[*,s] = los[*,s] / norm(los[*,s])
		endif else begin
			;\\ Else use azi and zenang converted to cartesian coords
			los[*,s] = obsDir[*,s]
		endelse
	endfor

	plane_normal = crossp(los[*,minIdx], los[*,maxIdx])
	plane_normal = plane_normal / norm(plane_normal)

	lVect = reform(loc[*,maxIdx] - loc[*,minIdx])
	lVect = lVect / norm(lVect)
	rotAngle = !PI/2.0
	quaternion = qtcompose(plane_normal, rotAngle)
	mVect = reform(qtvrot(lVect, quaternion))
	mVect = mVect / norm(mVect)

	cv_basis = get_unit_spherical(cvLat, cvLon)
	mangle = acos( dotp(cv_basis.zenith, mVect) ) / !dtor
	;langle = acos( dotp(cv_basis.merid, lVect) ) / !dtor

	;midPoint = loc[*,minIdx] + 0.5*reform(loc[*,maxIdx] - loc[*,minIdx])
	;midLine = locCV - midPoint
	;midLine = midLine/norm(midLine)
	;langle = acos( dotp(midLine, lVect) ) / !dtor
	;midDist = norm(locCV - midPoint)

	stAng = (map_2points(lons[minIdx], lats[minIdx], lons[maxIdx], lats[maxIdx]))[1]
	stDist = (map_2points(lons[minIdx], lats[minIdx], lons[maxIdx], lats[maxIdx], /meters))[0]
	midPt = get_end_lat_lon(lats[minIdx], lons[minIdx], stDist/2000., stAng)
	lAngle = (map_2points(midPt[1], midPt[0], cvLon, cvLat))[1] - $
			 (map_2points(midPt[1], midPt[0], lons[maxIdx], lats[maxIdx]))[1]

	midDist = (map_2points(midPt[1], midPt[0], cvLon, cvLat, /meters))[0]

	;\\ Test for sign of langle...
	;compAng = (map_2points(lons[minIdx], lats[minIdx], lons[maxIdx], lats[maxIdx]))[1]*!dtor
	;testAng = (map_2points(lons[minIdx], lats[minIdx], cvlon, cvlat))[1]*!dtor
	;if testAng lt compAng then langle = -1*langle

	obsV = fltarr(2, 2)
	obsV[0,*] = [dotp(lVect, los[*,0]), dotp(mVect, los[*,0])]
	obsV[1,*] = [dotp(lVect, los[*,1]), dotp(mVect, los[*,1])]

	dotprod = dotp(los[*,0], los[*,1])

	outParams = {lAxis:lVect, $
				 mAxis:mVect, $
				 nAxis:plane_normal, $
				 lAngle:lAngle, $
				 mAngle:mAngle, $
				 midDist:midDist, $
				 dotProduct:dotprod, $
				 obsVec:los, $
				 obsVecPlane:obsV, $
				 minIdx:minIdx, $
				 maxIdx:maxIdx}
end







;\\ Project a bistatic fit into the local horizontal, using an assumed vertical wind
function project_bistatic_fit, biFit, assumedVz, err=err, vz_err = vz_err
	;\\ Set up the equations
	basis = get_unit_spherical(biFit.lat, biFit.lon)
	coeffs = fltarr(3,3)
	coeffs[*,0] = [dotp(biFit.lAxis, basis.zonal), dotp(biFit.lAxis, basis.merid), dotp(biFit.lAxis, basis.zenith)]
	coeffs[*,1] = [dotp(biFit.mAxis, basis.zonal), dotp(biFit.mAxis, basis.merid), dotp(biFit.mAxis, basis.zenith)]
	coeffs[*,2] = [0, 0, 1]

	;\\ Do the inversion
	lhs = transpose([biFit.lcomp, biFit.mcomp, assumedVz])
	inv_coeffs = invert(coeffs, /double)
	rhs = reform( inv_coeffs ## lhs )

	;\\ Do the error inversion
	if not keyword_set(vz_err) then verr = 0. else verr = vz_err
	lhs_err = transpose([abs(biFit.lerr), abs(biFit.merr), abs(verr)])
	rhs_err = abs(reform( inv_coeffs ## lhs_err ))

	err = rhs_err

	return, rhs
end




;\\ NOTE: TO GO FROM CARTESIAN TO SPHERICAL, DO:
;\\ UNIT_SPH = GET_UNIT_SPHERICAL(LAT, LON)
;\\ SPH_VEC = [DOTP(CART_VEC, UNIT_SPH.ZONAL),DOTP(CART_VEC, UNIT_SPH.MERID),DOTP(CART_VEC, UNIT_SPH.ZENITH)]
;\\ TO GO FROM SPHERICAL TO CARTESIAN, DO:
;\\ UNIT_SPH = GET_UNIT_SPHERICAL(LAT, LON)
;\\ CART_VEC = SPH_VEC.ZONAL*UNIT_SPH.ZONAL + SPH_VEC.MERID*UNIT_SPH.MERID + SPH_VEC.ZENITH*UNIT_SPH.ZENITH




;\\ Calculate parameters for the tristatic inversion
pro calculate_tristatic_params, cvLat, cvLon, lats, lons, azis, zens, alts, outParams, $
							   assume_direct_los=assume_direct_los

   	meanPt = [cvLat, cvLon]

	earthRad = 6371.

	loc = fltarr(3, 3)		;\\ station locations in cartesian
	obsDir = fltarr(3, 3)	;\\ obs los directions in cartesian
	for s = 0, 2 do begin
		loc[*,s] = [cos(Lats[s]*!dtor)*cos(Lons[s]*!dtor), $
				 	cos(Lats[s]*!dtor)*sin(Lons[s]*!dtor), $
				 	sin(Lats[s]*!dtor)]

		dir = [sin(Zens[s]*!dtor)*sin(Azis[s]*!dtor), $
			   sin(Zens[s]*!dtor)*cos(Azis[s]*!dtor), $
			   cos(Zens[s]*!dtor)]

		units = get_unit_spherical(Lats[s], Lons[s])

		zondiff = units.zonal * dir[0]
		merdiff = units.merid * dir[1]
		zendiff = units.zenith * dir[2]
		losVec = zondiff + merdiff + zendiff
		losVec = losVec / norm(losVec)
		obsDir[*,s] = losVec
	endfor

	locCV = [(1 + (Alts[0]/earthRad))*cos(cvLat*!dtor)*cos(cvLon*!dtor), $
			 (1 + (Alts[0]/earthRad))*cos(cvLat*!dtor)*sin(cvLon*!dtor), $
			 (1 + (Alts[0]/earthRad))*sin(cvLat*!dtor)]

	los = fltarr(3, 3)
	for s = 0, 2 do begin
		if keyword_set(assume_direct_los) then begin
			;\\ This assumes the los is directly into the common-volume
			los[*,s] = locCV - loc[*,s]
			los[*,s] = los[*,s] / norm(los[*,s])
		endif else begin
			;\\ Else use azi and zenang converted to cartesian coords
			los[*,s] = obsDir[*,s]
		endelse
	endfor

	dot12 = dotp(los[*,0], los[*,1])
	dot13 = dotp(los[*,0], los[*,2])
	dot23 = dotp(los[*,1], los[*,2])
	obsdot = max(([dot12, dot13, dot23]))


	;\\ Get the horizontal projection of each line of sight, and estimate
	;\\ how well they fill the plane
	sph = get_unit_spherical(cvLat, cvLon)
	los1_mz = [dotp(los[*,0], sph.zonal), dotp(los[*,0], sph.merid), dotp(los[*,0], sph.zenith)]
	los2_mz = [dotp(los[*,1], sph.zonal), dotp(los[*,1], sph.merid), dotp(los[*,1], sph.zenith)]
	los3_mz = [dotp(los[*,2], sph.zonal), dotp(los[*,2], sph.merid), dotp(los[*,2], sph.zenith)]

	azi1 = (atan(los1_mz[0], los1_mz[1]) + !PI)/!DTOR
	azi2 = (atan(los2_mz[0], los2_mz[1]) + !PI)/!DTOR
	azi3 = (atan(los3_mz[0], los3_mz[1]) + !PI)/!DTOR

	planeDot12 = dotp(los1_mz, los2_mz) / (norm(los1_mz) * norm(los2_mz))
	planeAng12 = acos(planeDot12)
	planeDot13 = dotp(los1_mz, los3_mz) / (norm(los1_mz) * norm(los3_mz))
	planeAng13 = acos(planeDot13)
	planeFill = (planeAng12 + planeAng13) - abs(planeAng12 - planeAng13)


	;\\ Get the vector direction midway between the three
	sph = get_unit_spherical(cvLat, cvLon)

	s1 = slerp(reform(los[*,1]), reform(los[*,2]), 0.5)
	s2 = slerp(reform(los[*,0]), s1, 0.5)

	midvec = s2/norm(s2)
	midvec_sph = [dotp(midvec, sph.zonal), dotp(midvec, sph.merid), dotp(midvec, sph.zenith)]

	outParams = {obsDot:obsDot, $
				 aziSum:planeFill, $
				 midVec:midvec_sph, $
				 obsVec:los, $
				 losvec1:los[*,0], $
				 losvec2:los[*,1], $
				 losvec3:los[*,2] }

end



;\\ The inversion routines...
pro resolve_nStatic_wind, cvLat, $		;\\ common volume latitude, geographic
						  cvLon, $		;\\ common volume longitude, geographic
						  inLats, $		;\\ station latitudes, geographic
						  inLons, $	 	;\\ station longitudes, geographic
						  inZens, $		;\\ zenith angles from local station zenith, degrees
						  inAzis, $		;\\ azimuth angles from local station north, degrees
						  inAlts, $
						  inLos, $
						  inErr, $
						  outWind, $
						  outErr, $
						  outInfo, $
						  assume_direct_los=assume_direct_los, $ ;\\ calculate los vectors directly from cv location,
						  										 ;\\ instead of from azimuth and zenith angle
						  useSVD=useSVD		;\\ use singular value decomp

	nStations = n_elements(inLats)

	;\\ Bi-Static
	if nStations eq 2 then begin

		;\\ Get unit vectors in the plane
		;\\ one pointing from the southerly station to the northerly (l-axis)
		;\\ a second at right angles, lying in the plane formed by the two stations and the cv point (m-axis)

		calculate_bistatic_params, cvLat, cvLon, inLats, inLons, inAzis, inZens, inAlts, outParams, $
								   assume_direct_los=assume_direct_los

		outInfo = {lAxis:outParams.lAxis, $
				   mAxis:outParams.mAxis, $
				   nAxis:outParams.nAxis, $
				   lAngle:float(outParams.lAngle), $
				   mAngle:outParams.mAngle, $
				   midDist:float(outParams.midDist), $
				   obsDot:outParams.dotProduct, $
				   obsVecLo:outParams.obsVec[*,outParams.minIdx], $
				   obsVecHi:outParams.obsVec[*,outParams.maxIdx] }

		obsV = transpose(outParams.obsVecPlane)

		if not keyword_set(useSVD) then begin
			obsVinverse = invert(obsV, /double)
			outWind = reform( obsVinverse ## inLos )
			outErr = reform( obsVinverse ## inErr)
		endif else begin
			svdc, obsV, w, u, v
			n = n_elements(w)
			wp = fltarr(n, n)
			for k = 0, n-1 do $
			   if abs(w(k)) ge 1.0e-5 then wp(k, k) = 1.0/w(k)
			outWind = reform(v ## wp ## transpose(u) ## obsLos)
			outErr = reform(v ## wp ## transpose(u) ## obsErr)
		endelse

		return
	endif


	;\\ Tri-Static
	if nStations eq 3 then begin

		calculate_tristatic_params, cvLat, cvLon, inLats, inLons, inAzis, inZens, inAlts, outParams, $
								   assume_direct_los=assume_direct_los

		outInfo = {obsDot:outParams.obsDot, $
				   aziSum:outParams.aziSum, $
				   midVec:outParams.midVec, $
				   losvec1:outParams.losvec1, $
				   losvec2:outParams.losvec2, $
				   losvec3:outParams.losvec3 }

		obsVec = (outParams.obsVec)
		obsLos = (inLos)
		obsErr = (inErr)

		if not keyword_set(useSVD) then begin
			obsVecInverse = invert(obsVec, /double)
			outWind = reform( obsVecInverse ## obsLos )
			outErr = reform( obsVecInverse ## obsErr )
		endif else begin
			svdc, obsVec, w, u, v
			n = n_elements(w)
			wp = fltarr(n, n)
			for k = 0, n-1 do $
			   if abs(w(k)) ge 1.0e-5 then wp(k, k) = 1.0/w(k)
			outWind = double(reform(v ## wp ## transpose(u) ## obsLos))
			outErr = double(reform(v ## wp ## transpose(u) ## obsErr))
		endelse

		;\\ At this point, outWind is in cartesian space - need to convert back to local zonal, merid, zenith
		units = get_unit_spherical(cvLat, cvLon)

		cvWind = [ dotp(outWind, units.zonal), $
				   dotp(outWind, units.merid), $
				   dotp(outWind, units.zenith) ]
		cvErr =  [ dotp(outErr, units.zonal), $
				   dotp(outErr, units.merid), $
				   dotp(outErr, units.zenith) ]

		outWind = cvWind
		outErr = cvErr

		return
	endif

end