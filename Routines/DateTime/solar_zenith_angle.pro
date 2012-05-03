


pro solar_zenith_angle, lat, lon, offset_to_ut, js_range, n_points, out_ele, out_js

	if n_elements(js_range) gt 1 then begin
		js = findgen(n_points)/(float(n_points)) * (js_range[1] - js_range[0]) + js_range[0]
	endif else begin
		js = js_range
		n_points = 1
	endelse
	out_ele = fltarr(n_points)

	for j = 0, n_points - 1 do begin

		js2ymds, js[j], year, month, day, seconds
		jd = js2jd(js[j])

		ut_h = seconds/3600. + offset_to_ut
		ut_fraction = ( ut_h / 24.)

		sidereal_time = lmst(jd, ut_fraction, 0) * 24.

		sunpos, jd, RA, Dec

		sun_lat = Dec
		sun_lon = RA - (15. * sidereal_time)

		ll2rb, lon, lat, sun_lon, sun_lat, range, azimuth

		out_ele[j] = refract(90 - (range * !radeg))

	endfor
	out_js = js

end