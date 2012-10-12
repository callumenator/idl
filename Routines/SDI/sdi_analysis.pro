
pro sdi_analysis_ipc_message, ipc_info, sharedVar, msg_string
	time = string(long(systime(/sec)), f='(i10)')
	msg_string = byte(time + msg_string)
	sharedVar[0] = bytarr(ipc_info.maxlength)
	sharedVar[0] = msg_string[0: n_elements(msg_string) - 1 < (ipc_info.maxlength - 1)]
end


pro sdi_analysis, directory, $
				  filter = filter, $
				  plot_to = plot_to, $
				  move_to = move_to, $
				  only_zones = only_zones, $
				  skylist = skylist, $
				  ipc_info = ipc_info ;\\ inter-process communication info

;	catch, error_status
;	if error_status ne 0 then begin
;		if keyword_set(ipc_info) then begin
;			sdi_analysis_ipc_message, ipc_info, sharedVar, 'finished'
;			sharedVar = 0
;			shmunmap, ipc_info.shmid
;		endif
;		;\\ Should log the error here
;		catch, /cancel
;		return
;	endif


	if keyword_set(ipc_info) then begin
		shmmap, ipc_info.shmid, /byte, ipc_info.maxlength
		sharedVar = shmvar(ipc_info.shmid)
		sdi_analysis_ipc_message, ipc_info, sharedVar, 'Entered SDI Analysis'
	endif

	if keyword_set(plot_to) then plot_dir = plot_to

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
			las_list = file_search(directory + filter + '*CAL*', count = nlas)
			sky_list = file_search(directory + filter + '*SKY*', count = nsky)
		endelse
	endelse


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
	if nsky eq 0 then begin
		for k = 0, nlas - 1 do begin
			fname = las_list[k]
			sdi_fit_spectra, fit_insfile = fname, only_zones = only_zones, ipc_info = ipc_info
			append, fname, files_done
		endfor
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
			split = strsplit(fname, '_', /extract)

		;\\ Find best laser match
			match = intarr(nlas)
			for j = 0, nlas - 1 do begin
				cmp = las_names[j]
				for n = 0, n_elements(split) - 1 do begin
					match[j] += strmatch(cmp, '*_' + split[n] + '_*', /fold)
				endfor
			endfor
			best_match = where(match eq max(match), n_best)
			if n_best gt 1 then stop	;\\ HMMM?

			use_laser = las_list[best_match[0]]

			print, fname, las_names[best_match[0]]

			if keyword_set(ipc_info) then $
				sdi_analysis_ipc_message, ipc_info, sharedVar, 'LASER FIT: ' + las_names[best_match[0]]

			sdi_fit_spectra, fit_insfile = use_laser, only_zones = only_zones, ipc_info = ipc_info
			append, use_laser, files_done

			if keyword_set(ipc_info) then $
				sdi_analysis_ipc_message, ipc_info, sharedVar, 'SKY FIT: ' + fname

			sdi_fit_spectra, fit_skyfile = sky_list[k], use_insfile = use_laser, only_zones = only_zones, ipc_info = ipc_info
			append, sky_list[k], files_done

			if keyword_set(ipc_info) then $
				sdi_analysis_ipc_message, ipc_info, sharedVar, 'WIND FIT: ' + fname

			sdi3k_batch_windfitz, sky_list[k]

			;\\ Marks Plotter
			sdi3k_batch_plotz, sky_list[k], $
							   skip_existing = 0, $
							   stage = 0, $
							   drift_mode = 'data', $
							   xy_only = 0

			wait, 0.01
	endfor

	;\\ FIle move error handler
	catch, error_status
	if error_status ne 0 then goto, SKIP_MOVE

	if keyword_set(move_to) then begin
		u = files_done(sort(files_done))
		files_done = u[uniq(u)]
		for i = 0, n_elements(files_done) - 1 do begin
			file_move, files_done[i], move_to + '\' + file_basename(files_done[i])
		endfor
	endif

	SKIP_MOVE:
	catch, /cancel

	if keyword_set(ipc_info) then begin
		sdi_analysis_ipc_message, ipc_info, sharedVar, 'finished'
		sharedVar = 0
		shmunmap, ipc_info.shmid
	endif

end