
function DCAI_Etalon::init

	common DCAI_Control, dcai_global


	;\\ WHEN PLUGIN LOADS, STORE CURRENT LEG OFFSETS AND GAINS, SO THEY CAN BE RESTORED
		self.info_restore = 1
		self.info_save = ptr_new(dcai_global.settings.etalon)

	;\\ DEFAULTS
		self.parallel_step = [10,10]

	;\\ SAVE FIELDS
		self.save_tags = ['scan_range', 'step_size', 'move_together', 'parallel_step']

	;\\ RESTORE SAVED SETTINGS
		self->load_settings


	;\\ CREATE THE GUI
		font = dcai_global.gui.font
		_base = widget_base(group=dcai_global.gui.base, col=1, uval={tag:'plugin_base', object:self}, title = 'Etalon', $
							xoffset = self.xpos, yoffset = self.ypos, /base_align_center, tab_mode=1)


		n_etalons = n_elements(dcai_global.settings.etalon)
		leg_bar_wids = lonarr(n_etalons, 3)

		base_top = widget_base(_base, col = n_etalons)

		for i = 0, n_etalons - 1 do begin

			e = dcai_global.settings.etalon[i]

			base_left = widget_base(base_top, col = 1, frame = 1, /base_align_center)
				label = widget_label(base_left, value = 'Etalon ' + string(i, f='(i0)'), font = font + '*Bold')
				vrange = 'Voltage Range: ' + string(dcai_global.settings.etalon[i].voltage_range[0], f='(i0)') + $
						 '...' + string(dcai_global.settings.etalon[i].voltage_range[1], f='(i0)')
				label = widget_label(base_left, value = vrange, font = font)

				;\\ LEG VALUE INDICATORS
				leg_base = widget_base(base_left, row = 3)
					leg1_base = widget_base(leg_base, col = 3)
						leg1_lab = widget_label(leg1_base, value = 'Leg 1', font=font)
						leg1_bar = widget_draw(leg1_base, xs = 150, ys = 16)
						leg1_val = widget_label(leg1_base, value = string(e.leg_voltage[0], f='(i0)'), font=font, xs=50 )
					leg2_base = widget_base(leg_base, col = 3)
						leg2_lab = widget_label(leg2_base, value = 'Leg 2', font=font)
						leg2_bar = widget_draw(leg2_base, xs = 150, ys = 16)
						leg2_val = widget_label(leg2_base, value = string(e.leg_voltage[1], f='(i0)'), font=font, xs=50 )
					leg3_base = widget_base(leg_base, col = 3)
						leg3_lab = widget_label(leg3_base, value = 'Leg 3', font=font)
						leg3_bar = widget_draw(leg3_base, xs = 150, ys = 16)
						leg3_val = widget_label(leg3_base, value = string(e.leg_voltage[2], f='(i0)'), font=font, xs=50 )

					leg_bar_wids[i,*] = [leg1_bar, leg2_bar, leg3_bar]
					self.leg_val_ids[i,*] = [leg1_val, leg2_val, leg3_val]


				edit_base = widget_base(base_left, col = 3, /base_align_center)

					;\\ LEG OFFSET EDITS
					offset_edit = widget_base(edit_base, col = 1)
					parallel_label = widget_label(offset_edit, value='Leg Tilt', font=font+'*Bold')
					widget_edit_field, offset_edit, label = 'Leg 1', font = font, start_val=string(e.parallel_offset[0], f='(i0)'), /column, $
								edit_uval = {tag:'plugin_event', object:self, method:'LegOffsetEdit', etalon:i, leg:0}, edit_xs = 10, ids=ids
					self.parallel_offset_ids[i,0] = ids.text
					widget_edit_field, offset_edit, label = 'Leg 2', font = font, start_val=string(e.parallel_offset[1], f='(i0)'), /column, $
								edit_uval = {tag:'plugin_event', object:self, method:'LegOffsetEdit', etalon:i, leg:1}, edit_xs = 10, ids=ids
					self.parallel_offset_ids[i,1] = ids.text
					widget_edit_field, offset_edit, label = 'Leg 3', font = font, start_val=string(e.parallel_offset[2], f='(i0)'), /column,  $
								edit_uval = {tag:'plugin_event', object:self, method:'LegOffsetEdit', etalon:i, leg:2}, edit_xs = 10, ids=ids
					self.parallel_offset_ids[i,2] = ids.text

					;\\ LEG GAIN EDITS
					offset_edit = widget_base(edit_base, col = 1)
					gain_label = widget_label(offset_edit, value='Leg Gain', font=font+'*Bold')
					widget_edit_field, offset_edit, label = '', font = font, start_val=string(e.leg_gain[0], f='(f0.5)'), /column,  $
								edit_uval = {tag:'plugin_event', object:self, method:'LegGainEdit', etalon:i, leg:0}, edit_xs = 10, ids=ids
					self.gain_ids[i,0] = ids.text
					widget_edit_field, offset_edit, label = '', font = font, start_val=string(e.leg_gain[1], f='(f0.5)'), /column,  $
								edit_uval = {tag:'plugin_event', object:self, method:'LegGainEdit', etalon:i, leg:1}, edit_xs = 10, ids=ids
					self.gain_ids[i,1] = ids.text
					widget_edit_field, offset_edit, label = '', font = font, start_val=string(e.leg_gain[2], f='(f0.5)'), /column,  $
								edit_uval = {tag:'plugin_event', object:self, method:'LegGainEdit', etalon:i, leg:2}, edit_xs = 10, ids=ids
					self.gain_ids[i,2] = ids.text

					gain_set_base = widget_base(edit_base, col=1)
					gain_label = widget_label(gain_set_base, value='Gain Calculate', font=font+'*Bold')
						btn = widget_button(gain_set_base, value='Set Reference', font=font, $
									uval={tag:'plugin_event', object:self, method:'GainCalculate', action:'set', etalon:i})
						btn = widget_button(gain_set_base, value='Calculate', font=font, $
									uval={tag:'plugin_event', object:self, method:'GainCalculate', action:'calc', etalon:i})
						btn = widget_button(gain_set_base, value='Reset All', font=font, $
									uval={tag:'plugin_event', object:self, method:'GainCalculate', action:'reset', etalon:i})


					;\\ SCAN VOLTAGE
					widget_edit_field, base_left, label = 'Scan Voltage', font = font+'*Bold', start_val=string(e.scan_voltage, f='(i0)'), /column, $
								edit_uval = {tag:'plugin_event', object:self, method:'ScanVoltageEdit', etalon:i}, edit_xs = 10, ids=ids


				slider_base = widget_base(base_left, row = 4, frame=1)
					;\\ LEG SLIDERS
					together_base = widget_base(slider_base, /nonexclusive)
					rel_move = widget_button(together_base, value = 'Maintain Relative Offsets', $
														  uval = {tag:'plugin_event', object:self, method:'MoveTogether', etalon:i}, font=font)
					if self.move_together[i] eq 1 then widget_control, rel_move, /set_button
					leg1_slider = widget_slider(slider_base, max = e.voltage_range[1], min = e.voltage_range[0], xs = 300, value = e.leg_voltage[0], font=font, $
												/align_center, title = 'Leg 1', uval = {tag:'plugin_event', object:self, method:'LegSlider', etalon:i, leg:0}, /drag)
					leg2_slider = widget_slider(slider_base, max = e.voltage_range[1], min = e.voltage_range[0], xs = 300, value = e.leg_voltage[1], font=font, $
												/align_center, title = 'Leg 2', uval = {tag:'plugin_event', object:self, method:'LegSlider', etalon:i, leg:1}, /drag)
					leg3_slider = widget_slider(slider_base, max = e.voltage_range[1], min = e.voltage_range[0], xs = 300, value = e.leg_voltage[2], font=font, $
												/align_center, title = 'Leg 3', uval = {tag:'plugin_event', object:self, method:'LegSlider', etalon:i, leg:2}, /drag)
					self.slider_ids[i,*] = [leg1_slider, leg2_slider, leg3_slider]


				;\\ TWO-AXIS PARALLELISM
				parallel_base = widget_base(base_left, col = 1, frame=0)
					parallel_lab = widget_label(parallel_base, value = '2-Axis Parallelism', font=font+ '*Bold', /align_center)
					parallel_base_1 = widget_base(parallel_base, col = 5)
						x_up = widget_button(parallel_base_1, value = 'X+', font=font, uval={tag:'plugin_event', object:self, method:'TwoAxisParallel', action:'x+', etalon:i}, xs=47)
						x_down = widget_button(parallel_base_1, value = 'X-', font=font, uval={tag:'plugin_event', object:self, method:'TwoAxisParallel', action:'x-', etalon:i}, xs=47)
						y_up = widget_button(parallel_base_1, value = 'Y+', font=font, uval={tag:'plugin_event', object:self, method:'TwoAxisParallel', action:'y+', etalon:i}, xs=47)
						y_down = widget_button(parallel_base_1, value = 'Y-', font=font, uval={tag:'plugin_event', object:self, method:'TwoAxisParallel', action:'y-', etalon:i}, xs=47)

						widget_edit_field, parallel_base_1, label = 'Step Size', font = font, start_val=string(self.parallel_step[i], f='(f0.5)'), $
										   edit_uval = {tag:'plugin_event', object:self, method:'TwoAxisParallel', action:'step', etalon:i}, edit_xs = 10


				;\\ SOME EXTRA BUTTONS
				btn_base = widget_base(base_left, col=3)

					;\\ APPLY WEDGE
					wedge_btn = widget_button(btn_base, value = 'Apply Wedge', font=dcai_global.gui.font, $
											  uval = {tag:'plugin_event', object:self, method:'ApplyWedge', etalon:i})

					;\\ ADD A BUTTON TO RESET LEGS TO SCAN VOLTAGE + PARALLEL TILTS
					reset_btn = widget_button(btn_base, value = 'Reset Legs', font=dcai_global.gui.font, $
											  uval = {tag:'plugin_event', object:self, method:'ResetLegs', etalon:i})

					;\\ ADD A BUTTON TO APPLY THE CURRENT LEG OFFSETS AND GAINS TO THE SETTINGS FILE, AND SAVE THEM
					apply_btn = widget_button(btn_base, value = 'Apply Current Settings', font=dcai_global.gui.font, $
											  uval = {tag:'plugin_event', object:self, method:'ApplySettings', etalon:i})

		endfor

	;\\ REGISTER FOR TIMER EVENTS
		DCAI_Control_RegisterPlugin, _base, self, /timer

	for i = 0, n_etalons - 1 do begin
		widget_control, get_value = leg1_id, leg_bar_wids[i,0]
		widget_control, get_value = leg2_id, leg_bar_wids[i,1]
		widget_control, get_value = leg3_id, leg_bar_wids[i,2]
		self.leg_bar_ids[i,*] = [leg1_id,  leg2_id,  leg3_id]
	endfor

	self->LegUpdate

	self.id = _base
	return, 1
