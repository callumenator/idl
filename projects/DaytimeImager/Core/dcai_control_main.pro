

@DCAI_script_utilities
@DCAI_LoadCameraSetting



;\\ START/STOP THE CURRENT SCRIPT
pro DCAI_Control_ScriptStartStop, do_start=do_start, do_stop=do_stop

  	COMMON DCAI_Control, dcai_global

	;\\ START SCRIPT EXECUTION
	if dcai_global.info.gui_stop eq 1 and dcai_global.info.schedule_script ne '' then begin
		dcai_global.info.gui_stop = 0
	    widget_control, set_value = 'Stop Script Exec.', dcai_global.gui.start_stop_button
	endif else begin
	;\\ STOP SCRIPT EXECUTION
	    dcai_global.info.gui_stop = 1
	    dcai_global.info.current_command_index = -1
	    widget_control, set_value = 'Start Script Exec.', dcai_global.gui.start_stop_button
	endelse

  	if keyword_set(do_start) then begin
	    dcai_global.info.gui_stop = 0
	    widget_control, set_value = 'Stop Script Exec.', dcai_global.gui.start_stop_button
	endif
	if keyword_set(do_stop) then begin
	    dcai_global.info.gui_stop = 1
	    dcai_global.info.current_command_index = -1
	    widget_control, set_value = 'Start Script Exec.', dcai_global.gui.start_stop_button
	endif

end


;\\ CALLBACK FOR THE CAMERA DRIVER GUI TO UPDATE SETTINGS WHEN CLOSED
pro DCAI_Control_Driver_Callback, settings

	COMMON DCAI_Control, dcai_global

	dcai_global.info.camera_settings = settings
	DCAI_Log, 'Driver updated camera settings.'

	;\\ UPDATE ANY SETTINGS THAT NEED TO BE READ BACK FROM THE CAMERA
  	DCAI_LoadCameraSetting_Readback,/hsSpeed, /vsSpeed, /exposureTime, $
                                  	/readMode, /acqMode, /triggerMode, $
                                  	/emGain
end



;\\ MAKE SURE WE HAVE A LOG FILE FOR THE CURRENT DAY
pro DCAI_Control_LogCreate

  	COMMON DCAI_Control, dcai_global

 	log_filename = dcai_global.settings.paths.log + 'DCAILog_' + DateStringUT_YYYYMMDD_Nosep() + '.txt'

	if (dcai_global.log.log_filename eq '') then begin
  		;\\ CURRENTLY THERE IS NO LOG FILE OPEN, SO OPEN ONE
    	openw, log_handle, log_filename, /get_lun, /append
      	dcai_global.log.file_handle = log_handle
      	dcai_global.log.log_filename = log_filename
  	endif else begin
    	if (dcai_global.log.log_filename ne log_filename) then begin
    		;\\ WE NEED TO OPEN A NEW LOG FILE
    	  	close, dcai_global.log.file_handle
    	  	free_lun, dcai_global.log.file_handle
    	  	openw, log_handle, log_filename, /get_lun, /append
    	  	dcai_global.log.file_handle = log_handle
    	  	dcai_global.log.log_filename = log_filename
    	endif
  	endelse
end


;\\ REGISTER A PLUGIN FOR FRAME OR TIMER EVENTS (OR MAYBE BOTH), AND REALIZE ITS WIDGETS
pro DCAI_Control_RegisterPlugin, widget_id, objectRef, $
							     timer=timer, frame=frame

	COMMON DCAI_Control, dcai_global

	;\\ PLUGIN WANTS TO RECEIVE TIMER EVENTS
	if keyword_set(timer) then begin
		if size(*dcai_global.info.timer_list, /n_dimensions) eq 0 then begin
			*dcai_global.info.timer_list = [objectRef]
		endif else begin
			*dcai_global.info.timer_list = [*dcai_global.info.timer_list, objectRef]
		endelse
	endif

	;\\ PLUGIN WANTS TO RECEIVE FRAME EVENTS
	if keyword_set(frame) then begin
		if size(*dcai_global.info.frame_list, /n_dimensions) eq 0 then begin
			*dcai_global.info.frame_list = [objectRef]
		endif else begin
			*dcai_global.info.frame_list = [*dcai_global.info.frame_list, objectRef]
		endelse
	endif

	;\\ REALIZE THE WIDGET
	widget_control, /realize, widget_id

	xmanager, 'DCAI_Control_Main', $
			  widget_id, $
			  event_handler = 'DCAI_Control_Event', $
			  cleanup 		= 'DCAI_Control_Cleanup', $
			  /no_block
