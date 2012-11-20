@dcai_script_utilities

function DCAI_Spectrum::init

	COMMON DCAI_Control, dcai_global

	;\\ DEFAULTS
		self.tabbed_mode = 1
		self.lambda_scanning = -1
		self.free_list[*] = 1

	;\\ SAVE FIELDS

	;\\ RESTORE SAVED SETTINGS
		self->load_settings

		etalon = dcai_global.settings.etalon

	;\\ CREATE THE GUI
		font = dcai_global.gui.font
		_base = widget_base(group=dcai_global.gui.base, col = 2, uval={tag:'plugin_base', object:self, method:'RemoveSpectrum', index:-1}, $
						    title = 'Spectrum', xoffset = self.xpos, yoffset = self.ypos, /TLB_KILL_REQUEST_EVENTS)

		base_left = widget_base(_base, col=1)

		top_base = widget_base(base_left, col = 1, /base_align_left)
			self.info_labels[0] = widget_label(top_base, font=font, value = 'No Scans Active', xs = 200)
			self.info_labels[1] = widget_label(top_base, font=font, value = 'More Info', xs = 200)
			self.info_labels[2] = widget_label(top_base, font=font, value = 'More Info', xs = 200)

	;\\ TABBED/WINDOWED MODE TOGGLE
		mode_base = widget_base(base_left, col=1, /nonexclusive)
		mode_btn = widget_button(mode_base, value = 'Tabbed Mode', font=font, $
								uval={tag:'plugin_event', object:self, method:'TabbedMode'})
		widget_control, /set_button, mode_btn

		new_btn = widget_button(base_left, value = 'Add New Spectrum Tab', font=font, $
								uval={tag:'plugin_event', object:self, method:'UserNewSpectrum'})

		base_right = widget_base(_base, col=1)
		self.tab_base = widget_tab(base_right)


	;\\ REGISTER FOR FRAME EVENTS
		DCAI_Control_RegisterPlugin, _base, self, /frame

	self.id = _base
	return, 1
end


;\\ FRAME EVENT
pro DCAI_Spectrum::frame

	COMMON DCAI_Control, dcai_global


	;\\ GET THE ID OF THE ACTIVE SCANNER
		id = self.lambda_scanning


	;\\ UPDATE SOME INFO
		if self.scanning ne 0 then begin
			eids = where(self.lambdas[id].etalons eq 1, n_eta)
			if n_eta eq 1 then e_idx = eids[0] else e_idx = 0

			channel = dcai_global.scan.channel[e_idx]
			n_channels = dcai_global.scan.n_channels[e_idx]

			info_string0 = 'Scan # ' + string(self.lambdas[self.lambda_scanning].current_scan + 1, f='(i0)')
			info_string1 = 'Channel # ' + string(channel, f='(i0)') + '/' + string(n_channels, f='(i0)')
		endif else begin
			info_string0 = ' '
			info_string1 = ' '
		endelse
		widget_control, set_value = info_string0, self.info_labels[1]
		widget_control, set_value = info_string1, self.info_labels[2]


	;\\ IF THERE IS NO ACTIVE SCANNER, THEN RETURN
		if id eq -1 or self.scanning eq 2 then return

		image = ulong(*dcai_global.info.image)
		scan = self.lambdas[id].current_scan


	;\\ ACCUMULATE SPECTRA
		res = call_external(dcai_global.settings.external_dll, $
							'uUpdateSpectra', $
							image, $
							*self.lambdas[id].phasemap, $
							*self.lambdas[id].zonemap, $
							*self.lambdas[id].spectra, $
							fix(channel), $
							self.lambdas[id].sizes, $
							value=bytarr(6))


	;\\ UPDATE ACCUMULATED IMAGE
		*self.lambdas[id].accumulated_image += image


	;\\ IF A SCAN WAS FINISHED...
		if channel eq self.lambdas[id].n_scan_channels - 1 then begin

		;\\ DISPLAY THE ACCUMULATED IMAGE
			loadct, 0, /silent
			wset, self.lambdas[id].window_ids[0]
			idim = size(image, /dimensions)
			wdim = reform(self.lambdas[id].window_dims[0,*])
			accum = *self.lambdas[id].accumulated_image
			imsrt = accum[sort(accum)]
			nels = n_elements(imsrt)
			tv, congrid(bytscl(accum, min=imsrt[nels*.01], max=imsrt[nels*.99]), wdim[0], wdim[1], /interp)

		;\\ PLOT ZONE BOUNDARIES
			plot_zone_bounds, wdim[0], (*self.lambdas[id].zone_info).rads, $
									   (*self.lambdas[id].zone_info).secs, $
									   thick=1, color=255, ctable=0, $
									   offset=((*self.lambdas[id].zone_info).center - (idim/2)) * (float(wdim)/idim)

		;\\ CALCULATE BACKGROUND AND SNR, AND PLOT SPECTRA

			;\\ snr inits
				spec_dims = size(*self.lambdas[id].spectra, /dimensions)
				bgr = 0.
				signal_noise = fltarr(spec_dims[0])

			;\\ plot inits
				loadct, 39, /silent
				offsets = DCAI_ScanControl('getpixelwavelength', 'dummy', $
								{nominal_wavelength:self.lambdas[id].wavelength, $
								 center_wavelength:0.0, pixel:[-1,-1]})

				zc = (*self.lambdas[id].zone_info).zone_centers
				blank = replicate(' ', 20)
				min_l = self.lambdas[id].wavelength_range[0] - $
						abs(self.lambdas[id].wavelength_range_full[1]-$
							self.lambdas[id].wavelength_range[1])
				dl = (self.lambdas[id].wavelength_range_full[1] - $
					  self.lambdas[id].wavelength_range_full[0]) / $
					  (self.lambdas[id].n_scan_channels - 1)
				xaxis = findgen(spec_dims[1])*dl + min_l

			;\\ loop
				for z = 0, spec_dims[0] - 1 do begin

					spx = float(reform((*self.lambdas[id].spectra)[z, *]))
					norm = float(reform((*self.lambdas[id].normmap)[z, *]))

				;\\ snr calculation
				 	use = where(norm ne 0, n_chann) ;\\ spectral bins which contain signal for this zone
				    bgr  += spec_dims[1]*min(smooth(spx[use],7))
				    power = (abs(fft(spx[use])))^2
					signal_noise[z] = power[1]/median(power[(n_chann*3./8.):(n_chann/2.)])

				;\\ now plot
					sn = norm(sort(norm))
					un = sn(uniq(sn))
					use = where(norm gt un[n_elements(un)*.5], n_use)
					if n_use eq 0 then continue

					spx = spx[use] / norm[use]
					spx -= min(spx)

					plot, xaxis, xaxis, color = 255, /nodata, yrange = [0, max(spx)], $
						  /noerase, xtickname=blank, xstyle=5, ystyle=5, $
						  pos=[zc[z,0],zc[z,1],zc[z,0],zc[z,1]] + [-.07,-.07,.07,.07]
					oplot, self.lambdas[id].wavelength_range[[0,0]], [0,max(spx)], color = 100, line=1
					oplot, self.lambdas[id].wavelength_range[[1,1]], [0,max(spx)], color = 100, line=1
					oplot, xaxis[use], spx

					;\\ TEMPORARY - FOR TESTING
					if z eq -1 then begin
						window, 0
						dell = (self.lambdas[id].wavelength_range_full[1]-$
								self.lambdas[id].wavelength_range_full[0]) / $
								(self.lambdas[id].n_scan_channels-1)
						plot, xaxis, float(reform((*self.lambdas[id].spectra)[z, *])), $
								psym=-1, sym=.5
						wset, self.lambdas[id].window_ids[0]
					endif
				endfor

				snr = median(signal_noise)

		;\\ STORE SOME INFO
			(*self.lambdas[id].snr_history)[scan] = snr
			(*self.lambdas[id].bgr_history)[scan] = bgr
			self.lambdas[id].current_scan ++



		;\\ CHECK TO SEE IF THE EXPOSURE IS FINISHED
			exp_finished = 0
			if self.lambdas[id].current_scan ge self.lambdas[id].min_scans then begin ;\\ Make sure the minimum number of scans have been done

				if self.lambdas[id].current_scan eq self.lambdas[id].max_scans then exp_finished = 1 ;\\ Max scans reached
				if snr ge self.lambdas[id].min_snr then exp_finished = 1 							 ;\\ Min snr satisfied

			endif

			;\\ EVEN IF THE MINIMUM NUMBER OF SCANS HAVE NOT BEEN COMPLETED, IF THE FINALIZE FLAG IS
			;\\ SET THEN WE DO NEED TO END THE CURRENT EXPOSURE
			if self.lambdas[id].finalize eq 1 then exp_finished = 1



		;\\ STOP THE CURRENT SCAN
			self->Scan, 0, command = {index:id, action:'stop'}

		;\\ IF THE EXPOSURE IS FINISHED, SORT THAT OUT, ELSE RESTART
			if exp_finished eq 1 then begin
				self.lambdas[id].current_exposure ++

				;\\ IF MULTIPLE EXPOSURES HAVE BEEN SPECIFIED, KEEP GOING UNTIL THEY ARE COMPLETE
				if self.lambdas[id].current_exposure lt self.lambdas[id].num_exposures then begin
					self->Scan, 0, command = {index:id, action:'start', restart:0}
				endif
			endif else begin ;\\ if exposure finished
				self->Scan, 0, command = {index:id, action:'start', restart:1}
			endelse ;\\ exposure not finished

		endif ;\\ if scan finished

