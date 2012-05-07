
pro sdi_Andor_Camera_Driver_GUI_Init, base_widget=base_widget, $
									  no_viewer = no_viewer

	common SDI_CameraDriverGUI, gui, misc

	font = 'Ariel*16*Bold'

	driver_str = 'Driver Version: ' + string(misc.caps.softwareVersion[3], f='(f0.2)') $
					+ ', rev ' + string(misc.caps.softwareVersion[2], f='(f0.2)')
	dll_str = 'DLL Version: ' + string(misc.caps.softwareVersion[5], f='(f0.2)') $
					+ ', rev ' + string(misc.caps.softwareVersion[4], f='(f0.2)')

	if not keyword_set(base_widget) then begin
		base = widget_base(col=1, title = 'Andor Camera Driver (' + driver_str + ' | ' + dll_str + ')')
	endif else begin
		base = base_widget
	endelse

	info_base = widget_base(base, col=3)
	log = widget_list(info_base, xs = 50, ys = 20, value='', font=font)
	info = widget_list(info_base, xs = 30, ys = 20, value = infoList, font=font)
	drawsize =300
	if not keyword_set(no_viewer) then $
		draw = widget_draw(info_base, xs = drawsize, ys = drawsize)

	;\\ CAMERA STATUS, TEMPERATURE, ETC.
		stat_base = widget_base(base, col = 2)
		stat_label = widget_label(stat_base, value = 'Camera Status: ', font=font, xs=500)


	;\\ SETTINGS BASE
		set_base = widget_base(base, col = 2)

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

		lower_base = widget_base(base, col=2)
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
		   preamp_drop:preamp_drop}

end