end


;\\ TIMER EVENTS
pro DCAI_Etalon::timer
	self->LegUpdate
end



;\\ UPDATE THE ETALON LEG INDICATORS
pro DCAI_Etalon::LegUpdate, force_slider=force_slider

	COMMON DCAI_Control, dcai_global

	;\\ STORE THE CURRENT CTABLE
	tvlct, r, g, b, /get

	loadct, 39, /silent

	for ii = 0, n_elements(dcai_global.settings.etalon) - 1 do begin

		e = dcai_global.settings.etalon[ii]
		for i = 0, 2 do begin
			wset, self.leg_bar_ids[ii,i]
			erase, 0
			polyfill, [0, 0, 1, 1] * e.leg_voltage[i]/float(e.voltage_range[1]), [.01,.9,.9,.01], color=80, /normal
			widget_control, set_value = string(e.leg_voltage[i], f='(i0)'), self.leg_val_ids[ii,i]
			if keyword_set(force_slider) or dcai_global.scan.scanning[ii] eq 1 then begin
				widget_control, set_value = e.leg_voltage[i], self.slider_ids[ii, i]
			endif
		endfor

	endfor

	;\\ RESTORE THE PREVIOUS CTABLE
	tvlct, r, g, b

end


;\\ APPLY THE CURRENT LEF GAINS AND OFFSETS TO THE SAVE FILE, AND SAVE THEM
pro DCAI_Etalon::ApplySettings, event

	COMMON DCAI_Control, dcai_global

	widget_control, get_uval=uval, event.id

	self->UpdateParallelOffsets, uval.etalon

	self.info_restore = 0
	DCAI_SettingsWrite, dcai_global.settings, dcai_global.info.settings_file
