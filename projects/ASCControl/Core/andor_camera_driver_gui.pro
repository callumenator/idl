
pro Andor_Camera_Driver_GUI_Init, base_widget=base_widget, $
	  						  	  no_viewer = no_viewer

	common ASC_CameraDriverGUI, gui, misc

	font = 'Ariel*16*Bold'

	driver_str = 'Driver Version: ' + string(misc.caps.softwareVersion[3], f='(f0.2)') $
					+ ', rev ' + string(misc.caps.softwareVersion[2], f='(f0.2)')
	dll_str = 'DLL Version: ' + string(misc.caps.softwareVersion[5], f='(f0.2)') $
					+ ', rev ' + string(misc.caps.softwareVersion[4], f='(f0.2)')

	if not keyword_set(base_widget) then begin
		base = widget_base(title = 'Andor Camera Driver (' + driver_str + ' | ' + dll_str + ')')
	endif else begin
		base = base_widget
	endelse

	tp_base = widget_base(base, col = 1)

 	info_base = widget_base(tp_base, col=3, frame=1)

	log = widget_list(info_base, xs = 50, ys = 20, value='', font=font)
	info = widget_list(info_base, xs = 30, ys = 20, value = infoList, font=font)
	drawsize =300
	if not keyword_set(no_viewer) then $
		draw = widget_draw(info_base, xs = drawsize, ys = drawsize)

	;\\ CAMERA STATUS, TEMPERATURE, ETC., WRITE SETTINGS BUTTON
		stat_base = widget_base(tp_base, col = 3, frame=1)
		stat_label = widget_label(stat_base, value = 'Camera Status: ', font=font, xs=500)
		write_label = widget_button(stat_base, value = 'Write Settings to ASC Profile', font=font, uval={type:'settings_write_asc'})
		write_label = widget_button(stat_base, value = 'Read Settings from ASC Profile', font=font, uval={type:'settings_read_asc'})


	;\\ SETTINGS BASE
		set_base = widget_base(tp_base, col = 2, frame=1)

	;\\ A QUICK SETTINGS EDITOR IN A TABLE
		settings = {exptime:misc.settings.exptime_set, emgain_mode:misc.settings.emgain_mode, $
					emadvanced:misc.settings.emadvanced, emgain:misc.settings.emgain_set, $
					cnvgain:misc.settings.cnvgain_set, acqmode:misc.settings.acqmode, $
					readmode:misc.settings.readmode, $
					tempset:misc.settings.settemp, fanmode:misc.settings.fanmode}

		;table_base = widget_base(set_base, row = 2)

		labels = ['Exposure Time', 'EMGainMode', 'EMAdvanced', $
				  'EMCCD Gain', 'Conv. Gain', 'Acquisition Mode', $
				   'Read Mode', 'Set Temperature', 'Fan Mode' ]
		set_table = widget_table(set_base, value = settings, /column_major, font=font, $
									row_labels = labels, /no_column_headers, /editable, $
									uval={type:'settings_table'}, /all_events, column_width=200)

		lower_base = widget_base(tp_base, col=2, frame=1)
		lower_base_left = widget_base(lower_base, row = 3)
		labels = ['XBin', 'YBin', 'X Pix Start', 'X Pix Stop', 'Y Pix Start', 'Y Pix Stop']
		imagemode_label = widget_label(lower_base_left, value = 'Image Settings', font=font)
		imagemode_table = widget_table(lower_base_left, value = misc.settings.imageMode, /row_major, font=font, $
									column_labels = labels, /no_row_headers, /editable, /all_events, column_width=80)

		imagemode_set = widget_button(lower_base_left, value = 'Apply Image Read Settings', uval={type:'imagemode_set'}, font=font)


		lower_base_right = widget_base(lower_base, col=2, /nonexclusive, /base_align_left)
		coolercheck = widget_button(lower_base_right, value = 'Cooler ON?', font=font, uval={type:'coolercheck'})
		shuttercheck = widget_button(lower_base_right, value = 'Shutter Open?', font=font, uval={type:'shuttercheck'})
		clampcheck = widget_button(lower_base_right, value = 'Baseline Clamp?', font=font, uval={type:'clampcheck'})
		frametransfercheck = widget_button(lower_base_right, value = 'Frame Transfer?', font=font, uval={type:'frametransfer'})
		framegrabcheck = widget_button(lower_base_right, value = 'Grab Frames?', font=font, uval={type:'framegrabcheck'})


	;\\ MAKE THE DROP DOWN LISTS
		drop_base = widget_base(set_base, col = 1, /base_align_left)

		hs_base = widget_base(drop_base, row = 1, /base_align_center)
			hsspeed_drop = widget_droplist(hs_base, value='', uval={type:'hsspeed_droplist'}, font=font, xs=60)
			hsspeed_label = widget_label(hs_base, value = 'HS Speed', font=font)

		vs_base = widget_base(drop_base, row = 1, /base_align_center)
			if size(misc.caps.vsspeeds, /n_dimensions) ne 0 then $
				vslist = string(misc.caps.vsspeeds, f='(f0.1)') $
					else vslist = ''
			vsspeed_drop = widget_droplist(vs_base, value=vslist, uval={type:'vsspeed_droplist'}, font=font, xs=60)
			vsspeed_label = widget_label(vs_base, value = 'VS Speed', font=font)

		vsamp_base = widget_base(drop_base, row = 1, /base_align_center)
			if misc.caps.numVSAmplitudes gt 0 then $
				vsamplist = string(indgen(misc.caps.numVSAmplitudes), f='(i0)') $
					else vsamplist = ''
			vsamp_drop = widget_droplist(vsamp_base, value=vsamplist, uval={type:'vsamps_droplist'}, font=font, xs=60)
			vsapm_label = widget_label(vsamp_base, value = 'VS Amplitudes', font=font)

		preamp_base = widget_base(drop_base, row = 1, /base_align_center)
			preamplist = ''
			if size(misc.caps.preampgains, /n_dimensions) ne 0 then $
				preamplist = string(misc.caps.preampgains, f='(f0.1)')
			preamp_drop = widget_droplist(preamp_base, value=preamplist, uval={type:'preamp_droplist'}, font=font)
			preamp_label = widget_label(preamp_base, value = 'PreAmp Gain', font=font)


		adc_base = widget_base(drop_base, row = 1, /base_align_center)
			adclist = ''
			if misc.caps.numAdChannels ne 0 then $
				adclist = string(indgen(misc.caps.numADChannels), f='(i0)') + $
					' @ ' + string(misc.caps.bitdepths, f='(i0)') + ' bits'
			adc_drop = widget_droplist(adc_base, value=adclist, uval={type:'adchannel_droplist'}, font=font)
			adc_label = widget_label(adc_base, value = 'AD Channel', font=font)

		amp_base = widget_base(drop_base, row = 1, /base_align_center)
			amplist = ''
			if size(misc.caps.amps, /n_dimensions) ne 0 then $
				amplist = misc.caps.amps.description + string(misc.caps.amps.maxhsspeed, f='(f0.1)')
			amp_drop = widget_droplist(amp_base, value=amplist, uval={type:'outamp_droplist'}, font=font)
			amp_label = widget_label(amp_base, value = 'Output Amplifier', font=font)

	widget_control, base, /realize
	widget_control, timer = misc.timer_interval, info_base

	if not keyword_set(no_viewer) then widget_control, get_value = drawId, draw else drawId = -1

	widget_control, hsspeed_drop, set_droplist_select = misc.settings.hsspeedi
	widget_control, vsspeed_drop, set_droplist_select = misc.settings.vsspeedi
	widget_control, vsamp_drop, set_droplist_select = misc.settings.vsamplitude
	widget_control, adc_drop, set_droplist_select = misc.settings.adchannel
	widget_control, amp_drop, set_droplist_select = misc.settings.outamp
	widget_control, preamp_drop, set_droplist_select = misc.settings.preampgaini

	if misc.settings.baselineClamp eq 1 then widget_control, /set_button, clampcheck
	if misc.settings.frameTransfer eq 1 then widget_control, /set_button, frametransfercheck
	if misc.settings.coolerOn eq 1 then widget_control, /set_button, coolerCheck
	if misc.framegrab eq 1 then widget_control, /set_button, framegrabCheck

	gui = {base:base, $
		   info_base:info_base, $
		   log:log, $
		   drawId:drawId, $
		   drawSize:drawSize, $
		   camStatus:stat_label, $
		   font:font, $
		   info_list:info, $
		   imagemode_table:imagemode_table, $
		   hsspeed_drop:hsspeed_drop, $
		   vsspeed_drop:vsspeed_drop, $
		   vsamp_drop:vsamp_drop, $
		   adc_drop:adc_drop, $
		   amp_drop:amp_drop, $
		   set_table:set_table, $
		   preamp_drop:preamp_drop, $
		   clampcheck:clampcheck, $
		   frametransfercheck:frametransfercheck, $
		   coolerCheck:coolerCheck}

