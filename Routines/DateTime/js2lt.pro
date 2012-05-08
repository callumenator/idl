
function js2lt, js

	js2ymds, double(js(0)), y, m, d, s
	xvals = ((js - js(0)) / 3600.) + ((s/3600.))
 	xvals = xvals + 4.13

	return, xvals

end