;\\ EVENT HANDLER
pro sdi_Andor_Camera_Driver_GUI_Event, event

	common SDI_CameraDriverGUI

	;\\ TIMER EVENT, INCREMENT THE TIMER COUNTER
	if (size(event, /structure)).structure_name eq 'WIDGET_TIMER' then begin
		widget_control, timer = misc.timer_interval, gui.info_base
		misc.timer_count ++

		if (misc.framegrab eq 1) then begin
			if gui.drawId ne -1 then wset, gui.drawId
			grabber_settings = {mode:misc.settings.acqMode, imageMode:misc.settings.imageMode}

			sdi_Andor_Camera_Driver, misc.dll, 'uGrabFrame', grabber_settings, out, res
			if res eq 'image' and gui.drawId ne -1 then begin
				loadct, 0, /silent
				tvscl, congrid(out, gui.drawsize, gui.drawsize)
				thisRate = 1.0/(systime(/sec) - misc.frametime)
				misc.frametime = systime(/sec)
				xyouts, .03, .03, /normal, 'FR: ' + string(thisRate, f='(f0.2)') + ' Hz', color = 255
			endif
		endif

		if (misc.timer_count mod (.2/misc.timer_interval)) eq 0 then begin
			sdi_Andor_Camera_Driver, misc.dll, 'uGetStatus', 0, out, res
			widget_control, gui.camStatus, set_value = 'Camera Status: '+out+' ('+res+')'
		endif
		return
	endif

	widget_control, get_uval = uval, event.id

	if size(uval, /type) eq 8 then begin
		case uval.type of
			'hsspeed_droplist': begin
				misc.settings.hsspeedi = event.index
				sdi_Andor_Camera_Driver_GUI_UpdateHSSpeeds, speeds
				sdi_Andor_Camera_Driver, misc.dll, 'uSetHSSpeed', event.index, out, res, /auto_acq
				sdi_Andor_Camera_Driver_GUI_UpdateLog, 'SetHSSpeed: ' + $
					string(misc.settings.hsspeed, f='(f0.1)') + ' - ' + res
			end
			'vsspeed_droplist': begin
				misc.settings.vsspeedi = event.index
				misc.settings.vsspeed = misc.caps.vsspeeds[event.index]
				sdi_Andor_Camera_Driver, misc.dll, 'uSetVSSpeed', event.index, out, res, /auto_acq
				sdi_Andor_Camera_Driver_GUI_UpdateLog, 'SetVSSpeed: ' + $
					string(misc.settings.vsspeed, f='(f0.1)') + ' - ' + res
			end
			'vsamps_droplist': begin
				misc.settings.vsamplitude = event.index
				sdi_Andor_Camera_Driver, misc.dll, 'uSetVSAmplitude', event.index, out, res, /auto_acq
				sdi_Andor_Camera_Driver_GUI_UpdateLog, 'SetVSAmplitude: ' + $
					string(misc.settings.vsamplitude, f='(i0)') + ' - ' + res
			end
			'preamp_droplist': begin
				misc.settings.preAmpGaini = event.index
				misc.settings.preAmpGain = misc.caps.preAmpGains[event.index]
				sdi_Andor_Camera_Driver, misc.dll, 'uSetPreAmpGain', event.index, out, res, /auto_acq
				sdi_Andor_Camera_Driver_GUI_UpdateLog, 'SetPreAmpGain: ' + $
					string(misc.settings.preAmpGain, f='(f0.1)') + ' - ' + res
			end
			'adchannel_droplist': begin
				misc.settings.adchannel = event.index
				misc.settings.bitdepth = misc.caps.bitdepths[misc.settings.adchannel]
				sdi_Andor_Camera_Driver, misc.dll, 'uSetADChannel', event.index, out, res, /auto_acq
				sdi_Andor_Camera_Driver_GUI_UpdateLog, 'SetADChannel: ' + $
					string(misc.settings.adchannel, f='(i0)') + ' - ' + res
				sdi_Andor_Camera_Driver_GUI_UpdateHSSpeeds
			end
			'outamp_droplist': begin
				misc.settings.outAmp = event.index
				sdi_Andor_Camera_Driver, misc.dll, 'uSetOutputAmplifier', event.index, out, res, /auto_acq
				sdi_Andor_Camera_Driver_GUI_UpdateLog, 'SetOutputAmplifier: ' + $
					string(misc.settings.outAmp, f='(f0.1)') + ' - ' + res
				sdi_Andor_Camera_Driver_GUI_UpdateHSSpeeds
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
				sdi_Andor_Camera_Driver, misc.dll, 'uSetImage', $
					[table.(0),table.(1),table.(2),table.(3),table.(4),table.(5)], out, res, /auto_acq

				sdi_Andor_Camera_Driver_GUI_UpdateLog, 'SetImage: ' + $
					'XYBin: [' + string( [table.xbin, table.ybin], f='(i0,",",i0)') + '], '
				sdi_Andor_Camera_Driver_GUI_UpdateLog, ' > > ' + 'Pixel Bounds: [' $
					+ string([table.(2),table.(3),table.(4),table.(5)], f='(i0,",",i0,",",i0,",",i0)') + '] - ' + res

			end
			'coolercheck': begin
				misc.settings.cooleron = event.select
				if event.select eq 0 then begin
					sdi_Andor_Camera_Driver, misc.dll, 'uCoolerOFF', event.select, out, res, /auto_acq
					sdi_Andor_Camera_Driver_GUI_UpdateLog, 'CoolerOFF: ' + res
				endif else begin
					sdi_Andor_Camera_Driver, misc.dll, 'uCoolerON', event.select, out, res, /auto_acq
					sdi_Andor_Camera_Driver_GUI_UpdateLog, 'CoolerON: ' + res
				endelse
			end
			'clampcheck': begin
				misc.settings.baselineClamp = event.select
				if event.select eq 0 then onoff = 'OFF' else onoff = 'ON'
				sdi_Andor_Camera_Driver, misc.dll, 'uSetBaselineClamp', event.select, out, res, /auto_acq
				sdi_Andor_Camera_Driver_GUI_UpdateLog, 'BaselineClamping ' + onoff + ': ' + res
			end
			'frametransfer':begin
				misc.settings.frameTransfer = event.select
				if event.select eq 0 then onoff = 'OFF' else onoff = 'ON'
				sdi_Andor_Camera_Driver, misc.dll, 'uSetFrameTransferMode', event.select, out, res, /auto_acq
				sdi_Andor_Camera_Driver_GUI_UpdateLog, 'FrameTransfer ' + onoff + ': ' + res
			end
			'shuttercheck': begin
				misc.settings.shutterOpen = event.select
				if event.select eq 0 then in = [2,0,10] else in = [1,0,10]
				sdi_Andor_Camera_Driver, misc.dll, 'uSetShutter', in, out, res, /auto_acq
				sdi_Andor_Camera_Driver_GUI_UpdateLog, 'Shutter ' + string(in[0],f='(i0)') + ': ' + res
			end
			'framegrabcheck': begin
				misc.framegrab = event.select
				if event.select eq 0 then begin
					sdi_Andor_Camera_Driver, misc.dll, 'uAbortAcquisition', 0, out, res
				endif else begin
					if misc.acq_setup eq 0 then begin
						;\\ NEED TO SET UP THE ACQUISITION
						sdi_Andor_Camera_Driver, misc.dll, 'uApplySettingsStructure', misc.settings, out, res
						for k = 0, n_elements(res) - 1 do $
							sdi_Andor_Camera_Driver_GUI_UpdateLog, res[k]
						misc.acq_setup = 1
						sdi_Andor_Camera_Driver, misc.dll, 'uStartAcquisition', 0, out, res
					endif else begin
						;\\ START ACQUIRING
						sdi_Andor_Camera_Driver, misc.dll, 'uStartAcquisition', 0, out, res
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
								sdi_Andor_Camera_Driver, misc.dll, 'uSetExposureTime', value, out, res, /auto_acq
								sdi_Andor_Camera_Driver_GUI_UpdateLog, 'SetExpTime: ' + $
									string(misc.settings.exptime_set, f='(f0.3)') + ' - ' + res
								sdi_Andor_Camera_Driver_GUI_UpdateInfoList
							end
							'emgain_mode': begin
								misc.settings.emgain_mode = value < 4
								sdi_Andor_Camera_Driver, misc.dll, 'uSetEMGainMode', value, out, res, /auto_acq
								sdi_Andor_Camera_Driver_GUI_UpdateLog, 'SetEMGainMode: ' + $
									string(misc.settings.emgain_mode, f='(f0.3)') + ' - ' + res
								sdi_Andor_Camera_Driver_GUI_UpdateInfoList
							end
							'emadvanced': begin
								misc.settings.emadvanced = value < 2
								sdi_Andor_Camera_Driver, misc.dll, 'uSetEMAdvanced', value, out, res, /auto_acq
								sdi_Andor_Camera_Driver_GUI_UpdateLog, 'SetEMAdvanced: ' + $
									string(misc.settings.emadvanced, f='(f0.3)') + ' - ' + res
								sdi_Andor_Camera_Driver_GUI_UpdateInfoList
							end
							'emgain': begin
								misc.settings.emgain_set = value
								sdi_Andor_Camera_Driver, misc.dll, 'uSetEMCCDGain', value, out, res, /auto_acq
								sdi_Andor_Camera_Driver_GUI_UpdateLog, 'SetEMCCDGain: ' + $
									string(misc.settings.emgain_set, f='(f0.1)') + ' - ' + res
								sdi_Andor_Camera_Driver_GUI_UpdateInfoList
							end
							'cnvgain': begin
								misc.settings.cnvgain_set = value
								sdi_Andor_Camera_Driver, misc.dll, 'uSetGain', value, out, res, /auto_acq
								sdi_Andor_Camera_Driver_GUI_UpdateLog, 'SetGain: ' + $
									string(misc.settings.cnvgain_set, f='(f0.1)') + ' - ' + res
							end
							'tempset': begin
								misc.settings.settemp = value
								sdi_Andor_Camera_Driver, misc.dll, 'uSetTemperature', value, out, res, /auto_acq
								sdi_Andor_Camera_Driver_GUI_UpdateLog, 'SetTemperature: ' + $
									string(misc.settings.setTemp, f='(f0.1)') + 'C - ' + res
							end
							'fanmode': begin
								misc.settings.fanmode = value
								sdi_Andor_Camera_Driver, misc.dll, 'uSetFanMode', value, out, res, /auto_acq
								sdi_Andor_Camera_Driver_GUI_UpdateLog, 'SetFanMode: ' + $
									string(misc.settings.fanmode, f='(f0.1)') + ' - ' + res
							end
							'acqmode': begin
								misc.settings.acqmode = value
								sdi_Andor_Camera_Driver, misc.dll, 'uSetAcquisitionMode', value, out, res, /auto_acq
								sdi_Andor_Camera_Driver_GUI_UpdateLog, 'SetAcquisitionMode: ' + $
									string(misc.settings.acqmode, f='(f0.1)') + ' - ' + res
							end
							'readmode': begin
								misc.settings.readmode = value
								sdi_Andor_Camera_Driver, misc.dll, 'uSetReadMode', value, out, res, /auto_acq
								sdi_Andor_Camera_Driver_GUI_UpdateLog, 'SetReadMode: ' + $
									string(misc.settings.readmode, f='(f0.1)') + ' - ' + res
							end
						endcase

					endif
				endif
			end


			else:
		endcase
		sdi_Andor_Camera_Driver_GUI_UpdateInfoList
	endif
