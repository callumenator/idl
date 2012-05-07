

;\\ Argument depends upon command and scan_type:

;\\ command = 'start'
;\\ scan_type = 'normal'
;\\ argument (e.g.) = [{caller:objref, etalon:0, n_channels:128, wavelength_nm:632.8, start_voltage:0}] one struc for each etalon
;\\ scan_type = 'manual'
;\\ argument (e.g.) = [{caller:objref, etalon:0, n_channels:200, step_size:2, start_voltage:0}] one struc for each etalon
;\\ scan_type = 'wavelength'
;\\ argument (e.g.) = {caller:objref, etalons:[0,1], n_channels:100, wavelength_range_nm:[629.99, 630.01]}

;\\ command = 'stop'
;\\ scan_type = 'dummy'
;\\ argument = [{caller:objref, etalon:0}] one struc for each etalon

;\\ command = 'increment'
;\\ scan_type = 'dummy'
;\\ argument = optional [{etalon:0, channel:0}] one for each etalon, set to given channel

;\\ command = 'setnominal'
;\\ scan_type = 'dummy'
;\\ argument = [{etalon:0, voltage:0}] -- one struc for each etalon you want to set

;\\ command = 'setlegs'
;\\ scan_type = 'dummy'
;\\ argument = [{etalon:0, voltage:[0,0,0]}] -- one struc for each etalon you want to set

;\\ command = 'getpixelwavelength'
;\\ scan_type = 'dummy'
;\\ argument = {pixel:[0,0], central_wavelength:0.0, nominal_wavelength:0.0}

;\\ Function returns 1 on sucess, 0 on failure

