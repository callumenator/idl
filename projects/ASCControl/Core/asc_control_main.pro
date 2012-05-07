
;\\ This file includes a list of useful wrapped functions, (mostly) for use in scripts
	@asc_script_utilities


;\\ Event handler for the ASC gui
pro ASC_Control_Event, event

	COMMON ASC_Control, info, gui, log

	COMMON ASC_Debug, dbg_log_entry, dbg_log, dbg_sub_log, dbg_sub_log_last

	dbg_log_entry = {sun_angle:0.0, local_secs:0.0, log_string:''}


	;\\ Check for timer event.
	if tag_names(event, /structure_name) eq 'WIDGET_TIMER' then begin

		;\\ Init the next timer tick
		widget_control, gui.base, timer = info.timer_tick_interval

		;\\ Show frames if option is selected
		ASC_Control_ShowImage

		;\\ Enter the main control loop
		if info.run eq 1 then begin

		  ;\\ Check to see if we need to update the info section of the gui
		  info.info_update_ticks ++
		  if info.info_update_ticks mod 30 eq 0 then begin
		    info.info_update_ticks = 0
		    info_list = ['UT Time: ' + HourUtHHMMSS(), $
		                 'Solar Zenith Angle: ' + SolarZenithAngleStr(info), $
		                 'Camera Temperature: ' + string(CameraTemperature(info), f='(f0.3)')]
		    widget_control, set_value = info_list, gui.info

		    ;\\ Also check here to see if we need a new log file
		    ASC_Control_LogCreate

		    ;\\ And check to see if we need to load a new script
		    ASC_Control_LoadScript  
		    
		    ;\\ And check for free disk space
		    if (info.last_disk_check eq 0 or $  
		       (systime(/sec) - info.last_disk_check)/(86400.) gt 1) and $
		       (HourUT() gt 19 and HourUT() lt 24) then begin
          info.last_disk_check = systime(/sec)          
          disk = (strsplit(info.data_info.base_dir, path_sep(), /extract))[0] + path_sep()
          free_space = FreeDiskSpace(disk, /gb)
          if free_space lt 5 then begin
            asc_email_alert, subject='All-sky camera control disk alert', $
                             body='Disk space on drive ' + disk + ' is less than 5 Gb.'
          endif 
        endif
        
		  endif

			;\\ If in debugging mode, we simulate time passing
			if info.debug.running eq 1 then begin

				info.debug.progressbar->update, 100.* (info.debug.local_time_seconds/(24.*3600))

				js = ydns2js(2010, info.debug.day_number, info.debug.local_time_seconds)
				info.debug.time_string = dt_tm_fromjs(js, format='w$ n$ 0d$ h$:m$:s$ Y$')
				js_ut = ydns2js(2010, info.debug.day_number, info.debug.local_time_seconds - 3600.*info.site_info.geo_lon/15.)
				info.debug.time_string_ut = dt_tm_fromjs(js_ut, format="w$ n$ 0d$ h$:m$:s$ Y$")

				info.debug.local_time_seconds += info.debug.time_step_seconds
				if info.debug.local_time_seconds gt 24.*3600 then begin

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
						info.debug.time_string = ''
						info.debug.time_string_ut = ''

					;\\ Plot the results from the dbg_log
						if n_elements(dbg_log) gt 1 then begin
							ASC_Debug_Script_Plotter, dbg_log[1:*]
						endif

					;\\ Clear the dbg log
						dbg_log = [dbg_log_entry]
				endif
			endif


			;\\ Only look for/execute commands if gui_stop is not set
			if (info.gui_stop ne 1 or info.debug.running eq 1) and info.schedule_script ne '' then begin

				;\\ If the command queue is empty, get a new queue from the schedule script
				if info.current_command_index eq -1 then begin
					queue = call_function(info.schedule_script, info)
					*info.current_queue = queue
					info.current_command_index = 0

					;\\ Update the queue list widget
					widget_control, set_value = queue, gui.queue

					;\\ If debugging, store command results from last queue
					if info.debug.running eq 1 then begin
						if size(dbg_sub_log, /type) eq 0 then begin
							dbg_sub_log = ''
							dbg_sub_log_last = ''
						endif else begin
							new_entry = dbg_log_entry
							new_entry.sun_angle = SolarZenithAngle(info)
							new_entry.local_secs = Hour()*3600.

							;\\ Only update the log string if different from the last one
							if dbg_sub_log ne dbg_sub_log_last then $
								new_entry.log_string = dbg_sub_log

							dbg_log = [dbg_log, new_entry]
							dbg_sub_log_last = dbg_sub_log
							dbg_sub_log = ''
						endelse
					endif

				endif

				;\\ Command queue execution/reset
				if info.current_command_index lt n_elements(*info.current_queue) then begin
				;\\ Execute the next command in the queue
					cmd = (*info.current_queue)[info.current_command_index]
					info.current_command = cmd
					info.current_command_index ++
					ASC_Command, cmd, errcode = errcode

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
			endif

		endif


	endif

	;\\ Grab the uval structure from the widget to determine what to do with its events
	widget_control, get_uval = uval, event.id
	if size(uval, /type) eq 8 then begin

		case uval.tag of

			;\\ Stop/start schedule file execution
			'stop_start_button': begin
         ASC_Control_ScriptStartStop
			end

			'debug_script_button': begin
				if info.debug.running eq 0 and info.schedule_script ne '' then begin
					info.debug.running = 1
					info.current_command_index = -1
					dbg_log = [dbg_log_entry]
					dbg_sub_log = ''
						dbg_sub_log_last = ''
					info.debug.progressBar = Obj_New("SHOWPROGRESS", message='Percent Completion', title='Script Debug')
					info.debug.progressBar->Start
				endif
			end

			'load_script_button': begin
				info.current_command_index = -1
				fname = dialog_pickfile(/read)
				script_name = file_basename(strcompress(fname, /remove_all))
				spl = strsplit(script_name, '.', /extract)
				script_name = spl[0]
				res = execute('resolve_routine, /is_function, "' + script_name + '"')
				if res eq 1 then begin
					info.schedule_script = script_name
					widget_control, gui.script_label, set_value = 'Current Schedule: ' + script_name
					ASC_Log, 'Loaded new script: ' + script_name
				endif else begin
					ASC_Log, 'Unable to load script: ' + script_name
				endelse
			end

			'reset_script_button': begin
        info.current_command_index = -1
        if (info.schedule_script ne '') then begin
          res = call_function(info.schedule_script, /reset)
        endif
      end

			'start_camera_driver': begin
				;\\ Create a base widget to embed the driver gui in
					info.cam_driver_base = widget_base(group_leader = gui.base, title = 'Camera Driver', xoff = 40, yoff = 40)
					Andor_Camera_Driver_GUI, info.external_dll, embed_in_widget = info.cam_driver_base, $
											 initial_settings = info.camera_settings, update_settings_callback = 'ASC_Control_Driver_Callback'
			end

			'show_frames': begin
				info.show_frames = event.select
			end

			'run_daily_scripts': begin
        info.run_daily_scripts = event.select
      end

			'image_scale_min': begin
				widget_control, get_value = val, event.id
				info.image_scale.imin = float(val)
			end

			'image_scale_max': begin
				widget_control, get_value = val, event.id
				info.image_scale.imax = float(val)
			end

			'command_filter': begin
				new_filt = event.index + 1
				ASC_Command, 'filter, ' + string(new_filt, f='(i0)')
			end

			'home_filter_wheel':begin
				ASC_Command, 'filter, home = 1'
			end

			'command_shutter': begin
				widget_control, get_value = states, event.id
				ASC_Command, 'shutter, position = ' + strlowcase(states[event.index])
			end

			else:
		endcase
	endif

