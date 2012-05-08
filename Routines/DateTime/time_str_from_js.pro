
function time_str_from_js, js, forfilename=forfilename, noseconds=noseconds

	if keyword_set(forfilename) then char = '-' else char = ':'

	js2ymds, double(js), y, m, d, s
	hours = s/3600.
	minutes = (hours mod 1) * 60.
	seconds = (minutes mod 1) * 60.

	if keyword_set(noseconds) then begin
		minutes = round(minutes)
		time_str = string(fix(hours),f='(i02)') + char + string(minutes,f='(i02)')
	endif else begin
		time_str = string(fix(hours),f='(i02)') + char + string(minutes,f='(i02)') + char + string(seconds,f='(i02)')
	endelse

	return, time_str

end

