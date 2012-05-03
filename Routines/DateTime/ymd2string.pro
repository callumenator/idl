
function ymd2string, y, m, d, separator=separator

	if not keyword_set(separator) then separator = '-'

	return, string(y, f='(i04)') + separator + string(m, f='(i02)') + separator + string(d, f='(i02)')
end