end


;\\ RESET LEGS TO SCAN VOLTAGE + PARALLEL TILTS
pro DCAI_Etalon::ResetLegs, event

	COMMON DCAI_Control, dcai_global

	widget_control, get_uval=uval, event.id

	arg = {etalon:uval.etalon, voltage:dcai_global.settings.etalon[uval.etalon].scan_voltage}
	success = DCAI_ScanControl('setnominal', 'dummy', arg)
	self->LegUpdate, /force
end


;\\ PROCEDURE FOR LEG OFFSET EDIT BOXES
pro DCAI_Etalon::LegOffsetEdit, event

	COMMON DCAI_Control, dcai_global

	widget_control, get_uval = uval, event.id
	widget_control, get_value = val, event.id
	dcai_global.settings.etalon[uval.etalon].parallel_offset[uval.leg] = fix(val, type=3)
end

;\\ PROCEDURE FOR LEG GAIN EDIT BOXES
pro DCAI_Etalon::LegGainEdit, event

	COMMON DCAI_Control, dcai_global

	widget_control, get_uval = uval, event.id
	widget_control, get_value = val, event.id
	dcai_global.settings.etalon[uval.etalon].leg_gain[uval.leg] = float(val)
end

;\\ PROCEDURE FOR SCAN VOLTAGE EDIT BOX
pro DCAI_Etalon::ScanVoltageEdit, event

	COMMON DCAI_Control, dcai_global

	widget_control, get_uval = uval, event.id
	widget_control, get_value = val, event.id
	dcai_global.settings.etalon[uval.etalon].scan_voltage = fix(val, type=3)
