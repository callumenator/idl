

pro append, newdata, alldata

	if size(alldata, /type) eq 0 or (size(newdata, /type) ne size(alldata,/type)) then begin
		if nels(newdata) eq 1 then begin
			alldata = [newdata]
		endif else begin
			alldata = newdata
		endelse
	endif else begin
		alldata = [alldata, newdata]
	endelse

end