function DCAI_ScanControl, command, scan_type, argument, $
						   messages=messages, $
						   force_increment=force_increment, $
						   delayed_start=delayed_start

	COMMON DCAI_Control, dcai_global

	messages = 'none'

	case strlowcase(command) of

		'start':begin

			if scan_type ne 'normal' and scan_type ne 'manual' and scan_type ne 'wavelength' then begin
				print, 'ScanControl: scan_type not recognized: ' + scan_type
				return, 0
			endif


			if scan_type ne 'wavelength' then begin

				;\\ NEED TO MAKE SURE ALL REQUESTED ETALONS ARE AVAILABLE TO SCAN
				ready_to_scan = intarr(n_elements(dcai_global.settings.etalon))
				for i = 0, n_elements(argument) - 1 do begin
					args = argument[i]

					if dcai_global.scan.scanning[args.etalon] ne 0 then continue
					ready_to_scan[args.etalon] = 1
				endfor


				;\\ ONLY PROCEED IF ALL REQUESTED ETALONS ARE AVAILABLE FOR SCANNING
				if total(ready_to_scan) ne n_elements(argument) then begin
					print, 'ScanControl: Not all etalons available to scan.'
					return, 0
				endif

				dcai_global.scan.type = scan_type

				for i = 0, n_elements(argument) - 1 do begin
					args = argument[i]

					;\\ FLAG SCANNING FOR THIS ETALON
						if not keyword_set(delayed_start) then begin
							dcai_global.scan.scanning[args.etalon] = 1
							dcai_global.scan.scanner[args.etalon] = args.caller
						endif
						dcai_global.scan.started_at[args.etalon] = dcai_global.info.timer_ticks
						dcai_global.scan.n_channels[args.etalon] = args.n_channels


					if scan_type eq 'normal' then begin
						dcai_global.scan.step_size[args.etalon] = round(float(dcai_global.settings.etalon[args.etalon].steps_per_order * args.wavelength_nm) / float(args.n_channels))
						dcai_global.scan.offset[args.etalon] = args.start_voltage
						dcai_global.scan.type = 'normal'

						;\\ DRIVE TO INITIAL LEG POSITIONS
						;success = DCAI_ScanControl('setnominal', 'dummy', {etalon:args.etalon, voltage:dcai_global.scan.offset[args.etalon]})
						;wait, 2
						;\\ FLUSH THE CAMERA IMAGES
						;call_procedure, dcai_global.info.drivers, {device:'camera_flush'}
					endif

					if scan_type eq 'manual' then begin
						dcai_global.scan.step_size[args.etalon] = args.step_size
						dcai_global.scan.offset[args.etalon] = args.start_voltage
						dcai_global.scan.type = 'manual'
					endif

				endfor
			endif else begin

				;\\ THIS IS A WAVELENGTH SCAN

				;\\ NEED TO MAKE SURE ALL REQUESTED ETALONS ARE AVAILABLE TO SCAN
				ready_to_scan = intarr(n_elements(dcai_global.settings.etalon))
				for k = 0, n_elements(argument.etalons) - 1 do begin
					if dcai_global.scan.scanning[argument.etalons[k]] ne 0 then continue
					ready_to_scan[argument.etalons[k]] = 1
				endfor

				if total(ready_to_scan) ne n_elements(argument.etalons) then begin
					DCAI_Log, 'ScanControl: Not all etalons available to scan.'
					return, 0
				endif


				;\\ FIND THE CLOSEST LAMBDA IN THE CALIBRATION INFO
					cws = dcai_global.scan.center_wavelength
					lambda_diff = abs(argument.wavelength_range_nm[0] - cws[0,*].view_wavelength_nm)
					cws_idx = (where(lambda_diff eq min(lambda_diff)))[0]
					if cws[0, cws_idx].view_wavelength_nm eq 0.0 then begin
						DCAI_Log, 'ScanControl: No calibration info for wavelength scan.'
						return, 0
					endif

				dcai_global.scan.type = 'wavelength'
				dcai_global.scan.wavelength_nm = (argument.wavelength_range_nm[0] + $
												  argument.wavelength_range_nm[1]) / 2.

				for i = 0, n_elements(argument.etalons) - 1 do begin
					etz_idx = argument.etalons[i]
					etz = dcai_global.settings.etalon[etz_idx]

					;\\ FLAG SCANNING FOR THIS ETALON
					if not keyword_set(delayed_start) then begin
						dcai_global.scan.scanning[etz_idx] = 1
						dcai_global.scan.scanner[etz_idx] = argument.caller
					endif

					dcai_global.scan.n_channels[etz_idx] = argument.n_channels
					dcai_global.scan.started_at[etz_idx] = dcai_global.info.timer_ticks

					;\\ CALCULATE STEP SIZE REQUIRED TO COVER WAVELENGTH RANGE IN N_CHANNELS
					lambda_stp = (argument.wavelength_range_nm[1] - argument.wavelength_range_nm[0]) / $
									float(argument.n_channels -1)
					order_stp = lambda_stp / cws[etz_idx,cws_idx].fsr
					voltage_stp = order_stp * etz.steps_per_order * dcai_global.scan.wavelength_nm
					dcai_global.scan.step_size[etz_idx] = voltage_stp

					;\\ CALCULATE WHERE THE SCAN NEEDS TO START
					del_lambda = argument.wavelength_range_nm[0] - cws[etz_idx,cws_idx].center_wavelength_nm

					;\\ CONVERT TO # ORDERS
					del_orders = (del_lambda / cws[etz_idx,cws_idx].fsr) mod 1

					;\\ CONVERT TO 'VOLTAGE'
					del_volts = del_orders * etz.steps_per_order * dcai_global.scan.wavelength_nm

					;\\ SET THE STARTING NOMINAL VOLTAGE
					home_volts = cws[etz_idx,cws_idx].home_voltage
					dcai_global.scan.offset[etz_idx] = home_volts + del_volts

				endfor

			endelse

			success = DCAI_ScanControl('increment', 'dummy', 0, /force_increment)
			return, 1
		end


		'stop':begin

			stopped = intarr(n_elements(argument))
			for i = 0, n_elements(argument) - 1 do begin
				args = argument[i]

				allow_stop = 0
				if size(args.caller, /type) eq 7 then begin
					if args.caller eq 'control' then allow_stop = 1
				endif
				if size(args.caller, /type) eq 11 then begin
					if args.caller eq dcai_global.scan.scanner[args.etalon] then allow_stop = 1
				endif

				if allow_stop eq 1 then begin
					dcai_global.scan.type = ''
					dcai_global.scan.wavelength_nm = 0.0
					dcai_global.scan.scanning[args.etalon] = 0
					dcai_global.scan.started_at[args.etalon] = 0
					dcai_global.scan.n_channels[args.etalon] = -1
					dcai_global.scan.channel[args.etalon] = -1
					dcai_global.scan.step_size[args.etalon] = 0
					dcai_global.scan.offset[args.etalon] = 0
					dcai_global.scan.scanner[args.etalon] = obj_new()
					stopped[i] = 1
				endif
			endfor
			return, (total(stopped) ne 0)
		end


		'pause':begin

			paused = intarr(n_elements(argument))
			for i = 0, n_elements(argument) - 1 do begin
				args = argument[i]
				if dcai_global.scan.scanning[args.etalon] eq 1 then begin
					dcai_global.scan.scanning[args.etalon] = 2
					paused[i] = 1
				endif
			endfor

			return, (total(paused) ne 0)
		end


		'unpause':begin

			unpaused = intarr(n_elements(argument))
			for i = 0, n_elements(argument) - 1 do begin
				args = argument[i]
				if dcai_global.scan.scanning[args.etalon] eq 2 then begin
					dcai_global.scan.scanning[args.etalon] = 1
					unpaused[i] = 1
				endif
			endfor

			return, (total(unpaused) ne 0)
		end


		'increment':begin ;\\ INCREMENT THE SCAN CHANNELS IF SCANNING

			set_channel = lonarr(n_elements(dcai_global.settings.etalon))
			set_channel[*] = -1L
			force_channel = 0
			if size(argument, /type) eq 8 then begin
				for k = 0, n_elements(argument) - 1 do begin
					set_channel[argument[k].etalon] = argument[k].channel
				endfor
				force_channel = 1
			endif


			for idx = 0, n_elements(dcai_global.settings.etalon) - 1 do begin

				do_inc = ((keyword_set(force_increment) and (dcai_global.scan.started_at[idx] eq dcai_global.info.timer_ticks)) or $
						 (dcai_global.scan.started_at[idx] ne dcai_global.info.timer_ticks))

				if (dcai_global.scan.scanning[idx] eq 1 and do_inc eq 1) or force_channel eq 1 then begin

					;\\ INCREMENT THE SCAN CHANNEL OR SET ACCORDING TO SUPPLIED ARGUMENT
					if set_channel[idx] eq -1 then begin
						if force_channel eq 0 then dcai_global.scan.channel[idx] ++
					endif else begin
						dcai_global.scan.channel[idx] = set_channel[idx]
					endelse

					;\\ CHECK FOR END OF SCAN
					if dcai_global.scan.channel[idx] ge dcai_global.scan.n_channels[idx] then begin
						success = DCAI_ScanControl('stop', 'dummy', {caller:'control', etalon:idx})
					endif else begin

						;\\ IF WE HAVEN'T REACHED THE END OF THE SCAN, UPDATE THE LEG VOLTAGES
						increment = float(dcai_global.scan.channel[idx]) * $
									float(dcai_global.scan.step_size[idx])

						if dcai_global.scan.type eq 'wavelength' then begin
							wrap_at = (dcai_global.settings.etalon[idx].steps_per_order*dcai_global.scan.wavelength_nm)
							increment = increment mod wrap_at
						endif

						offset = dcai_global.scan.offset[idx]

						leg0_inc = offset + increment - dcai_global.settings.etalon[idx].reference_voltage
						leg_inc = leg0_inc * dcai_global.settings.etalon[idx].leg_gain
						leg_start = dcai_global.settings.etalon[idx].reference_voltage + $
									dcai_global.settings.etalon[idx].parallel_offset

						volts = leg_start + leg_inc
						dcai_global.settings.etalon[idx].leg_voltage = round(volts)


						;\\ KEEP THE LEG VOLTAGES INSIDE THEIR RANGES
						dcai_global.settings.etalon[idx].leg_voltage = dcai_global.settings.etalon[idx].leg_voltage > dcai_global.settings.etalon[idx].voltage_range[0]
						dcai_global.settings.etalon[idx].leg_voltage = dcai_global.settings.etalon[idx].leg_voltage < dcai_global.settings.etalon[idx].voltage_range[1]

						DCAI_Log, 'E'+string(idx, f='(i0)') + strjoin(string(dcai_global.settings.etalon[idx].leg_voltage, f='(i0)'), ','), /no_write

						call_procedure, dcai_global.info.drivers, $
								{device:'etalon_setlegs', number:idx, $
								 voltage:dcai_global.settings.etalon[idx].leg_voltage}

					endelse
				endif
			endfor

			return, 1
		end


		'setnominal':begin	;\\ SET THE NOMINAL LEG VOLTAGE (AND MAINTAIN PARALLELISM)
			for i = 0, n_elements(argument) - 1 do begin
				args = argument[i]

				leg0_inc = args.voltage - dcai_global.settings.etalon[args.etalon].reference_voltage
				leg_inc = leg0_inc*dcai_global.settings.etalon[args.etalon].leg_gain
				leg_start = dcai_global.settings.etalon[args.etalon].reference_voltage + $
							dcai_global.settings.etalon[args.etalon].parallel_offset

				volts = leg_start + leg_inc
				dcai_global.settings.etalon[args.etalon].leg_voltage = round(volts)
				call_procedure, dcai_global.info.drivers, {device:'etalon_setlegs', number:args.etalon, voltage:round(volts)}
			endfor
			return, 1
		end


		'setlegs':begin	;\\ SET THE LEGS TO GIVEN VOLTAGES
			for i = 0, n_elements(argument) - 1 do begin
				args = argument[i]
				dcai_global.settings.etalon[args.etalon].leg_voltage = args.voltage
				call_procedure, dcai_global.info.drivers, {device:'etalon_setlegs', number:args.etalon, voltage:args.voltage}
			endfor
			return, 1
		end


		'getpixelwavelength':begin
			pmaps = intarr(n_elements(dcai_global.info.phasemap))
			for k = 0, n_elements(pmaps) - 1 do pmaps[k] = size(*dcai_global.info.phasemap[k], /type) ne 0
			pts = where(pmaps ne 0, npmap)
			if npmap eq 0 then return, 0

			;\\ FIND CLOSEST CALIBRATION INFO
			cws = dcai_global.scan.center_wavelength
			diff = abs(cws[0,*].view_wavelength_nm - argument.nominal_wavelength)
			pt = (where(diff eq min(diff)))[0]
			cws = reform(cws[*, pt])


			;\\ COMBINE THE PHASEMAPS
			if npmap eq 1 then begin
				pmap = *dcai_global.info.phasemap[pts[0]]/cws[pts[0]].view_wavelength_nm
				lmap = cws[pts[0]].fsr * (pmap - pmap[cws[0].center[0], cws[0].center[1]])
			endif else begin
				wgt0 = .5
				wgt1 = .5
				pmap0 = *dcai_global.info.phasemap[0]/cws[0].view_wavelength_nm
				lmap0 = cws[0].fsr * (pmap0 - pmap0[cws[0].center[0], cws[0].center[1]])
				pmap1 = *dcai_global.info.phasemap[1]/cws[1].view_wavelength_nm
				lmap1 = cws[1].fsr * (pmap1 - pmap1[cws[0].center[0], cws[0].center[1]])
				lmap = (lmap0*wgt0 + lmap1*wgt1) / (wgt0 + wgt1)
			endelse

			if argument.pixel[0] lt 0 and argument.pixel[1] lt 0 then begin
				return, argument.center_wavelength - lmap
			endif else begin
				return, argument.center_wavelength - lmap[argument.pixel[0], argument.pixel[1]]
			endelse

		end


		'getfringecenter':begin

			dims = size(*dcai_global.info.image, /dimensions)

			pmaps = 0
			x_cen = 0.
			y_cen = 0.
			for k = 0, n_elements(dcai_global.info.phasemap) - 1 do begin
				if size(*dcai_global.info.phasemap[k], /type) ne 0 then begin

					fit = sfit(*dcai_global.info.phasemap[k], 2, kx=coeff, /max_degree)

					xc = ( (coeff[4]*coeff[1]/(2*coeff[2])) - coeff[3] ) / $
						 (2*coeff[5] - (coeff[4]*coeff[4]/(2*coeff[2])))

					yc = (coeff[1] - (coeff[4]*coeff[3]/(2*coeff[5]))) / $
						 ((coeff[4]*coeff[4]/(2*coeff[5])) - 2*coeff[2])

					x_cen += xc
					y_cen += yc

					pmaps ++
				endif
			endfor

			if pmaps eq 0 then center = dims/2 else center = [x_cen, y_cen]/float(pmaps)

			return, center
		end


		else: print, 'ScanControl: Command not recognized: ' + command
	endcase


end
