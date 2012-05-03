
pro sdi_batch_rename

	path = path
	filter = ['*.las', '*.sky']

	if strmid(path, strlen(path)-1, 1) ne '\' then path = path + '\'

	files = file_search(path, filter, count = n_files)

	for j = 0, n_files - 1 do begin

		sdi3k_read_netcdf_data, files[j], metadata=mm, /close

		if size(mm, /tname) ne 'STRUCT' then goto, null_file
		if mm.maxrec lt 1 then goto, null_file

		preferred_name = dt_tm_mk(js2jd(0d)+1, mm.start_time, $
		                 format = mm.viewtype + '_' + string(fix(10*mm.wavelength_nm), format='(i4.4)') + '_Y$_doy$_Date_0n$_0d$' + mm.extension)

		print, preferred_name

		null_file:
	endfor

end