end



;\\ SCAN START/STOP/FINALIZE
pro DCAI_Spectrum::Scan, event, command=command

	COMMON DCAI_Control, dcai_global

	if not keyword_set(command) then begin
		widget_control, get_uval = uval, event.id
	endif else begin
		uval = command	;\\ uval = {index:, action:''}
	endelse

	id = uval.index		;\\ index into the self.lambdas array

	case uval.action of

		'start':begin
			;\\ CHECK TO SEE IF ANY OTHER SCANS ARE RUNNING
			if self.scanning eq 1 then return

			args = 0
			if self.lambdas[id].scan_type eq 'order' then begin
				for k = 0, n_elements(self.lambdas[id].etalons) - 1 do begin
					if self.lambdas[id].etalons[k] eq 1 then begin

						arg = {caller:self, etalon:k, $
						       n_channels:self.lambdas[id].n_scan_channels, $
						       wavelength_nm:self.lambdas[id].wavelength, $
						       start_voltage:dcai_global.settings.etalon[k].scan_voltage}

						if size(args, /type) ne 8 then args = arg else args = [args, arg]
					endif
				endfor

				success = DCAI_ScanControl('start', 'normal', args)
			endif else begin

				arg = {caller:self, etalons:where(self.lambdas[id].etalons eq 1), $
				       n_channels:self.lambdas[id].n_scan_channels, $
				       wavelength_range_nm:self.lambdas[id].wavelength_range_full}

				success = DCAI_ScanControl('start', 'wavelength', arg)
			endelse


			if success eq 0 then return

			self.scanning = 1
			self.lambda_scanning = id
			self.lambdas[id].scanning = 1

			if uval.restart eq 0 then begin
				;\\ (RE)CREATE SOME FIELDS
				self.lambdas[id].current_scan = 0
				image_dims = size(*dcai_global.info.image, /dimensions)
				*self.lambdas[id].spectra = ulonarr(self.lambdas[id].n_zones, self.lambdas[id].n_spectral_channels)
				*self.lambdas[id].accumulated_image = ulonarr(image_dims[0], image_dims[1])
				*self.lambdas[id].snr_history = fltarr(self.lambdas[id].max_scans)
				*self.lambdas[id].bgr_history = fltarr(self.lambdas[id].max_scans)
			endif

			;\\ UPDATE WIDGET INFO
			widget_control, set_value = 'Acquiring Spectra at ' + string(self.lambdas[id].wavelength, f='(f0.1)') + ' nm', $
							self.info_labels[0]
		end


		'stop': begin
			;\\ CHECK TO SEE IF THE STOPPING CALLER IS THE CURRENT SCANNER
			if self.lambdas[id].scanning eq 0 then return

			args = 0
			for k = 0, n_elements(self.lambdas[id].etalons) - 1 do begin
				if self.lambdas[id].etalons[k] eq 1 then begin
					arg = {caller:self, etalon:k}
					if size(args, /type) ne 8 then args = arg else args = [args, arg]
				endif
			endfor

			success = DCAI_ScanControl('stop', 'dummy', args)
			if success eq 0 then return

			widget_control, set_value = 'No Scans Active', self.info_labels[0]
			self.scanning = 0
			self.lambda_scanning = -1
			self.lambdas[id].scanning = 0
			self.lambdas[id].finalize = 0 ;\\ Clear the finalize flag
		end


		'pause':begin
			;\\ CHECK TO SEE IF THE CALLER IS THE CURRENT SCANNER
			if self.lambdas[id].scanning eq 0 then return

			etz = where(self.lambdas[id].etalons eq 1, n_etz)
			if n_etz eq 0 then return
			args = replicate({caller:self, etalon:0}, n_etz)
			args.etalon = etz

			success = DCAI_ScanControl('pause', 'dummy', args)
			if success eq 0 then return
			self.scanning = 2

			;\\ UPDATE WIDGET INFO
			widget_control, set_value = 'Paused Acquisition at ' + string(self.lambdas[id].wavelength, f='(f0.1)') + ' nm', $
							self.info_labels[0]
		end

		'unpause':begin
		;\\ CHECK TO SEE IF THE CALLER IS THE CURRENT SCANNER
			if self.lambdas[id].scanning eq 0 then return

			etz = where(self.lambdas[id].etalons eq 1, n_etz)
			if n_etz eq 0 then return
			args = replicate({caller:self, etalon:0}, n_etz)
			args.etalon = etz

			success = DCAI_ScanControl('unpause', 'dummy', args)
			if success eq 0 then return
			self.scanning = 1

			;\\ UPDATE WIDGET INFO
			widget_control, set_value = 'Acquiring Spectra at ' + string(self.lambdas[id].wavelength, f='(f0.1)') + ' nm', $
							self.info_labels[0]

		end

		'finalize': begin
			;\\ CHECK TO SEE IF THE STOPPING CALLER IS THE CURRENT SCANNER
			if self.lambdas[id].scanning eq 0 then return
			self.lambdas[id].finalize = 1
		end

		else:
	endcase

