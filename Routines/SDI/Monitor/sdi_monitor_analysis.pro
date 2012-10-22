
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
		for ii = 0, n_elements(list) - 2 do begin
			parts = strsplit(list[ii], ',', /extract)
			sent_sum = parts[1]
			received_sum = get_md5_checksum('c:\FTP\instrument_incomming\' + parts[0], exe = 'c:\rsi\gitsdi\bin\md5sums')
			if (sent_sum ne received_sum) then begin
				if not keyword_set(ignore_checksum) then goto, SKIP_FILE
			endif
		endfor

		;\\ If we got to here, everything is OK, so create a job for these files
		site_code = strmid(file_basename(in_files[i]),0,3)
		for ii = 0, n_elements(list) - 2 do begin
			parts = strsplit(list[ii], ',', /extract)
			res = execute('append, "' + 'c:\FTP\instrument_incomming\' + parts[0] + '", ' + site_code + '_files')
		end
		append, site_code, site_codes

		SKIP_FILE:
	endfor

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

		sdi_analysis, '', skylist = files_arr, move_to = move_to_dir, files_processed = processed

		openw, handle, 'c:\ftp\instrument_incomming\_processed.txt', /get, /append
		for ff = 0, n_elements(processed) - 1 do printf, handle, strupcase(file_basename(processed[ff]))
		close, handle
		free_lun, handle

	endfor

end