end


;\\ EVENT HANDLER
pro Andor_Camera_Driver_GUI_Event, event

	common ASC_CameraDriverGUI

	;\\ TIMER EVENT, INCREMENT THE TIMER COUNTER
	if (size(event, /structure)).structure_name eq 'WIDGET_TIMER' then begin
		widget_control, timer = misc.timer_interval, gui.info_base
		misc.timer_count ++

		if (misc.framegrab eq 1) then begin
			if gui.drawId ne -1 then wset, gui.drawId
			grabber_settings = {mode:misc.settings.acqMode, imageMode:misc.settings.imageMode, startAndWait:1}

			Andor_Camera_Driver, misc.dll, 'uGrabFrame', grabber_settings, out, res
			if res eq 'image' and gui.drawId ne -1 then begin
				loadct, 0, /silent
				tvscl, congrid(out.image, gui.drawsize, gui.drawsize)
				thisRate = 1.0/(systime(/sec) - misc.frametime)
				misc.frametime = systime(/sec)
				xyouts, .03, .03, /normal, 'FR: ' + string(thisRate, f='(f0.2)') + ' Hz', color = 255
			endif
		endif

		if (misc.timer_count mod (.2/misc.timer_interval)) eq 0 then begin
			Andor_Camera_Driver, misc.dll, 'uGetStatus', 0, out, res
			widget_control, gui.camStatus, set_value = 'Camera Status: '+out+' ('+res+')'
		endif
		return
	endif

	widget_control, get_uval = uval, event.id

	if size(uval, /type) eq 8 then begin
		case uval.type of
			'settings_write_asc': begin
				fname = dialog_pickfile(/write)
				if fname ne '' then begin
					openw, handle, fname, /get
						Andor_Camera_Driver_GUI_ASCWrite, handle, fname
					close, handle
					free_lun, handle
					Andor_Camera_Driver_GUI_UpdateLog, 'File Write succeeded: ' + fname
				endif else begin
					Andor_Camera_Driver_GUI_UpdateLog, 'File Write failed - bad filename: ' + fname
				endelse
			end
			'settings_read_asc': begin
				fname = dialog_pickfile(/read)
				if fname ne '' then begin
					Andor_Camera_Driver_GUI_ASCRead, fname
					Andor_Camera_Driver_GUI_UpdateLog, 'File Read succeeded: ' + fname
				endif else begin
					Andor_Camera_Driver_GUI_UpdateLog, 'File Read failed - bad filename: ' + fname
				endelse
			end
			'hsspeed_droplist': begin
				misc.settings.hsspeedi = event.index
				Andor_Camera_Driver_GUI_UpdateHSSpeeds, speeds
				Andor_Camera_Driver, misc.dll, 'uSetHSSpeed', event.index, out, res, /auto_acq
				Andor_Camera_Driver_GUI_UpdateLog, 'SetHSSpeed: ' + $
					string(misc.settings.hsspeed, f='(f0.1)') + ' - ' + res
			end
			'vsspeed_droplist': begin
				misc.settings.vsspeedi = event.index
				misc.settings.vsspeed = misc.caps.vsspeeds[event.index]
				Andor_Camera_Driver, misc.dll, 'uSetVSSpeed', event.index, out, res, /auto_acq
				Andor_Camera_Driver_GUI_UpdateLog, 'SetVSSpeed: ' + $
					string(misc.settings.vsspeed, f='(f0.1)') + ' - ' + res
			end
			'vsamps_droplist': begin
				misc.settings.vsamplitude = event.index
				Andor_Camera_Driver, misc.dll, 'uSetVSAmplitude', event.index, out, res, /auto_acq
				Andor_Camera_Driver_GUI_UpdateLog, 'SetVSAmplitude: ' + $
					string(misc.settings.vsamplitude, f='(i0)') + ' - ' + res
			end
			'preamp_droplist': begin
				misc.settings.preAmpGaini = event.index
				misc.settings.preAmpGain = misc.caps.preAmpGains[event.index]
				Andor_Camera_Driver, misc.dll, 'uSetPreAmpGain', event.index, out, res, /auto_acq
				Andor_Camera_Driver_GUI_UpdateLog, 'SetPreAmpGain: ' + $
					string(misc.settings.preAmpGain, f='(f0.1)') + ' - ' + res
			end
			'adchannel_droplist': begin
				misc.settings.adchannel = event.index
				misc.settings.bitdepth = misc.caps.bitdepths[misc.settings.adchannel]
				Andor_Camera_Driver, misc.dll, 'uSetADChannel', event.index, out, res, /auto_acq
				Andor_Camera_Driver_GUI_UpdateLog, 'SetADChannel: ' + $
					string(misc.settings.adchannel, f='(i0)') + ' - ' + res
				Andor_Camera_Driver_GUI_UpdateHSSpeeds
			end
			'outamp_droplist': begin
				misc.settings.outAmp = event.index
				Andor_Camera_Driver, misc.dll, 'uSetOutputAmplifier', event.index, out, res, /auto_acq
				Andor_Camera_Driver_GUI_UpdateLog, 'SetOutputAmplifier: ' + $
					string(misc.settings.outAmp, f='(f0.1)') + ' - ' + res
				Andor_Camera_Driver_GUI_UpdateHSSpeeds
			end
			'imagemode_set': begin
				widget_control, get_value = table, gui.imagemode_table
				;\\ Check pixel and binning bounds...
				if table.xbin le 0 then table.xbin = 1
				if table.ybin le 0 then table.ybin = 1
				if table.xpixstart le 0 then table.xpixstart = 1
				if table.ypixstart le 0 then table.ypixstart = 1
				if table.xpixstop gt misc.caps.pixels[0] then table.xpixstop = misc.caps.pixels[0]
				if table.ypixstop gt misc.caps.pixels[1] then table.ypixstop = misc.caps.pixels[1]
				misc.settings.imageMode = table
				widget_control, set_value = table, gui.imagemode_table
				Andor_Camera_Driver, misc.dll, 'uSetImage', $
					[table.(0),table.(1),table.(2),table.(3),table.(4),table.(5)], out, res, /auto_acq

				Andor_Camera_Driver_GUI_UpdateLog, 'SetImage: ' + $
					'XYBin: [' + string( [table.xbin, table.ybin], f='(i0,",",i0)') + '], '
				Andor_Camera_Driver_GUI_UpdateLog, ' > > ' + 'Pixel Bounds: [' $
					+ string([table.(2),table.(3),table.(4),table.(5)], f='(i0,",",i0,",",i0,",",i0)') + '] - ' + res

			end
			'coolercheck': begin
				misc.settings.cooleron = event.select
				if event.select eq 0 then begin
					Andor_Camera_Driver, misc.dll, 'uCoolerOFF', event.select, out, res, /auto_acq
					Andor_Camera_Driver_GUI_UpdateLog, 'CoolerOFF: ' + res
				endif else begin
					Andor_Camera_Driver, misc.dll, 'uCoolerON', event.select, out, res, /auto_acq
					Andor_Camera_Driver_GUI_UpdateLog, 'CoolerON: ' + res
				endelse
			end
			'clampcheck': begin
				misc.settings.baselineClamp = event.select
				if event.select eq 0 then onoff = 'OFF' else onoff = 'ON'
				Andor_Camera_Driver, misc.dll, 'uSetBaselineClamp', event.select, out, res, /auto_acq
				Andor_Camera_Driver_GUI_UpdateLog, 'BaselineClamping ' + onoff + ': ' + res
			end
			'frametransfer':begin
				misc.settings.frameTransfer = event.select
				if event.select eq 0 then onoff = 'OFF' else onoff = 'ON'
				Andor_Camera_Driver, misc.dll, 'uSetFrameTransferMode', event.select, out, res, /auto_acq
				Andor_Camera_Driver_GUI_UpdateLog, 'FrameTransfer ' + onoff + ': ' + res
			end
			'shuttercheck': begin
				misc.settings.shutterOpen = event.select
				if event.select eq 0 then in = [2,0,10] else in = [1,0,10]
				Andor_Camera_Driver, misc.dll, 'uSetShutter', in, out, res, /auto_acq
				Andor_Camera_Driver_GUI_UpdateLog, 'Shutter ' + string(in[0],f='(i0)') + ': ' + res
			end
			'framegrabcheck': begin
				misc.framegrab = event.select
				if event.select eq 0 then begin
					Andor_Camera_Driver, misc.dll, 'uAbortAcquisition', 0, out, res
				endif else begin
					if misc.acq_setup eq 0 then begin
						;\\ NEED TO SET UP THE ACQUISITION
						Andor_Camera_Driver, misc.dll, 'uApplySettingsStructure', misc.settings, out, res
						for k = 0, n_elements(res) - 1 do $
							Andor_Camera_Driver_GUI_UpdateLog, res[k]
						misc.acq_setup = 1
						Andor_Camera_Driver, misc.dll, 'uStartAcquisition', 0, out, res
					endif else begin
						;\\ START ACQUIRING
						Andor_Camera_Driver, misc.dll, 'uStartAcquisition', 0, out, res
					endelse
				endelse
			end
			'settings_table':begin
				if event.type eq 0 then begin
					if event.ch eq 13 then begin
						;\\ ENTER KEY HAS BEEN PRESSED
						widget_control, get_value = table, event.id
						names = strlowcase(tag_names(table))
						value = table.(event.y)
						case names(event.y) of
							'exptime': begin
								misc.settings.exptime_set = value
								Andor_Camera_Driver, misc.dll, 'uSetExposureTime', value, out, res, /auto_acq
								Andor_Camera_Driver_GUI_UpdateLog, 'SetExpTime: ' + $
									string(misc.settings.exptime_set, f='(f0.3)') + ' - ' + res
								Andor_Camera_Driver_GUI_UpdateInfoList
							end
							'emgain_mode': begin
								misc.settings.emgain_mode = value < 4
								Andor_Camera_Driver, misc.dll, 'uSetEMGainMode', value, out, res, /auto_acq
								Andor_Camera_Driver_GUI_UpdateLog, 'SetEMGainMode: ' + $
									string(misc.settings.emgain_mode, f='(f0.3)') + ' - ' + res
								Andor_Camera_Driver_GUI_UpdateInfoList
							end
							'emadvanced': begin
								misc.settings.emadvanced = value < 2
								Andor_Camera_Driver, misc.dll, 'uSetEMAdvanced', value, out, res, /auto_acq
								Andor_Camera_Driver_GUI_UpdateLog, 'SetEMAdvanced: ' + $
									string(misc.settings.emadvanced, f='(f0.3)') + ' - ' + res
								Andor_Camera_Driver_GUI_UpdateInfoList
							end
							'emgain': begin
								misc.settings.emgain_set = value
								Andor_Camera_Driver, misc.dll, 'uSetEMCCDGain', value, out, res, /auto_acq
								Andor_Camera_Driver_GUI_UpdateLog, 'SetEMCCDGain: ' + $
									string(misc.settings.emgain_set, f='(f0.1)') + ' - ' + res
								Andor_Camera_Driver_GUI_UpdateInfoList
							end
							'cnvgain': begin
								misc.settings.cnvgain_set = value
								Andor_Camera_Driver, misc.dll, 'uSetGain', value, out, res, /auto_acq
								Andor_Camera_Driver_GUI_UpdateLog, 'SetGain: ' + $
									string(misc.settings.cnvgain_set, f='(f0.1)') + ' - ' + res
							end
							'tempset': begin
								misc.settings.settemp = value
								Andor_Camera_Driver, misc.dll, 'uSetTemperature', value, out, res, /auto_acq
								Andor_Camera_Driver_GUI_UpdateLog, 'SetTemperature: ' + $
									string(misc.settings.setTemp, f='(f0.1)') + 'C - ' + res
							end
							'fanmode': begin
								misc.settings.fanmode = value
								Andor_Camera_Driver, misc.dll, 'uSetFanMode', value, out, res, /auto_acq
								Andor_Camera_Driver_GUI_UpdateLog, 'SetFanMode: ' + $
									string(misc.settings.fanmode, f='(f0.1)') + ' - ' + res
							end
							'acqmode': begin
								misc.settings.acqmode = value
								Andor_Camera_Driver, misc.dll, 'uSetAcquisitionMode', value, out, res, /auto_acq
								Andor_Camera_Driver_GUI_UpdateLog, 'SetAcquisitionMode: ' + $
									string(misc.settings.acqmode, f='(f0.1)') + ' - ' + res
							end
							'readmode': begin
								misc.settings.readmode = value
								Andor_Camera_Driver, misc.dll, 'uSetReadMode', value, out, res, /auto_acq
								Andor_Camera_Driver_GUI_UpdateLog, 'SetReadMode: ' + $
									string(misc.settings.readmode, f='(f0.1)') + ' - ' + res
							end
						endcase

					endif
				endif
			end


			else:
		endcase
		Andor_Camera_Driver_GUI_UpdateInfoList
	endif
