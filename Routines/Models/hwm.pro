
pro hwm_args, nels, var, default
	if n_elements(var) eq 0 then var = default
	if n_elements(var) ne nels then var = replicate(var[0], nels)
end

function hwm, year = year, $
			  doy = doy, $
			  ut_secs = ut_secs, $
			  altitude = altitude, $
			  latitude = latitude, $
			  longitude = longitude, $
			  f107 = f107, $
			  ap = ap

	nt = n_elements(ut_secs)

	if (nt eq 0) then begin
		print, 'MUST GIVE A UT TIME IN SECONDS'
	endif

	hwm_args, nt, year, 2012
	hwm_args, nt, doy, 100
	hwm_args, nt, altitude, 240.
	hwm_args, nt, latitude, 65
	hwm_args, nt, longitude, -145
	hwm_args, nt, f107, 100
	hwm_args, nt, ap, 15

	yyddd = lonarr(nt)
	for i = 0, nt - 1 do begin
		if year[i] ge 2000 then yyddd[i] = 1000L*(year[i] - 2000) + doy[i] $
			else yyddd[i] = 1000L*(year[i] - 1900) + doy[i]
	endfor

	ut_secs = float(us_secs)
	altitude = float(altitude)
	latitude = float(latitude)
	longitude = float(longitude)
	ap = float(ap)


	merid = fltarr(nt)
	zonal = fltarr(nt)
	w = fltarr(2)

	cd, 'C:\RSI\IDLSource\Code\HWM\Win32HWM07+\', curr=olddir
	for j = 0, nt - 1  do begin

		result = call_external('C:\RSI\IDLSource\Models\HWM07\hwm07+.dll','hwm07', $
								yyddd[j], $
								ut_secs[j], $
								altitude[j], $
								latitude[j], $
								longitude[j], $
								0., $ ;\\ used to be lst?
								0., $ ;\\ used to be f107a
								0., $ ;\\ used to be f107
								[0., ap[j]], $
								w)


		merid[j] = w[0]
		zonal[j] = w[1]

	endfor
	cd, olddir

	return, {merid:merid, zonal:zonal}
end