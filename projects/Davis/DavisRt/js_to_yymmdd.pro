
;\\ Returns a yymmdd string from a julian seconds time

function js_to_yymmdd, js

	js2ymds, double(js), y, m, d, s
	yymmdd = string(y-2000, f='(i2.2)') + string(m, f='(i2.2)') + string(d, f='(i2.2)')

	return, yymmdd

end