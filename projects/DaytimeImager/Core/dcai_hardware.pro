
;\\ CONTROL HARDWARE (CAMERA, ETALON(S), MOTORS, FILTER WHEEL, ETC.)
pro DCAI_Hardware, init = init, $
				   deinit = deinit, $
				   etalon = etalon, $
				   filter = filter

	COMMON DCAI_Control, dcai_global


	;\\ INITIALIZATION
	if keyword_set(init) then begin

		;\\ TEST TO SEE IF WE CAN TALK TO THE CAMERA
		Andor_Camera_Driver, dcai_global.settings.external_dll, 'uGetStatus', 0, out, res
		DCAI_Log, 'Cam Status: ' + res

		if res eq 'DRV_NOT_INITIALIZED' then $
			Andor_Camera_Driver, dcai_global.settings.external_dll, 'uInitialize', '', out, res

			Andor_Camera_Driver, dcai_global.settings.external_dll, 'uAbortAcquisition', '', out, res
			did_we_init = 0
			if res eq 'DRV_ERROR_ACK' then begin
				dcai_global.info.camera_settings.initialized = 0
				DCAI_Log, 'Camera acknowledge...False - PROBLEM!'
			endif else begin
				dcai_global.info.camera_settings.initialized = 1
				did_we_init = 1
				DCAI_Log, 'Camera acknowledge...True'
			endelse

			DCAI_Log, 'Cam Init: ' + res

			;\\ QUERY THE CAMERA TO FIND OUT ITS CAPABILITIES
				Andor_Camera_Driver, dcai_global.settings.external_dll, 'uGetCapabilities', 0, caps, res, /auto_acq
				*dcai_global.info.camera_caps = caps

			;\\ LOAD THE INITIAL CAMERA SETTINGS
			if dcai_global.info.camera_profile ne '' then begin

				DCAI_LoadCameraSetting, dcai_global.settings.external_dll, settings_script = dcai_global.info.camera_profile, $
									   debug_ress = dbg_results
	      		dcai_global.info.camera_settings.initialized = did_we_init
				for i = 0, n_elements(dbg_results) - 1 do DCAI_Log, dbg_results[i]
			endif

		;\\ WE ALSO NEED TO GRAB A DUMMY CAMERA IMAGE, SO THAT WE KNOW WHAT THE IMAGE DIMENSIONS ARE
			imageMode = dcai_global.info.camera_settings.imageMode
			Andor_Camera_Driver, dcai_global.settings.external_dll, 'uGrabFrame', {mode:-1, imageMode:imageMode}, out, res
			*dcai_global.info.image = out.image

		;\\ INIT THE ETALON(S)
			call_procedure, dcai_global.info.drivers, {device:'etalon_init'}

		return
	endif


	;\\ SHUTDOWN
	if keyword_set(deinit) then begin

		;\\ CLOSE THE COMM PORTS
		;\\ #### IMPLEMENT FILTER WHEEL, MOTOR DRIVE, ETALON, ETC #####

		return
	endif


	;\\ ETALON
	if keyword_set(etalon) then begin

		return
	endif


	;\\ FILTER WHEEL
	if keyword_set(filter) then begin

		return
	endif


end