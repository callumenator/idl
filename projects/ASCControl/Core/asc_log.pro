
pro ASC_Log, in_string

	COMMON ASC_Control, info, gui, log

	if widget_info(gui.log, /valid_id) eq 0 then return

	log_string = systime() + '>> ' + in_string

	if log.n_entries lt log.max_entries then begin
		widget_control, set_value = log_string, gui.log, /append
		widget_control, set_text_top_line = (log.n_entries - 5) > 0, gui.log
		log.n_entries ++
	endif else begin
		widget_control, get_value = curr_log, gui.log
		log.n_entries -= 50
		widget_control, set_value = curr_log[50:*], gui.log
		widget_control, set_value = log_string, gui.log, /append
		widget_control, set_text_top_line = (log.n_entries - 10) > 0, gui.log
		log.n_entries ++
	endelse
	
	;\\ Output to the log file
	if (log.file_handle ne 0) then begin
	  printf, log.file_handle, log_string
	endif

end