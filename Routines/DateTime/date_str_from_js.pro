
function date_str_from_js, js, forfilename=forfilename, $
						   day_month_year = day_month_year, $
						   separator=separator

	if keyword_set(forfilename) then char = '-' else char = '/'
	if keyword_set(separator) then begin
		if size(separator, /type) eq 7 then char = separator
	endif

	js2ymds, double(js), y, m, d, s
	hours = s/3600.
	minutes = (hours mod 1) * 60.
	seconds = (minutes mod 1) * 60.

	if not keyword_set(day_month_year) then $
		date_str =  string(y,f='(i4.4)') + char + string(m,f='(i2.2)') + char + string(fix(d),f='(i2.2)')

	if keyword_set(day_month_year) then $
		date_str = string(fix(d),f='(i2.2)') + char + string(m,f='(i2.2)') + char +  string(y,f='(i4.4)')

	return, date_str

end