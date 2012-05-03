
function split_page, nrows, ncolumns, $
					 bounds = bounds, $
					 row_gap = row_gap, $
					 col_gap = col_gap, $
					 col_percents = col_percents, $
					 row_percents = row_percents

	if not keyword_set(bounds) then bounds = [.1,.1,.98,.98]
	if n_elements(row_gap) eq 0 then row_gap = .1
	if n_elements(col_gap) eq 0 then col_gap = .1

	ob = fltarr(nrows, ncolumns, 4)

	fwidth = bounds[2] - bounds[0]
	fheight = bounds[3] - bounds[1]


	if keyword_set(col_percents) then begin
		if n_elements(col_percents) eq ncolumns then begin
			col_percents = float(col_percents) / total(col_percents)
			fcolWidth = fwidth*col_percents
		endif
	endif else begin
		fcolWidth = replicate( fwidth/float(ncolumns), ncolumns)
	endelse

	if keyword_set(row_percents) then begin
		if n_elements(row_percents) eq nrows then begin
			row_percents = float(row_percents) / total(row_percents)
			frowWidth = fheight*row_percents
		endif
	endif else begin
		frowWidth = replicate( fheight/float(nrows), nrows)
	endelse

	colWidth = fcolWidth - col_gap/2.
	rowWidth = frowWidth - row_gap/2.

	for r = 0, nrows - 1 do begin
		for c = 0, ncolumns - 1 do begin

			xc = bounds[0] + total(fcolWidth[0:c]) - fcolWidth[c]/2.
			yc = bounds[3] - total(frowWidth[0:r]) + frowWidth[r]/2.
			;yc = bounds[3] - (r+1)*(frowWidth) + frowWidth/2.


			x0 = xc - colWidth[c]/2.
			x1 = xc + colWidth[c]/2.
			y0 = yc - rowWidth[r]/2.
			y1 = yc + rowWidth[r]/2.

			ob[r,c,*] = [x0,y0,x1,y1]

		endfor
	endfor

	return, ob

end
