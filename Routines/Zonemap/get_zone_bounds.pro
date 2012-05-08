
function get_zone_bounds, zonemap, zones=zones, thick=thick

	bounds = zonemap
	nx = n_elements(zonemap(*,0))
	ny = n_elements(zonemap(0,*))
	zbounds = intarr(nx,ny)

	if keyword_set(thick) then thickIdxs = indgen(thick) - fix(thick/2.) $
		else thickIdxs = [0]

	if keyword_set(zones) then begin

		for x = 0, nx - 2 do begin
		for y = 0, ny - 1 do begin
			if (zonemap(x,y) - zonemap(x+1,y)) ne 0 then begin
				mtch1 = where(zonemap(x,y) eq zones, nmtch1)
				mtch2 = where(zonemap(x+1,y) eq zones, nmtch2)
				if nmtch1 eq 1 or nmtch2 eq 1 then zbounds(x,y) = 1

			endif
		endfor
		endfor

		for x = 0, nx - 1 do begin
		for y = 0, ny - 2 do begin
			if (zonemap(x,y) - zonemap(x,y+1)) ne 0 then begin
				mtch1 = where(zonemap(x,y) eq zones, nmtch1)
				mtch2 = where(zonemap(x,y+1) eq zones, nmtch2)
				if nmtch1 eq 1 or nmtch2 eq 1 then zbounds(x,y) = 1
			endif
		endfor
		endfor


	endif else begin

		for x = 0, nx - 2 do begin
		for y = 0, ny - 1 do begin
			if (zonemap(x,y) - zonemap(x+1,y)) ne 0 then zbounds(x,y) = 1
		endfor
		endfor

		for x = 0, nx - 1 do begin
		for y = 0, ny - 2 do begin
			if (zonemap(x,y) - zonemap(x,y+1)) ne 0 then zbounds(x,y) = 1
		endfor
		endfor

	endelse


	if keyword_set(thick) then begin
		for j = 0, thick do begin
			zbounds = zbounds + shift(zbounds, j, 0)
			zbounds = zbounds + shift(zbounds, 0, j)
		endfor
		zbounds(where(zbounds gt 0)) = 1
	endif

	return, zbounds
end