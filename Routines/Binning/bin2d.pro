
;\\ Bin in 2 dimensions

pro bin2d, x, y, z, widths, outx, outy, outz, $
	grid_x=grid_x, grid_y=grid_y, extrap=extrap


	if keyword_set(grid_x) and keyword_set(grid_y) then begin
		nx = n_elements(grid_x)
		ny = n_elements(grid_y)

		outx = fltarr(nx)
		outy = fltarr(ny)
		outz = fltarr(nx, ny)
		outz[*] = -999

		for ix = 0, nx - 2 do begin
		for iy = 0, ny - 2 do begin

			pts = where(x ge grid_x[ix] and $
						x le grid_x[ix+1] and $
						y ge grid_y[iy] and $
						y le grid_y[iy+1], np)

			if np gt 3 then begin
				outx[ix] = median(x[pts])
				outy[iy]= median(y[pts])
				outz[ix,iy] = median(z[pts])
			endif else begin
				outx[ix]=0.5*(grid_x[ix]+grid_x[ix+1])
				outy[iy]=0.5*(grid_y[iy]+grid_y[iy+1])
			endelse

		endfor
		endfor

	endif else begin
		nx = ceil((max(x) - min(x)) / float(widths[0]))
		ny = ceil((max(y) - min(y)) / float(widths[1]))

		outx = fltarr(nx)
		outy = fltarr(ny)
		outz = fltarr(nx, ny)
		outz[*] = -999

		for ix = 0, nx - 1 do begin
		for iy = 0, ny - 1 do begin

			pts = where(x ge min(x) + ix*widths[0] and $
						x le min(x) + (ix+1)*widths[0] and $
						y ge min(y) + iy*widths[1] and $
						y le min(y) + (iy+1)*widths[1], np)

			if np gt 3 then begin
				outx[ix] = median(x[pts])
				outy[iy]= median(y[pts])
				outz[ix,iy] = median(z[pts])
			endif else begin
				outx[ix] = min(x) + (ix+.5)*widths[0]
				outy[iy]= min(y) + (iy+.5)*widths[1]
			endelse

		endfor
		endfor
	endelse

	;\\ If set, fill in the missing points with the value of the closest point
	;\\ Not really extrapolation, but needed a name
	if keyword_set(extrap) then begin
		pts = where(outz eq -999, npts)
		for k = 0, npts - 1 do begin
			idx = array_indices(outz, pts[k])
			dst = (x-outx[idx[0]])^2 + (y-outy[idx[1]])^2
			cl = (where(dst eq min(dst)))[0]
			outz[idx[0], idx[1]] = z[cl]
		endfor
	endif

end