end


;\\ WRITE THE SETTINGS STRUCTURE TO AN ASC SCRIPT  FILE
pro Andor_Camera_Driver_GUI_ASCWrite, file_handle, file_name
	common ASC_CameraDriverGUI

	pro_name = file_basename(file_name)
	spl = strsplit(pro_name, '.', /extract)
	pro_name = spl[0]

	tab = string(9B) ;\\ Horizontal tab

	printf, file_handle ;\\ Two blank lines
	printf, file_handle ;\\
	printf, file_handle, 'pro ' + pro_name + ', settings = settings'
	printf, file_handle

	tags = strlowcase(tag_names(misc.settings))
	for i = 0, n_elements(tags) - 1 do begin
		type = size(misc.settings.(i), /type)

		if n_elements(misc.settings.(i)) gt 1 then array = 1 else array = 0

		if type eq 8 then begin

			str = 'settings.' + tags[i] + ' = {'
			sub_tags = strlowcase(tag_names(misc.settings.(i)))
			for j = 0, n_elements(sub_tags) - 1 do begin
				sub_type = size(misc.settings.(i).(j), /type)
				if sub_type ge 1 and sub_type le 3 or sub_type ge 12 then fmt = '(i0)'
				if sub_type eq 4 or sub_type eq 5 then fmt = '(f0.10)'
				if sub_type eq 7 then fmt = '(a0)'

				if sub_type ne 7 then begin
				  str += sub_tags[j] + ':' + string(misc.settings.(i).(j), f=fmt)
				endif else begin
				  str += sub_tags[j] + ':"' + string(misc.settings.(i).(j), f=fmt) + '"'
				endelse
				if j ne n_elements(sub_tags) - 1 then str += ', '

			endfor
			printf, file_handle, tab + str + '}'

		endif else begin
			if type ge 1 and type le 3 or type ge 12 then fmt = '(i0)'
			if type eq 4 or type eq 5 then fmt = '(f0.10)'
			if type eq 7 then fmt = '(a0)'

			if array eq 0 then begin
				if type ne 7 then begin
				  printf, file_handle, tab + 'settings.' + tags[i] + ' = ' + string(misc.settings.(i), f=fmt)
				endif else begin
				  printf, file_handle, tab + 'settings.' + tags[i] + ' = "' + string(misc.settings.(i), f=fmt) + '"'
				endelse
			endif else begin
				str = 'settings.' + tags[i] + ' = ['
				for k = 0, n_elements(misc.settings.(i)) - 1 do begin
				  if type ne 7 then begin
					 str += string((misc.settings.(i))[k], f=fmt)
					endif else begin
					 str += '"' + string((misc.settings.(i))[k], f=fmt) + '"'
					endelse
					if k ne n_elements(misc.settings.(i)) - 1 then str += ', '
				endfor
				printf, file_handle, tab + str + ']'
			endelse
		endelse

	endfor

	printf, file_handle
	printf, file_handle, 'end'