end


;\\ LOAD A SETTINGS FILE (ACTUALLY, WE USE A SETTINGS PROCEDURE TO FILL-UP A STRUCTURE)
pro DCAI_Control_LoadSettings, filename = filename

	COMMON DCAI_Control, dcai_global

	settings = dcai_global.settings

	if not keyword_set(filename) then begin
		filename = dialog_pickfile(title='Read Settings From...', $
							file = file_basename(dcai_global.info.settings_file), $
							path = file_dirname(dcai_global.info.settings_file))
		if filename eq '' then return
	endif

	script_name = file_basename(strcompress(filename, /remove_all))
	spl = strsplit(script_name, '.', /extract)
	script_name = spl[0]

	res = execute('resolve_routine, "' + script_name + '"')
	if res eq 1 then begin
		call_procedure, script_name, settings = settings
		dcai_global.settings = settings
		dcai_global.info.settings_file = filename
		DCAI_Log, 'Loaded settings: ' + script_name
	endif else begin
		DCAI_Log, 'Unable to load settings: ' + script_name
	endelse
end


;\\ SAVE THE CURRENT SETTINGS
pro DCAI_Control_SaveSettings, filename=filename
	COMMON DCAI_Control, dcai_global

	if not keyword_set(filename) then begin
		filename = dcai_global.info.settings_file
	endif

	DCAI_SettingsWrite, dcai_global.settings, filename
	DCAI_Log, 'Wrote Settings: ' + filename
end


;\\ SAVE AND RESTORE PERSISTENT DATA, LIKE PHASEMAPS, ETC
pro DCAI_Control_Persistent, save=save, load=load
	COMMON DCAI_Control, dcai_global

	filename = dcai_global.settings.paths.persistent + 'Data.idlsave'

	if keyword_set(save) then begin

		;\\ SAVE PHASEMAP DATA
		image_dims = size(*dcai_global.info.image, /dimensions)
		pmap_dims = n_elements(dcai_global.info.phasemap)
		pmap_data = fltarr(pmap_dims, image_dims[0], image_dims[1])
		pmaps_acquired = intarr(n_elements(dcai_global.info.phasemap))

		for k = 0, n_elements(dcai_global.info.phasemap) - 1 do begin
			if size(*dcai_global.info.phasemap[k], /type) ne 0 then begin
				pmap_data[k,*,*] = *dcai_global.info.phasemap[k]
				pmaps_acquired[k] = 1
			endif
		endfor

		persistent_data = {phasemaps:pmap_data, $
						   phasemaps_acquired:pmaps_acquired, $
						   phasemap_systimes:dcai_global.info.phasemap_systime}


		;\\ SAVE CENTER WAVELENGTH DATA
		persistent_data = create_struct(persistent_data, 'center_wavelength', dcai_global.scan.center_wavelength)

		save, filename=filename, persistent_data

	endif	;\\ END SAVE


	if keyword_set(load) then begin

		if file_test(filename) eq 0 then return

		restore, filename

		;\\ DO WE HAVE PHASEMAP DATA?
		tag = (where(tag_names(persistent_data) eq 'PHASEMAPS', tag_yn))[0]
		if tag_yn eq 1 then begin
			;\\ ONLY ATTEMPT TO RESTORE IF BOTH CURRENT AND SAVED SETTINGS INDICATE
			;\\ SAME NUMBER OF ETALONS, AND SAME IMAGE SIZE
			n_dims = size(persistent_data.phasemaps, /n_dimensions)
			if n_dims eq 3 then begin

				dims = size(persistent_data.phasemaps, /dimensions)
				image_dims = size(*dcai_global.info.image, /dimensions)

				if dims[0] eq n_elements(dcai_global.info.phasemap) and $
				   dims[1] eq image_dims[0] and $
				   dims[2] eq image_dims[1] then begin

					for k = 0, n_elements(dcai_global.info.phasemap) - 1 do begin
						if persistent_data.phasemaps_acquired[k] eq 1 then begin
							*dcai_global.info.phasemap[k] = reform(persistent_data.phasemaps[k,*,*])
						endif
					endfor	;\\ loop over etalons

				endif	;\\ if dims
			endif	;\\ if n_dims

			tag = (where(tag_names(persistent_data) eq 'PHASEMAP_SYSTIMES', tag_yn))[0]
			if tag_yn eq 1 then begin
				if n_elements(persistent_data.phasemap_systimes) eq $
					n_elements(dcai_global.info.phasemap_systime) then $
						dcai_global.info.phasemap_systime = persistent_data.phasemap_systimes
			endif

		endif ;\\ if have phasemaps

		;\\ DO WE HAVE CENTER WAVELENGTH DATA?
		tag = (where(tag_names(persistent_data) eq 'CENTER_WAVELENGTH', tag_yn))[0]
		if tag_yn eq 1 then begin
			if size(persistent_data.center_wavelength, /type) eq 8 then begin
				template = reform(dcai_global.scan.center_wavelength[0,0])
				dims = size(dcai_global.scan.center_wavelength, /dimensions)
				for x = 0, dims[0] - 1 do begin
				for y = 0, dims[1] - 1 do begin
					struct_assign, persistent_data.center_wavelength[x,y], template
					dcai_global.scan.center_wavelength[x,y] = template
				endfor
				endfor
			endif
		endif



	endif	;\\ END LOAD
