
function davis_count_filters, year, dayn, filename=filename

	dir = where_is('davis_data')

	if not keyword_set(filename) then begin
		if size(year, /type) ne 7 then year = string(year, f='(i04)')
		if size(dayn, /type) ne 7 then dayn = string(dayn, f='(i03)')
		fname = dir + year + '_' + dayn
	endif else begin
		fname = filename
	endelse

	if file_test(fname) then begin
		restore, fname
		all_filters = sky.data.filter
		filters = get_unique(all_filters)

		if n_elements(filters) gt 0 then wavelengths = fltarr(n_elements(filters))
		for i = 0, n_elements(filters) - 1 do begin
			pt = where(sky.data.filter eq filters[i], nmatch)
			title = sky[pt[0]].data.title
			red_match = strmatch(title, '*red*', /fold)
			gre_match = strmatch(title, '*green*', /fold)
			if red_match ne 0 then wavelengths[i] = 630.0
			if gre_match ne 0 then wavelengths[i] = 557.7
		endfor

	endif else begin
		filters = [-1]
		wavelengths = [-1]
	endelse

	return, {number:filters, wavelengths:wavelengths}

end