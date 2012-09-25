
;\\ Wraptimes will make sure all times are within 0-24 hours, else
;\\ times like 26 hours are possibly returned

function js2ut, js, wraptimes=wraptimes

	;js2ymds, double(js(0)), y, m, d, s
	;xvals = ((js - js(0)) / 3600.) + ((s/3600.))

	js2ymds, double(js), y, m, d, s
	xvals = (s/3600.)

	if not keyword_set(wraptimes) then begin
		;add24 = where( (d - d(0)) ne 0, npts)
		;if npts gt 0 then xvals(add24) = xvals(add24) + 24
		xvals += (d - d[0])*24.
	endif

	return, xvals

end