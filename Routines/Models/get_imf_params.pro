
;\\ Read in IMF data

function get_imf_params, yymmdd, fname=fname

	year = strmid(yymmdd, 0, 2)
	mnth = strmid(yymmdd, 2, 2)
	day  = strmid(yymmdd, 4, 2)

	path = 'c:\cal\geodata\imf\'
	filename = path + 'IMF_' + year + '.dat'
	if keyword_set(fname) then filename = fname

	if file_test(filename) eq 0 then begin
		print, 'No IMF data file!'
		return, {data:0}
	endif


	restore, filename

	if not keyword_set(fname) then begin
		year = float(year) + 2000
		mnth = float(mnth)
		day  = float(day)

		dayno = ymd2dn(year, mnth, day)

		match = where(data(0,*) eq year and $
				  data(1,*) eq dayno, nmatch)

		if nmatch eq 0 then return, {data:0}

		data = data(*,match)
	endif

	mean_bx = mean(data(5,*))
	mean_by = mean(data(6,*))
	mean_bz = mean(data(7,*))

	hrs = data(2,*) + (data(3,*) / 60.) + (data(4,*) / 3600.)

	return, {data:1, $
			 ut:reform(hrs), $
			 bx:reform(data(5,*)), $
			 by:reform(data(6,*)), $
			 bz:reform(data(7,*)), $
			 bx_mean:mean_bx, $
			 by_mean:mean_by, $
			 bz_mean:mean_bz}

end