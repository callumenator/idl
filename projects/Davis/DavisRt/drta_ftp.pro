

pro drta_ftp, save_path, transfer_path, log_path

	filename = log_path + 'ftp_log.txt'

	if file_test(log_path + 'ftp_files.dat') then begin
		restore, log_path + 'ftp_files.dat'
	endif else begin
		files_sent = ''
	endelse

	;\\ Get file list
	list = file_search(save_path, '*', count = nfiles)

		openw, f, filename, /get, /append
		printf, f
		printf, f, systime() + ' - Found: ' + string(nfiles, f='(i0)') + ' in ' + save_path
		close, f
		free_lun, f

	;\\ Only move two files into transfer folder
	moved = 0

	for n = 0, nfiles - 1 do begin

		if moved gt 1 then break

		sent = where(files_sent eq file_basename(list(n)), sentyn)

		if sentyn gt 0 then goto, DRTA_FTP_SKIP

			;\\ Check to see if the file is old enough (ie not still being analysed)
			restore, list(n)
			last_sky_js = sky[nsky-1].time_done
			current_js = dt_tm_tojs(systime())
			delta_t = (current_js - last_sky_js)/(3600.*24.)

			;\\ If not more than two days old, skip
			if delta_t lt 2 then goto, DRTA_FTP_SKIP

			file_copy, list(n), transfer_path + file_basename(list(n))

			moved ++
			files_sent = [files_sent, file_basename(list(n))]
			save, filename = log_path + 'ftp_files.dat', files_sent

		openw, f, filename, /get, /append
		printf, f, systime() + ' - Moved: ' + file_basename(list(n)) + ' to ' + transfer_path
		close, f
		free_lun, f

	DRTA_FTP_SKIP:
	endfor

		openw, f, filename, /get, /append
		printf, f, systime() + ' - Moved: ' + string(moved, f='(i0)') + ' files'
		close, f
		free_lun, f

	if moved ne 0 then begin

		spawn, 'ftp -i -s:d:\drta\transfer.txt', res, err

		openw, f, filename, /get, /append
		printf, f, systime() + ' - Ran transfer script:'
		printf, f, 'Result:'
		printf, f, res
		printf, f, 'Error:'
		printf, f, err
		close, f
		free_lun, f

	endif


end