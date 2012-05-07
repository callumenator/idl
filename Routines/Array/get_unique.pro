
function get_unique, inarray, indices=indices

	oin = inarray
	xin = inarray
	xin = xin(sort(xin))
	uxin = xin(uniq(xin))

	if keyword_set(indices) then begin
		;\\ Return first matching index of each unique value in orig array
		indices = intarr(n_elements(uxin))
		for k = 0, n_elements(uxin) - 1 do begin
			indices[k] = (where(inarray eq uxin[k]))[0]
		endfor
		return, indices
	endif else begin
		return, uxin
	endelse
end