end



;\\ UPDATE HSSPEEDS - THEY VARY DEPENDING ON ADCHANNEL AND OUTPUTAMP
pro sdi_Andor_Camera_Driver_GUI_UpdateHSSpeeds, speeds_numeric

	common SDI_CameraDriverGUI

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
		sdi_Andor_Camera_Driver, misc.dll, 'uSetHSSpeed', misc.settings.hsspeedi, out, res, /auto_acq
		sdi_Andor_Camera_Driver_GUI_UpdateLog, 'SetHSSpeed: ' + $
					string(misc.settings.hsspeed, f='(f0.1)') + ' - ' + res
	endif else begin
		newIndex = 0
		misc.settings.hsspeedi = newIndex
		misc.settings.hsspeed = speeds_numeric(newIndex)
		sdi_Andor_Camera_Driver, misc.dll, 'uSetHSSpeed', newIndex, out, res, /auto_acq
		sdi_Andor_Camera_Driver_GUI_UpdateLog, 'SetHSSpeed: ' + $
					string(misc.settings.hsspeed, f='(f0.1)') + ' - ' + res
	endelse

end



;\\ UPDATE THE CURRENT INFO LIST
pro sdi_Andor_Camera_Driver_GUI_UpdateInfoList

	common SDI_CameraDriverGUI

	need_restart = 0
	sdi_Andor_Camera_Driver, misc.dll, 'uIsAcquiring', 0, out, res
	if out eq 1 then begin
		need_restart = 1
		sdi_Andor_Camera_Driver, misc.dll, 'uAbortAcquisition'
	endif

	list = 'Exp Time Set: ' + string(misc.settings.exptime_set, f='(f0.5)')
	sdi_Andor_Camera_Driver, misc.dll, 'uGetAcquisitionTimings', 0, out, res
	misc.settings.exptime_use = out.exposure
	list = [list, 'Actual Exp. Time: ' + string(out.exposure, f='(f0.5)')]

	list = [list, 'EM Gain Set: ' + string(misc.settings.emgain_set, f='(f0.2)')]
	sdi_Andor_Camera_Driver, misc.dll, 'uGetEMCCDGain', 0, out, res
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

	sdi_Andor_Camera_Driver, misc.dll, 'uGetEMGainRange', 0, out, res
	list = [list, 'Gain Range: ' + string(out, f='("[", i0, ", ", i0, "]")')]

	sdi_Andor_Camera_Driver, misc.dll, 'uGetTemperatureRange', 0, out, res
	list = [list, 'Temp Range: ' + string(out, f='("[", i0, ", ", i0, "]")')]

	list = [list, 'Detector Pixels: ' + string(misc.caps.pixels, f='("[", i0, ", ", i0, "]")')]
	list = [list, 'Recommended VS: ' + string([misc.caps.vsrecommended.index, $
				misc.caps.vsrecommended.speed], f='(i0, " (", f0.1, ")")')]

	list = [list, 'Max Exp. Time: ' + string(misc.caps.maxExposureTime, f='(i0)')]
	list = [list, 'Buffer Size: ' + string(misc.caps.buffer_size, f='(i0)') + ' images']

	widget_control, set_value = list, gui.info_list

	if need_restart eq 1 then begin
		sdi_Andor_Camera_Driver, misc.dll, 'uFreeInternalMemory'
		sdi_Andor_Camera_Driver, misc.dll, 'uStartAcquisition'
	endif
