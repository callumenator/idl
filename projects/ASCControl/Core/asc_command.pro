
@asc_script_utilities

;\\ If argument is a keyword (a = b) will set out equal to {name:a, value:b}
;\\ and return a 1, else will return a zero
function ASC_Command_Keyword, in_arg, out

	sub = strsplit(in_arg, '=', /extract)
	if n_elements(sub) eq 2 then begin
		out = {name:strlowcase(strcompress(sub[0], /remove)), $
			   value:strlowcase(strcompress(sub[1], /remove))}
		return, 1
	endif else begin
		out = {name:'', value:''}
		return, 0
	endelse

end

;\\ Get all the keywords for a given command
pro ASC_Command_GetArgsAndKeywords, in_args, out_args, n_args, out_keywords, n_keywords

  keywords = replicate({name:'', value:''}, n_elements(in_args))
  arguments = strarr(n_elements(in_args))
  keycount = 0
  argcount = 0
  for ai = 0, n_elements(in_args) - 1 do begin
    if (ASC_Command_Keyword(in_args[ai], out) eq 1) then begin
      keywords[keycount] = out
      keycount ++
    endif else begin
      arguments[argcount] = in_args[ai]
      argcount ++
    endelse
  endfor

  n_args = argcount
  n_keywords = keycount
  if n_args gt 0 then out_args = arguments[0:argcount-1]
  if n_keywords gt 0 then out_keywords = keywords[0:keycount-1]

end