end


;\\ CALCULATE GAINS
pro DCAI_Etalon::GainCalculate, event

	COMMON DCAI_Control, dcai_global

	widget_control, get_uval = uval, event.id

	case uval.action of
		'reset':dcai_global.settings.etalon[uval.etalon].leg_gain[*] = 1.0
		'set':self.gain_refs[uval.etalon,*] = dcai_global.settings.etalon[uval.etalon].leg_voltage
		'calc': begin
			leg_diffs = (dcai_global.settings.etalon[uval.etalon].leg_voltage - reform(self.gain_refs[uval.etalon,*]))
			leg_gain = leg_diffs / float(dcai_global.settings.etalon[uval.etalon].leg_voltage[0])
			leg_gain = float(leg_gain)/float(leg_gain[0])
			pts = where(leg_gain eq 0 or finite(leg_gain) eq 0, n_zero)
			if n_zero gt 0 then leg_gain[pts] = 1
			dcai_global.settings.etalon[uval.etalon].leg_gain = leg_gain
		end
		else:
	endcase

	for leg = 0, 2 do $
		widget_control, set_value=string(dcai_global.settings.etalon[uval.etalon].leg_gain[leg], f='(f0.5)'), $
						self.gain_ids[uval.etalon,leg]

end


;\\ PROCEDURE FOR APPLYING WEDGE
pro DCAI_Etalon::ApplyWedge, event

	COMMON DCAI_Control, dcai_global

	widget_control, get_uval = uval, event.id

	volts = dcai_global.settings.etalon[uval.etalon].wedge_voltage
	dcai_global.settings.etalon[uval.etalon].leg_voltage = volts

	command = {device:'etalon_setlegs', number:uval.etalon, $
					   port:dcai_global.settings.etalon[uval.etalon].port, $
					   voltage:dcai_global.settings.etalon[uval.etalon].leg_voltage}
	call_procedure, dcai_global.info.drivers, command

	self->LegUpdate, /force_slider