end


;\\ READ THE SETTINGS STRUCTURE FROM AN ASC SCRIPT  FILE
pro Andor_Camera_Driver_GUI_ASCRead, file_name
	common ASC_CameraDriverGUI

	pro_name = file_basename(file_name)
	spl = strsplit(pro_name, '.', /extract)
	pro_name = spl[0]

	resolve_routine, pro_name
	sets= misc.settings
	call_procedure, pro_name, settings = sets
	misc.acq_setup = 1
	misc.settings = sets

	Andor_Camera_Driver, misc.dll, 'uApplySettingsStructure', misc.settings, out, res, /auto_acq
	for k = 0, n_elements(res) - 1 do $
		Andor_Camera_Driver_GUI_UpdateLog, res[k]

	;\\ UPDATE THE DROPLISTS
		widget_control, gui.hsspeed_drop, set_droplist_select = misc.settings.hsspeedi
		widget_control, gui.vsspeed_drop, set_droplist_select = misc.settings.vsspeedi
		widget_control, gui.vsamp_drop, set_droplist_select = misc.settings.vsamplitude
		widget_control, gui.adc_drop, set_droplist_select = misc.settings.adchannel
		widget_control, gui.amp_drop, set_droplist_select = misc.settings.outamp
		widget_control, gui.preamp_drop, set_droplist_select = misc.settings.preampgaini

	;\\ UPDATE THE SETTINGS TABLE AND IMAGEMODE TABLE
		settings = {exptime:misc.settings.exptime_set, emgain_mode:misc.settings.emgain_mode, $
					emadvanced:misc.settings.emadvanced, emgain:misc.settings.emgain_set, $
					cnvgain:misc.settings.cnvgain_set, acqmode:misc.settings.acqmode, $
					readmode:misc.settings.readmode, $
					tempset:misc.settings.settemp, fanmode:misc.settings.fanmode}

		widget_control, set_value = settings, gui.set_table
		widget_control, set_value = misc.settings.imagemode, gui.imagemode_table


	;\\ UPDATE THE CHECK BOXES
		if misc.settings.baselineClamp eq 1 then widget_control, set_button=1, gui.clampcheck $
			else widget_control, set_button=0, gui.clampcheck
		if misc.settings.frameTransfer eq 1 then widget_control, set_button=1, gui.frametransfercheck $
			else widget_control, set_button=0, gui.frametransfercheck
		if misc.settings.coolerOn eq 1 then widget_control, set_button=1, gui.coolerCheck $
			else widget_control, set_button=0, gui.coolerCheck
