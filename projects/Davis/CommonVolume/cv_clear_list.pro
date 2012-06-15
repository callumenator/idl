
pro cv_clear_list, transfer=transfer

	if not keyword_set(transfer) then begin
		;filenames = file_search('c:\cal\idlsource\newalaskacode\davis\commonvolume\data\clear\*', count=nfiles)
		;clear_names = file_basename(filenames)
		;save, filename='c:\cal\idlsource\newalaskacode\davis\commonvolume\clear_list.idlsave', clear_names
	endif else begin
		restore, 'c:\RSI\idlsource\newalaskacode\davis\commonvolume\clear_list.idlsave'

		;\\ Clear out the clear folder
		oldclear = file_search('c:\RSI\idlsource\newalaskacode\davis\commonvolume\data\clear\*', count=nfiles)
		if nfiles gt 0 then file_delete, oldclear

		;\\ Transfer
		alldata = file_search('c:\RSI\idlsource\newalaskacode\davis\commonvolume\data\*', count=nfiles)
		all_names = file_basename(alldata)
		for k = 0, nfiles - 1 do begin
			match = where(clear_names eq all_names[k], n_match)
			if n_match eq 1 then file_copy, alldata[k], 'c:\RSI\idlsource\newalaskacode\davis\commonvolume\data\clear\' + all_names[k]
		endfor
	endelse

end