
function ydn2string, y, dayno, separator=separator

	if not keyword_set(separator) then separator = '-'

	return, string(y, f='(i04)') + separator + string(dayno, f='(i03)')
end