end


;\\ SWITCH BETWEEN TABBED AND WINDOWED MODE
pro DCAI_Spectrum::TabbedMode, event

	if event.select eq 1 then begin
		;\\ SWITCH TO TABBBED MODE
		self.tabbed_mode = 1
	endif else begin
		;\\ SWITCH TO WINDOWED MODE
		self.tabbed_mode = 0
	endelse

	;\\ REBUILD THE WIDGETS
	for l = 0, self.n_lambdas - 1 do begin
		widget_control, /destroy, self.lambdas[l].base_id
		self->BuildWidgets, l
		if self.tabbed_mode eq 0 then $
			widget_control, xoffset = 150*l, yoffset = 50*l, self.lambdas[l].base_id
	endfor
end


;\\ ADD NEW WAVELENGTH FROM THE USER INTERFACE BUTTON
pro DCAI_Spectrum::UserNewSpectrum, event

	COMMON DCAI_Control, dcai_global

	;\\ MAX 20 WAVELENGTHS CURRENTLY
	if self.n_lambdas le 19 then begin

		;\\ CREATE A DIALOG ALLOWING TO SELECT WAVELENGTH, ZONEMAP, ETC.

		dlg = widget_base(/modal, group_leader = self.id, title = 'Enter Spectrum Parameters', col=1, $
						  uval={tag:'dummy_tag'}, tab_mode=1, /base_align_right)

		widget_edit_field, dlg, label = 'Nominal Wavelength (nm)', font = dcai_global.gui.font, $
					   	   ids = lambda_id, edit_xsize = 10, lab_xsize = 100, start_value = '0.0', /column

		widget_edit_field, dlg, label = 'Start Wavelength (nm)', font = dcai_global.gui.font, $
					   	   ids = start_lambda_id, edit_xsize = 10, lab_xsize = 100, start_value = '0.0', /column

		widget_edit_field, dlg, label = 'Stop Wavelength (nm)', font = dcai_global.gui.font, $
					   	   ids = stop_lambda_id, edit_xsize = 10, lab_xsize = 100, start_value = '0.0', /column

		widget_edit_field, dlg, label = 'Channels', font = dcai_global.gui.font, $
					   	   ids = channel_id, edit_xsize = 10, lab_xsize = 100, start_value = '128', /column

		widget_edit_field, dlg, label = 'Min # Scans', font = dcai_global.gui.font, $
					   	   ids = minscan_id, edit_xsize = 10, lab_xsize = 100, start_value = '2', /column

		widget_edit_field, dlg, label = 'Max # Scans', font = dcai_global.gui.font, $
					   	   ids = maxscan_id, edit_xsize = 10, lab_xsize = 100, start_value = '20', /column

		widget_edit_field, dlg, label = 'Min SNR', font = dcai_global.gui.font, $
					   	   ids = minsnr_id, edit_xsize = 10, lab_xsize = 100, start_value = '1200', /column

		zmap_base = widget_base(dlg, col=2)

			;\\ PICK A DEFAULT ZONEMAP
			def_zmap = ''
			zmaps = file_search(dcai_global.settings.paths.zonemaps, '*.txt', count=n_zmaps)
			if n_zmaps ne 0 then begin
				def = strmatch(file_basename(zmaps), '*default*', /fold)
				def = (where(def eq 1, n_def))[0]
				if n_def ne 0 then def_zmap = zmaps[def]
			endif

		widget_edit_field, zmap_base, label = 'Zonemap', font = dcai_global.gui.font, $
					   	   ids = zonemap_id, edit_xsize = 10, lab_xsize = 100, start_value=def_zmap, /column
		browse_btn = widget_button(zmap_base, value='Browse', font=dcai_global.gui.font, $
									uval={tag:'plugin_event', object:self, method:'UserNewSpectrum_ZmapBrowse', id:zonemap_id.text})

		etalons_base = widget_base(dlg, col=n_elements(dcai_global.settings.etalon), /nonexclusive)
		buttons = lonarr(n_elements(dcai_global.settings.etalon))
			for i = 0, n_elements(dcai_global.settings.etalon) - 1 do begin
				buttons[i] = widget_button(etalons_base, value = 'Etalon ' + string(i, f='(i0)'), $
									uval = {tag:'plugin_event', object:self, method:'UserNewSpectrum_EtalonToggle', state:1})
				widget_control, buttons[i], /set_button
			endfor

		ok_btn = widget_button(dlg, value = 'OK', font=dcai_global.gui.font, $
							   uval = {tag:'plugin_event', object:self, method:'UserNewSpectrum_OK', $
							   		   base:dlg, wavelength_id:lambda_id.text, channels_id:channel_id.text, $
							   		   minscans_id:minscan_id.text, maxscans_id:maxscan_id.text, $
							   		   minsnr_id:minsnr_id.text, $
							   		   start_lambda_id:start_lambda_id.text, stop_lambda_id:stop_lambda_id.text, $
							   		   zonemap_id:zonemap_id.text, $
							   		   button_ids:buttons})

		DCAI_Control_RegisterPlugin, dlg, self
	endif
