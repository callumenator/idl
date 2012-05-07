
@DCAI_script_utilities

pro DCAI_script_debug, schedule_name, $					;\\ Name of the script (just the function name, no .pro) to debug
					  day_number = day_number, $	;\\ Day number (defualts to todays date)
					  yymmdd = yymmdd, $			;\\ YYMMDD date as a string (defaults to todays date)
					  latitude = latitude, $		;\\ Geographic latitude (defaults to Poker Flat)
					  longitude = longitude			;\\ Geographic longitude (defaults to Poker Flat)

	common DCAI_Control, info, gui

	;\\ If schedule was left out, prompt for one
	if size(schedule_name, /type) eq 0 then schedule_name = ''

	if schedule_name eq '' then begin
		fname = dialog_pickfile(/read, title = 'Select Schedule Script' )
		script_name = file_basename(strcompress(fname, /remove_all))
		spl = strsplit(script_name, '.', /extract)
		script_name = spl[0]
	endif

	;\\ Try to compile the selected schedule
	res = execute('resolve_routine, /is_function, "' + script_name + '"')
	if res ne 1 then begin
		print, 'Unable to compile schedule. Returning.'
		return
	endif

	;\\ By default, we assume the site location is Poker Flat, and use todays date.
	if not keyword_set(latitude) then latitude = 65.13
	if not keyword_set(longitude) then longitude = -147.48
	if not keyword_set(day_number) and not keyword_set(yymmdd) then begin
		day_number = DayOfYearUT()
		yr = Year()
	endif
	if keyword_set(yymmdd) then begin
		yr = float(strmid(yymmdd, 0, 2))
		if yr lt 50 then yr = yr + 2000 else yr = yr + 1900
		mnth = float(strmid(yymmdd, 2, 2))
		day = float(strmid(yymmdd, 4, 2))
		day_number = ymd2dn(yr, mnth, day)
	endif

	debug = {running:0, $
			 day_number:day_number, $
			 local_time_seconds:0.0, $
			 ut_time_seconds:0.0, $
			 errors:0, $
			 progressbar:obj_new(), $
			 time_step_seconds:60., $
			 time_string:'', $
			 time_string_ut:''}

	site_info = {geo_lat:latitude, geo_lon:longitude}

	Andor_Camera_Driver, '', 'uGetSettingsStructure', 0, settings, result
	settings.initialized = 1

	info = {site_info:site_info, $
			debug:debug, $
			camera_settings:settings, $
			image:ptr_new(/alloc), $
			external_dll:'SDI_External.dll', $
			schedule_script:script_name, $
			current_command_index:0, $
			current_queue:ptr_new(/alloc), $
			current_command:''}

		gui = {log:0}
		dbg_log_entry = {sun_angle:0.0, local_secs:0.0, ut_secs:0.0, log_string:''}

		info.debug.running = 1
		info.current_command_index = -1
		dbg_log = [dbg_log_entry]
		dbg_sub_log = ''
		dbg_sub_log_last = ''

	info.debug.progressBar = Obj_New("SHOWPROGRESS", message='Percent Completion', title='Script Debug')
	info.debug.progressBar->Start

	while info.debug.running eq 1 do begin

		info.debug.progressbar->update, 100.* (info.debug.ut_time_seconds/(24.*3600))

		js = ydns2js(2010, info.debug.day_number, info.debug.ut_time_seconds + 3600.*info.site_info.geo_lon/15.)
		info.debug.time_string = dt_tm_fromjs(js, format='w$ n$ 0d$ h$:m$:s$ Y$')
		js_ut = ydns2js(2010, info.debug.day_number, info.debug.ut_time_seconds)
		info.debug.time_string_ut = dt_tm_fromjs(js_ut, format="w$ n$ 0d$ h$:m$:s$ Y$")


		info.debug.ut_time_seconds += info.debug.time_step_seconds
		if info.debug.ut_time_seconds gt 24.*3600 then begin

			info.debug.progressBar->Destroy
	    	Obj_Destroy, info.debug.progressBar

			if (info.debug.errors gt 0) then begin
				Result = dialog_message(string(info.debug.errors, f='(i0)') + ' errors were encoutered.', /error)
				for dbg_i = 0, n_elements(dbg_log) - 1 do print, dbg_log[dbg_i]
			endif else begin
				Result = dialog_message('No errors were encountered.', /info)
			endelse

			;\\ Stop debugging
				info.debug.errors = 0
				info.debug.running = 0
				info.debug.day_number = 1
				info.debug.local_time_seconds = 0
				info.debug.ut_time_seconds = 0
				info.debug.time_string = ''
				info.debug.time_string_ut = ''

			;\\ Plot the results from the dbg_log
				if n_elements(dbg_log) gt 1 then begin
					DCAI_Debug_Script_Plotter, dbg_log[1:*]
				endif

			;\\ Clear the dbg log
				dbg_log = [dbg_log_entry]

			heap_gc
			return

		endif


		;\\ If the command queue is empty, get a new queue from the schedule script
		if info.current_command_index eq -1 then begin
			queue = call_function(info.schedule_script, info)
			*info.current_queue = queue
			info.current_command_index = 0

			;\\ Update the queue list widget
			;widget_control, set_value = queue, gui.queue

			if size(dbg_sub_log, /type) eq 0 then begin
				dbg_sub_log = ''
				dbg_sub_log_last = ''
			endif else begin
				new_entry = dbg_log_entry
				new_entry.sun_angle = SolarZenithAngle(info)
				new_entry.local_secs = Hour()*3600.
				new_entry.ut_secs = HourUT()*3600.

				;\\ Only update the log string if different from the last one
				if dbg_sub_log ne dbg_sub_log_last then $
					new_entry.log_string = dbg_sub_log

				dbg_log = [dbg_log, new_entry]
				dbg_sub_log_last = dbg_sub_log
				dbg_sub_log = ''
			endelse
		endif

		;\\ Command queue execution/reset
		if info.current_command_index lt n_elements(*info.current_queue) then begin
			;\\ Execute the next command in the queue
			cmd = (*info.current_queue)[info.current_command_index]
			info.current_command = cmd
			info.current_command_index ++
			DCAI_Command, cmd, errcode = errcode

			;\\ If debugging, log commands in this queue
			if info.debug.running eq 1 then begin
				dbg_sub_log += errcode + '|'
				if strlowcase(strmid(errcode, 0, 5)) eq 'error' then info.debug.errors ++
			endif
		endif else begin
			;\\ Or reset the queue if we are done with the current queue
			info.current_command_index = -1
			info.current_command = ''
		endelse

	endwhile

	heap_gc

end