end



;\\ UPDATE HSSPEEDS - THEY VARY DEPENDING ON ADCHANNEL AND OUTPUTAMP
pro Andor_Camera_Driver_GUI_UpdateHSSpeeds, speeds_numeric

	common ASC_CameraDriverGUI

	if size(misc.caps.hsspeeds, /n_dimensions) gt 0 then begin
		speeds = misc.caps.hsspeeds

		match = (where(speeds.adChannel eq misc.settings.adChannel and $
					         speeds.outputAmp eq misc.settings.outAmp, nmatch))[0]

		if nmatch eq 0 then begin
			value = ''
			speeds_numeric = [0]
		endif else begin
			value = string(speeds[match].speeds[0:speeds[match].numHSSpeeds], f='(f0.1)')
			speeds_numeric = speeds[match].speeds[0:speeds[match].numHSSpeeds]
		endelse
	endif else begin
		value = ''
		speeds_numeric = [0]
	endelse

	widget_control, set_value = value, gui.hsspeed_drop
	if misc.settings.hsspeedi le (n_elements(speeds_numeric)-1) then begin
		widget_control, gui.hsspeed_drop, set_droplist_select = misc.settings.hsspeedi
		misc.settings.hsspeed = speeds_numeric(misc.settings.hsspeedi)
		Andor_Camera_Driver, misc.dll, 'uSetHSSpeed', misc.settings.hsspeedi, out, res, /auto_acq
		Andor_Camera_Driver_GUI_UpdateLog, 'SetHSSpeed: ' + $
					string(misc.settings.hsspeed, f='(f0.1)') + ' - ' + res
	endif else begin
		newIndex = 0
		misc.settings.hsspeedi = newIndex
		misc.settings.hsspeed = speeds_numeric(newIndex)
		Andor_Camera_Driver, misc.dll, 'uSetHSSpeed', newIndex, out, res, /auto_acq
		Andor_Camera_Driver_GUI_UpdateLog, 'SetHSSpeed: ' + $
					string(misc.settings.hsspeed, f='(f0.1)') + ' - ' + res
	endelse

