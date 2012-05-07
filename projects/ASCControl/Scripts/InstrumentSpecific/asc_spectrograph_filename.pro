
function asc_spectrograph_filename, sub_dir

	COMMON ASC_Control, info, gui, log

	;\\ FORMAT (prepend)_YYYYMMDD_HHMMSS.SSS.FIT

	if size(sub_dir, /type) ne 7 then begin
		dir_string = info.data_info.base_dir
	endif else begin
		dir_string = info.data_info.base_dir + sub_dir + '\'
	endelse

	sec = string( (systime(/sec) mod 1) * 1000, f='(i03)')
	time_string = dt_tm_fromjs(dt_tm_tojs(_systime(/ut)), format='Y$0n$d$_h$m$s$', decimal = 3) + '.' + sec
	filename = dir_string + info.data_info.prepend + '_' + time_string

	return, filename

end