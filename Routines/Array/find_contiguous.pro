


pro find_contiguous, in_array, gap_threshold, out_indices, n_blocks = n_blocks

	diff = (in_array - shift(in_array, 1))[1:*]
	pts = where(diff gt gap_threshold, n_pts) + 1
	if n_pts eq 0 then begin
		pts = [n_elements(in_array)]
	endif else begin
		pts = [pts, n_elements(in_array)]
	endelse

	idx = 0
	indices = intarr(n_pts + 1, 2)
	for j = 0, n_pts do begin
		indices[j,0] = idx
		indices[j,1] = pts[j]-1
		idx = pts[j]
	endfor

	out_indices = indices
	n_blocks = (n_pts + 1)
end