end



;\\ UPDATE THE CURRENT INFO LIST
pro Andor_Camera_Driver_GUI_UpdateInfoList

	common ASC_CameraDriverGUI

	need_restart = 0
	Andor_Camera_Driver, misc.dll, 'uIsAcquiring', 0, out, res
	if out eq 1 then begin
		need_restart = 1
		Andor_Camera_Driver, misc.dll, 'uAbortAcquisition'
	endif

	list = 'Exp Time Set: ' + string(misc.settings.exptime_set, f='(f0.5)')
	Andor_Camera_Driver, misc.dll, 'uGetAcquisitionTimings', 0, out, res
	misc.settings.exptime_use = out.exposure
	list = [list, 'Actual Exp. Time: ' + string(out.exposure, f='(f0.5)')]

	list = [list, 'EM Gain Set: ' + string(misc.settings.emgain_set, f='(f0.2)')]
	Andor_Camera_Driver, misc.dll, 'uGetEMCCDGain', 0, out, res
	misc.settings.emgain_use = out
	list = [list, 'Actual EM Gain: ' + string(out, f='(f0.3)')]
	list = [list, 'Conv. Gain Set: ' + string(misc.settings.cnvgain_set, f='(f0.2)')]

	list = [list, 'HS Speed: ' + string(misc.settings.hsspeed, f='(f0.2)')+ $
				' [idx ' + string(misc.settings.hsspeedi, f='(i0)') + ']']

	list = [list, 'VS Speed: ' + string(misc.settings.vsspeed, f='(f0.2)')+ $
				' [idx ' + string(misc.settings.vsspeedi, f='(i0)') + ']']

	list = [list, 'VS Amplitude: ' + string(misc.settings.vsamplitude, f='(f0.2)')]

	list = [list, 'PreAmp Gain: ' + string(misc.settings.preAmpGain, f='(f0.2)') + $
				' [idx ' + string(misc.settings.preAmpGaini, f='(i0)') + ']']

	list = [list, 'AD Channel: ' + string(misc.settings.adchannel, f='(i0)')]
	list = [list, 'Bit Depth: ' + string(misc.settings.bitdepth, f='(i0)')]

	if size(misc.caps.amps, /n_dimensions) ne 0 then $
		list = [list, 'OutputAmp: ' + misc.caps.amps[misc.settings.outAmp].description] $
			else list = [list, 'OutputAmp: N/A']

	Andor_Camera_Driver, misc.dll, 'uGetEMGainRange', 0, out, res
	list = [list, 'Gain Range: ' + string(out, f='("[", i0, ", ", i0, "]")')]

	Andor_Camera_Driver, misc.dll, 'uGetTemperatureRange', 0, out, res
	list = [list, 'Temp Range: ' + string(out, f='("[", i0, ", ", i0, "]")')]

	list = [list, 'Detector Pixels: ' + string(misc.caps.pixels, f='("[", i0, ", ", i0, "]")')]
	list = [list, 'Recommended VS: ' + string([misc.caps.vsrecommended.index, $
				misc.caps.vsrecommended.speed], f='(i0, " (", f0.1, ")")')]

	list = [list, 'Max Exp. Time: ' + string(misc.caps.maxExposureTime, f='(i0)')]
	list = [list, 'Buffer Size: ' + string(misc.caps.buffer_size, f='(i0)') + ' images']

	widget_control, set_value = list, gui.info_list

	if need_restart eq 1 then begin
		Andor_Camera_Driver, misc.dll, 'uFreeInternalMemory'
		Andor_Camera_Driver, misc.dll, 'uStartAcquisition'
	endif
