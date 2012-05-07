
pro SDIControl_EventHandler, event

	common SDIControl


	widget_control, get_uval=uval, event.id

	;\\ If timer event, reset the timer and do some stuff
	if tag_names(event, /structure_name) eq 'WIDGET_TIMER' then begin
		widget_control, event.id, timer = sdic_misc.timer_interval
		sdic_misc.timer_counter ++

		;\\ Alert the timer listeners
		if size(*sdic_misc.timer_list, /n_dimensions) ne 0 then $
			for j = 0, n_elements(*sdic_misc.timer_list) - 1 do call_method, 'timer', (*sdic_misc.timer_list)[j]


		;\\ Get new camera frame
			call_procedure, sdic_instrument.name + '_instrument_control', command = 'grab_frame', out=out


			if out.result eq 'image' then begin
				;\\ Alert the frame listeners
				*sdic_frame_buffer.image = out.image
				if size(*sdic_misc.frame_list, /n_dimensions) ne 0 then $
					for j = 0, n_elements(*sdic_misc.frame_list) - 1 do call_method, 'frame', (*sdic_misc.frame_list)[j]
			endif


		;\\ If scanning, increment the scan channel and adjust etalon legs
			if sdic_scan.active eq 1 then begin
				call_procedure, sdic_instrument.name + '_instrument_control', command = 'scan_etalon'
			endif

		return
	endif


	;\\ NON-TIMER EVENTS
	if size(uval, /type) eq 8 then begin
		descr = uval.descr

		case descr of

			'plugin': begin
				newPlugin = obj_new(uval.plugin)
			end

			'plugin_event': call_method, uval.method, uval.object, event

			else:
		endcase

	endif

end