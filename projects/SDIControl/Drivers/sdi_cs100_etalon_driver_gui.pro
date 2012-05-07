

pro SDI_CS100_Etalon_Driver_GUI_Init, base_widget = base_widget, $
									  no_timers = no_timers

	common SDI_EtalonDriverShare, gui, misc

	font = 'Ariel*16*Bold'

	if not keyword_set(base_widget) then begin
		base = widget_base(col=1, title = 'CS100 Etalon Driver')
	endif else begin
		base = base_widget
	endelse

	info_base = widget_base(base, col=2)
	log = widget_list(info_base, xs = 70, ys = 10, value='', font=font)

	bar_base = widget_base(info_base, col = 1, /base_align_center)
	bar = widget_draw(bar_base, xs = 20, ys = 140)
	zspace_label = widget_label(bar_base, value = 'Z: ', font=font, xs = 50)

	scanrate_lab = widget_label(base, value = 'Scan Rate: ', font=font, xs=150)

	split_base = widget_base(base, col = 2)

	par_base = widget_base(split_base, row=4, frame=1)
	xparbtn = widget_button(par_base, value='X Parallel +', uval={type:'xpar_plus'}, font=font)
	xparbtn = widget_button(par_base, value='X Parallel -', uval={type:'xpar_minus'}, font=font)
	yparbtn = widget_button(par_base, value='X Parallel +', uval={type:'ypar_plus'}, font=font)
	yparbtn = widget_button(par_base, value='Y Parallel -', uval={type:'ypar_minus'}, font=font)
	stepsize_lab = widget_label(par_base, value='Step Size', font=font)
	stepsize = widget_text(par_base, /editable, font=font)

	cmd_str_base = widget_base(split_base, col=1, frame=1)
	lab = widget_label(cmd_str_base, value='Command String', font=font)
	cmd = widget_text(cmd_str_base, /editable, uval = {type:'cmd_str'}, font=font)

	scan_base = widget_base(split_base, col = 3, frame=1)
	scan_base_btn = widget_base(scan_base, row = 3)
	scan = widget_button(scan_base_btn, value = 'Start Scan', uval={type:'scan_start'}, font=font)
	scan = widget_button(scan_base_btn, value = 'Stop Scan', uval={type:'scan_stop'}, font=font)
	scan = widget_button(scan_base_btn, value = 'Pause Scan', uval={type:'scan_pause'}, font=font)

	lab_base = widget_base(scan_base, col=2)
	lab = widget_label(lab_base, value = 'Z Min', font=font, ys=25)
	lab = widget_label(lab_base, value = 'Z Max', font=font, ys=25)
	lab = widget_label(lab_base, value = 'Step', font=font, ys=25)
	zmin = widget_text(lab_base, /editable, font=font, xs=15, /align_right)
	zmax = widget_text(lab_base, /editable, font=font, xs=15)
	scanstepsize = widget_text(lab_base, /editable, font=font, xs=15, /align_right)

	widget_control, base, /realize
	if not keyword_set(no_timers) then widget_control, timer = misc.timer_interval, info_base
	widget_control, get_value = bar, bar

	gui = {base:base, $
		   bar:bar, $
		   info_base:info_base, $
		   log:log, $
		   stepsize:stepsize, $
		   scanstepsize:scanstepsize, $
		   zmin:zmin, $
		   zmax:zmax, $
		   zspace_label:zspace_label, $
		   scanrate_lab:scanrate_lab, $
		   cmd_box:cmd}
end


