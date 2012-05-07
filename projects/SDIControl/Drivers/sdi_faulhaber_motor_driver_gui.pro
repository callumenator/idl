
pro SDI_Faulhaber_Motor_Driver_GUI_Init, base_widget = base_widget

	common SDI_MotorDriverShare, gui, misc

	font = 'Ariel*16*Bold'

	if not keyword_set(base_widget) then begin
		base = widget_base(col=1, title = 'Faulhaber Motor Driver')
	endif else begin
		base = base_widget
	endelse

	info_base = widget_base(base, col=2)
	log = widget_list(info_base, xs = 70, ys = 10, value='', font=font)
	info = widget_list(info_base, xs = 30, ys = 10, value = infoList, font=font)

	lower_base = widget_base(base, col = 2)

	set_base = widget_base(lower_base, col=1)
	labels = tag_names(misc.settings)
	set_table = widget_table(set_base, value = misc.settings, /column_major, font=font, $
							 row_labels = labels, /no_column_headers, /editable, $
							 uval={type:'settings_table'}, /all_events, column_width=200)


	btn_base = widget_base(lower_base, col = 2)
	btn = widget_button(btn_base, value = 'Open Port', uval = {type:'open_port_btn'}, font=font)
	btn = widget_button(btn_base, value = 'Close Port', uval = {type:'close_port_btn'}, font=font)
	btn = widget_button(btn_base, value = 'Enable', uval = {type:'enable_btn'}, font=font)
	btn = widget_button(btn_base, value = 'Disable', uval = {type:'disable_btn'}, font=font)
	btn = widget_button(btn_base, value = 'Drive to Pos', uval = {type:'drive_to_btn'}, font=font)
	btn = widget_button(btn_base, value = 'Set Pos 0', uval = {type:'set_zero_btn'}, font=font)

	cmd_str_base = widget_base(btn_base, col=1)
	lab = widget_label(cmd_str_base, value='Command String', font=font)
	cmd = widget_text(cmd_str_base, /editable, uval = {type:'cmd_str'}, font=font)

	widget_control, base, /realize
	widget_control, timer = misc.timer_interval, info_base

	gui = {base:base, $
		   info_base:info_base, $
		   log:log, $
		   info:info, $
		   cmd_box:cmd}
end


