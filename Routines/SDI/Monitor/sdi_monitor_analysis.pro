
pro sdi_monitor_analysis_log, msg_string

	logName = 'c:\rsi\idl\routines\sdi\monitor\Log\' + 'AnalysisLog_' + $
				dt_tm_fromjs(dt_tm_tojs(systime()), format='Y$_doy$') + '.txt'
	openw, hnd, logName, /get, /append
	printf, hnd, systime() + ' -> ' + msg_string + string([13B,10B])
	free_lun, hnd
end

pro sdi_monitor_analysis, ignore_checksum = ignore_checksum

	;\\ Control where analyzed data are moved to
	data_directories = [{site_code:'MAW', directory:'F:\SDIData\Mawson\'}, $
						{site_code:'PKR', directory:'F:\SDIData\Poker\'}, $
						{site_code:'HRP', directory:'F:\SDIData\Gakona\'}, $
						{site_code:'TLK', directory:'F:\SDIData\Toolik\'}, $
						{site_code:'KTO', directory:'F:\SDIData\Kaktovik\'} ]

	;\\ Check to see if we can start any new jobs -- look for _incomming files
	in_files = file_search('c:\ftp\instrument_incomming\{HRP,PKR,MAW,TLK,KTO}*_incomming.txt', count = n_in)

	for i = 0, n_in - 1 do begin
		lines = file_lines(in_files[i])
		if lines eq 0 then continue

		list = strarr(lines)
		openr, handle, in_files[i], /get
		readf, handle, list
		close, handle
		free_lun, handle

		;\\ First make sure ENDOFFILE is present
		if (list[n_elements(list)-1] ne 'ENDOFFILE') then continue
		if (n_elements(list) eq 1) then continue ;\\ no file names

		;\\ Now make sure all checksums match
		do_files = 0
		do_file_count = 0
		for ii = 0, n_elements(list) - 2 do begin
			parts = strsplit(list[ii], ',', /extract)
			if file_test('c:\FTP\instrument_incomming\' + parts[0]) eq 0 then continue

			sent_sum = parts[1]
			received_sum = get_md5_checksum('c:\FTP\instrument_incomming\' + parts[0], exe = 'c:\rsi\gitsdi\bin\md5sums')
			if (not keyword_set(ignore_checksum)) and (sent_sum ne received_sum) then begin
				;\\ If it is a laser, skip all files...
				if strmatch(parts[0], '*_CAL_*') ne 0 then goto, SKIP_FILE_GROUP
				;\\ Else, simply don't append it to the do-list
			endif else begin
				append, parts[0], do_files
				do_file_count ++
			endelse
		endfor

		;\\ If we got to here, everything is OK, so create a job for these files
		if do_file_count gt 0 then begin
			site_code = strmid(file_basename(in_files[i]),0,3)
			for ii = 0, n_elements(do_files) - 1 do begin
				res = execute('append, "' + 'c:\FTP\instrument_incomming\' + do_files[ii] + '", ' + site_code + '_files')
			end
			append, site_code, site_codes
		endif

		SKIP_FILE_GROUP:
	endfor


	;\\ Grab the list of processed files
		lines = file_lines('c:\ftp\instrument_incomming\_processed.txt')
		openr, handle, 'c:\ftp\instrument_incomming\_processed.txt', /get
		if lines ne 0 then begin
			done = strarr(lines)
			readf, handle, done
		endif else begin
			done = ['']
		endelse
		close, handle
		free_lun, handle

	;\\ Run through the list of sites to analyze
	for i = 0, n_elements(site_codes) - 1 do begin

		;\\ List of sky files to analyze, call it 'files_arr'
		res = execute('files_arr = ' + site_codes[i] + '_files')

		;\\ Where to move files once analyzed
		match = where(site_code eq data_directories.site_code, nmatch)
		if (nmatch eq 0) then begin
			move_to_dir = 'F:\'
		endif else begin
			move_to_dir = data_directories[match].directory
		endelse

		sky_files = where(strmatch(files_arr, '*CAL*') eq 0, n_sky)
		if (n_sky gt 0) then begin
			sdi_analysis, '', skylist = files_arr[sky_files], move_to = move_to_dir, files_processed = processed
		endif
		;sdi_analysis, '', skylist = files_arr, files_processed = processed

		openw, handle, 'c:\ftp\instrument_incomming\_processed.txt', /get, /append
		for ff = 0, n_elements(processed) - 1 do begin
			thisFile = strupcase(file_basename(processed[ff]))
			match = where(thisFile eq done, nmatch)
			if nmatch eq 0 then printf, handle, thisFile
			sdi_monitor_analysis_log, 'Processed ' + file_basename(processed[ff])
		endfor
		close, handle
		free_lun, handle

	endfor

end