end


;\\ UPDATE THE LOG
pro Andor_Camera_Driver_GUI_UpdateLog, entry

	common ASC_CameraDriverGUI

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


;\\ CLEANUP
pro Andor_Camera_Driver_GUI_Cleanup, event

	common ASC_CameraDriverGUI, gui, misc

	;\\ On cleanup, update settings if given a callback
	;\\ This could fail if the callback is an object method, so catch it:
	catch, error_status

	if error_status ne 0 then begin
		catch, /cancel
		return
	endif

	if (misc.settings_callback ne '') then begin
		call_procedure, misc.settings_callback, misc.settings
	endif

end


pro Andor_Camera_Driver_GUI, dll, embed_in_widget = embed_in_widget, $
								  no_viewer = no_viewer, $
								  initial_settings = initial_settings, $
								  update_settings_callback = update_settings_callback

	common ASC_CameraDriverGUI, gui, misc

	if size(dll, /type) eq 0 then $
		dll = 'SDI_External_ASC.dll'
		;dll = 'C:\Users\sdi3000\ControlSoftware\SDI_External\sdi_external.dll'

	;\\ Fill the capabilities structure...
	Andor_Camera_Driver, dll, 'uGetStatus', 0, out, res

	if res eq 'DRV_NOT_INITIALIZED' then Andor_Camera_Driver, dll, 'uInitialize', '', out, res

	Andor_Camera_Driver, dll, 'uGetCapabilities', 0, caps, res, /auto_acq

	;\\ Camera Settings Structure
	if not keyword_set(initial_settings) then begin
		Andor_Camera_Driver, dll, 'uGetSettingsStructure', 0, settings
		settings.imageMode = {xbin:1, ybin:1, xPixStart:1, xPixStop:caps.pixels[0], yPixStart:1, yPixStop:caps.pixels[1]}

		settings.expTime_set = 0.01
		settings.emgain_set = 2
		settings.emgain_mode = 0
		settings.readMode = 4
		settings.acqMode = 1
		settings.baselineClamp = 1
		settings.frameTransfer = 1
		settings.coolerOn = 1
		settings.setTemp = -50
		settings.hsspeedi = 0
	endif else begin
		settings = initial_settings
	endelse

	misc = {dll:dll, $
			log:{entries:strarr(100), n:0}, $
			timer_interval:0.05, $
			timer_count:0UL, $
			framegrab:0, $
			frametime:0D, $
			acq_setup:0, $
			caps:caps, $
			settings:settings, $
			settings_callback:''}

	if keyword_set(update_settings_callback) then misc.settings_callback = update_settings_callback

	;\\ Initiate the GUI
	if keyword_set(embed_in_widget) then Andor_Camera_Driver_GUI_Init, base = embed_in_widget, no_viewer=no_viewer $
		else Andor_Camera_Driver_GUI_Init, no_viewer=no_viewer

	Andor_Camera_Driver_GUI_UpdateHSSpeeds
	Andor_Camera_Driver_GUI_UpdateInfoList

		xmanager, 'Andor_Camera_Driver_GUI', gui.base, $
					event_handler = 'Andor_Camera_Driver_GUI_Event', $
					cleanup = 'Andor_Camera_Driver_GUI_Cleanup', /no_block


end
