
function ydn_to_yymmdd, year, dayno, separator=separator

	if keyword_set(separator) then seps = separator else seps = ''
	ydn2md, year, dayno, m, d
	yymmdd = string(year-2000, f='(i02)') + seps + string(m, f='(i02)') + seps + string(d, f='(i02)')

	return, yymmdd
end