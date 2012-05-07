
;\\ Initialize hardware (camera, com ports, shutter open, etc. )
pro ASC_Hardware, init = init, $
				  deinit = deinit

	COMMON ASC_Control, info, gui, log

	if keyword_set(init) then begin

		;\\ Grab camera capabilities
		Andor_Camera_Driver, info.external_dll, 'uGetStatus', 0, out, res
		if res eq 'DRV_NOT_INITIALIZED' then $
			Andor_Camera_Driver, info.external_dll, 'uInitialize', '', out, res

			Andor_Camera_Driver, info.external_dll, 'uAbortAcquisition', '', out, res
			did_we_init = 0
			if res eq 'DRV_ERROR_ACK' then begin
				info.camera_settings.initialized = 0
				ASC_Log, 'Camera acknowledge...False - PROBLEM!'
			endif else begin
				info.camera_settings.initialized = 1
				did_we_init = 1
				ASC_Log, 'Camera acknowledge...True'
			endelse


			ASC_Log, 'Cam Init: ' + res
			Andor_Camera_Driver, info.external_dll, 'uGetCapabilities', 0, caps, res, /auto_acq
			*info.camera_caps = caps

		;\\ Load initial camera settings - this will update the global info.camera_settings
		if info.camera_profile ne '' then begin
			ASC_LoadCameraSetting, info.external_dll, settings_script = info.camera_profile, $
								   debug_ress = dbg_results
      info.camera_settings.initialized = did_we_init
			for i = 0, n_elements(dbg_results) - 1 do ASC_Log, dbg_results[i]
		endif

		;\\ Open com ports
		comms_wrapper, info.comms.filter.port, $
					   info.external_dll, $
					   type = 'com', $	;\\ Use standard windows comms
					   /open, $
					   data = 'COM1: baud=9600 data=8 parity=N stop=1', $
					   errcode = errcode
		info.comms.filter.port_opened = 1

	  	if (info.comms.shutter.port ne info.comms.filter.port) then begin

			comms_wrapper, info.comms.shutter.port, info.external_dll, $
	   			type = 'com', $	;\\ Use standard windows comms
	   			/open, $
	   			data = 'COM1: baud=9600 data=8 parity=N stop=1', $
	   			errcode = errcode

	   		info.comms.shutter.port_opened = 1
	  	endif else begin
	    	info.comms.shutter.port_opened = 1
	  	endelse

		;\\ Close the shutter
		ASC_Command, 'shutter, position = close, force = 1'
		
		;\\ Home the filter wheel
    ASC_Command, 'filter, home = 1'
    
	endif

	if keyword_set(deinit) then begin
    
    ;\\ Close the shutter
    ASC_Command, 'shutter, position = close, force = 1, nogui = 1'

		;\\ Close com ports
		comms_wrapper, info.comms.filter.port, $
					   info.external_dll, $
					   type = 'com', $	;\\ Use standard windows comms
					   /close, $
					   data = 'COM1: baud=9600 data=8 parity=N stop=1', $
					   errcode = errcode
		info.comms.filter.port_opened = 0

	  	if (info.comms.shutter.port ne info.comms.filter.port) then begin

			comms_wrapper, info.comms.shutter.port, info.external_dll, $
	   			type = 'com', $	;\\ Use standard windows comms
	   			/close, $
	   			data = 'COM1: baud=9600 data=8 parity=N stop=1', $
	   			errcode = errcode

	   		info.comms.shutter.port_opened = 0
	  	endif else begin
	    	info.comms.shutter.port_opened = 0
	  	endelse		
	endif

end