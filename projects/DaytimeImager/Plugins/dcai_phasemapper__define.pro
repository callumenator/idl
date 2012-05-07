
function DCAI_Phasemapper::init

	COMMON DCAI_Control, dcai_global

	;\\ DEFAULTS
		dims = size(*dcai_global.info.image, /dimensions)
		self.draw_size = [dims[0], dims[1]]/1.2
		self.nscans = 5
		self.channels = 128
		self.smoothing = 5
		self.center = [dims[0], dims[1]]/2
		self.p = ptr_new(/alloc)
		self.q = ptr_new(/alloc)


	;\\ SAVE FIELDS
		self.save_tags = ['etalons', 'wavelength', 'nscans', 'channels', 'smoothing', 'center']


	;\\ RESTORE SAVED SETTINGS
		self->load_settings


	;\\ CREATE THE GUI
		_base = widget_base(group=dcai_global.gui.base, col=1, uval={tag:'plugin_base', object:self}, title = 'Phase Mapper', $
							xoffset = self.xpos, yoffset = self.ypos, /base_align_center)

		draw = widget_draw(_base, xs=self.draw_size[0], ys=self.draw_size[1])
		xsection = widget_draw(_base, xs=self.draw_size[0], ys=100)
		status = widget_label(_base, xs=self.draw_size[0], value = 'Status: Idle', font=dcai_global.gui.font+'*Bold')
		self.status_id = status

		show = widget_button(_base, value = 'Show Current Phase Map', font=dcai_global.gui.font, $
							 uval={tag:'plugin_event', object:self, method:'ShowCurrent'}, xs = self.draw_size[0])

		edit_base = widget_base(_base, col=5)

			widget_edit_field, edit_base, label = 'Wavelength (nm)', font=dcai_global.gui.font, start_val=string(self.wavelength, f='(f0.3)'), $
									edit_uval = {tag:'plugin_event', object:self, method:'SetWavelength'}, edit_xs = 10, ids=ids
			self.edit_ids.wavelength = ids.text

			widget_edit_field, edit_base, label = '# Scans', font=dcai_global.gui.font, start_val=string(self.nscans, f='(i0)'), $
									edit_uval = {tag:'plugin_event', object:self, method:'SetNScans'}, edit_xs = 10, ids=ids
			self.edit_ids.nscans = ids.text

			widget_edit_field, edit_base, label = '# Channels', font=dcai_global.gui.font, start_val=string(self.channels, f='(i0)'), $
									edit_uval = {tag:'plugin_event', object:self, method:'SetChannels'}, edit_xs = 10, ids=ids
			self.edit_ids.channels = ids.text

			widget_edit_field, edit_base, label = 'Smooth Window', font=dcai_global.gui.font, start_val=string(self.smoothing, f='(i0)'), $
									edit_uval = {tag:'plugin_event', object:self, method:'SetSmoothing'}, edit_xs = 10, ids=ids
			self.edit_ids.smoothing = ids.text

			widget_edit_field, edit_base, label = 'Nominal Center', font=dcai_global.gui.font, start_val=strjoin(string(self.center, f='(i0)'), ', '), $
									edit_uval = {tag:'plugin_event', object:self, method:'SetCenter'}, edit_xs = 10, ids=ids
			self.edit_ids.center = ids.text

		etalon_base = widget_base(_base, /nonexclusive, col=2)
		for k = 0, n_elements(dcai_global.settings.etalon) - 1 do begin
			btn = widget_button(etalon_base, value = 'Etalon ' + string(k, f='(i0)'), font=dcai_global.gui.font, $
								uval={tag:'plugin_event', object:self, method:'EtalonSelect', etalon:k})
			if self.etalons[k] eq 1 then widget_control, btn, /set_button
			self.edit_ids.etalons[k] = btn
		endfor


		;\\ SCAN CONTROL BUTTONS
		btn_base = widget_base(_base, col = 4)
			scan_btn = widget_button(btn_base, value = 'Start', font=dcai_global.gui.font, xs=80, uval = {tag:'plugin_event', object:self, method:'Scan', action:'start'})
			scan_btn = widget_button(btn_base, value = 'Stop', font=dcai_global.gui.font, xs=80, uval = {tag:'plugin_event', object:self, method:'Scan', action:'stop'})
			scan_btn = widget_button(btn_base, value = 'Pause ', font=dcai_global.gui.font, xs=80, uval = {tag:'plugin_event', object:self, method:'Scan', action:'pause'})
			scan_btn = widget_button(btn_base, value = 'UnPause ', font=dcai_global.gui.font, xs=80, uval = {tag:'plugin_event', object:self, method:'Scan', action:'unpause'})



	;\\ REGISTER FOR FRAME EVENTS
		DCAI_Control_RegisterPlugin, _base, self, /frame

	widget_control, get_value = wind_id, draw
	self.draw_window = wind_id
	widget_control, get_value = wind_id, xsection
	self.xsect_window = wind_id
	self.id = _base
	return, 1