end

	pro DCAI_Spectrum::UserNewSpectrum_EtalonToggle, event
		widget_control, get_uvalue = uval, event.id
		if uval.state eq 0 then uval.state = 1 else uval.state = 0
		widget_control, set_uvalue = uval, event.id
	end

	pro DCAI_Spectrum::UserNewSpectrum_ZmapBrowse, event
		COMMON DCAI_Control, dcai_global
		widget_control, get_uvalue = uval, event.id
		filename = dialog_pickfile(default_ext='txt', dialog_parent=self.id, display_name='Select Zonemap File', $
									path=dcai_global.settings.paths.zonemaps)
		widget_control, set_value = filename, uval.id
	end

	pro DCAI_Spectrum::UserNewSpectrum_OK, event

		widget_control, get_uval = uval, event.id
		widget_control, get_value = wavelength, uval.wavelength_id
		widget_control, get_value = zonemap, uval.zonemap_id
		widget_control, get_value = minscans, uval.minscans_id
		widget_control, get_value = maxscans, uval.maxscans_id
		widget_control, get_value = start_lambda, uval.start_lambda_id
		widget_control, get_value = stop_lambda, uval.stop_lambda_id
		widget_control, get_value = minsnr, uval.minsnr_id
		widget_control, get_value = channels, uval.channels_id

		etalons = replicate(0, n_elements(uval.button_ids))
		for i = 0, n_elements(uval.button_ids)-1 do begin
			widget_control, get_uval = btn_uval, uval.button_ids[i]
			if btn_uval.state eq 1 then etalons[i] = 1
		endfor

		widget_control, /destroy, uval.base

		wavelength = float(wavelength)
		if wavelength eq 0.0 then return

		info = {wavelength:(fix(wavelength, type=4))[0], $
				channels:(fix(channels, type=3))[0], $
				minscans:(fix(minscans, type=3))[0], $
				maxscans:(fix(maxscans, type=3))[0], $
				minsnr:(fix(minsnr, type=4))[0], $
				start_lambda:(fix(start_lambda, type=4))[0], $
				stop_lambda:(fix(stop_lambda, type=4))[0], $
				zonemap:zonemap, $
				etalons:etalons}

		self->NewSpectrum, info
	end