pro SDI_CS100_Etalon_Driver_GUI_Event, event

	common SDI_EtalonDriverShare

	;\\ TIMER EVENT, INCREMENT THE TIMER COUNTER
	if (size(event, /structure)).structure_name eq 'WIDGET_TIMER' then begin
		widget_control, timer = misc.timer_interval, gui.info_base
		misc.timer_count ++

		;if (misc.timer_count mod (0.05/misc.timer_interval)) eq 0 then begin
			if misc.scan.scanning eq 1 then begin
				thisRate = 1.0/(systime(/sec) - misc.scantime)
				misc.scantime = systime(/sec)
				widget_control, set_value = 'Scan Rate: ' + string(thisrate, f='(f0.2)') + ' Hz', $
						gui.scanrate_lab
				SDI_CS100_Etalon_Driver_GUI_Scan
			endif
		;endif
		return
	endif

	;\\ Read the parallelism step size and scan range and step
	widget_control, get_value = step_str, gui.stepsize
	stepsize = float(step_str[0])
	widget_control, get_value = zmin_str, gui.zmin
	zmin = float(zmin_str[0])
	widget_control, get_value = zmax_str, gui.zmax
	zmax = float(zmax_str[0])
	widget_control, get_value = scan_step_str, gui.scanstepsize
	scanstep = float(scan_step_str[0])

	widget_control, get_uval = uval, event.id
	if size(uval, /type) eq 8 then begin

		case uval.type of
			'xpar_plus': begin
				temp_x = misc.parallel.x + stepsize
				if temp_x ge -2048 and temp_x le 2047 then begin
					misc.parallel.x = temp_x
					sdi_cs100_etalon_driver, 'set_x_parallelism', {port:misc.port, dll:misc.dll, comms:misc.comms, spacing:temp_x}, out, err
					SDI_CS100_Etalon_Driver_GUI_UpdateLog, 'Set X Parallelism: ' + string(temp_x, f='(i0)')
				endif
			end
			'xpar_minus': begin
				temp_x = misc.parallel.x - stepsize
				if temp_x ge -2048 and temp_x le 2047 then begin
					misc.parallel.x = temp_x
					sdi_cs100_etalon_driver, 'set_x_parallelism', {port:misc.port, dll:misc.dll, comms:misc.comms, spacing:temp_x}, out, err
					SDI_CS100_Etalon_Driver_GUI_UpdateLog, 'Set X Parallelism: ' + string(temp_x, f='(i0)')
				endif
			end
			'ypar_plus': begin
				temp_y = misc.parallel.y + stepsize
				if temp_y ge -2048 and temp_y le 2047 then begin
					misc.parallel.y = temp_y
					sdi_cs100_etalon_driver, 'set_y_parallelism', {port:misc.port, dll:misc.dll, comms:misc.comms, spacing:temp_y}, out, err
					SDI_CS100_Etalon_Driver_GUI_UpdateLog, 'Set Y Parallelism: ' + string(temp_y, f='(i0)')
				endif
			end
			'ypar_minus': begin
				temp_y = misc.parallel.y - stepsize
				if temp_y ge -2048 and temp_y le 2047 then begin
					misc.parallel.y = temp_y
					sdi_cs100_etalon_driver, 'set_y_parallelism', {port:misc.port, dll:misc.dll, comms:misc.comms, spacing:temp_y}, out, err
					SDI_CS100_Etalon_Driver_GUI_UpdateLog, 'Set Y Parallelism: ' + string(temp_y, f='(i0)')
				endif
			end
			'scan_start': begin
				if misc.scan.scanning eq 0 then begin
					if zmin ge -2048 then begin
						lo = zmin
						misc.scan.zmin = lo
					endif else begin
						lo = -2048
						misc.scan.zmin = lo
					endelse
					if zmax le 2047 then begin
						hi = zmax
						misc.scan.zmax = hi
					endif else begin
						hi = 2047
						misc.scan.zmax = hi
					endelse
					if scanstep lt -2000 then scanstep = -2000
					if scanstep gt 2000 then scanstep = 2000
					if scanstep eq 0 then scanstep = 1
					misc.scan.scan_stepsize = scanstep
					misc.scan.current_z = lo
					misc.scan.scanning = 1

					widget_control, set_value = string(scanstep, f='(i0)'), gui.scanstepsize
					widget_control, set_value = string(lo, f='(i0)'), gui.zmin
					widget_control, set_value = string(hi, f='(i0)'), gui.zmax
					SDI_CS100_Etalon_Driver_GUI_Scan, /start
				endif
				if misc.scan.scanning eq - 1 then begin	;\\ Paused scan restart
					misc.scan.scanning = 1
				endif
			end
			'scan_stop': begin
				misc.scan.scanning = 0
				SDI_CS100_Etalon_Driver_GUI_Scan, /stop
			end
			'scan_pause': begin
				misc.scan.scanning = -1
			end


			else: print, 'Event Not Recognized'
		endcase
	endif

end

;\\ UPDATE THE LOG
pro SDI_CS100_Etalon_Driver_GUI_UpdateLog, entry

	common SDI_EtalonDriverShare

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


