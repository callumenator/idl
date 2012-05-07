
function asc_asc_filename, type, extra=extra, filter_name_override=filter_name_override

	COMMON ASC_Control, info, gui, log

	;\\ extra = {date:strarr(3), time:strarr(4)}

	;\\ FORMAT (prepend)_FFFF_YYYYMMDD_HHMMSS.SSS.FIT

  	;\\ D:\ASCDATA\type\YYYYMMDD\FILENAME

	if size(type, /type) ne 7 then begin
		dir_string = info.data_info.base_dir
	endif else begin
		if type eq 'FITS' then dir_string = info.data_info.fits_dir + '\'
		if type eq 'JPEG' then dir_string = info.data_info.jpeg_dir + '\'
	endelse

	if not keyword_set(filter_name_override) then begin
		if info.comms.filter.current lt 0 or $
		   info.comms.filter.current gt n_elements(info.comms.filter.lookup) then begin
			filter_string = 'EMPTY'
		endif else begin
			filter_string = strmid(info.comms.filter.lookup[info.comms.filter.current], 0, 4)
			l = strlen(filter_string)
			for j = 1, 4-l do filter_string = '_' + filter_string
		endelse
	endif else begin
		filter_string = strmid(filter_name_override, 0, 4)
		l = strlen(filter_string)
		for j = 1, 4-l do filter_string = '_' + filter_string
	endelse

	date = extra.date[0] + extra.date[1] + extra.date[2]
	time = extra.time[0] + extra.time[1] + extra.time[2] + '.' + extra.time[3]

	filename = dir_string + info.data_info.prepend + '_' + filter_string + '_' + date + '_' + time

	return, filename

end