;\\ ADD A NEW SPECTRUM
pro DCAI_Spectrum::NewSpectrum, info

	COMMON DCAI_Control, dcai_global

	image_dims = size(*dcai_global.info.image, /dimensions)

	;\\ REACHED MAX NUMBER (20)
	if self.n_lambdas ge 20 then return
	if total(info.etalons) eq 0 then return	;\\ NOT USING ANY ETALONS!!


	;\\ TRY TO BUILD THE ZONEMAP
	fringe_center = DCAI_ScanControl('getfringecenter', 'dummy', 0)
	zonemap = self->BuildZonemap(info.zonemap, image_dims, fringe_center)
	if zonemap.error ne 'none' then begin
		DCAI_Log, 'ERROR: Spectrum object could not build zonemap from ' + info.zonemap + $
				  ', got error ' + zonemap.error
		return
	endif


	;\\ CHECK TO SEE IF THIS WAVELENGTH, ETALON COMBO, AND ZONEMAP IS ALREADY PRESENT
	uid = self->uid(arg={wavelength:info.wavelength, etalons:info.etalons, n_zones:zonemap.n_zones})
	if self.n_lambdas ne 0 then begin
		match = where(self.lambdas.uid eq uid, nmatch)
		if nmatch eq 1 then return
	endif


	;\\ ADD TO THE WAVELENGTH LIST
	free = where(self.free_list eq 1, n_free)
	index = min(free)
	self.free_list[index] = 0
	self.n_lambdas ++
	self.lambdas[index].wavelength = info.wavelength


	;\\ DO OTHER SETUP STUFF HERE
	self.lambdas[index].uid = uid
	self.lambdas[index].n_scan_channels = info.channels
	self.lambdas[index].n_zones = zonemap.n_zones
	self.lambdas[index].min_scans = info.minscans
	self.lambdas[index].max_scans = info.maxscans
	self.lambdas[index].min_snr = info.minsnr
	self.lambdas[index].wavelength_range = [info.start_lambda, info.stop_lambda]
	self.lambdas[index].etalons = info.etalons
	self.lambdas[index].zonemap = ptr_new(zonemap.zonemap)
	self.lambdas[index].zone_info = ptr_new(zonemap)
	self.lambdas[index].num_exposures = 1

	;\\ MAKE SURE WE HAVE ALL THE PHASEMAPS REQUIRED
	for k = 0, n_elements(etalons) - 1 do begin
		if info.etalons[k] eq 1 and size(*dcai_global.info.phasemap[k], /n_dimensions) eq 0 then begin
			;\\ NO PHASEMAP FOR THE SELECTED ETALON(S), DON'T CREATE SPECTRUM OBJECT
				DCAI_Log, 'ERROR: Spectrum object could not be created, as no phase map is defined for etalon ' + string(index, f='(i0)') + '!'
				self->RemoveSpectrum, 0, index=index, /no_confirm
				return
		endif
	endfor


	;\\ ONE ETALON CHOSEN, MUST BE A SCAN OVER ONE ORDER
	if total(info.etalons) eq 1 then begin
		self.lambdas[index].scan_type = 'order'
		idx = (where(info.etalons eq 1))[0]
		pmap = *dcai_global.info.phasemap[idx] / self.lambdas[index].wavelength
		pmap = pmap mod 1
		pmap *= info.channels
		pmap = fix(pmap)
		self.lambdas[index].phasemap = ptr_new(pmap)
		self.lambdas[index].n_spectral_channels = info.channels
		self.lambdas[index].sizes = fix([image_dims[0], image_dims[1], zonemap.n_zones, info.channels])
	endif


	;\\ FOR TWO ETALONS, MUST BE SCANNING IN WAVELENGTH, MAKE SURE A WAVELENGTH RANGE IS DEFINED
	if total(info.etalons) eq 2 then begin
		if info.start_lambda eq info.stop_lambda then begin
			;\\ NO WAVELENGTH RANGE
				DCAI_Log, 'ERROR: Spectrum object could not be created, as no wavelenght scan range was supplied!'
				self->RemoveSpectrum, 0, index=index, /no_confirm
				return
		endif

		self.lambdas[index].scan_type = 'wavelength'
		offsets = DCAI_ScanControl('getpixelwavelength', 'dummy', {nominal_wavelength:(info.start_lambda+info.stop_lambda)/2., $
																   center_wavelength:0.0, pixel:[-1,-1]})

		;\\ NEED THE LARGEST WAVELENGTH OFFSET RELATIVE TO FRINGE CENTER,
		;\\ TO CALCULATE REQUIRED WAVELENGTH RANGE AT FRINGE CENTER
		defined = where(*self.lambdas[index].zonemap ne -1, n_defined)
		max_offset = max(abs(offsets[defined]))
		self.lambdas[index].wavelength_range_full = [info.start_lambda, info.stop_lambda + max_offset]

		lambda_per_scan_channel = ((info.stop_lambda + max_offset) - info.start_lambda) / float(info.channels)
		max_channel_offset = ceil(max_offset / lambda_per_scan_channel)
		self.lambdas[index].n_spectral_channels = info.channels + max_channel_offset

		pmap = (max_offset + offsets) / lambda_per_scan_channel
		pmap = pmap > 0
		pmap = pmap < (self.lambdas[index].n_spectral_channels - 1)
		pmap = -fix(pmap)

		self.lambdas[index].phasemap = ptr_new(pmap)
		self.lambdas[index].sizes = fix([image_dims[0], image_dims[1], zonemap.n_zones, $
										 self.lambdas[index].n_spectral_channels])



		;\\ SINCE EACH SPECTAL BIN IN EACH ZONE HAS A DIFFERENT NUMBER OF
		;\\ PIXELS CONTRIBUTING. CALCULATE A NORMALIZING MAP FOR EACH ZONE (n_zones x n_spectral_channels)
		norm = lonarr(self.lambdas[index].n_zones, self.lambdas[index].n_spectral_channels)
		for zidx = 0, self.lambdas[index].n_zones - 1 do begin
			pix = where(*self.lambdas[index].zonemap eq zidx, n_pix)
			pix_pmap = -pmap[pix]
			znorm = lonarr(self.lambdas[index].n_spectral_channels)
			for spx_chann = 0, self.lambdas[index].n_scan_channels - 1 do begin
				histo = histogram(pix_pmap + spx_chann, binsize=1, locations=chann_offset, $
								  min=0, max=self.lambdas[index].n_spectral_channels-1)
				znorm[chann_offset] += histo
			endfor
			norm[zidx,*] = znorm
		endfor
		self.lambdas[index].normmap = ptr_new(norm)
	endif

	if total(info.etalons) gt 2 then return

	self.lambdas[index].spectra = ptr_new(/alloc)
	self.lambdas[index].snr_history = ptr_new(/alloc)
	self.lambdas[index].bgr_history = ptr_new(/alloc)
	self.lambdas[index].accumulated_image = ptr_new(/alloc)


	;\\ BUILD THE WIDGETS
	self->BuildWidgets, index
end