end


;\\ Notify that gui has closed.
pro ASC_Control_GUIClosed, event

	COMMON ASC_Control, info, gui, log

	info.gui_closed = 1
	info.run = 0

	ASC_Hardware, /deinit

	;\\ Close the log file
	close, log.file_handle
	free_lun, log.file_handle
	log.log_filename = ''
	log.file_handle = 0

	;\\ CLean up the heap variables
	ptr_free, info.camera_caps
	ptr_free, info.image
	ptr_free, info.current_queue

	;PROFILER, /REPORT, data = perf
end


;\\ Start or stop the script
pro ASC_Control_ScriptStartStop, do_start=do_start, do_stop=do_stop

  COMMON ASC_Control, info, gui, log

  if info.gui_stop eq 1 and info.schedule_script ne '' then begin
    info.gui_stop = 0
    widget_control, set_value = 'Stop Script Exec.', gui.start_stop_button
  endif else begin
    info.gui_stop = 1
    info.current_command_index = -1
    widget_control, set_value = 'Start Script Exec.', gui.start_stop_button
  endelse

  if keyword_set(do_start) then begin
    info.gui_stop = 0
    widget_control, set_value = 'Stop Script Exec.', gui.start_stop_button
  endif
  if keyword_set(do_stop) then begin
    info.gui_stop = 1
    info.current_command_index = -1
    widget_control, set_value = 'Start Script Exec.', gui.start_stop_button
  endif