end



;\\ DCAI control program entry point. Should be called with the following arguments:
;\\
;\\ External_dll = the dll containing wrapped camera calls, etc
;\\
;\\ Camera_profile = the initial set of camera settings to upload to the camera.
;\\
;\\ Drivers [optional] = idl pro file containing code to actually talk to hardware
;\\						 (defaults to a null driver, which does nothing)
;\\
;\\ Schedule [optional] = a file containing a schedule script.
;\\
pro DCAI_Control_Main, external_dll, $
					   camera_profile, $
					   drivers=drivers, $
					   schedule_script=schedule_script, $
					   simulate_frames=simulate_frames, $
					   settings_file=settings_file


	COMMON DCAI_Control, dcai_global

	if not keyword_set(settings_file) then settings_file = 'dcai_settings.pro'

	;PROFILER

	if not keyword_set(drivers) then drivers = 'DCAI_NullDrivers'
	if not keyword_set(schedule_script) then schedule_script = ''
	if file_basename(settings_file) eq '.' then settings_file = (routine_info(settings_file, /source)).path

	;\\ GRAB A DUMMY CAMERA SETTINGS STRUCTURE
		Andor_Camera_Driver, camera_dll, 'uGetSettingsStructure', 0, cam_settings, result

	;\\ CONSOLIDATE ALL THE INFO
		info = { drivers:drivers, $					;\\ Hardware driver code
				 schedule_script:schedule_script, $ ;\\ Current schedule script
				 settings_file:settings_file, $ 	;\\ Name of the current settings file
				 camera_profile:camera_profile, $ 	;\\ The camera settings to use on startup
				 camera_caps:ptr_new(/alloc), $ 	;\\ Structure of camera capabilities, returned by the driver
				 camera_settings:cam_settings, $ 	;\\ Structure of camera settings, returned by the driver

				 cam_driver_base:0L, $ 		;\\ Widget ID into which the camera driver gui is embedded
				 gui_stop:0, $ 				;\\ Flag to indicate that script is not being executed
				 gui_closed:0, $ 			;\\ Flag to indicate that the main console gui is closed
				 timer_tick_interval:0.1, $ ;\\ Interval between IDL timer ticks, which drive everything
				 info_update_ticks:0, $ 	;\\ Number of timer ticks before the info list is updated
				 timer_ticks:0, $ 			;\\ Track all timer ticks
				 run:1, $ 					;\\ Flag to indicate that we are running

				 image:ptr_new(/alloc), $ 		;\\ Most recently acquired processed image
				 raw_image:ptr_new(/alloc), $ 	;\\ Most recently acquired raw image
				 image_systime:0D, $			;\\ systime(/sec) at which image was acquired
				 frame_rate:0D, $, 				;\\ Frame rate
				 phasemap:[ptr_new(/alloc), ptr_new(/alloc)], $ ;\\ Phasemap, one for each etalon, one for both etalons
				 phasemap_systime:[0D, 0D, 0D], $ ;\\ systime(/sec) at which phasemap was acquired, for each etalon

				 plugins:ptr_new(/alloc), $ 	;\\ Array of object references, one for each plugin
				 timer_list:ptr_new(/alloc), $ 	;\\ Array of objects requiring timer events
				 frame_list:ptr_new(/alloc), $ 	;\\ Array of objects requiring frame events
				 active_plugin:{object:obj_new(), uid:''}, $ ;\\ Field containing information on the currently active plugin, if any

				 current_queue:ptr_new(/alloc), $ 	;\\ The current command queue
				 current_command:'', $ 				;\\ The current command
				 current_command_index:-1, $ 		;\\ The current index into the command queue

				 ;\\ Debug info
				 debug:{running:0, day_number:258, $
				 		local_time_seconds:0.0, $
				 		errors:0, $
				 		progressbar:obj_new(), $
				 		time_step_seconds:60., $
				 		time_string:'', $
				 		time_string_ut:''}, $

				 simulate_frames:keyword_set(simulate_frames) $
			  }


			scan = {type:'', $ 				;\\ String indicating the type of scan we are currently performing
					wavelength_nm:0.0, $	;\\ Scan wavelength in nm
				 	scanning:[0,0], $ 		;\\ Flag to indicate whether the etalon is being scanned (1) paused (2) not scanned (0) for each etalon
				 	scanner:[obj_new(), obj_new()], $ ;\\ Object ref of the caller
				 	started_at:[0L,0L], $ 	;\\ Timer-tick at which a scan was started, for channel/image book-keeping
				 	channel:[-1,-1], $ 		;\\ The current scan channel, or -1 if not scanning, for both etalons
				 	offset:lonarr(2), $ 	;\\ Start nominal voltages for each etalon
				 	n_channels:[-1,-1], $ 	;\\ The current number of scan channels, set by the object which initiated the scan
				 	step_size:[0L,0L], $ 	;\\ For normal scans, this will be the scaled steps_per_order, for manual scans it is
											;\\ set manually
				 	center_wavelength:replicate({view_wavelength_nm:0.0, center_wavelength_nm:0.0, $
				 								 home_voltage:0L, fsr:0.0, center:[0,0]}, 2, 10) $

				 	}

			log = {entries:strarr(1000), $
				   n_entries:0, $
				   max_entries:100, $
				   log_filename:'', $
				   file_handle:0L}


		;\\ THIS IS THE MAIN HANDLE FOR ALL THE GLOBAL VARS
			dcai_global = {info:info, $
						   scan:scan, $
						   log:log, $
						   settings:DCAI_SettingsTemplate() }


  	;\\ IF NO SCHEDULE WAS SPECIFIED, SET GUI_STOP = 1 TO PREVENT SCRIPT EXECUTION
  		if dcai_global.info.schedule_script eq '' then begin
  			dcai_global.info.gui_stop = 1
  		endif

	;\\ CREATE THE USER INTERFACE
		DCAI_InitGui, running = dcai_global.info.gui_stop
		widget_control, dcai_global.gui.script_label, set_value = 'Current Schedule: ' + schedule_script

	;\\ LOAD SETTINGS
		DCAI_Control_LoadSettings, filename = settings_file

	;\\ CREATE A LOG FILENAME BASED ON THE CURRENT UT DAY, AND OPEN IT
  		DCAI_Control_LogCreate


	;\\ FIND THE PLUGINS AND CREATE MENU ENTRIES FOR THEM
		list = file_search(dcai_global.settings.paths.plugin_base + '*__define.pro', count = n_plugins)
		plugin_menu = widget_button(dcai_global.gui.menu, value = 'Plugins')
		for p = 0, n_plugins - 1 do begin
			str = file_basename(list[p])
			pos = strpos(str, '__define')
			name = strmid(str, 0, pos)
			plug = widget_button(plugin_menu, value = name, uval = {tag:'plugin', plugin:name})
		endfor

	;\\ PASS EVENT HANDLING OVER TO XMANAGER
		xmanager, 'DCAI_Control_Main', $
				  dcai_global.gui.base, $
				  event_handler = 'DCAI_Control_Event', $
				  cleanup 		= 'DCAI_Control_Cleanup', $
				  /no_block

	;\\ INITIALIZE THE HARDWARE
		DCAI_Hardware, /init

	;\\ RESTORE PERSISTENT DATA HERE (BY NOW WE KNOW THE CAMERA IMAGE DIMENSIONS)
		DCAI_Control_Persistent, /load

end


