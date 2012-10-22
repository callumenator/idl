
pro msis_args, nels, var, default
	if n_elements(var) eq 0 then var = default
	if n_elements(var) ne nels then var = replicate(var[0], nels)
end

function msis, year = year, $
			   doy = doy, $
			   ut_secs = ut_secs, $
			   altitude = altitude, $
			   latitude = latitude, $
			   longitude = longitude, $
			   f107 = f107, $
			   f107a = f107a, $
			   ap = ap

	;function msis, doy, sec, alt, lat, lon, f107a, f107, ap, ap_array = ap_array

	;\\ If ap_array is set, then it should be an array of N x 7 elements, where
	;\\ N is the number of time values being input, so there are 7 elements for
	;\\ each time

	;\\ NRLMSISE-00 takes the following arguments, and types MUST match
	;\\ or call will be UNSTABLE

	;\\ LONG year - currently ignored
	;\\ LONG doy - day of year
	;\\ DOUBLE sec - ut seconds into day
	;\\ DOUBLE alt - altitude in km
	;\\ DOUBLE lat - geodetic latitude
	;\\ DOUBLE lon - geodetic longitude
	;\\ DOUBLE lst - local solar time in hours (sec/3600. + lon/15.)
	;\\ DOUBLE f107A - 81 day average of f10.7 flux centered on doy
	;\\ DOUBLE f107 - daily f10.7 flux on previous day
	;\\ DOUBLE ap - ap index (daily)
	;\\ DOUBLE ap_array - only used (i think) if FLAGS(9) is set to -1
		;/* Array containing the following magnetic values:

		; *   0 : daily AP
		; *   1 : 3 hr AP index for current time
		; *   2 : 3 hr AP index for 3 hrs before current time
		; *   3 : 3 hr AP index for 6 hrs before current time
		; *   4 : 3 hr AP index for 9 hrs before current time
		; *   5 : Average of eight 3 hr AP indicies from 12 to 33 hrs
		; *           prior to current time
		; *   6 : Average of eight 3 hr AP indicies from 36 to 57 hrs
		; *           prior to current time
	;\\ INT ARRAY flags(24) - switches, described in the source code
	;\\ DOUBLE ARRAY d(9) - supplied to hold density outputs (see below)
	;\\ DOUBLE ARRAY t(2) - supplied to hold temperature outputs (see below)

		 ;*   OUTPUT VARIABLES:
		 ;*      d[0] - HE NUMBER DENSITY(CM-3)
		 ;*      d[1] - O NUMBER DENSITY(CM-3)
		 ;*      d[2] - N2 NUMBER DENSITY(CM-3)
		 ;*      d[3] - O2 NUMBER DENSITY(CM-3)
		 ;*      d[4] - AR NUMBER DENSITY(CM-3)
		 ;*      d[5] - TOTAL MASS DENSITY(GM/CM3) [includes d[8] in td7d]
		 ;*      d[6] - H NUMBER DENSITY(CM-3)
		 ;*      d[7] - N NUMBER DENSITY(CM-3)
		 ;*      d[8] - Anomalous oxygen NUMBER DENSITY(CM-3)
		 ;*      t[0] - EXOSPHERIC TEMPERATURE
		 ;*      t[1] - TEMPERATURE AT ALT
		 ;*
		 ;*
		 ;*      O, H, and N are set to zero below 72.5 km
		 ;*
		 ;*      t[0], Exospheric temperature, is set to global average for
		 ;*      altitudes below 120 km. The 120 km gradient is left at global
		 ;*      average value for altitudes below 72 km.


	nt = n_elements(ut_secs)

	if (nt eq 0) then begin
		print, 'MUST GIVE A UT TIME IN SECONDS'
	endif

	msis_args, nt, year, 2012
	msis_args, nt, doy, 100
	msis_args, nt, altitude, 240.
	msis_args, nt, latitude, 65
	msis_args, nt, longitude, -145
	msis_args, nt, f107, 100
	msis_args, nt, f107a, f107[0]
	msis_args, nt, ap, 15

	year = long(year)
	doy = long(doy)
	ut_secs = double(ut_secs)
	altitude = double(altitude)
	latitude = double(latitude)
	longitude = double(longitude)
	ap = double(ap)
	f107 = double(f107)
	f107a = double(f107a)

	flags = intarr(24)
	flags(*) = 1L
	flags(0) = 0L

	if keyword_set(ap_array) then flags(9) = -1

	if not keyword_set(ap_array) then begin
		apa = dblarr(7)
		apa(*) = 10D
	endif

	rtemp = fltarr(nt)
	rdens = {he:fltarr(nt), $
			 o:fltarr(nt), $
			 n2:fltarr(nt), $
			 o2:fltarr(nt), $
			 ar:fltarr(nt), $
			 all:fltarr(nt), $
			 h:fltarr(nt), $
			 n:fltarr(nt), $
			 anom_oxy:fltarr(nt)}

	solar_time = fltarr(nt)
	scale_height = fltarr(nt)

	boltz = 1.380658e-23
	amu   = 1.6726231e-27

	dens = dblarr(9)
	temp = dblarr(2)
	for j = 0, nt - 1 do begin

		lst = double(ut_secs[j]/3600. + longitude[j]/15.)
		result = call_external('C:\rsi\idlsource\models\msis2000\msise2000.dll','nrlmsise00', $
                        year[j], $
                        doy[j], $
                        ut_secs[j], $
                        altitude[j], $
                        latitude[j], $
                        longitude[j], $
                        lst, $
                        f107a[j], $
                        f107[j], $
                        ap[j], $
                        apa, $
                        flags, $
                        dens, $
                        temp)

		rtemp[j] = temp[1]
		for k = 0, 8 do rdens.(k)[j] = dens[k]
		solar_time[j] = lst

		mmm = (dens[0]*4. + dens[1]*16. + dens[2]*28. + dens[3]*32.)/(dens[0] + dens[1] + dens[2] + dens[3])
		hh  = boltz*temp[1]/(mmm*amu*(9.8*(6371./(6371.+altitude[j]))^2))
		scale_height[j] = hh

	endfor

	return, {dens:rdens, temp:rtemp, solar_time:solar_time, scale_height:hh}

end