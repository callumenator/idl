
function get_msis2000_params, doy, sec, alt, lat, lon, f107a, f107, ap, ap_array = ap_array

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


		year = 2007L
		doy  = long(doy)

		lon = double(lon)
		lat = double(lat)
		alt = double(alt)
		msissec = double(sec)

		flags = intarr(24)
		flags(*) = 1L
		flags(0) = 0L

		if keyword_set(ap_array) then flags(9) = -1


		f107A = double(f107a)
		f107  = double(f107)
		ap = double(ap)

		if not keyword_set(ap_array) then begin
			apa = dblarr(7)
			apa(*) = 10D
		endif

		nsecs = n_elements(msissec)
		rtemp = fltarr(nsecs)
		rdens = {he:fltarr(nsecs), $
				 o:fltarr(nsecs), $
				 n2:fltarr(nsecs), $
				 o2:fltarr(nsecs), $
				 ar:fltarr(nsecs), $
				 all:fltarr(nsecs), $
				 h:fltarr(nsecs), $
				 n:fltarr(nsecs), $
				 anom_oxy:fltarr(nsecs)}
		solar_time = fltarr(nsecs)
		scale_height = fltarr(nsecs)

		boltz = 1.380658e-23
		amu   = 1.6726231e-27

		for idx = 0, nsecs - 1 do begin

			if keyword_set(ap_array) then apa = reform(ap_array(idx,*))

			tsec = msissec(idx)

			dens = dblarr(9)
			temp = dblarr(2)

			if nels(ap) eq nsecs then this_ap = ap[idx] else this_ap = ap[0]

			lst = double(tsec/3600. + lon/15.)
			result = call_external('C:\cal\idlsource\code\msise2000\debug\msise2000.dll','nrlmsise00', $
                        year, doy, msissec(idx), alt, lat, lon, lst, f107a, f107, this_ap, apa, flags, dens, temp)

			rtemp(idx) = temp(1)
			for j = 0, 8 do rdens.(j)(idx) = dens(j)
			solar_time(idx) = lst

			mmm = (dens(0)*4. + dens(1)*16. + dens(2)*28. + dens(3)*32.)/(dens(0) + dens(1) + dens(2) + dens(3))
			hh  = boltz*temp(1)/(mmm*amu*(9.8*(6371./(6371.+alt))^2))
			scale_height(idx) = hh

		endfor

		return, {dens:rdens, temp:rtemp, solar_time:solar_time, scale_height:hh}

end