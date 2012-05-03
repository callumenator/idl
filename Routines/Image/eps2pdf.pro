
;\\ Simple batch call for miktex epstopdf...
pro eps2pdf, path, doall=doall

	if keyword_set(doall) then begin
		list = file_search(path + '*.eps', count = nf)
		for j = 0, nf - 1 do spawn, 'epstopdf --nocompress ' + list[j]
	endif else begin
		spawn, 'epstopdf ' + path
	endelse
end