pro SDI_Faulhaber_Motor_Driver_GUI_Event, event

	common SDI_MotorDriverShare

	;\\ TIMER EVENT, INCREMENT THE TIMER COUNTER
	if (size(event, /structure)).structure_name eq 'WIDGET_TIMER' then begin
		widget_control, timer = misc.timer_interval, gui.info_base
		misc.timer_count ++

		;\\ Read the current position
		if (misc.timer_count mod (0.5/misc.timer_interval)) eq 0 then begin
			if misc.info.opened eq 1 then begin
				comms_wrapper, misc.settings.port, misc.dll, type=misc.comms, /write, $
								data = 'POS'+string(13B), err=err
				comms_wrapper, misc.settings.port, misc.dll, type=misc.comms, /read, $
								data = data, err=err

				if total(byte(data) ne 32) ne 0 then begin
					misc.info.position = long(data)
				endif
			endif
			SDI_Faulhaber_Motor_Driver_GUI_UpdateInfo
		endif
		return
	endif

	widget_control, get_uval = uval, event.id
	if size(uval, /type) eq 8 then begin

		case uval.type of
			'open_port_btn': begin
				SDI_Faulhaber_Motor_Driver_GUI_OpenPort
			end
			'close_port_btn': begin
				SDI_Faulhaber_Motor_Driver_GUI_ClosePort
			end
			'enable_btn': begin
				if misc.info.opened eq 0 then SDI_Faulhaber_Motor_Driver_GUI_UpdateLog, 'Port Not Open' & break
				comms_wrapper, misc.settings.port, misc.dll, type=misc.comms, /write, data = 'EN' + string(13B), err=err
				SDI_Faulhaber_Motor_Driver_GUI_UpdateLog, 'Enable Motor: ' + get_moxa_error(err)
			end
			'disable_btn': begin
				if misc.info.opened eq 0 then SDI_Faulhaber_Motor_Driver_GUI_UpdateLog, 'Port Not Open' & break
				comms_wrapper, misc.settings.port, misc.dll, type=misc.comms, /write, data = 'DI' + string(13B), err=err
				SDI_Faulhaber_Motor_Driver_GUI_UpdateLog, 'Disable Motor: ' + get_moxa_error(err)
			end
			'drive_to_btn': begin
				if misc.info.opened eq 0 then SDI_Faulhaber_Motor_Driver_GUI_UpdateLog, 'Port Not Open' & break
				comms_wrapper, misc.settings.port, misc.dll, type=misc.comms, /write, data = 'M' + string(13B), err=err
				SDI_Faulhaber_Motor_Driver_GUI_UpdateLog, 'Start Positioning: ' + get_moxa_error(err)
			end
			'set_zero_btn': begin
				if misc.info.opened eq 0 then SDI_Faulhaber_Motor_Driver_GUI_UpdateLog, 'Port Not Open' & break
				comms_wrapper, misc.settings.port, misc.dll, type=misc.comms, /write, data = 'HO' + string(13B), err=err
				SDI_Faulhaber_Motor_Driver_GUI_UpdateLog, 'Set Zero Position: ' + get_moxa_error(err)
			end
			'cmd_str': begin
				if misc.info.opened eq 0 then SDI_Faulhaber_Motor_Driver_GUI_UpdateLog, 'Port Not Open' & break
				widget_control, get_value = cmd_string, gui.cmd_box
				print, byte(cmd_string)
				comms_wrapper, misc.settings.port, misc.dll, type=misc.comms, /write, data = cmd_string + string(13B), err=err
				SDI_Faulhaber_Motor_Driver_GUI_UpdateLog, 'Sent String: ' + cmd_string + ', ' + get_moxa_error(err)
				comms_wrapper, misc.settings.port, misc.dll, type=misc.comms, /read, data = data, err=err
				SDI_Faulhaber_Motor_Driver_GUI_UpdateLog, 'Read back: ' + data + ', ' + get_moxa_error(err)
			end
			'settings_table':begin
				if event.type eq 0 then begin
					if event.ch eq 13 then begin
						;\\ ENTER KEY HAS BEEN PRESSED
						widget_control, get_value = table, event.id
						names = strlowcase(tag_names(table))
						value = table.(event.y)
						case names(event.y) of
							'port':begin
								if misc.info.opened eq 1 then begin
									SDI_Faulhaber_Motor_Driver_GUI_ClosePort
								endif
								if table.port lt 10 then begin
									if misc.info.opened eq 0 then begin
										misc.settings.port = table.port
										SDI_Faulhaber_Motor_Driver_GUI_OpenPort
									endif
								endif
							end
							'absolute_pos':begin
								if misc.info.opened eq 0 then SDI_Faulhaber_Motor_Driver_GUI_UpdateLog, 'Port Not Open' & break
								if misc.info.position_mode eq 1 then begin
									misc.settings.absolute_pos = table.absolute_pos
									comms_wrapper, misc.settings.port, misc.dll, type=misc.comms, /write, $
											data = 'LA' + string(table.absolute_pos, f='(i0)') + ' - ' + string(13B), err=err
									SDI_Faulhaber_Motor_Driver_GUI_UpdateLog, 'LA' + string(table.absolute_pos, f='(i0)') + ' - ' $
										+ get_moxa_error(err)
								endif
							end
							'relative_pos':begin
								if misc.info.opened eq 0 then SDI_Faulhaber_Motor_Driver_GUI_UpdateLog, 'Port Not Open' & break
								if misc.info.position_mode eq 1 then begin
									misc.settings.relative_pos = table.relative_pos
									comms_wrapper, misc.settings.port, misc.dll, type=misc.comms, /write, $
											data = 'LR' + string(table.relative_pos, f='(i0)') + ' - ' + string(13B), err=err
									SDI_Faulhaber_Motor_Driver_GUI_UpdateLog, 'LA' + string(table.relative_pos, f='(i0)') + ' - ' $
										+ get_moxa_error(err)
								endif
							end
							'velocity':begin
								if misc.info.opened eq 0 then SDI_Faulhaber_Motor_Driver_GUI_UpdateLog, 'Port Not Open' & break
								if misc.info.velocity_mode eq 1 then begin
									if abs(table.velocity) lt 100 then begin
										misc.settings.velocity = table.velocity
										comms_wrapper, misc.settings.port, misc.dll, type=misc.comms, /write, $
												data = 'V' + string(table.velocity, f='(i0)') + ' - ' + string(13B), err=err
										SDI_Faulhaber_Motor_Driver_GUI_UpdateLog, 'V' + string(table.velocity, f='(i0)') + ' - ' $
											+ get_moxa_error(err)
									endif
								endif
							end
							else:
						endcase
						widget_control, set_value = misc.settings, event.id
					endif
				endif
			end

			else: print, 'Event Not Recognized'
		endcase
	endif

