
@sdi3k_read_netcdf_data

pro sdi_analysis, directory, $
				  filter = filter, $
				  plot_to = plot_to, $
				  move_to = move_to, $
				  only_zones = only_zones, $
				  skylist = skylist, $
				  files_processed = files_processed, $
				  speks=speks, $
				  winds=winds, $
				  plots=plots, $
				  ascii=ascii

	if keyword_set(plot_to) then plot_dir = plot_to else plot_dir = 'c:\users\sdi\sdiplots\'

	if keyword_set(skylist) then begin
		sky_list = skylist
		nsky = n_elements(skylist)
		directory = file_dirname(sky_list[0])
		las_list = file_search(directory + '\*CAL*', count = nlas)
	endif else begin
		if not keyword_set(filter) then begin
			las_list = file_search(directory + '*CAL*', count = nlas)
			sky_list = file_search(directory + '*SKY*', count = nsky)
		endif else begin
			las_list = file_search(directory +  '*CAL*', count = nlas)
			sky_list = file_search(directory + filter + '*SKY*', count = nsky)
		endelse
	endelse

	;\\ Should sort by file age, to do newest ones first

	;\\ Format the laser names
	las_names = strarr(nlas)
	for k = 0, nlas - 1 do begin

		fname = file_basename(las_list[k])

		;\\ Replace spaces with underscores
			byte_name = byte(fname)
			pts = where(byte_name eq byte(' '), npts)
			if npts gt 0 then byte_name[pts] = byte('_')
			fname = string(byte_name)

		las_names[k] = fname
	endfor


	;\\ If there are no skies, just fit the lasers
	if keyword_set(speks) then begin
		if nsky eq 0 then begin
			for k = 0, nlas - 1 do begin
				fname = las_list[k]
				sdi_fit_spectra, fit_insfile = fname, ipc_info = ipc_info
				append, fname, files_done
			endfor
		endif
	endif


	;\\ Else fit the lasers when we fit the corresponding skies
	for k = 0, nsky - 1 do begin

		fname = file_basename(sky_list[k])

		;\\ Replace spaces with underscores
			byte_name = byte(fname)
			pts = where(byte_name eq byte(' '), npts)
			if npts gt 0 then byte_name[pts] = byte('_')
			fname = string(byte_name)

		;\\ Match up a laser calibration file for this sky file
			split = strsplit(strlowcase(fname), '_', /extract)

		;\\ Find best laser match
			match = intarr(nlas)
			for j = 0, nlas - 1 do begin
				cmp = las_names[j]
				cmp_split = strsplit(strlowcase(cmp), '_', /extract)
				for n = 0, n_elements(split) - 1 do begin
					;match[j] += strmatch(cmp, '*' + split[n] + '*', /fold)
					match[j] += cmp_split[n] eq split[n] ;\\ names must have same number of fields
				endfor
				if cmp_split[0] ne split[0] then match[j] = 0
			endfor
			best_match = where(match eq max(match), n_best)
			if n_best gt 1 then stop	;\\ HMMM?

			use_laser = las_list[best_match[0]]

			print, fname, las_names[best_match[0]]

			if keyword_set(speks) then sdi_fit_spectra, fit_insfile = use_laser, ipc_info = ipc_info
			append, use_laser, files_done

			if keyword_set(speks) then sdi_fit_spectra, fit_skyfile = sky_list[k], use_insfile = use_laser, ipc_info = ipc_info
			append, sky_list[k], files_done

			setenv, 'SDI_GREEN_ZERO_VELOCITY_FILE=AUTO'
    		setenv, 'SDI_RED_ZERO_VELOCITY_FILE=AUTO'
    		setenv, 'SDI_OH_ZERO_VELOCITY_FILE=AUTO'
			if keyword_set(winds) then sdi3k_batch_windfitz, sky_list[k], /auto_flat

			if keyword_set(plots) then begin
				sdi3k_batch_plotz, sky_list[k], $
								   skip_existing = 0, $
								   stage = 0, $
								   drift_mode = 'data', $
								   xy_only = 0, $
								   root_dir = plot_dir, $
								   /msis2000, $
								   /hwm07
			endif


			if keyword_set(ascii) then begin

				sdi3k_read_netcdf_data, sky_list[k], meta=mm
				if size(mm, /type) eq 8 then begin
			       	year      = strcompress(string(fix(mm.year)),             /remove_all)
			       	lamstring = strcompress(string(fix(10*mm.wavelength_nm)), /remove_all)
			       	scode     = strcompress(mm.site_code, /remove_all)
			       	if strupcase(scode) eq 'PF' then scode = 'PKR'
			       	md_err = 0
			       	catch, md_err
			       	if md_err ne 0 then goto, keep_going
			       	folder = plot_dir + year + '_' + scode + '_' + lamstring + '\' + 'ASCII_Data' + '\'
			       	if !version.release ne '5.2' then file_mkdir, folder else spawn, 'mkdir ' + folder

				keep_going:
			       	catch, /cancel

			       	stp = {export_allsky: 1, $
			         	   export_skymaps: 1, $
			           	   export_spectra: 0, $
			           	   export_wind_gradients: 0, $
			           	   apply_smoothing: 1, $
			           	   time_smoothing: 1.1, $
			           	   space_smoothing: 0.09}

			    	sdi3k_ascii_export, setup = stp, files = sky_list[k], outpath = folder

			    endif
		    endif

			wait, 0.01
	endfor

	;\\ File move error handler
	catch, error_status
	if error_status ne 0 then goto, SKIP_MOVE

	base_dir = file_dirname(files_done[0])
	files_done = file_basename(files_done)
	u = files_done(sort(files_done))
	files_done = u[uniq(u)]

	if keyword_set(move_to) then begin
		for i = 0, n_elements(files_done) - 1 do begin
			file_move, base_dir + '\' + files_done[i], move_to + '\' + files_done[i]
		endfor
	endif

	files_processed = files_done

	SKIP_MOVE:
	catch, /cancel

end