end


;\\ Callback for the camera driver to update settings
pro ASC_Control_Driver_Callback, settings

	COMMON ASC_Control, info, gui, log

	info.camera_settings = settings
	ASC_Log, 'Driver updated camera settings.'

	;\\ Update any values that may need to be read back from the camera
  ASC_LoadCameraSetting_Readback, /hsSpeed, /vsSpeed, /exposureTime, $
                                  /readMode, /acqMode, /triggerMode, $
                                  /emGain
end


;\\ Display a camera frame in the main window
pro ASC_Control_ShowImage

	COMMON ASC_Control, info, gui, log

	if widget_info(gui.base, /valid_id) and (info.show_frames eq 1) then begin
		loadct, 0,/silent
		wset, gui.draw1

		if size(*info.image, /n_dimensions) eq 2 then $
			tv, congrid( bytscl(*info.image, min=info.image_scale.imin, max=info.image_scale.imax), 300, 300)
	endif
end


;\\ Check to see if we need to load a new script file
pro ASC_Control_LoadScript

  COMMON ASC_Control, info, gui, log

  ;\\ If script execution is not enabled, don't check
  ;if info.gui_stop eq 1 then return

  ;\\ Or if we are not running daily scripts, return
  if info.run_daily_scripts eq 0 then return

  script_name = 'ASC_Script_' + DateStringUT_YYYYMMDD_Nosep()

  ;\\ If we are already running this script, do nothing
  if info.schedule_script eq script_name then return

  ;\\ If not, check if we tried to load this script already, and failed
  if script_name eq info.schedule_cantload_day then begin
  	;\\ We couldn't load this script, so we must be running either the default,
  	;\\ or the last good script  	
  	return
  endif

  ;\\ If the current script is not the one for this day, and we haven't already
  ;\\ tried (and failed) to load it, then load the current days' script
  ASC_Command, 'load_next_script, today=1', errcode=errcode
  ASC_Control_ScriptStartStop, /do_start

  ;\\ If the script failed to load, then flag it as such, and stick with the default
  if errcode ne 'loaded_script' then info.schedule_cantload_day = script_name $
  	else info.schedule_cantload_day = ''

end

;\\ Create a log file for the current UT day and open it for appending
pro ASC_Control_LogCreate

  COMMON ASC_Control, info, gui, log

  log_filename = 'C:\Users\allsky\ASCControl\Logs\ASCLog_' + DateStringUT_YYYYMMDD_Nosep() + '.txt'
  
  if (log.log_filename eq '') then begin
      openw, log_handle, log_filename, /get_lun, /append
      log.file_handle = log_handle
      log.log_filename = log_filename
  endif else begin
    if (log.log_filename ne log_filename) then begin
      ;\\ TIme to open a new log
      close, log.file_handle
      free_lun, log.file_handle
      openw, log_handle, log_filename, /get_lun, /append
      log.file_handle = log_handle
      log.log_filename = log_filename
    endif
  endelse
