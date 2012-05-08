
function time_str_from_decimalut, decut, forfilename=forfilename, $
										 noseconds=noseconds, $
										 separator = separator
	hour = fix(decut)
	mins = ((float(decut) mod 1)*60.)
	secs = ((float(mins) mod 1)*60.)

	if keyword_set(forfilename) then char = '-' else char = ':'
	if keyword_set(separator) then begin
		if size(separator, /type) eq 7 then char = separator
	endif

	if keyword_set(noseconds) then begin
		mins = round(mins)
		time_str = string(fix(hour),f='(i02)') + char + string(mins,f='(i02)')
	endif else begin
		time_str = string(fix(hour),f='(i02)') + char + string(mins,f='(i02)') + char + string(secs,f='(i02)')
	endelse

	return, time_str
end