end


;\\ FRAME EVENT
pro DCAI_Phasemapper::frame

	COMMON DCAI_Control, dcai_global

	;\\ STORE THE CURRENT CHANNEL NUMBER
		channels = dcai_global.scan.channel
		pt = where(channels ne -1, npt)
		if npt gt 0 then channel = float(channels[pt[0]])

	;\\ UPDATE STATUS BAR
	status = ''
	case self.scanning of
		0: status = 'Status: Idle'
		1: status = 'Status: Scanning, Scan # ' + string(self.current_scan + 1, f='(i0)') + '/' + $
					string(self.nscans, f='(i0)') + ', Step # ' + string(channel + 1, f='(i0)') + $
					'/' + string(self.channels, f='(i0)')
		2: status = 'Status: Paused'
		else: status = 'Status: Unknown'
	endcase

	widget_control, self.status_id, set_value = status

	if self.scanning ne 1 then return

	;\\ WE MUST BE SCANNING NOW
		dims = size(*dcai_global.info.image, /dimensions)
		signal = float(*dcai_global.info.image)
		;signal = signal - min( smooth(signal, [dims[0], dims[1]]/3., /edge))
		;signal = signal > 0

	;\\ BUILD UP COEFFICIENTS
		*self.p += (signal * sin((2*!PI*channel)/float(self.channels)))
		*self.q += (signal * cos((2*!PI*channel)/float(self.channels)))
		pmap = atan(*self.p, *self.q) / (2*!pi)

	;\\ SHOW THE CURRENT PMAP AND XSECTION
		loadct, 0, /silent
		wset, self.draw_window
		tv, congrid(bytscl(pmap), self.draw_size[0], self.draw_size[1])
		wset, self.xsect_window
		plot, pmap[*,dims[1]/2], pos=[0,0,1,1], xstyle=5, ystyle=5


	;\\ HAVE WE FINISHED A SCAN?
	if channel eq self.channels - 1 then begin

		;\\ STOP THE SCAN
			args = 0
			for k = 0, n_elements(self.etalons) - 1 do begin
				if self.etalons[k] eq 1 then begin
					arg = {caller:self, etalon:k, n_channels:self.channels, wavelength_nm:self.wavelength, $
						   start_voltage:dcai_global.settings.etalon[k].scan_voltage}
					if size(args, /type) eq 2 then args = arg else args = [args, arg]
				endif
			endfor
			if size(args, /type) ne 2 then begin
				success = DCAI_ScanControl('stop', 'normal', args)
				if success eq 1 then self.scanning = 0
			endif



		;\\ INCREMENT THE SCAN COUNTER
		self.current_scan ++


		;\\ HAVE WE FINISHED ALL SCANS?
		if self.current_scan lt self.nscans then begin

			;\\ NO, START ANOTHER SCAN
			if size(args, /type) ne 2 then begin
				success = DCAI_ScanControl('start', 'normal', args)
				if success eq 1 then self.scanning = 1
			endif

		endif else begin

			;\\ YES, DO FINAL PHASE MAP STUFF
			final_pmap = (atan(*self.p, *self.q) + !pi) / (2*!pi)
			final_pmap /= max(final_pmap)

			threshold = .625
			radial_chunk = 50
			fxcen = self.center[0]
			fycen = self.center[1]
			phasemap = phasemap_unwrap(fxcen, fycen, radial_chunk, 1, threshold, 0, final_pmap, $
										/show, tv_id=self.draw_window, dims=self.draw_size)
			phasemap = smooth(phasemap, self.smoothing, /edge_truncate)
			phasemap *= self.wavelength

			index = -1
			if total(self.etalons) eq 1 then index = (where(self.etalons eq 1))[0]
			if total(self.etalons) eq n_elements(dcai_global.settings.etalon) then index = 2

			*dcai_global.info.phasemap[index] = phasemap
			dcai_global.info.phasemap_systime[index] = systime(/sec)

			;\\ SAVE THIS LATEST DATA
			DCAI_Control_Persistent, /save


			;\\ SHOW THE CURRENT PMAP
				wset, self.draw_window
				tv, congrid(bytscl(phasemap), self.draw_size[0], self.draw_size[1])
				wset, self.xsect_window
				plot, phasemap[*,dims[1]/2], pos=[0,0,1,1], xstyle=5, ystyle=5


			;\\ IF REQUESTED, CLOSE THE PLUGIN NOW THAT IT IS FINISHED
			if self.close_on_finish eq 1 then begin
				;\\ UNSET AS ACTIVE PLUGIN
				success = self->unset_active(self->uid())
				if success eq 1 then begin
					DCAI_Control_Cleanup, 0, object=self
				endif else begin
					DCAI_Log, 'ERROR: Unable to UNset as active plugin: ' + self->uid() + $
							  ', plugin was not auto-closed on finish!'
				endelse
			endif

		endelse

	endif