end


;\\ UPDATE THE INFO LIST
pro SDI_Faulhaber_Motor_Driver_GUI_UpdateInfo

	common SDI_MotorDriverShare

	tags = tag_names(misc.info)
	infoList = strarr(n_tags(misc.info))
	for k = 0, n_tags(misc.info) - 1 do begin
		infoList[k] = tags[k] + ': ' + string(misc.info.(k), f='(i0)')
	endfor

	widget_control, set_value = infoList, gui.info
end


;\\ UPDATE THE LOG
pro SDI_Faulhaber_Motor_Driver_GUI_UpdateLog, entry

	common SDI_MotorDriverShare

	if misc.log.n eq n_elements(misc.log.entries) then begin
		misc.log.entries = shift(misc.log.entries, -5)
		misc.log.entries[n_elements(misc.log.entries) - 6:*] = ''
		misc.log.n = misc.log.n - 6
	endif

	entry = '[' + strmid(systime(),11,8) + '] ' + entry
	misc.log.entries[misc.log.n] = entry
	misc.log.n ++
	widget_control, set_value = misc.log.entries, gui.log
	widget_control, set_list_top = (misc.log.n - 5) > 0, gui.log

end


;\\ OPEN A PORT AND ENABLE THE MOTOR (OR TRY TO)
pro SDI_Faulhaber_Motor_Driver_GUI_OpenPort

	common SDI_MotorDriverShare

	if misc.info.opened eq 1 then begin
		SDI_Faulhaber_Motor_Driver_GUI_UpdateLog, 'A port is already open'
		return
	endif

	comms_wrapper, misc.settings.port, misc.dll, type=misc.comms, /open, err=err
	SDI_Faulhaber_Motor_Driver_GUI_UpdateLog, 'Open Port: ' + get_moxa_error(err)
	if err ne 0 then begin
		misc.info.opened = 1

		;\\ Set the baud
		comms_wrapper, misc.settings.port, misc.dll, type=misc.comms, moxa_setbaud=12, err=err
		SDI_Faulhaber_Motor_Driver_GUI_UpdateLog, 'Set Baud 12: ' + get_moxa_error(err)

		;\\ Set the max speed
		comms_wrapper, misc.settings.port, misc.dll, type=misc.comms, /write, data = 'SP70' + string(13B), err=err
		SDI_Faulhaber_Motor_Driver_GUI_UpdateLog, 'Set Max Speed 70: ' + get_moxa_error(err)

		;\\ Set the max accel
		comms_wrapper, misc.settings.port, misc.dll, type=misc.comms, /write, data = 'AC100' + string(13B), err=err
		SDI_Faulhaber_Motor_Driver_GUI_UpdateLog, 'Set Max Acceleration 100: ' + get_moxa_error(err)

		;\\ Enable the motor
		comms_wrapper, misc.settings.port, misc.dll, type=misc.comms, /write, data = 'EN' + string(13B), err=err
		SDI_Faulhaber_Motor_Driver_GUI_UpdateLog, 'Enable Motor: ' + get_moxa_error(err)

		;\\ Set motor current limits
		comms_wrapper, misc.settings.port, misc.dll, type=misc.comms, /write, $
			data = 'LPC' + string(misc.settings.current_limit_pk, f='(i0)') + string(13B), err=err
		SDI_Faulhaber_Motor_Driver_GUI_UpdateLog, 'LPC' + $
			string(misc.settings.current_limit_pk, f='(i0)') + ' - ' + get_moxa_error(err)

	endif
