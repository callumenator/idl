
function get_boundcoords_for_multiplots, nplots, bigdims, gap

	;\\ Bounds are given from bottom to top

	gap = float(gap)
	bounds = fltarr(nplots, 4)	;\\ x0, y0, x1, y1

	;\\ Xcoords are the same as bigdims coords
		bounds(*,0) = bigdims(0)
		bounds(*,2) = bigdims(2)

	;\\ Ycoords depend on nplots
		y0 = bigdims(1)
		y1 = bigdims(3)
		dy = (float(y1-y0) / (float(nplots))) - gap

		bounds(0,1) = y0 + gap
		bounds(0,3) = bounds(0,1) + dy

		for n = 1, nplots - 1 do begin
			bounds(n,1) = bounds(n-1,3) + gap
			bounds(n,3) = bounds(n,1) + dy
		endfor

	bounds(*,1) = bounds(*,1) - gap
	bounds(*,3) = bounds(*,3) - gap

	return, bounds

end