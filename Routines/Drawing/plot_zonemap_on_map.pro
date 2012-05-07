
pro plot_zonemap_on_map, centerLat, centerLon, $ ;\\ these can be zero if a metadata structure is supplied
						 rads, secs, $ ;\\ these can be zero if a metadata structure is supplied
						 height, $	;\\ projection altitude
						 geoNorthAzi, $ ;\\ the angle to rotate from geographic north
						 fov, $ ;\\ Half-angle field-of-view in degrees, can be zero if a meta-data structure is supplied
						 mapstruct, $ ;\\ The mapping structure
						 onlyTheseZones=onlyTheseZones, $ ;\\ Only show these zones [ , , ,]
						 ctable=ctable, $ ;\\ Color table
						 back_color=back_color, $ ;\\ Line back-color
						 front_color=front_color, $ ;\\ Line color
						 no_outline = no_outline, $ ;\\ Don't draw a thick background line
						 number_color = number_color, $ ;\\ Color for zone numbe characters
						 numberZones=numberZones, $ ;\\ Show zone numbers
						 numberChar=numberChar, $ ;\\ [Charsize, Charthick, Front Color, Back Color, Ctable, xoffset, yoffset, azoffset, radoffset]
						 lineStyle=lineStyle, $
						 lineThick=lineThick, $
						 fovEdgeOnly=fovEdgeOnly, $ ;\\ Only plot the field-of-view edge circle, no zones
						 fovFill=fovFill, $	;\\ Fill the field-of-view edge circle
						 transparent=transparent, $	;\\ Alpha value, only with fovFill and only with a screen device
						 meta=meta ;\\ If metadata is supplied, no need for lat, lon, rads, secs, fov

	if not keyword_set(numberChar) then numberChar = [1,1,0,0,0,0,0,0,0]

	if keyword_set(meta) then begin
		rads = [0, meta.zone_radii[0:meta.rings-1]/100.]
		secs = meta.zone_sectors[0:meta.rings-1]
		fov = meta.sky_fov_deg
		centerLon = meta.longitude
		centerLat = meta.latitude
	endif else begin
		secs = secs(0:n_elements(rads)-2)
	endelse

	radius = fltarr(total(secs))
	azimuth  = fltarr(total(secs))
	zenith_ang = fltarr(total(secs))
	radius(0) = 0 &	azimuth(0) = 0 & zenith_ang(0) = 0

	ring = [0]
	rcnt = 1
	for sidx = 1, n_elements(secs) - 1 do begin
		fill = intarr(secs(sidx))
		fill(*) = rcnt
		ring = [ring, fill]
		rcnt ++
	endfor

	nrings = max(ring) + 1

	for r = 1, nrings-1 do begin
		pts = where(ring eq r, npts)
		for rr = 0., npts - 1 do begin
			radius(pts(rr)) = (rads(ring(pts(rr)))+rads(ring(pts(rr))+1))/2.
			azimuth(pts(rr)) = (180.*(2*rr + 1))/secs(ring(pts(rr)))
		endfor
	endfor

	azimuth = azimuth + geoNorthAzi

	pts = where(azimuth gt 360, npts)
	if npts gt 0 then azimuth(pts) = azimuth(pts) - 360
	pts = where(azimuth lt 0, npts)
	if npts gt 0 then azimuth(pts) = azimuth(pts) + 360

	ptsl = where(azimuth le 180, complement = ptsg)
	azimuth(ptsl) = 180 - azimuth(ptsl)
	azimuth(ptsg) = 540 - azimuth(ptsg)
	azi = azimuth
	for hh = 0, total(secs)-1 do begin
		if azimuth(hh) ge 0   and azimuth(hh) le 90  then azi(hh) = 90 - azimuth(hh)
		if azimuth(hh) gt 90  and azimuth(hh) le 270 then azi(hh) = -(azimuth(hh) - 90)
		if azimuth(hh) gt 270 and azimuth(hh) le 360 then azi(hh) = 90 + (360 - azimuth(hh))
	endfor
	azimuth = azi

	if size(ctable, /type) eq 0 then loadct, 39, /silent else loadct, ctable, /silent
	if size(back_color, /type) eq 0 then line_bcolor = 0 else line_bcolor = back_color
	if size(front_color, /type) eq 0 then line_fcolor = 180 else line_fcolor = front_color
	if size(number_color, /type) eq 0 then num_color = 180 else num_color = number_color
	if size(lineThick, /type) eq 0 then lineThick = 1
	if size(lineStyle, /type) eq 0 then lineStyle = 0


	circ = fltarr(n_elements(rads)-1,361,2)		;lat, lon
	for r = 0, n_elements(rads) - 2 do begin
		tc = get_end_lat_lon(centerLat, centerLon, get_great_circle_length(rads(r+1)*fov, height), findgen(361))
		circ(r,*,0) = tc(*,0)
		circ(r,*,1) = tc(*,1)
	endfor

	if keyword_set(fovFill) then begin
		if not keyword_set(transparent) then transparent = .3
		r = n_elements(rads) - 2
		centerXY = MAP_PROJ_FORWARD(centerLon, centerLat , MAP_STRUCTURE=mapStruct)
		Result_circ = MAP_PROJ_FORWARD(circ(r,*,1) , circ(r,*,0) , MAP_STRUCTURE=mapStruct)

		current_image = tvrd(/true)
		erase, 0

		for cc = 0, n_elements(result_circ(0,*)) - 4 do begin
			xxarr = [centerXY[0], centerXY[0], result_circ(0,cc+3), result_circ(0,cc)]
			yyarr = [centerXY[1], centerXY[1], result_circ(1,cc+3), result_circ(1,cc)]
			polyfill, /data, xxarr, yyarr, color = line_fcolor, transparent=1
		endfor

		overlay_image = tvrd(/true)
		alpha = float(reform(overlay_image[0,*,*]))
		pts = where(total(overlay_image, 1) eq 0, complement=blend)
		alpha[blend] = transparent
		alpha3 = overlay_image
		alpha3 = [[alpha], [alpha], [alpha]]
		blend_image = alpha_blend(current_image, overlay_image, alpha3)

		device, decom=1
		tv, blend_image, /true
		device, decomp=0

	endif

	if size(onlyTheseZones, /type) eq 0 then begin
	if not keyword_set(fovEdgeOnly) then begin

		for r = 1, n_elements(rads) - 2 do begin
			inner = get_great_circle_length(rads(r)*fov, height)
			outer = get_great_circle_length(rads(r+1)*fov, height)
			az_offset = (360. / secs(r))/2.
			zones = findgen(total(secs))
			zones = zones(total(secs(0:r-1)):total(secs(0:r-1)) + secs(r) - 1)
			inn = get_end_lat_lon(centerLat, centerLon, inner, azimuth(zones) + az_offset)
			out = get_end_lat_lon(centerLat, centerLon, outer, azimuth(zones) + az_offset)
			iResult = MAP_PROJ_FORWARD(inn(*,1) , inn(*,0) , MAP_STRUCTURE=mapStruct)
			oResult = MAP_PROJ_FORWARD(out(*,1) , out(*,0) , MAP_STRUCTURE=mapStruct)

			if not keyword_set(no_outline) then begin
				for k = 0, n_elements(iresult(0,*)) - 1 do plots, [iresult(0,k),oresult(0,k)], [iresult(1,k),oresult(1,k)], /data, $
															  thick = lineThick*2, color = line_bcolor, line=lineStyle, noclip=0
			endif
			for k = 0, n_elements(iresult(0,*)) - 1 do plots, [iresult(0,k),oresult(0,k)], [iresult(1,k),oresult(1,k)], /data, $
															  thick = lineThick, color = line_fcolor, line=lineStyle, noclip=0
		endfor

		for r = 0, n_elements(rads) - 2	do begin
			Result_circ = MAP_PROJ_FORWARD(circ(r,*,1) , circ(r,*,0) , MAP_STRUCTURE=mapStruct)
			if r eq n_elements(rads) - 2 then begin
				if not keyword_set(no_outline) then plots, result_circ(0,*), result_circ(1,*), /data, thick=lineThick*4, color = line_bcolor, line=lineStyle, noclip=0
				plots, result_circ(0,*), result_circ(1,*), /data, thick=lineThick*2, color = line_fcolor, line=lineStyle, noclip=0
			endif else begin
				if not keyword_set(no_outline) then plots, result_circ(0,*), result_circ(1,*), /data, thick=lineThick*2, color = line_bcolor, line=lineStyle, noclip=0
				plots, result_circ(0,*), result_circ(1,*), /data, thick=lineThick, color = line_fcolor, line=lineStyle, noclip=0
			endelse
		endfor

	endif else begin

		frac = rads[n_elements(rads)-1]
		edg = get_end_lat_lon(centerLat, centerLon, get_great_circle_length(replicate(fov*frac, 360), height), findgen(360))
		Result_circ = MAP_PROJ_FORWARD(edg[*,1] , edg[*,0] , MAP_STRUCTURE=mapStruct)
		if not keyword_set(no_outline) then plots, result_circ(0,*), result_circ(1,*), /data, thick=lineThick*4, color = line_bcolor, line=lineStyle, noclip=0
		plots, result_circ(0,*), result_circ(1,*), /data, thick=lineThick*2, color = line_fcolor, line=lineStyle, noclip=0

	endelse

	if keyword_set(numberZones) then begin
		loadct, numberChar[4], /silent
		latLon = get_end_lat_lon(centerLat, centerLon, get_great_circle_length((radius+numberChar[7])*fov, height), azimuth+numberChar[8])
		mapXY = MAP_PROJ_FORWARD(latLon[*,1] , latLon[*,0] , MAP_STRUCTURE=mapStruct)
		xyouts, /data, mapXY[0,*]+ numberChar[5], mapXY[1,*]+ numberChar[6], string(findgen(total(secs)), f='(i0)'), color = numberChar[3], $
			align=.5, chart = numberChar[1], chars=numberChar[0], noclip=0
		xyouts, /data, mapXY[0,*]+ numberChar[5], mapXY[1,*]+ numberChar[6], string(findgen(total(secs)), f='(i0)'), color = numberChar[2], $
			align=.5, chart = numberChar[1], chars=numberChar[0], noclip=0
	endif

	endif ;\\ onlyTheseZones not set

	if size(onlyTheseZones, /type) ne 0 then begin
		for znIdx = 0, n_elements(onlyTheseZones) - 1 do begin
			zn = onlyTheseZones[znIdx]
			if zn ne 0 then begin
				r = ring[zn]
				azWidth = 360./secs[r]
				znWidth = (rads[r+1] - rads[r])*fov

				arc = ((findgen(20)/19.)*(azWidth) + azimuth[zn] - azWidth/2.)


				eptinner = get_end_lat_lon(centerLat, centerLon, get_great_circle_length(rads[r]*fov, height), arc)
				eptouter = get_end_lat_lon(centerLat, centerLon, get_great_circle_length(rads[r+1]*fov, height), arc)

				if not keyword_set(no_outline) then plots, map_proj_forward(eptinner[*,1], eptinner[*,0], map=mapStruct), /data, $
					   thick = lineThick*2, color = line_bcolor, line=lineStyle
				plots, map_proj_forward(eptinner[*,1], eptinner[*,0], map=mapStruct), /data, $
					   thick = lineThick, color = line_fcolor, line=lineStyle, noclip=0
				if not keyword_set(no_outline) then plots, map_proj_forward(eptouter[*,1], eptouter[*,0], map=mapStruct), /data, $
					   thick = lineThick*2, color = line_bcolor, line=lineStyle, noclip=0
				plots, map_proj_forward(eptouter[*,1], eptouter[*,0], map=mapStruct), /data, $
					   thick = lineThick, color = line_fcolor, line=lineStyle, noclip=0
				if not keyword_set(no_outline) then plots, map_proj_forward([eptinner[0,1], eptouter[0,1]], [eptinner[0,0],eptouter[0,0]], map=mapStruct), /data, $
					   thick = lineThick*2, color = line_bcolor, line=lineStyle, noclip=0
				plots, map_proj_forward([eptinner[0,1], eptouter[0,1]], [eptinner[0,0],eptouter[0,0]], map=mapStruct), /data, $
					   thick = lineThick, color = line_fcolor, line=lineStyle, noclip=0
				if not keyword_set(no_outline) then plots, map_proj_forward([eptinner[19,1], eptouter[19,1]], [eptinner[19,0],eptouter[19,0]], map=mapStruct), /data, $
					   thick = lineThick*2, color = line_bcolor, line=lineStyle, noclip=0
				plots, map_proj_forward([eptinner[19,1], eptouter[19,1]], [eptinner[19,0],eptouter[19,0]], map=mapStruct), /data, $
					   thick = lineThick, color = line_fcolor, line=lineStyle, noclip=0

			endif else begin

				circ = findgen(361)
				ept = get_end_lat_lon(centerLat, centerLon, get_great_circle_length(rads[1]*fov, height), circ)
				if not keyword_set(no_outline) then plots, map_proj_forward(ept[*,1], ept[*,0], map=mapStruct), /data, $
					   thick = lineThick*2, color = line_bcolor, line=lineStyle, noclip=0
				plots, map_proj_forward(ept[*,1], ept[*,0], map=mapStruct), /data, $
					   thick = lineThick, color = line_fcolor, line=lineStyle, noclip=0

			endelse
		endfor

		if keyword_set(numberZones) then begin
			loadct, numberChar[4], /silent
			;latLon = get_end_lat_lon(centerLat, centerLon, get_great_circle_length(radius[onlyTheseZones]*fov, height), azimuth[onlyTheseZones])
			latLon = get_end_lat_lon(centerLat, centerLon, get_great_circle_length((radius[onlyTheseZones]+numberChar[7])*fov, height), azimuth[onlyTheseZones]+numberChar[8])
			mapXY = MAP_PROJ_FORWARD(latLon[*,1] , latLon[*,0] , MAP_STRUCTURE=mapStruct)
			xyouts, /data, mapXY[0,*] + numberChar[5], mapXY[1,*] + numberChar[6], string(onlythesezones, f='(i0)'), color = numberChar[3], $
				align=.5, chart = numberChar[1]*1.2, chars=numberChar[0], noclip=0
			xyouts, /data, mapXY[0,*] + numberChar[5], mapXY[1,*] + numberChar[6], string(onlythesezones, f='(i0)'), color = numberChar[2], $
				align=.5, chart = numberChar[1], chars=numberChar[0], noclip=0
		endif

	endif

end