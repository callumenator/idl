
;\\ Delete 1-D array elements. Elements is an array of element indices to delete.

function delete_elements, inArray, elements

	dims = size(inArray, /dimensions)

	flag = bytarr(dims[0])
	flag[*] = 0
	flag[elements] = 1

	pts = where(flag eq 0, npts)

	if npts gt 0 then begin
		return, inArray[pts]
	endif else begin
		return, -1
	endelse
end