
;\\ Davis real time analysis log file writer

function DRTA_write_to_log_file, filename, text, write_header=write_header, widget_id

	openw, handle, filename, /get_lun, /append

		if keyword_set(write_header) then begin
			printf, handle, write_header
			printf, handle
		endif else begin
			printf, handle, 'Time (UT): ' + systime(/ut) + ' | LOG: ' + text
		endelse

	close, handle
	free_lun, handle

	;\\ Write to the widget
	widget_control, set_value = 'Status: ' + text, widget_id

return, 1

end