end


;\\ PROCEDURE FOR STEP SIZE EDIT BOXES
pro DCAI_Etalon::StepSizeEdit, event
	widget_control, get_uval = uval, event.id
	widget_control, get_value = val, event.id
	self.step_size[uval.etalon] = fix(val)
end


;\\ PROCEDURE FOR TOGGLING THE OPTION TO MOVE ALL LEGS TOGETHER
pro DCAI_Etalon::MoveTogether, event
	widget_control, get_uval = uval, event.id
	self.move_together[uval.etalon] = event.select
end


;\\ PROCEDURE FOR LEG SLIDER EVENTS
pro DCAI_Etalon::LegSlider, event

	COMMON DCAI_Control, dcai_global

	widget_control, get_uval = uval, event.id
	ids = reform(self.slider_ids[uval.etalon,*])
	move_together = self.move_together[uval.etalon]
	etalon = dcai_global.settings.etalon[uval.etalon]

	;\\ WHILE DRAGGING, DON'T SEND ETALON COMMANDS, JUST UPDATE ALL SLIDERS
	;\\ IF THEIR RELATIVE POSITIONS ARE LOCKED
	gain = dcai_global.settings.etalon[uval.etalon].leg_gain
	if uval.leg eq 0 then begin
		update = [1,2]
		ugain = [gain[1],gain[2]]/gain[0]
	endif

	if uval.leg eq 1 then begin
		update = [0,2]
		ugain = [gain[0],gain[2]]/gain[1]
	endif

	if uval.leg eq 2 then begin
		update = [0,1]
		ugain = [gain[0],gain[1]]/gain[2]
	endif

	if move_together eq 1 then begin
		delta = event.value - etalon.leg_voltage[uval.leg]
		widget_control, set_value = etalon.leg_voltage[update[0]] + delta*ugain[0], ids[update[0]]
		widget_control, set_value = etalon.leg_voltage[update[1]] + delta*ugain[1], ids[update[1]]
	endif

	if event.drag eq 1 then begin

		self.dragging = 1

	endif else begin

		self.dragging = 0

		widget_control, get_value = l1, ids[0]
		widget_control, get_value = l2, ids[1]
		widget_control, get_value = l3, ids[2]

		etalon.leg_voltage = [l1, l2, l3]
		dcai_global.settings.etalon[uval.etalon] = etalon

		;\\ PHYSICALLY UPDATE THE ETALON LEG VOLTAGES
		command = {device:'etalon_setlegs', number:uval.etalon, $
				   port:etalon.port, voltage:etalon.leg_voltage}
		call_procedure, dcai_global.info.drivers, command

	endelse
end


;\\ UPDATE LEG PARALLEL OFFSETS
pro DCAI_Etalon::UpdateParallelOffsets, etalon_index

	COMMON DCAI_Control, dcai_global
	etz = dcai_global.settings.etalon[etalon_index]
	etz.parallel_offset = etz.leg_voltage - etz.leg_voltage[0]
	dcai_global.settings.etalon[etalon_index].parallel_offset = etz.parallel_offset
	dcai_global.settings.etalon[etalon_index].reference_voltage = etz.leg_voltage[0]

	widget_control, set_value=string(etz.parallel_offset[0], f='(i0)'), self.parallel_offset_ids[etalon_index, 0]
	widget_control, set_value=string(etz.parallel_offset[1], f='(i0)'), self.parallel_offset_ids[etalon_index, 1]
	widget_control, set_value=string(etz.parallel_offset[2], f='(i0)'), self.parallel_offset_ids[etalon_index, 2]
end


