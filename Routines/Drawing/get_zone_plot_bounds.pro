
;\\ Return the coordinates needed for plots-ing the boundary of a given zone
;\\ If zone is set to -1 then the zonemap boundary is returned.
pro get_zone_plot_bounds, rads, secs, nzones, dims, zone, boundaryCoords, $
						  to_geo=to_geo, to_cgm=to_cgm, start_time_js=start_time_js

	radius = fltarr(nzones)
	azimuth  = fltarr(nzones)
	zenith_ang = fltarr(nzones)
	secs = secs(0:n_elements(rads)-2)
	radius(0) = 0 &	azimuth(0) = 0 & zenith_ang(0) = 0

	ring = [0]
	rcnt = 1
	for sidx = 1, n_elements(secs) - 1 do begin
		fill = intarr(secs(sidx))
		fill(*) = rcnt
		ring = [ring, fill]
		rcnt ++
	endfor

	nrings = max(ring)+1

	for r = 1, nrings-1 do begin
		pts = where(ring eq r, npts)
		for rr = 0., npts - 1 do begin
			radius(pts(rr)) = (rads(ring(pts(rr)))+rads(ring(pts(rr))+1))/2.
			azimuth(pts(rr)) = (180.*(2*rr + 1))/secs(ring(pts(rr)))
		endfor
	endfor

	if keyword_set(to_geo) or keyword_set(to_cgm) then begin
		if keyword_set(start_time_js) then begin
			azimuth = convert_mawson_azimuth(azimuth, start_time_js, to_cgm = to_cgm, to_geo = to_geo)
		endif
	endif

	case zone of
		0: begin
			minAngle = 0
			maxAngle = 360
			minRadius = rads(1)
			maxRadius = rads(1)
		end
		-1: begin
			minAngle = 0
			maxAngle = 360
			minRadius = rads(n_elements(rads) - 1)
			maxRadius = rads(n_elements(rads) - 1)
		end
		else: begin
			minAngle = azimuth(zone) - (180./secs(ring(zone)))
			maxAngle = azimuth(zone) + (180./secs(ring(zone)))
			minRadius = rads(ring(zone))
			maxRadius = rads(ring(zone)+1)
		end
	endcase

	angArray = (findgen(maxAngle - minAngle + 1) + minAngle) * !dtor
	nangs = n_elements(angArray)
	innerCoords = transpose([[(dims(0)/2.) + minRadius*(dims(0)/2.)*sin(angArray)], $
				   			 [(dims(1)/2.) + minRadius*(dims(1)/2.)*cos(angArray)]])
	outerCoords = transpose([[(dims(0)/2.) + maxRadius*(dims(0)/2.)*sin(reverse(angArray))], $
				   			 [(dims(1)/2.) + maxRadius*(dims(1)/2.)*cos(reverse(angArray))]])
	lowerRadCoords = transpose([[innerCoords(0,0), outerCoords(0,nangs-1)], $
								[innerCoords(1,0), outerCoords(1,nangs-1)]])
	upperRadCoords = transpose([[innerCoords(0,nangs-1), outerCoords(0,0)], $
	     						[innerCoords(1,nangs-1), outerCoords(1,0)]])

	boundaryCoords = [[innerCoords], [upperRadCoords], [outerCoords], [lowerRadCoords]]

end