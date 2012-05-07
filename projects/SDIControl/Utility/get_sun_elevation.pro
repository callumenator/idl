;\\ Code formatted by DocGen


;\D\<Function/method/pro documentation here>
function get_sun_elevation, lat, $   ;\A\<Arg0>
                            lon      ;\A\<Arg1>

	time = bin_date(systime(/ut))

	ut_fraction = (time(3)*3600. + time(4)*60. + time(5)) / 86400.

	sidereal_time = lmst(systime(/julian), ut_fraction, 0) * 24.

	sunpos, systime(/julian), RA, Dec

	sun_lat = Dec
	sun_lon = RA - (15. * sidereal_time)

	ll2rb, lon, lat, sun_lon, sun_lat, range, azimuth

	sun_elevation = refract(90 - (range * !radeg))

	return, sun_elevation

end