end


;\\ ASC control program entry point. Should be called with the following arguments:
;\\
;\\ External_dll = the dll containing wrapped camera calls, etc
;\\
;\\ Camera_profile = the initial set of camera settings to upload to the camera.
;\\
;\\ Filename_function - instrument specific function used to build a filename string for saved files
;\\
;\\ Site_info = a structure containing at least the following:
;\\ 			{ name:"",	- site name
;\\				  geo_lat:0.0, - site latitude
;\\				  geo_lon:0.0  - site longitude
;\\ 			}
;\\
;\\ Data_info = a structure containing at least the following:
;\\ 			{ prepend:"", - string to prepend to iamge filenames
;\\				  base_dir:"", - base data directory
;\\ 			}
;\\
;\\ Comms_info = a structure containing at least the following:
;\\ 			{ shutter_port:0,
;\\ 			  filter_port:0,
;\\ 			  filter_names: [''] - string array containing names indexed by filter number
;\\				}
;\\
;\\ Schedule = a file containing a schedule script.
;\\
pro ASC_Control_Main, external_dll, $
					  camera_profile, $
					  filename_builder, $
					  site_info, $
					  data_info, $
					  comms_info, $
					  schedule_script = schedule_script


	COMMON ASC_Control, info, gui, log

	;PROFILER

	if not keyword_set(schedule_script) then schedule_script = ''

	;\\ Fill the hardware comms structure
	comms = {shutter:{port:comms_info.shutter_port, port_opened:0, shutter_opened:0}, $
           filter: {port:comms_info.filter_port,  port_opened:0, current:-1, selected:-1, lookup:comms_info.filter_names}}

  data = {prepend:data_info.prepend, base_dir:data_info.base_dir, $
         	fits_dir:'', jpeg_dir:''}

	;\\ Dummy camera settings structure
	Andor_Camera_Driver, camera_dll, 'uGetSettingsStructure', 0, settings, result

	;\\ Keep track of control info
	info = { external_dll:external_dll, $
			 filename_function:filename_builder, $
			 schedule_script:schedule_script, $
			 schedule_cantload_day:'', $
			 camera_profile:camera_profile, $
			 site_info:site_info, $
			 data_info:data, $
			 camera_caps:ptr_new(/alloc), $
			 camera_settings:settings, $
			 cam_driver_base:0L, $
			 comms:comms, $
			 gui_stop:0, $
			 gui_closed:0, $
			 run_daily_scripts:1, $
			 timer_tick_interval:0.05, $
			 info_update_ticks:0, $
			 last_disk_check:0D, $ 
			 run:1, $
			 show_frames:0, $
			 image:ptr_new(/alloc), $
			 image_exp_start_date:strarr(3), $
			 image_exp_start_time:strarr(4), $
			 image_scale:{imin:300, imax:1500}, $
			 current_queue:ptr_new(/alloc), $
			 current_command:'', $
			 current_command_index:-1, $
			 debug:{running:0, day_number:258, local_time_seconds:0.0, errors:0, progressbar:obj_new(), $
			 		time_step_seconds:60., time_string:'', time_string_ut:''}}

  ;\\ Create a log filename based on the current UT day and open it
  log = {entries:strarr(1000), n_entries:0, max_entries:100, log_filename:'', file_handle:0L}
  ASC_Control_LogCreate

  ;\\ If we don't have a schedule script, don't try getting scheduled commands
  	if info.schedule_script eq '' then begin
  		info.gui_stop = 1
  	endif

	;\\ Create the user interface
		ASC_InitGui, running = info.gui_stop
		widget_control, gui.script_label, set_value = 'Current Schedule: ' + schedule_script
		widget_control, gui.show_frames_check, set_button = info.show_frames
		widget_control, gui.daily_scripts_check, set_button = info.run_daily_scripts
		xmanager, 'ASC_Control_Main', gui.base, event_handler = 'ASC_Control_Event', $
					cleanup = 'ASC_Control_GUIClosed', /no_block

	;\\ Initialize the hardware
		ASC_Hardware, /init

end