;\\ HANDLE ETALON SCANNING
pro SDI_CS100_Etalon_Driver_GUI_Scan, start=start, stop=stop

	common SDI_EtalonDriverShare

	if keyword_set(start) then begin
		;\\ Set the etalon to its initial spacing
		sdi_cs100_etalon_driver, 'set_spacing', {port:misc.port, dll:misc.dll, comms:misc.comms, spacing:misc.scan.zmin}, out, err
	endif

	if not keyword_set(stop) and not keyword_set(start) then begin
		temp_z = misc.scan.current_z + misc.scan.scan_stepsize
		if temp_z lt -2048 or temp_z gt 2047 or temp_z gt misc.scan.zmax then begin
			misc.scan.scanning = 0
			return
		endif
		sdi_cs100_etalon_driver, 'set_spacing', {port:misc.port, dll:misc.dll, comms:misc.comms, spacing:temp_z}, out, err
		wait, 0.1
		misc.scan.current_z = temp_z
	endif


	;\\ Update the draw widget
	wset, gui.bar
	pcnt = (misc.scan.current_z - misc.scan.zmin)/float(misc.scan.zmax - misc.scan.zmin)
	loadct, 39, /silent
	polyfill, [0,0,1,1], [-.1,pcnt,pcnt,-.1], /normal, color = 80

	widget_control, set_value = 'Z: ' + string(misc.scan.current_z, f='(i0)'), gui.zspace_label

	if keyword_set(stop) or keyword_set(start) then begin
		wset, gui.bar
		loadct, 39, /silent
		erase, 0
	endif
end


;\\ OPEN THE ETALON PORT
pro SDI_CS100_Etalon_Driver_GUI_OpenPort
	common SDI_EtalonDriverShare

	comms_wrapper, misc.port, misc.dll, type=misc.comms, /open, err=err
	SDI_CS100_Etalon_Driver_GUI_UpdateLog, 'Open Port ' + string(misc.port, f='(i0)') + $
		': ' + string(err, f='(i0)')

	if err eq 0 then misc.port_open = 1
end

;\\ CLOSE THE ETALON PORT
pro SDI_CS100_Etalon_Driver_GUI_ClosePort, nolog=nolog
	common SDI_EtalonDriverShare
	comms_wrapper, misc.port, misc.dll, type=misc.comms, /close, err=err
	if not keyword_set(nolog) then $
		SDI_CS100_Etalon_Driver_GUI_UpdateLog, 'Open Port ' + string(misc.port, f='(i0)') + $
			': ' + err
end


pro SDI_CS100_Etalon_Driver_GUI_Cleanup, val
	common SDI_EtalonDriverShare
	SDI_CS100_Etalon_Driver_GUI_ClosePort, /nolog
end



pro SDI_CS100_Etalon_Driver_GUI, dll, $
								 embed_in_widget = embed_in_widget, $
								 no_timers = no_timers

	common SDI_EtalonDriverShare, gui, misc

	;if size(dll, /type) eq 0 then $
	;	dll = 'C:\mawsoncode\sdi_external\sdi_external.dll'

	if size(dll, /type) eq 0 then $
		dll = 'C:\Users\sdi3000\ControlSoftware\SDI_External\sdi_external.dll'

	parallel = {x:0, y:0}
	scan = {zmin:0, zmax:0, current_z:0, scanning:0, scan_stepsize:1}

	misc = {port:3L, $
			port_open:0, $
			dll:dll, $
			comms:'moxa', $
			parallel:parallel, $
			scan:scan, $
			timer_interval:0.05, $
			timer_count:0UL, $
			scantime:0D, $
			log:{entries:strarr(100), n:0}}

	if keyword_set(embed_in_widget) then begin
		SDI_CS100_Etalon_Driver_GUI_init, base_widget = embed_in_widget, no_timers = no_timers
	endif else begin
		SDI_CS100_Etalon_Driver_GUI_init, no_timers = no_timers
		SDI_CS100_Etalon_Driver_GUI_OpenPort
		sdi_cs100_etalon_driver, 'initialise', {port:3L, dll:dll, comms:'moxa'}, out, err
	endelse

	xmanager, 'SDI_CS100_Etalon_Driver_GUI', gui.base, $
				event_handler = 'SDI_CS100_Etalon_Driver_GUI_Event', $
				cleanup = 'SDI_CS100_Etalon_Driver_GUI_Cleanup', /no_block
end