
;\\ Register the object with xmanager, ask for frame/timer events
pro SDIControl_RegisterPlugin, widget_id, objectRef, $
							   timer=timer, frame=frame

	common SDIControl

	if keyword_set(timer) then begin
		if size(*sdic_misc.timer_list, /n_dimensions) eq 0 then begin
			*sdic_misc.timer_list = [objectRef]
		endif else begin
			*sdic_misc.timer_list = [*sdic_misc.timer_list, objectRef]
		endelse
	endif

	if keyword_set(frame) then begin
		if size(*sdic_misc.frame_list, /n_dimensions) eq 0 then begin
			*sdic_misc.frame_list = [objectRef]
		endif else begin
			*sdic_misc.frame_list = [*sdic_misc.frame_list, objectRef]
		endelse
	endif

	widget_control, /realize, widget_id

	xmanager, 'SDIControl_Main', $
			  widget_id, $
			  event_handler = 'SDIControl_EventHandler', $
			  cleanup = 'SDIControl_Cleanup', $
			  /no_block
end