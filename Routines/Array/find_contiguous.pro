
pro find_contiguous, in_array, gap_threshold, out_indices, n_blocks = n_blocks, absolute=absolute

	if n_elements(in_array) eq 1 then begin

		out_indices = intarr(1,2)
		n_blocks = 1

	endif else begin

		diff = (in_array - shift(in_array, 1))[1:*]
		if keyword_set(absolute) then diff = abs(diff)
		pts = where(diff gt gap_threshold, n_pts) + 1
		if n_pts eq 0 then begin
			pts = [n_elements(in_array)]
		endif else begin
			pts = [pts, n_elements(in_array)]
		endelse

		idx = 0
		indices = lonarr(n_pts + 1, 2)
		for j = 0L, n_pts do begin
			indices[j,0] = idx
			indices[j,1] = pts[j]-1
			idx = pts[j]
		endfor

		out_indices = indices
		n_blocks = (n_pts + 1)
	endelse
end