end


;\\ SCAN CONTROLS
pro DCAI_Phasemapper::Scan, event, action=action

	COMMON DCAI_Control, dcai_global

	if not keyword_set(action) then begin
		widget_control, get_uval=uval, event.id
		action = uval.action
	endif

	args = 0
	success = 0
	for k = 0, n_elements(self.etalons) - 1 do begin
		if self.etalons[k] eq 1 then begin
			arg = {caller:self, etalon:k, n_channels:self.channels, wavelength_nm:self.wavelength, $
				   start_voltage:dcai_global.settings.etalon[k].scan_voltage}
			if size(args, /type) eq 2 then args = arg else args = [args, arg]
		endif
	endfor

	case action of
		'start': begin

			;\\ IF IN AUTO MODE, TRY TO SET AS ACTIVE PLUGIN
				success = 0
				if self.auto_mode eq 1 then success = self->set_active(self->uid()) else success = 1
				if success eq 0 then return

			if self.scanning ne 1 and self.wavelength ne 0 then begin

				dims = size(*dcai_global.info.image, /dimensions)
				*self.p = fltarr(dims[0], dims[1])
				*self.q = fltarr(dims[0], dims[1])
				self.current_scan = 0

				success = DCAI_ScanControl('start', 'normal', args)
				if success eq 1 then self.scanning = 1

			endif
		end

		'stop':begin
			;\\ IF IN AUTO MODE, TRY TO UNSET AS ACTIVE PLUGIN
				success = 0
				if self.auto_mode eq 1 then success = self->unset_active(self->uid()) else success = 1
				if success eq 0 then return

			success = DCAI_ScanControl('stop', 'normal', args)
			if success eq 1 then self.scanning = 0
		end

		'pause':begin
			success = DCAI_ScanControl('pause', 'normal', args)
			if success eq 1 then self.scanning = 2
		end

		'unpause':begin
			success = DCAI_ScanControl('unpause', 'normal', args)
			if success eq 1 then self.scanning = 1
		end

		else:
	endcase

end


;\\ SHOW CURRENT PHASEMAP
pro DCAI_Phasemapper::ShowCurrent, event

	COMMON DCAI_Control, dcai_global

end


;\\ SET WAVELENGTH
pro DCAI_Phasemapper::SetWavelength, event
	if self.scanning eq 0 then begin
		widget_control, get_value = val, event.id
		self.wavelength = fix(val, type=4)
	endif else begin
		widget_control, set_value=string(self.wavelength, f='(f0.2)'), event.id
	endelse
end

;\\ SET NSCANS
pro DCAI_Phasemapper::SetNScans, event
	if self.scanning eq 0 then begin
		widget_control, get_value = val, event.id
		self.nscans = fix(val, type=3) > 1
	endif else begin
		widget_control, set_value=string(self.nscans, f='(i0)'), event.id
	endelse
end

;\\ SET CHANNELS
pro DCAI_Phasemapper::SetChannels, event
	if self.scanning eq 0 then begin
		widget_control, get_value = val, event.id
		self.channels = fix(val, type=3) > 1
	endif else begin
		widget_control, set_value=string(self.channels, f='(i0)'), event.id
	endelse
end

;\\ SET SMOOTHING
pro DCAI_Phasemapper::SetSmoothing, event
	widget_control, get_value = val, event.id
	self.smoothing = fix(val, type=3)
end

