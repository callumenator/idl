
;\\ CONTROL HARDWARE (CAMERA, ETALON(S), MOTORS, FILTER WHEEL, ETC.)
pro DCAI_Hardware, init = init, $
				   deinit = deinit, $
				   etalon = etalon, $
				   filter = filter

	COMMON DCAI_Control, dcai_global


	;\\ INITIALIZATION
	if keyword_set(init) then begin

		;\\ INIT THE CAMERA
			call_procedure, dcai_global.info.drivers, {device:'camera_init', settings:dcai_global.info.camera_profile}

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