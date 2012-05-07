
pro hwm, yyddd, $
		 time_sec, $		;\\ UT time in seconds
		 f107a, $			;\\ 3-month average F10.7 for each time (time is first dimension)
		 f107, $			;\\ Previous day daily F10.7 for each time (time is first dimension)
		 ap, $				;\\ One or two element array for each time (time is first dimension)
		 wind = wind, $		;\\ Returned wind structure
		 flags = flags, $
		 altitude = alt, $	;\\ Altitude in km
		 latitude = lat, $	;\\ Geodetic lat and lon
		 longitude = lon, $
		 fill = fill		;\\ Fill all times with same activity parameters

	if not keyword_set(flags) then begin
		flags = fltarr(25); Control flags (see HWM-93 FORTRAN source code for usage)
		flags(*) = 1.
	endif

	if not keyword_set(lat) then lat = 65.
	if not keyword_set(lon) then lon = -145.
	if not keyword_set(alt) then alt = 240.

	if n_elements(ap) eq 0 or n_elements(ap) eq 1 then begin
		ap = [ap[0], ap[0]]
	endif else begin
		dims = size(ap, /dimensions)
		if n_elements(dims) eq 2 then flags[8] = -1
	endelse

	n_times = n_elements(time_sec)
	n_alts = n_elements(alt)

	len = n_alts > n_times

	if keyword_set(fill) then begin
		use_ap = fltarr(len, 2)
		use_f107a = fltarr(len)
		use_f107 = fltarr(len)
		use_ap[*,0] = ap[0]
		use_ap[*,1] = ap[1]
		use_f107a[*] = f107a
		use_f107[*] = f107

		ap = use_ap
		f107a = use_f107a
		f107 = use_f107
	endif

	if n_times gt 1 then begin
		dims = size(ap, /dimensions)
		if dims[0] ne len then stop
		dims = size(f107a, /dimensions)
		if dims[0] ne len then stop
		dims = size(f107, /dimensions)
		if dims[0] ne len then stop
	endif

	merid = fltarr(len)
	zonal = fltarr(len)
	w = fltarr(2)

	dir = 'c:\cal\idlsource\code\hwm\win32hwm07+\'
	cd, dir, curr=old_dir

	for j = 0, len - 1  do begin

		case len of
			n_times: begin
				alt = float(alt)
				tsec = float(time_sec[j])
			end

			n_alts: begin
				alt = float(alt[j])
				tsec = float(time_sec)
			end

			else:stop
		endcase

		lst = float(tsec/3600. + lon/15.)

		this_f107a = f107a[j]
		this_f107 = f107[j]
		this_ap = reform(ap[j,*])

		lon = float(lon)
		lat = float(lat)

		result = call_external(dir + 'hwm07+.dll','hwm07', $
			long(yyddd), tsec, alt, lat, lon, lst, this_f107a, this_f107, this_ap, w)

		merid[j] = w(0)
		zonal[j] = w(1)

	endfor

	cd, old_dir

	wind = {merid:merid, zonal:zonal}
end