
function infer_height_from_temp, year, dayno, lat, lon, ut, temperature

	ydn2md, year, dayno, month, day
	yymmdd = strmid(ymd2string(year, month, day, sep=''), 2, 6)
	cnds = get_geomag_conditions(yymmdd, /quick)

	alts = findgen(321) + 80

	heights = fltarr(n_elements(ut), n_elements(temperature))

	for t = 0, n_elements(ut) - 1 do begin

		msis_temp = fltarr(n_elements(alts))

		for a = 0, n_elements(alts) - 1 do begin

			altitude = float(alts[a])
			msis = get_msis2000_params(dayno, ut[t]*3600., altitude, lat, lon, $
									   cnds.mag.f107 > 70, cnds.mag.f107 > 70, cnds.mag.apmean > 2)

			msis_temp[a] = msis.temp
		endfor

		;\\ Interpolate to measured temperature
		heights[t,*] = interpol(alts, msis_temp, temperature)

	endfor

	;\\ Replace negatives and such
	good = where(finite(heights) eq 1 and heights gt 0 and heights lt 500, ngood, complement=bad, ncomp=nbad)
	if ngood eq 0 then stop

	if nbad gt 0 then begin
		heights[bad] = median(heights[good])
	endif

	return, heights

end