
pro load_color_table, name, full=full
	if not keyword_set(full) then begin
		path = where_is('color_tables')
		restore, path + '\' + name
	endif else begin
		restore, name
	endelse
	tvlct, r, g, b
end