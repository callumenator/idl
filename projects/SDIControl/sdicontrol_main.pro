

;\\ Entry point for the SDI control
pro SDIControl_Main

	common SDIControl, sdic_widget, $
					   sdic_drivers, $
					   sdic_plugins, $
					   sdic_misc, $
					   sdic_scan, $
					   sdic_paths, $
					   sdic_hardware, $
					   sdic_frame_buffer, $
					   sdic_instrument


	sdic_instrument = {name:'blank'}

	rootPath = 'c:\cal\idlsource\SDIControl\'
	sdic_paths = {plugins: rootPath + 'Plugins\', $
				 settings: rootPath + 'Settings\', $
				 driver: rootPath + 'Drivers\'}

	;sdi_Andor_Camera_Driver
	sdic_drivers = {camera:'sdi_null_driver', $
				   etalon:'sdi_CS100_Etalon_Driver', $
				   motor:'sdi_Faulhaber_Motor_Driver'}

	call_procedure, sdic_drivers.camera, 'dummy', 'uGetSettingsStructure', 0, camera_settings
	sdic_hardware = {etalon:{type:'serial', value:0}, $
				    view_switch:{type:'serial', value:0}, $
				    cal_switch:{type:'serial', value:0}, $
			    	camera:camera_settings}

	sdic_frame_buffer = {nx:0, ny:0, image:ptr_new(/alloc)}

	sdic_misc = {dll: rootPath + 'External\SDI_External.dll', $
				mode:'manual', $
				timer_interval:0.1, $
				timer_counter:0UL, $
				timer_list:ptr_new(/alloc), $
				frame_list:ptr_new(/alloc) }

	sdic_scan = {active:0, $
				channel:0, $
				nchannels:128, $
				wavelength_nm:0.0, $
				steps_per_channel:0.0, $
				leg_offset:intarr(3), $
				leg_gain:fltarr(3), $
				leg_voltage:intarr(3)}

	SDIControl_FindPlugins, sdic_paths.plugins
	SDIControl_CreateInterface, title = 'SDI New Control'
	call_procedure, sdic_instrument.name + '_instrument_control', command = 'initialise', out=out

	;\\ Load/embed the drivers
		if sdic_drivers.camera ne 'sdi_null_driver' then call_procedure, sdic_drivers.camera + '_GUI', sdic_misc.dll, embed_in_widget = sdic_widget.cam_tab, /no_viewer
		if sdic_drivers.etalon ne 'sdi_null_driver' then call_procedure, sdic_drivers.etalon + '_GUI', sdic_misc.dll, embed_in_widget = sdic_widget.eta_tab
		if sdic_drivers.motor  ne 'sdi_null_driver' then call_procedure, sdic_drivers.motor  + '_GUI', sdic_misc.dll, embed_in_widget = sdic_widget.mot_tab

	xmanager, 'SDIControl_Main', $
			  sdic_widget.root, $
			  event_handler = 'SDIControl_EventHandler', $
			  cleanup = 'SDIControl_Cleanup', $
			  /no_block

end