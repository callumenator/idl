
function js2magnetic, js

	js2ymds, double(js(0)), y, m, d, s
	xvals = ((js - js(0)) / 3600.) + ((s/3600.) + 1.3)

	return, xvals

end