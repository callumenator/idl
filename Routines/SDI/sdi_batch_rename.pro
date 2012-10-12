
pro sdi_batch_rename


	search_path = 'F:\SDIData\'
	output_path = 'F:\SDIData\'
	move_renamed_to = 'F:\SDIOldNames\'
	filter = '{*.las,*.sky,*.nc,*.pf}'
	files = file_search(search_path, filter, count = n_files)

	conflict_action = 'skip' ; or 'write_copy' - appends '.COPY' to the preferred name

	conflicts = ['']

	for j = 0, n_files - 1 do begin

		sdi3k_read_netcdf_data, files[j], metadata=mm, /close

		if size(mm, /tname) ne 'STRUCT' then goto, null_file
		if mm.maxrec lt 1 then goto, null_file

		preferred_name = dt_tm_mk(js2jd(0d)+1, mm.start_time, $
		                 format = strupcase(mm.site_code) + '_' + $
		                 		  'Y$_doy$_Date_0n$_0d$_' + $
		                 		  strupcase(mm.viewtype) + '_' + $
		                 		  string(fix(10*mm.wavelength_nm), format='(i04)') + '_' + $
		                 		  'NZ' + string(mm.nzones, f='(i04)') + $
		                 		  '.nc')

		bin = byte(file_dirname(files[j]))
		sbin = bin
		sbin[*] = 0
		if (strlen(search_path)-1) ge strlen(file_dirname(files[j])) then begin
			n_diff = 0
		endif else begin
			sbin[0:strlen(search_path)-1] = byte(search_path)
			same = bin eq sbin
			diff = min(where(same eq 0, n_diff))
		endelse

		if n_diff ne 0 then begin
			add_dir = string(bin[diff:*])
			use_path = output_path + add_dir + '\'
			move_path = move_renamed_to + add_dir + '\'
		endif else begin
			use_path = output_path
			move_path = move_renamed_to
		endelse

		if use_path + preferred_name eq files[j] then continue


		conflict = file_test(use_path + preferred_name)
		if conflict eq 1 then begin
			conflicts = [conflicts, output_path + preferred_name]
			if conflict_action eq 'write_copy' then preferred_name += '.COPY'
			if conflict_action eq 'skip' then continue
		endif

		file_mkdir, use_path
		file_copy, files[j], use_path + preferred_name, /verbose
		if move_renamed_to ne '' and move_renamed_to ne search_path then begin
			file_mkdir, move_path
			file_move, files[j], move_path + file_basename(files[j])
		endif

		null_file:
		wait, 0.0001
	endfor

end