;\\ BUILD THE WIDGET INTERFACE FOR A SINGLE WAVELENGTH
pro DCAI_Spectrum::BuildWidgets, lambda_index

	COMMON DCAI_Control, dcai_global

	self.lambdas[lambda_index].window_dims = transpose([[400,400],[197,197],[197,197]])
	wavelength_string = string(self.lambdas[lambda_index].wavelength, f='(f0.1)')

	if self.tabbed_mode eq 1 then begin
		base = widget_base(self.tab_base, title = wavelength_string + ' nm', col = 1)
	endif else begin
		base = widget_base(group_leader = self.id, title = 'Spectrum: ' + wavelength_string + ' nm', col = 1, /TLB_KILL_REQUEST_EVENTS, $
					uval={tag:'plugin_child_base', object:self, method:'RemoveSpectrum', index:lambda_index})
	endelse

	self.lambdas[lambda_index].base_id = base

	sub_base = widget_base(base, col=2)

	w_dims = self.lambdas[lambda_index].window_dims
	draw_base = widget_base(sub_base, col = 1)
		draw0 = widget_draw(draw_base, xs=w_dims[0,0], ys=w_dims[0,1])

		draw_base_right = widget_base(draw_base, col = 2)
			draw1 = widget_draw(draw_base_right, xs=w_dims[1,0], ys=w_dims[1,1], /align_center)
			draw2 = widget_draw(draw_base_right, xs=w_dims[2,0], ys=w_dims[2,1], /align_center)

	info_base = widget_base(sub_base, col = 1)

	edit_base = widget_base(info_base, col=1, /base_align_right)
	widget_edit_field, edit_base, label = 'Channels', font = dcai_global.gui.font, /column, $
					   ids=ids, edit_xsize=7, lab_xsize=80, start_value=string(self.lambdas[lambda_index].n_scan_channels, f='(i0)'), $
					   edit_uval={tag:'plugin_event', object:self, method:'EditSpectrum', index:lambda_index, field:'channels'}
	self.lambdas[lambda_index].edit_ids.n_channels = ids.text

	widget_edit_field, edit_base, label = 'Min # Scans', font = dcai_global.gui.font, /column, $
					   ids=ids, edit_xsize=7, lab_xsize=100, start_value=string(self.lambdas[lambda_index].min_scans, f='(i0)'), $
					   edit_uval={tag:'plugin_event', object:self, method:'EditSpectrum', index:lambda_index, field:'minscans'}
	self.lambdas[lambda_index].edit_ids.minscans = ids.text

	widget_edit_field, edit_base, label = 'Max # Scans', font = dcai_global.gui.font, /column, $
					   ids=ids, edit_xsize=7, lab_xsize=100, start_value=string(self.lambdas[lambda_index].max_scans, f='(i0)'), $
					   edit_uval={tag:'plugin_event', object:self, method:'EditSpectrum', index:lambda_index, field:'maxscans'}
	self.lambdas[lambda_index].edit_ids.maxscans = ids.text

	widget_edit_field, edit_base, label = 'Min SNR', font = dcai_global.gui.font, /column, $
				   	   ids=ids, edit_xsize=7, lab_xsize=80, start_value=string(self.lambdas[lambda_index].min_snr, f='(i0)'), $
					   edit_uval={tag:'plugin_event', object:self, method:'EditSpectrum', index:lambda_index, field:'minsnr'}
	self.lambdas[lambda_index].edit_ids.minsnr = ids.text

	widget_edit_field, edit_base, label = '# Exposures', font = dcai_global.gui.font, /column, $
				   	   ids=ids, edit_xsize=7, lab_xsize=100, start_value=string(self.lambdas[lambda_index].num_exposures, f='(i0)'), $
					   edit_uval={tag:'plugin_event', object:self, method:'EditSpectrum', index:lambda_index, field:'numexposures'}
	self.lambdas[lambda_index].edit_ids.numexposures = ids.text

	lab = widget_label(info_base, font=dcai_global.gui.font, value = 'Etalons: ' + $
						strjoin(string(where(self.lambdas[lambda_index].etalons eq 1), f='(i0)'), ','), xsize=100)


	delete = widget_button(info_base, value = 'Close ' + wavelength_string, font = dcai_global.gui.font, xs = 100, $
								uval={tag:'plugin_event', object:self, method:'RemoveSpectrum', index:lambda_index})

	scan_base = widget_base(info_base, row = 2, frame=1)
		label = widget_label(scan_base, value = 'Scan', font= dcai_global.gui.font + '*Bold')
		scan_base_btn = widget_base(scan_base, col = 1)
			scan = widget_button(scan_base_btn, value = 'Start', font = dcai_global.gui.font, xs = 100, $
								uval={tag:'plugin_event', object:self, method:'Scan', action:'start', index:lambda_index, restart:0})
			scan = widget_button(scan_base_btn, value = 'Stop', font = dcai_global.gui.font, xs = 100, $
								uval={tag:'plugin_event', object:self, method:'Scan', action:'stop', index:lambda_index})
			scan = widget_button(scan_base_btn, value = 'Pause', font = dcai_global.gui.font, xs = 100, $
								uval={tag:'plugin_event', object:self, method:'Scan', action:'pause', index:lambda_index})
			scan = widget_button(scan_base_btn, value = 'UnPause', font = dcai_global.gui.font, xs = 100, $
								uval={tag:'plugin_event', object:self, method:'Scan', action:'unpause', index:lambda_index})
			scan = widget_button(scan_base_btn, value = 'Finalize', font = dcai_global.gui.font, xs = 100, $
								uval={tag:'plugin_event', object:self, method:'Scan', action:'finalize', index:lambda_index})

	if self.tabbed_mode eq 0 then DCAI_Control_RegisterPlugin, base, self

	widget_control, get_value = wind, draw0
		self.lambdas[lambda_index].window_ids[0] = wind
	widget_control, get_value = wind, draw1
		self.lambdas[lambda_index].window_ids[1] = wind
	widget_control, get_value = wind, draw2
		self.lambdas[lambda_index].window_ids[2] = wind



	;\\ DISPLAY THE ZONEMAP
	wset, self.lambdas[lambda_index].window_ids[2]
	loadct, 39, /silent
	tvscl, congrid(*self.lambdas[lambda_index].zonemap, 197, 197)

end