end


;\\ CLSE A PORT AND DISABLE THE MOTOR (OR TRY TO)
pro SDI_Faulhaber_Motor_Driver_GUI_ClosePort, nolog=nolog

	common SDI_MotorDriverShare

	if keyword_set(nolog) then nolog = 1 else nolog = 0

	if misc.info.opened eq 0 then begin
		if nolog eq 0 then begin
			SDI_Faulhaber_Motor_Driver_GUI_UpdateLog, 'No port is open'
		endif else begin
			print, 'No Port is Open'
		endelse
		return
	endif

	;\\ Disable current motor
	comms_wrapper, misc.settings.port, misc.dll, type=misc.comms, /write, data = 'DI' + string(13B), err=err
	if nolog eq 0 then begin
		SDI_Faulhaber_Motor_Driver_GUI_UpdateLog, 'Disable Motor: ' + get_moxa_error(err)
	endif else begin
		print, 'Disable Motor: ' + get_moxa_error(err)
	endelse

	;\\ Close the port
	comms_wrapper, misc.settings.port, misc.dll, type=misc.comms, /close, err=err
	if err eq 0 then misc.info.opened = 0
	if nolog eq 0 then begin
		SDI_Faulhaber_Motor_Driver_GUI_UpdateLog, 'Close Port: ' + get_moxa_error(err)
	endif else begin
		print, 'Close Port: ' + get_moxa_error(err)
	endelse
end



pro SDI_Faulhaber_Motor_Driver_GUI_Cleanup, val

	common SDI_MotorDriverShare
	SDI_Faulhaber_Motor_Driver_GUI_ClosePort, /nolog

end



pro SDI_Faulhaber_Motor_Driver_GUI, dll, embed_in_widget = embed_in_widget

	common SDI_MotorDriverShare, gui, misc

	if size(dll, /type) eq 0 then $
		dll = 'C:\mawsoncode\sdi_external\sdi_external.dll'

	;if size(dll, /type) eq 0 then $
	;	dll = 'C:\cal\dllstore\sdi_external.dll'

	info = {position:0L, $
			opened:0, $
			position_mode:1, $
			velocity_mode:0}

	settings = {port:0L, $
				current_limit_pk:1000, $
				currnet_limit_cn:0, $
				absolute_pos:0L, $
				relative_pos:0L, $
				velocity:0, $
				baud:9600 }

	misc = {dll:dll, $
			comms:'moxa', $
			log:{entries:strarr(100), n:0}, $
			timer_interval:0.1, $
			timer_count:0UL, $
			settings:settings, $
			info:info}

	if keyword_set(embed_in_widget) then begin
		SDI_Faulhaber_Motor_Driver_GUI_init, base_widget = embed_in_widget
	endif else begin
		SDI_Faulhaber_Motor_Driver_GUI_init
	endelse

	xmanager, 'SDI_Faulhaber_Motor_Driver_GUI', gui.base, $
				event_handler = 'SDI_Faulhaber_Motor_Driver_GUI_Event', $
				cleanup = 'SDI_Faulhaber_Motor_Driver_GUI_Cleanup', /no_block


end