;\\ Interpret a command read from an ASC command script queue
pro ASC_Command, in_string, errcode=errcode

	COMMON ASC_Control, info, gui

	;\\ Extract command and arguments
		substrings = strsplit(in_string, ',', /extract)
		command = strlowcase(strcompress(substrings[0], /remove_all))

  if n_elements(substrings) gt 1 then begin
    ASC_Command_GetArgsAndKeywords, substrings[1:*], args, nargs, keywords, nkeywords
  endif else begin
    nargs = 0
    nkeywords = 0
  endelse

	;\\ Process command
	dbg = info.debug.running
	errcode = 'null'

	case command of

    ;\\ Empty command string. Do nothing
		'' : begin
			errcode = 'Info: No command supplied'
			return
		end

		;\\ Create data directories for the current UT day, based on information in the
		;\\ data_info structure in asc_startup
		'init_directories':begin

		    if dbg eq 1 then return

    		;\\ Initialize data directories
        date = DateStringUT_YYYYMMDD_Nosep()

        fits_dname = info.data_info.base_dir + 'FITS\' + date
        if file_test(fits_dname, /directory) eq 0 then file_mkdir, fits_dname

        jpeg_dname = info.data_info.base_dir + 'JPEG\' + date
        if file_test(jpeg_dname, /directory) eq 0 then file_mkdir, jpeg_dname

        info.data_info.fits_dir = fits_dname
        info.data_info.jpeg_dir = jpeg_dname
		end

    ;\\ Load the next script - when called from a schedule script, this will replace the current
    ;\\ schedule script with the new one, unless the systme is unable to compile the selected script,
    ;\\ in which case it will fall back to a default script ....
    'load_next_script': begin

        if dbg eq 1 then return

        script_name = ''
        if nkeywords eq 1 then begin
          if keywords[0].name eq 'today' then begin
            ;\\ Generate the script name for the current day.
              script_name = 'ASC_Script_' + DateStringUT_YYYYMMDD_Nosep()
          endif
        endif

        if script_name eq '' then begin
          ;\\ Generate the script name for the next day.
            script_name = 'ASC_Script_' + DateString_NextUTDay_YYYYMMDD_Nosep()
        endif

        ;\\ Try to find/compile the script
        res = execute('resolve_routine, /is_function, "' + script_name + '"')

        if res eq 1 then begin
          ;\\ New script was successfully compile. Make it current.
          info.current_command_index = -1
          info.schedule_script = script_name
          widget_control, gui.script_label, set_value = 'Current Schedule: ' + script_name
          ASC_Log, 'Loaded new script: ' + script_name
          errcode = 'loaded_script'

        endif else begin
          ;\\ We were unable to compile/find the selected script. Fall back on a default.
          ASC_Log, 'Unable to load script: ' + script_name + ', falling back on default...'
          script_name = 'ASC_Script_Default'  ;\\ #### Make a default script.
          res = execute('resolve_routine, /is_function, "' + script_name + '"')

          ;\\ We should make sure the default is available, just in case.
          if res eq 1 then begin
            ;\\ New script was successfully compile. Make it current.
            info.current_command_index = -1
            info.schedule_script = script_name
            widget_control, gui.script_label, set_value = 'Current Schedule: ' + script_name
            ASC_Log, 'Loaded default script: ' + script_name
            errcode = 'loaded_default'

          endif else begin
            ;\\ The default script couldn't be found!
            ASC_Log, 'Default script not found! No new script was loaded.'
            errcode = 'loaded_none'
          endelse
        endelse

    end

		;\\ Select a filter, or home the filter wheel
		'filter' : begin

			if nkeywords eq 1 then begin
        if keywords[0].name eq 'home' then begin
				  if dbg eq 0 then HomeFilterWheel, info, errcode=errcode
					return
        endif
			endif

			if nargs eq 1 then begin

				if fix(args[0]) lt 1 or fix(args[0]) gt 6 then begin
					errcode = 'Error: Filter number ' + args[0] + ' out of range (1-6).'
				endif else begin
					if dbg eq 0 then begin
						if info.comms.filter.current ne fix(args[0]) then begin
							SelectFilter, info, fix(args[0]), errcode=filter_readback

							info.comms.filter.selected = fix(args[0])
							if fix(filter_readback) eq fix(args[0]) then begin
              			info.comms.filter.current = fix(filter_readback)
              			ASC_Log, 'Filter select: ' + args[0]

              			;\\ Update the gui
              			widget_control, set_droplist_select = info.comms.filter.current - 1, gui.filter_list
              endif else begin
								ASC_Log, 'Failed to select filter: ' + args[0] + ' Error: ' + filter_readback
							endelse
             			endif
					endif else begin
						errcode = in_string + ' - no error'
					endelse
				endelse
			endif else begin
				errcode = 'Error: No arguments supplied for command: filter, 1 argument expected'
			endelse
		end


		;\\ Control the shutter
		'shutter' : begin

		  force = 0
		  nogui = 0
			if nkeywords gt 0 then begin

				  pos = ''
				  for k = 0, nkeywords - 1 do begin
				    if keywords[k].name eq 'force' then force = keywords[k].value
				    if keywords[k].name eq 'position' then pos = keywords[k].value
				    if keywords[k].name eq 'nogui' then nogui = keywords[k].value
				  endfor

					if pos eq 'open' then begin
						if dbg eq 0 then begin
							if info.comms.shutter.shutter_opened ne 1 or force eq 1 then begin

								SetShutter, info, 'open', errcode=errcode

								if fix(errcode) eq 1 then begin
									info.comms.shutter.shutter_opened = 1
									ASC_Log, 'Opened shutter'

									;\\ Update the gui
									if nogui eq 0 then begin
									  widget_control, get_value = states, gui.shutter_list
									  ipos = (where(strlowcase(states) eq 'open'))[0]
                    widget_control, set_droplist_select = ipos, gui.shutter_list
                  endif
								endif else begin
									ASC_Log, 'Failed to open shutter! Error: ' + errcode
								endelse

							endif

						endif else  begin
							errcode = in_string + ' - no error'
						endelse
					endif

					if pos eq 'close' then begin
						if dbg eq 0 then begin
							if info.comms.shutter.shutter_opened ne 0 or force eq 1 then begin

								SetShutter, info, 'close', errcode = errcode

								if fix(errcode) eq 0 then begin
									info.comms.shutter.shutter_opened = 0
									ASC_Log, 'Closed shutter'

									;\\ Update the gui
									if nogui eq 0 then begin
									  widget_control, get_value = states, gui.shutter_list
                    ipos = (where(strlowcase(states) eq 'close'))[0]
                    widget_control, set_droplist_select = ipos, gui.shutter_list
                  endif
								endif else begin
									ASC_Log, 'Failed to close shutter! Error: ' + errcode
								endelse

							endif

						endif else  begin
							errcode = in_string + ' - no error'
						endelse
					endif

					if pos eq '' then begin
						errcode = 'Supplied argument not recognized: ' + args[0]
					endif

			endif else begin
				errcode = 'Error: No arguments supplied for command: shutter, minimum 1 keyword expected'
			endelse
		end


		;\\ Control the camera
		'camera' : begin
			if nkeywords eq 0 then begin
				errcode  = 'Error: No keywords supplied to camera command'
			endif else begin
				cmd_str = 'ASC_LoadCameraSetting, "' + info.external_dll + '", '
	    		for j = 0, nkeywords - 1 do begin
	    			cmd_str += keywords[j].name + '=' + keywords[j].value
	    			if j ne nkeywords - 1 then cmd_str += ','
	    		endfor

	    		if dbg eq 0 then begin
					res = execute(cmd_str)
					if res eq 0 then begin
						errcode = 'Error: Error executing string: ' + cmd_str
					endif else begin
						errcode = in_string + ' - no error'
						ASC_Log, 'Camera set: ' + cmd_str
					endelse
				endif else begin
					errcode = in_string + ' - no error'
				endelse
			endelse
		end


		;\\ Grab a frame from the camera. Accepts following keywords:
		;\\ numframes = n, number of frames to grab (and optionally process and save)
		;\\ process = name, the name of an idl function which takes an image and returns a processed image
		;\\ save_raw = 0, set to one to save the captured frame in a raw fits file
		;\\ save_jpeg = 0, set to one to save the captured frame in a jpeg file
		;\\ start_on_minute = 0, set to one to start the frame grab on the minute
		'grab_frame' : begin

			if info.camera_settings.initialized eq 0 then begin
				ASC_Log, 'Trying to grab frames, but camera not initialized - PROBLEM!'
				errcode = 'Error - Grabbing frames when camera not initialized'
				return
			endif

			errcode = ''

			;\\ Options
				nframes = 1
				postProcess = ''
				save_raw = 0
				save_jpeg = 0
				start_on_minute = 0
				inter_frame_delay = 0.0
				ftp_jpeg = 0

			;\\ Set options from keywords
			for k = 0, nkeywords - 1 do begin
			   case keywords[k].name of
            'numframes': nframes = fix(keywords[k].value)
            'postprocess': postProcess = keywords[k].value
            'save_raw': save_raw = fix(keywords[k].value)
            'save_jpeg': save_jpeg = fix(keywords[k].value)
            'start_on_minute': start_on_minute = fix(keywords[k].value)
            'inter_frame_delay': inter_frame_delay = float(keywords[k].value)
            'ftp_jpeg': ftp_jpeg = fix(keywords[k].value)
            else:
          endcase
			endfor

			;\\ Grab the requested number of frames, and optionally process and save them
			frame = 0
			consecutive_failures = 0
			while frame lt nframes do begin

				;\\ If requested, delay and start acquisition on the minute
				if start_on_minute eq 1 then begin
					if frame eq 0 then errcode += 'Wait for minute - '
					while Seconds() gt 2 do begin
						;\\ Keep processing events
						print, 'Waiting for minute... ' + string(Seconds(), f='(f0.1)')
						wait, 1
					endwhile
				endif

				if dbg eq 0 then begin

					info.image_exp_start_date = DateStringUT_YYYYMMDD_Array()
					info.image_exp_start_time = HourUtHHMMSS_SSS_Array()
					exp_start = systime(/sec)

					Andor_Camera_Driver, info.external_dll, 'uGrabFrame', $
										 {mode:info.camera_settings.acqMode, $
										  imageMode:info.camera_settings.imageMode, $
										  startAndWait:1, $
										  exptime:info.camera_settings.exptime_set}, $
										  out, result

					exp_time = systime(/sec) - exp_start
					image = out.image
					exp_time = out.exp_time

				endif else begin
					result = 'image'
					image = intarr(10,10)
					exp_time = -1.0
					if frame eq 0 then errcode += 'Grabbed image - '
				endelse

				;\\ Check to make sure we got an image from the camera
				if result eq 'image' then begin
          frame++
          consecutive_failures  = (consecutive_failures - 1) > 0

					;\\ Store it in the global variable
					*info.image = image

					;\\ See if we need to show it in the main window
					if dbg eq 0 then ASC_Control_ShowImage

					;\\ Save the raw image if required
					if save_raw eq 1 and dbg eq 0 then begin
						filename = call_function(info.filename_function, 'FITS', $
										        extra = {date:info.image_exp_start_date, $
										                 time:info.image_exp_start_time} ) + '.FITS'

						if frame eq 0 then errcode += 'Saved FITS - '
						print, filename

						;\\ Get a FITS header
						start_date = info.image_exp_start_date[0] + '-' + info.image_exp_start_date[1] + '-' + info.image_exp_start_date[2]
						start_time = info.image_exp_start_time[0] + ':' + info.image_exp_start_time[1] + ':' + $
									 info.image_exp_start_time[2] + '.' + info.image_exp_start_time[3]
						header = asc_generate_fits_header(filename, start_date, start_time, exp_time)

						;\\ Write it
						image_int = fix(image)
						fits_write, filename, image_int, header
						ASC_Log, filename
					endif

					if postProcess ne '' and dbg eq 0 then begin
            processedImage = call_function(postProcess, image)
            if frame eq 0 then errcode += 'Processed image - '
          endif else processedImage = image

				endif else begin
				  
				  ;\\ This is if no frame was acquired
				  consecutive_failures ++
				  
				  if consecutive_failures gt 50 then begin
            ;\\ If we are here, we are not talking to the camera, something has happened.
            asc_email_alert, subject='All-sky camera control has stopped', $
                             body='Stopped due to 50 consecutive frame-grab failures.'
            stop                        
				  endif
				
				endelse

				;\\ Delay between frames
				if (inter_frame_delay ne 0) then begin
				  ASC_Log, 'Inter frame delay: ' + string(inter_frame_delay, f='(f0.3)') + ' secs...'
				  if dbg eq 0 then wait, inter_frame_delay
				endif

			endwhile

			errcode = string(nframes, f='(i0)') + 'x ' + errcode
		end


		;\\ Execute an IDL command string
		'idl' : begin
			if nargs gt 0 then begin
				cmd_str = ''
    			for j = 0, nargs - 1 do begin
    				cmd_str += args[j]
    				if j ne nargs - 1 then cmd_str += ','
    			endfor
				res = execute(cmd_str)
				if res eq 0 then begin
					errcode = 'Error: Error executing IDL string: ' + cmd_str
				endif else begin
					errcode = in_string + ' - no error'
				endelse
			endif else begin
				errcode = 'Error: No arguments supplied for command: idl'
			endelse
		end


		;\\ Command not recognized
		else: begin
			errcode = 'Error: Command not recognized: ' + in_string
		end

	endcase

end