;\\ EDIT SPECTRUM
pro DCAI_Spectrum::EditSpectrum, event

	widget_control, get_uval=uval, event.id
	widget_control, get_val=val, event.id



	case uval.field of
		'channels':begin
			;\\ DONT ALLOW CHANNELS TO BE CHANGED
			widget_control, set_value=string(self.lambdas[uval.index].n_scan_channels, f='(i0)'), $
							self.lambdas[uval.index].edit_ids.n_channels
		end
		'minscans':begin
			if uval.index eq self.lambda_scanning then begin
				widget_control, set_value=string(self.lambdas[uval.index].min_scans, f='(i0)'), $
								self.lambdas[uval.index].edit_ids.minscans
			endif else begin
				self.lambdas[uval.index].min_scans = fix(val, type=3)
			endelse
		end
		'maxscans':begin
			if uval.index eq self.lambda_scanning then begin
				widget_control, set_value=string(self.lambdas[uval.index].max_scans, f='(i0)'), $
								self.lambdas[uval.index].edit_ids.maxscans
			endif else begin
				self.lambdas[uval.index].max_scans = fix(val, type=3)
			endelse
		end
		'minsnr':begin
			if uval.index eq self.lambda_scanning then begin
				widget_control, set_value=string(self.lambdas[uval.index].min_snr, f='(i0)'), $
								self.lambdas[uval.index].edit_ids.minsnr
			endif else begin
				self.lambdas[uval.index].min_snr = fix(val, type=3)
			endelse
		end
		'numexposures':begin
			if uval.index eq self.lambda_scanning then begin
				widget_control, set_value=string(self.lambdas[uval.index].num_exposures, f='(i0)'), $
								self.lambdas[uval.index].edit_ids.numexposures
			endif else begin
				self.lambdas[uval.index].num_exposures = fix(val, type=3)
			endelse
		end

		else:
	endcase

end


;\\ REMOVE SPECTRUM
pro DCAI_Spectrum::RemoveSpectrum, event, index=index, no_confirm=no_confirm

	COMMON DCAI_Control, dcai_global

	if size(index, /type) eq 0 then begin
		widget_control, get_uval = uval, event.id
		index = uval.index
	endif

	;\\ CONFIRM CLOSE

		;\\ IS THIS THE TOP-LEVEL BASE CLOSING?
		if index eq -1 then begin

			if self.lambda_scanning ne -1 then begin
				res = dialog_message('A Spectrum plugin is still scanning, stop it first!', $
									 dialog_parent = self.id, /error)
				return
			endif

			confirm = dialog_message('Confirm: Close ALL Spectrum Objects?', /question)
			if confirm eq 'No' then return

			;\\ DESTROY THE WIDGET
			if widget_info(self.id, /valid) then widget_control, /destroy, self.id

		endif else begin

			;\\ IS THIS WAVELENGTH SCANNING?
			if self.lambda_scanning eq index then begin
				res = dialog_message('This Spectrum plugin is scanning, stop it first!', $
									 dialog_parent = self.id, /error)
				return
			endif

			if not keyword_set(no_confirm) then begin
				wavelength = self.lambdas[index].wavelength
				confirm = dialog_message('Confirm: Close ' + string(wavelength, f='(f0.1)'), /question)
				if confirm eq 'No' then return
			endif

			;\\ DESTROY THE WIDGET
			if widget_info(self.lambdas[index].base_id, /valid) then widget_control, /destroy, self.lambdas[index].base_id

			;\\ CLEAN UP
			ptr_free, self.lambdas[index].spectra
			ptr_free, self.lambdas[index].zonemap
			ptr_free, self.lambdas[index].normmap
			ptr_free, self.lambdas[index].zone_info
			ptr_free, self.lambdas[index].phasemap
			ptr_free, self.lambdas[index].snr_history
			ptr_free, self.lambdas[index].bgr_history
			ptr_free, self.lambdas[index].accumulated_image

			self.n_lambdas --
			self.free_list[index] = 1

		endelse
end



;\\ EXECUTE COMMANDS SENT FROM A SCHEDULE FILE
pro DCAI_Spectrum::ScheduleCommand, command, keywords, values

	if self.scanning ne 0 then return

	lambda = 0.
	min_snr = 1000.
	min_scans = 2
	max_scans = 15
	num_exposures = 1

	for k = 0, n_elements(keywords) - 1 do begin
		case keywords[k] of
			'wavelength': lambda = float(values[k])
			'min_snr': min_snr = float(values[k])
			'min_scans': min_scans = fix(values[k])
			'max_scans': max_scans = fix(values[k])
			'num_exposures': num_exposures = fix(values[k])
			else: DCAI_Log, 'WARNING: Keyword not recognized by Spectrum plugin: ' + keywords[k]
		endcase
	endfor

	case command of
		'shutdown_all':begin ;\\ SHUTDOWN ALL SPECTRA
			for l = 0, self.n_lambdas - 1 do self->RemoveSpectrum, 0, l
		end

		'shutdown':begin ;\\ SHUTDOWN THE SPECTRUM OF THE SPECIFIED WAVELENGTH (AND ZONEMAP - TODO )
			if lambda ne 0 then begin
				l = where(self.lambas.wavlength eq lambda, nmatch)
				if nmatch eq 1 then self->RemoveSpectrum, 0, l[0]
			endif
		end

		'start':begin ;\\ START SPECTRAL ACQUISITION (MATCH ZONEMAP ALSO - TODO )
			if lambda ne 0 then begin
				l = (where(self.lambas.wavlength eq lambda, nmatch))[0]
				if nmatch eq 1 then begin
					self.lambdas[l].min_snr = min_snr
					self.lambdas[l].min_scans = min_scans
					self.lambdas[l].max_scans = max_scans
					self.lambdas[l].num_exposures = num_exposures
					self->Scan, 0, command = {index:l, action:'start', restart:0}
				endif
			endif
		end

		else: DCAI_Log, 'WARNING: Command not recognized by Spectrum plugin: ' + command
	endcase

end


;\\ BUILD A UID STRING FROM THIS OBJECT
function DCAI_Spectrum::uid, args=args

	if not keyword_set(args) then begin
		;\\ IF THERE IS AN ACTIVE SPECTRUM OBJECT, RETURN THAT ONE'S UID, ELSE BUILD A GENERIC ONE
		if self.lambda_scanning ne - 1 then begin
			return, 'spectrum_' + self.lambdas[self.lambda_scanning].uid
		endif else begin
			return, 'spectrum'
		endelse
	endif else begin
		;\\ BUILD UID FROM THE GIVEN INFO
		;\\ args = {wavelength:0.0, etalons:intarr[], ...}
		uid = 'spectrum_' + string(args.wavelength*10, f='(i04)') + '_' + $
			  strjoin(string(args.etalons, f='(i01)'), '') + '_' + $
			  string(args.n_zones, f='(i04)')
		return, uid
	endelse