end


;\\ UPDATE THE LOG
pro sdi_Andor_Camera_Driver_GUI_UpdateLog, entry

	common SDI_CameraDriverGUI

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


pro sdi_Andor_Camera_Driver_GUI, dll, embed_in_widget = embed_in_widget, $
									  no_viewer = no_viewer

	common SDI_CameraDriverGUI, gui, misc

	if size(dll, /type) eq 0 then $
		dll = 'C:\cal\idlsource\sdicontrol\external\sdi_external.dll'

	;\\ Fill the capabilities structure...
	sdi_Andor_Camera_Driver, dll, 'uGetStatus', 0, out, res

	if res eq 'DRV_NOT_INITIALIZED' then sdi_Andor_Camera_Driver, dll, 'uInitialize', '', out, res


	sdi_Andor_Camera_Driver, dll, 'uGetCapabilities', 0, caps, res, /auto_acq

	;\\ Camera Settings Structure
	sdi_Andor_Camera_Driver, dll, 'uGetSettingsStructure', 0, settings
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

	misc = {dll:dll, $
			log:{entries:strarr(100), n:0}, $
			timer_interval:0.05, $
			timer_count:0UL, $
			framegrab:0, $
			frametime:0D, $
			acq_setup:0, $
			caps:caps, $
			settings:settings}

	;\\ Initiate the GUI
	if keyword_set(embed_in_widget) then sdi_Andor_Camera_Driver_GUI_Init, base = embed_in_widget, no_viewer=no_viewer $
		else sdi_Andor_Camera_Driver_GUI_Init, no_viewer=no_viewer

	sdi_Andor_Camera_Driver_GUI_UpdateHSSpeeds
	sdi_Andor_Camera_Driver_GUI_UpdateInfoList


	xmanager, 'sdi_Andor_Camera_Driver_GUI', gui.base, $
				event_handler = 'sdi_Andor_Camera_Driver_GUI_Event', /no_block

end
