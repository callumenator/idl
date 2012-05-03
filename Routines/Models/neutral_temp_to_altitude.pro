

;\\ Use MSIS to convert a neutral temperature to an altitude.
function neutral_temp_to_altitude, temperature, day_of_year, lat, lon, ut_hour, f107, ap

	;doy, sec, alt, lat, lon, f107a, f107, ap, ap_array = ap_array

	h = findgen(1000) + 50
	temp = fltarr(nels(h))
	for k = 0, nels(h) - 1 do begin
		msis = get_msis2000_params(day_of_year, ut_hour*3600., h[k], lat, lon, f107, f107, ap)
		temp[k] = msis.temp
	endfor

	i = interpol(h, temp, temperature)

	return, i

end