end


;\\ ZONEMAP BUILDER
function DCAI_Spectrum::BuildZonemap, filename, dimensions, center

	if file_test(filename) eq 0 then return, {error:'invalid_filename'}

	lines = strarr(file_lines(filename))
	openr, handle, filename, /get
	readf, handle, lines
	free_lun, handle

	lines = strcompress(lines, /remove)
	keep = where(lines ne '', nkeep)

	if nkeep eq 0 then return, {error:'no_text'}

	lines = lines[keep]

	;\\ SEARCH FOR A BEGIN STATEMENT
	begins = where(strmatch(lines, '*begin*', /fold) eq 1, n_begins)
	ends = where(strmatch(lines, '*end*', /fold) eq 1, n_ends)
	ends = ends > begins[0]

	if n_begins lt 1 then return, {error:'no_sections'}
	if n_ends ne n_begins then return, {error:'unmatched_begin_or_end'}

	;\\ USE THE FISRT ONE
	sect_start = begins[0]
	sect_end = ends[0]

	;\\ ZONEMAP TYPE
	zmap_type = strlowcase(strcompress((strsplit(lines[sect_start], ':', /extract))[1], /remove))

	;\\ GET LINES IN SECTION
	sect_lines = lines[sect_start+1: sect_end-1]
	case zmap_type of

		'annular':begin

			rads_line = (where(strmatch(sect_lines, '*rads*', /fold) eq 1, n_rads))[0]
			secs_line = (where(strmatch(sect_lines, '*secs*', /fold) eq 1, n_secs))[0]

			if n_rads eq 0 then return, {error:'no_rads_line'}
			if n_secs eq 0 then return, {error:'no_secs_line'}

			if execute(sect_lines[rads_line]) eq 0 then return, {error:'error_executing_rads'}
			if execute(sect_lines[secs_line]) eq 0 then return, {error:'error_executing_secs'}

			zonemap = zonemap_builder(annular={xsize:dimensions[0], ysize:dimensions[1], $
											   xcenter:center[0], ycenter:center[1], $
											   radii:rads, sectors:secs}, $
									  zone_centers=zone_centers)

			zone_centers[*,0] /= float(dimensions[0])
			zone_centers[*,1] /= float(dimensions[1])
			return, {error:'none', $
					 rads:rads, $
					 secs:secs, $
					 center:center, $
					 zonemap:zonemap, $
					 n_zones:max(zonemap)+1, $
					 zone_centers:zone_centers}
		end

		else: return, {error:'unsupported_zonemap_type'}
	endcase

end


;\\ CLEANUP
pro DCAI_Spectrum::Cleanup

	self->DCAI_Plugin::cleanup

	for j = 0, n_elements(self.lambdas) - 1 do begin
		ptr_free, self.lambdas[j].spectra
		ptr_free, self.lambdas[j].zonemap
		ptr_free, self.lambdas[j].normmap
		ptr_free, self.lambdas[j].zone_info
		ptr_free, self.lambdas[j].phasemap
		ptr_free, self.lambdas[j].snr_history
		ptr_free, self.lambdas[j].bgr_history
		ptr_free, self.lambdas[j].accumulated_image
	endfor

end


;\\ DEFINITION
pro DCAI_Spectrum__define

	COMMON DCAI_Control, dcai_global

	n_etalons = n_elements(dcai_global.settings.etalon)

	per_lambda = {lambda_struc, $ ;\\ Has to be a named structure to appear in an object structure
				  uid:'', $ ;\\ String allowing unique id for each wavelength, zonemap, etlaon, etc.
				  etalons:intarr(n_etalons), $ ;\\ Will be initialized to -1 for each etalon
				  wavelength:0.0, $	;\\ Wavelength of this spectrum
				  scanning:0, $ ;\\ Flag to indicate that this wavelength is currently scanning
				  n_zones:0, $ ;\\ Number of zones in the zonemap
				  n_scan_channels:0, $ ;\\ Number of scan channels
				  n_spectral_channels:0, $ ;\\ Number of spectral channels
				  wavelength_range:[0.0, 0.0], $ ;\\ Wavelength range of interest
				  wavelength_range_full:[0.0, 0.0], $ ;\\ Wavelength range required at fringe center to give wavelength_range in each zone
				  scan_type:'', $	;\\ Scan type: 'wavelength' (dual etalon) or 'order' (single etalon)
				  window_ids:[0,0,0], $
				  window_dims:intarr(3,2), $
				  edit_ids:{spex_edit_ids, n_channels:0L, minscans:0L, maxscans:0L, minsnr:0L, numexposures:0L}, $
				  base_id:0L, $
				  finalize:0, $ ;\\ Flag to indicate that acquisition will be finalized, regardless of snr or # scans
				  min_snr:0., $ ;\\ Minimum snr to reach
				  min_scans:0., $ ;\\ Minimum number of scans to do
				  max_scans:0., $ ;\\ Maximum number of scans to do
				  current_scan:0, $ ;\\ The current scan number
				  num_exposures:0, $ ;\\ Number of exposures to do consecutively
				  current_exposure:0, $ ;\\ The current exposure number
				  sizes:intarr(4), $	;\\ Information for the spectra accumulator
				  spectra:ptr_new(/alloc), $
				  zonemap:ptr_new(/alloc), $
				  normmap:ptr_new(/alloc), $
				  zone_info:ptr_new(/alloc), $
				  phasemap:ptr_new(/alloc), $
				  accumulated_image:ptr_new(/alloc), $
				  snr_history:ptr_new(/alloc), $
				  bgr_history:ptr_new(/alloc) $
				 }

	state = {DCAI_Spectrum, tab_base:0L, $
							info_labels:[0L,0L,0L,0L], $
							tabbed_mode:0, $
							lambdas:replicate(per_lambda, 20), $
							n_lambdas:0, $
							free_list:intarr(20), $
							scanning:0, $
							lambda_scanning:-1, $
							INHERITS DCAI_Plugin}
end