;\\ SET NOMINAL CENTER
pro DCAI_Phasemapper::SetCenter, event
	widget_control, get_value = val, event.id
	split = strtrim(strcompress(strsplit(val, ',', /extract), /remove), 2)
	if n_elements(split) ne 2 then begin
		widget_control, set_value=strjoin(string(self.center, f='(i0)'), ', '), event.id
	endif else begin
		self.center = [fix(split[0], type=3), fix(split[1], type=3)]
	endelse
end

;\\ SELECT ETALON(S)
pro DCAI_Phasemapper::EtalonSelect, event
	COMMON DCAI_Control, dcai_global
	widget_control, get_uval = uval, event.id
	if self.scanning eq 0 then begin
		self.etalons[uval.etalon] = event.select
	endif else begin
		widget_control, set_button=self.etalons[uval.etalon], event.id
	endelse
end


;\\ EXECUTE COMMANDS SENT FROM A SCHEDULE FILE
pro DCAI_Phasemapper::ScheduleCommand, command, keywords, values

	COMMON DCAI_Control, dcai_global

	if self.scanning ne 0 then return

	;\\ FLAG AUTO MODE
	self.auto_mode = 1

	;\\ HANDLE KEYWORDS
	for k = 0, n_elements(keywords) - 1 do begin
		case keywords[k] of
			'close_on_finish': self.close_on_finish = 1
			'wavelength':begin

				self.wavelength = float(values[k])
				widget_control, set_value=string(self.wavelength, f='(f0.2)'), self.edit_ids.wavelength
			end
			'nscans':begin
				self.nscans = fix(values[k])
				widget_control, set_value=string(self.nscans, f='(i0)'), self.edit_ids.nscans
			end
			'smoothing':begin
				self.smoothing = fix(values[k])
				widget_control, set_value=string(self.smoothing, f='(i0)'), self.edit_ids.smoothing
			end
			'center':begin
				res = execute('center = ' + values[k])
				self.center = center
				widget_control, set_value=strjoin(string(self.center, f='(i0)'), ', '), self.edit_ids.center
			end
			'channels':begin
				self.channels = fix(values[k])
				widget_control, set_value=string(self.channels, f='(i0)'), self.edit_ids.channels
			end
			'etalons':begin
				res = execute('etalons = ' + values[k])
				for j = 0, n_elements(etalons) - 1 do begin
					if etalons[j] lt n_elements(self.etalons) then self.etalons[etalons[j]] = 1
				endfor
				for j = 0, n_elements(self.edit_ids.etalons) - 1 do widget_control, set_button=self.etalons[k], self.edit_ids.etalons[k]
			end
			else: DCAI_Log, 'WARNING: Keyword not recognized by Phasemapper plugin: ' + keywords[k]
		endcase
	endfor

	case command of

		'start':begin

			;\\ IF WE ARE NOT IN AUTO MODE, WE SHOULD NOT BE GETTING THIS COMMAND
				if self.auto_mode eq 0 then return

			;\\ TRY TO SET AS ACTIVE PLUGIN
				success = self->set_active(self->uid())
				if success eq 1 then self->Scan, 0, action='start'
		end

		else: DCAI_Log, 'WARNING: Command not recognized by StepsperOrder plugin: ' + command
	endcase

end


;\\ BUILD A UID STRING FROM THIS OBJECT
function DCAI_Phasemapper::uid, args=args
	return, 'phasemapper_' + string(self.wavelength, f='(f0.2)') + '_' + string(self.channels, f='(i0)')
end


;\\ CLEANUP
pro DCAI_Phasemapper::Cleanup

	self->DCAI_Plugin::Cleanup
	ptr_free, self.p, self.q

end


;\\ DEFINITION
pro DCAI_Phasemapper__define

	COMMON DCAI_Control, dcai_global

	n_etalons = n_elements(dcai_global.settings.etalon)
	state = {DCAI_Phasemapper, draw_window:0, $
							   xsect_window:0, $
							   status_id:0L, $
							   edit_ids:{phasemapper_edit_ids, wavelength:0L, nscans:0L, channels:0L, smoothing:0L, etalons:lonarr(n_etalons), center:0L}, $
							   draw_size:[0,0], $
							   wavelength:0.0, $
							   channels:0, $
							   smoothing:0, $
							   scanning:0, $
							   center:[0,0], $
							   nscans:0, $
							   current_scan:0, $
							   etalons:intarr(n_etalons), $
							   p:ptr_new(), $
							   q:ptr_new(), $
							   close_on_finish:0, $
						   	   INHERITS DCAI_Plugin}
end

