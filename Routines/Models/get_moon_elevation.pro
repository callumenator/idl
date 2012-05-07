
function get_moon_elevation, yymmdd, ut, lat, lon, azimuth=azimuth

	;lst = ut + (lon/15.)

	year = float(strmid(yymmdd, 0, 2)) + 2000
	month= float(strmid(yymmdd, 2, 2))
	day  = float(strmid(yymmdd, 4, 2))

	jd = julday(month, day, year, ut)

	MOONPOS, jd, ra, dec, dis

	EQ2HOR, ra, dec, jd, alt, azimuth, lat=lat, lon=lon

	return, alt

end