;\\ PROCEDURE FOR SCANNING BUTTONS
pro DCAI_Etalon::Scan, event
	widget_control, get_uval = uval, event.id
	arg = {caller:self, etalon:uval.etalon, n_channels:self.scan_range[uval.etalon], step_size:self.step_size[uval.etalon], scan_offset:0}
	success = DCAI_ScanControl(uval.action, 'manual', arg)
end


;\\ TWO-AXIS PARALLELISM
pro DCAI_Etalon::TwoAxisParallel, event

	COMMON DCAI_Control, dcai_global

	widget_control, get_uval=uval, event.id
	idx = uval.etalon
	inc = 0

	case uval.action of
		'step':begin
			widget_control, get_value=val, event.id
			self.parallel_step[idx] = fix(val, type=3)
		end

		'x+':begin
			inc = [self.parallel_step[idx], -self.parallel_step[idx], -self.parallel_step[idx]]
			dcai_global.settings.etalon[idx].leg_voltage += inc



			command = {device:'etalon_setlegs', number:idx, $
					   port:dcai_global.settings.etalon[idx].port, $
					   voltage:dcai_global.settings.etalon[idx].leg_voltage}
			call_procedure, dcai_global.info.drivers, command

			self->LegUpdate, /force_slider
		end

		'x-':begin
			inc = [-self.parallel_step[idx], self.parallel_step[idx], self.parallel_step[idx]]
			dcai_global.settings.etalon[idx].leg_voltage += inc

			command = {device:'etalon_setlegs', number:idx, $
					   port:dcai_global.settings.etalon[idx].port, $
					   voltage:dcai_global.settings.etalon[idx].leg_voltage}
			call_procedure, dcai_global.info.drivers, command

			self->LegUpdate, /force_slider
		end

		'y+':begin
			inc = [0, self.parallel_step[idx], -self.parallel_step[idx]]
			dcai_global.settings.etalon[idx].leg_voltage += inc

			command = {device:'etalon_setlegs', number:idx, $
					   port:dcai_global.settings.etalon[idx].port, $
					   voltage:dcai_global.settings.etalon[idx].leg_voltage}
			call_procedure, dcai_global.info.drivers, command

			self->LegUpdate, /force_slider
		end

		'y-':begin
			inc = [0, -self.parallel_step[idx], self.parallel_step[idx]]
			dcai_global.settings.etalon[idx].leg_voltage += inc

			command = {device:'etalon_setlegs', number:idx, $
					   port:dcai_global.settings.etalon[idx].port, $
					   voltage:dcai_global.settings.etalon[idx].leg_voltage}
			call_procedure, dcai_global.info.drivers, command

			self->LegUpdate, /force_slider
		end
	endcase
end


;\\ CLEANUP
pro DCAI_Etalon::cleanup, arg

	COMMON DCAI_Control, dcai_global

	self->DCAI_Plugin::cleanup

	if self.info_restore eq 1 then begin
		for j = 0, n_elements(dcai_global.settings.etalon) - 1 do begin
			dcai_global.settings.etalon[j].leg_gain = (*self.info_save)[j].leg_gain
			dcai_global.settings.etalon[j].parallel_offset = (*self.info_save)[j].parallel_offset
		endfor
	endif
	ptr_free, self.info_save
end


;\\ DEFINITION
pro DCAI_Etalon__define

	COMMON DCAI_Control, dcai_global

	n_etalons = n_elements(dcai_global.settings.etalon)

	state = {DCAI_Etalon, leg_bar_ids:intarr(n_etalons, 3), $
						  leg_val_ids:intarr(n_etalons, 3), $
						  slider_ids:lonarr(n_etalons, 3), $
						  parallel_offset_ids:lonarr(n_etalons, 3), $
						  gain_ids:lonarr(n_etalons, 3), $
						  move_together:intarr(n_etalons), $
						  gain_refs:lonarr(n_etalons, 3), $
						  info_save:ptr_new(), $
						  info_restore:0, $
						  dragging:0, $
						  parallel_step:intarr(n_etalons), $
						  INHERITS DCAI_Plugin}
end
