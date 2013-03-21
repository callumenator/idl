
;\\ Given a starting lat, lon, distance (in km) and azimuth (degrees east of north)
;\\ computes the end lat and lon of the path.
;\\ Azimuth and distance can be arrays

function get_end_lat_lon, start_lat, start_lon, distance, azimuth

	;\\ NEW CHANGE ... CAL FEB 09 2011
	if n_elements(azimuth) gt 1 then begin
		if n_elements(start_lat) eq 1 then start_lat = replicate(start_lat, n_elements(azimuth))
		if n_elements(start_lon) eq 1 then start_lon = replicate(start_lon, n_elements(azimuth))
	endif

	Polar_Rad = 6356.752
	Path_Length = distance

	sb = (90 + start_lat) * (!dtor)		;\\ angle from south pole to start pos along a meridian
	sc = Path_Length / Polar_Rad		;\\ angle from start pos to end pos

	A = fltarr(n_elements(azimuth))
	for hh = 0L, n_elements(azimuth) - 1 do if azimuth(hh) le 180 then A(hh) = (180 - azimuth(hh))*!dtor else A(hh) = (azimuth(hh) - 180)*!dtor

	sa = acos( cos(sb)*cos(sc) + sin(sb)*sin(sc)*cos(A) )

	end_lat = (sa / !dtor) - 90.0

	C = asin( (sin(sc) * sin(A)) / sin(sa) )

	end_lon = fltarr(n_elements(azimuth))
	for hh = 0L, n_elements(azimuth) - 1 do begin
		if azimuth(hh) le 180 then begin
			end_lon(hh) = start_lon(hh) + (C(hh) / !dtor)
		endif else begin
			end_lon(hh) = start_lon(hh) - (C(hh) / !dtor)
		endelse

		;\\ THIS IS A HACK FOR POINTS NEAR THE POLE
		dist = map_2points(start_lon[hh], start_lat[hh], end_lon[hh], end_lat[hh])
		if n_elements(sc) gt 1 then begin
			if abs(dist[0]*!dtor - sc[hh]) gt 1E-5 then end_lon[hh] += 180
		endif else begin
			if abs(dist[0]*!dtor - sc) gt 1E-5 then end_lon[hh] += 180
		endelse

	endfor

	return, [[end_lat],[end_lon]]

end