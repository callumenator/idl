
;\\ Andor Camera Driver
;\\ keyword <unload> set this to unload the dll from memory after the given command
;\\ keyword <auto_acq> set this to automatically interupt acquisition in order to perform command.
;\\					   Acquisition will be restarted after the command is executed

pro Andor_Camera_Driver, dll, command, in, out, result, unload=unload, auto_acq=auto_acq

		out = 'empty'

		if keyword_set(auto_acq) then begin
			;\\ Check to see if acquiring
			need_acq_restart = 0
			Andor_Camera_Driver, dll, 'uGetStatus', 0, out, res
			if out eq 'DRV_ACQUIRING' then begin
				need_acq_restart = 1
				result = get_error(call_external(dll, 'uAbortAcquisition'))
			endif
		endif

	;\\ For efficiency, sort the case statements by most frequent call
	case strlowcase(command) of

		;\\ GENERIC FRAME GRABBER, DEPENDS ON ACQ MODE
		;\\ e.g. in = {mode:5, imageMode: from the settings structure, startAndWait:0}
		strlowcase('uGrabFrame'): begin

			result = 'noimage'
			image_x=long( (in.imageMode.xPixStop - in.imageMode.xPixStart + 1L) / $
							(in.imageMode.xBin>1) )
			image_y=long( (in.imageMode.yPixStop - in.imageMode.yPixStart + 1L	) / $
							(in.imageMode.yBin>1) )

			image = lonarr(image_x, image_y)
			image_size = ulong(float(image_x) * float(image_y))
			exp_time_sec = -1.0

			case in.mode of

				1: begin	;\\ SINGLE IMAGE MODE
					if in.startAndWait eq 1 then begin

						res = call_external(dll, 'uStartAcquisition')
						if res eq 20002 then begin ;\\ if res = DRV_SUCCESS

			                status = 0
			                res = call_external(dll, 'uGetStatus', status)
			                exp_start_sec = systime(/sec)
			                inf_loop = 0
			                while status ne 20073 do begin
			                  res = call_external(dll, 'uGetStatus', status)
			                  if systime(/sec) - exp_start_sec gt 5 then begin
			                    inf_loop = 1
			                    print, 'Breaking out of inf loop...'
			                    break
			                  endif
			                endwhile


			  				exp_time_sec = systime(/sec) - exp_start_sec
			  				if inf_loop eq 0 then begin
					           	res = call_external(dll, 'uGetMostRecentImage', image, image_size)
					           	exp_time_sec = systime(/sec) - exp_start_sec
					           	result = 'image'
					        endif else begin
					           	print, 'Aborting acq...'
					            res = call_external(dll, 'uAbortAcquisition')
					        	print, get_error(res)
					        endelse

	  					endif

					endif else begin

						status = 0
						res = call_external(dll, 'uGetStatus', status)
						if status eq 20073 then begin ;\\ if res = DRV_IDLE
							res = call_external(dll, 'uGetMostRecentImage', image, image_size)
							result = 'image'
						endif else begin
						  res = call_external(dll, 'uStartAcquisition')
						endelse

					endelse

					break
				end

				5: begin ;\\ RUN TILL ABORT MODE

					image_buffer = lonarr(image_x, image_y)
					firstim = -1L
					lastim  = -1L
					res = get_error(call_external(dll, 'uGetNumberNewImages', firstim, lastim, value=[0b, 0b]))

					if res eq 'DRV_NO_NEW_DATA' or firstim eq -1 or lastim eq -1 then return

					if res eq 'DRV_SUCCESS' and (lastim - firstim) eq 47 then begin
						resx = call_external(dll, 'uAbortAcquisition')
						resx = call_external(dll, 'uStartAcquisition')
						firstim = lastim
						result = res
						break
					endif

					nframes = 0

			        repeat begin
		  				res = call_external(dll, 'uGetOldestImage', image_buffer, image_size)

		  				if nframes eq 0 then image = image_buffer else image += image_buffer
	 					nframes = nframes + 1

		  				firstim = 0L
		  				lastim = 0L
		  				res = get_error(call_external(dll, 'uGetNumberNewImages', firstim, lastim, value=[0b, 0b]))
					endrep until firstim eq lastim
					result = 'image'

					image = image/nframes

					break
				end

				else:

			endcase

			out = {image:image, exp_time:exp_time_sec}

		end

		strlowcase('uGetStatus'): begin
			;\\ Query the camera status
			status = 0
			result = get_error(call_external(dll, 'uGetStatus', status))
			out = get_error(status)
		end

		strlowcase('uSetExposureTime'): begin
			;\\ Set exposure time
			result = get_error(call_external(dll, 'uSetExposureTime', in))
			;MC: Added the following line, which might be helpful for acquisition mode 5:
			result = get_error(call_external(dll, 'uSetKineticCycleTime', in+0.01))
		end

		strlowcase('uSetEMCCDGain'): begin
			;\\ Get the current gain
			result = get_error(call_external(dll, 'uSetEMCCDGain', long(in)))
		end

		strlowcase('uSetGain'): begin
			;\\ Set gain - Probably don't want this one, use setEMCCDGain
			result = get_error(call_external(dll, 'uSetGain', long(in)))
		end

		strlowcase('uIsAcquiring'): begin
			Andor_Camera_Driver, dll, 'uGetStatus', 0, out, res
			if out eq 'DRV_ACQUIRING' then out = 1 else out = 0
			break
		end

		strlowcase('uAbortAcquisition'): begin
			;\\ Abort the current acquisition
			result = get_error(call_external(dll, 'uAbortAcquisition'))
		end

		strlowcase('uStartAcquisition'): begin
			;\\ Start acquiring
			result = get_error(call_external(dll, 'uStartAcquisition'))
		end

		strlowcase('uWaitForAcquisition'): begin
			;\\ Wait for an acquisition
			result = get_error(call_external(dll, 'uWaitForAcquisition'))
		end

		strlowcase('uGetTemperatureF'): begin
			;\\ Get cooler temperature
			temp = 0.0
			result = get_error(call_external(dll, 'uGetTemperatureF', temp))
			out = temp
		end

		strlowcase('uSetImage'): begin
			;\\ Set Image mode attributes: binning, size of image
			res = call_external(dll, 'uAbortAcquisition')
      res = call_external(dll, 'uFreeInternalMemory')
      wait, 2
			result = get_error(call_external(dll, 'uSetImage', $
						long(in[0]), long(in[1]), long(in[2]), long(in[3]), long(in[4]), long(in[5])))
			wait, 2
			res = call_external(dll, 'uFreeInternalMemory')
		end

		strlowcase('uSetHSSpeed'): begin
			;\\ Set horizontal shift speed
			;\\ in = {outamp:0 or 1, index:}
			if size(in, /type) ne 8 then begin
			 result = get_error(call_external(dll, 'uSetHSSpeed', long(0), long(in)))
			endif else begin
			 result = get_error(call_external(dll, 'uSetHSSpeed', long(in.outamp), long(in.index)))
			endelse
		end

		strlowcase('uSetVSSpeed'): begin
			;\\ Set vertical shift speed
			result = get_error(call_external(dll, 'uSetVSSpeed', long(in)))
		end

		strlowcase('uSetVSAmplitude'): begin
			;\\ Set Amplitude of the vertical shift clock pulse:
			result = get_error(call_external(dll, 'uSetVSAmplitude', long(in)))
		end

		strlowcase('uGetHSSpeed'): begin
			;\\ Get HS Speed given the adchannel, outamp and index.
			;\\ in = {adchannel:0, outputamp:0, hsindex:0}
			hsspeed = 0.
			result = get_error(call_external(dll, 'uGetHSSpeed', long(in.adchannel), long(in.outputamp), long(in.hsindex), hsspeed))
			out = hsspeed
		end

		strlowcase('uGetAcquisitionTimings'): begin
			;\\ Get the current 'valid' acquisition timings
			exposure = 0.0
			accumulate = 0.0
			kinetic = 0.0
			result = get_error(call_external(dll, 'uGetAcquisitionTimings', exposure, $
									accumulate, kinetic))
			out = {exposure:exposure, accumulate:accumulate, kinetic:kinetic}
		end

		strlowcase('uSetHighCapacity'): begin
			;\\ Set or unset the high capacity funcitonality
			result = get_error(call_external(dll, 'uSetHighCapacity', long(in)))
		end

		strlowcase('uGetNumberNewImages'): begin
			;\\ Get number of new images in the circular buffer
			firstim = 0L
			lastim  = 0L
			result = get_error(call_external(dll, 'uGetNumberNewImages', firstim, lastim, value=[0b, 0b]))
			out = [firstim, lastim]
		end

		strlowcase('uFreeInternalMemory'): begin
			result = get_error(call_external(dll, 'uFreeInternalMemory'))
		end

		strlowcase('uSetReadMode'): begin
			;\\ Set read mode
			result = get_error(call_external(dll, 'uSetReadMode', in))
		end

		strlowcase('uGetHeadModel'): begin
			desc = " "
			for j = 0, 20 do desc += "?"
			result = get_error(call_external(dll, 'uGetHeadModel', desc))
			out = desc
		end

		strlowcase('uGetCameraSerialNumber'): begin
			serno = 0
			result = get_error(call_external(dll, 'uGetCameraSerialNumber', serno))
			out = serno
		end

		strlowcase('uSetAcquisitionMode'): begin
			;\\ Set acquisition mode
			status = 0
			result = get_error(call_external(dll, 'uSetAcquisitionMode', long(in)))
		end

		strlowcase('uSetFrameTransferMode'): begin
			;\\ Set frame transfer mode
			result = get_error(call_external(dll, 'uSetFrameTransferMode', long(in)))
		end

		strlowcase('uSetBaselineClamp'): begin
			;\\ Set baseline clamping in = 1 (on) in = 0 (off)
			result = get_error(call_external(dll, 'uSetBaselineClamp', long(in)))
		end

		strlowcase('uSetPreAmpGain'): begin
			;\\ Set preamp gain index
			result = get_error(call_external(dll, 'uSetPreAmpGain', long(in)))
		end

		strlowcase('uSetEMGainMode'): begin
			;\\ Set EM gain Mode
			result = get_error(call_external(dll, 'uSetEMGainMode', long(in)))
		end

		strlowcase('uSetEMAdvanced'): begin
			;\\ Set Extended EM gain Mode
			result = get_error(call_external(dll, 'uSetEMAdvanced', long(in)))
		end

		strlowcase('uSetADChannel'): begin
			;\\ AD 0 is high sped 14 bit, amp 1 is only 1MHz 16 bit.
			result = get_error(call_external(dll, 'uSetADChannel', long(in)))
		end

	    strlowcase('uSetOutputAmplifier'): begin
			;\\ Amp 0 is EM mode, Amp 1 is regular
			result = get_error(call_external(dll, 'uSetOutputAmplifier', long(in)))
		end

		strlowcase('uSetTriggerMode'): begin
			;\\ Set internal triggering
			result = get_error(call_external(dll, 'uSetTriggerMode', long(in)))
		end

		strlowcase('uSetShutter'): begin
			;\\ Set shutter, in = [0 =auto 1=open 2=close, closing time, opening time]
			result = get_error(call_external(dll, 'uSetShutter', 1, long(in[0]), long(in[1]), long(in[2])))
		end

		strlowcase('uSetTemperature'): begin
			;\\ Set cooler temperature
			result = get_error(call_external(dll, 'uSetTemperature', long(in)))
		end

		strlowcase('uCoolerON'): begin
			;\\ Turn on the cooler
			result = get_error(call_external(dll, 'uCoolerON'))
		end

		strlowcase('uCoolerOFF'): begin
			;\\ Turn off the cooler
			result = get_error(call_external(dll, 'uCoolerOFF'))
		end

		strlowcase('uGetTemperatureRange'): begin
			min_temp = 0
			max_temp = 0
			res = call_external(dll, 'uGetTemperatureRange', min_temp, max_temp)
			out = [min_temp, max_temp]
		end

		strlowcase('uGetEMCCDGain'): begin
			;\\ Get the current gain
			gain = -1
			result = get_error(call_external(dll, 'uGetEMCCDGain', gain))
			out = gain
		end

		strlowcase('uGetEMGainRange'): begin
			;\\ Get the allowable gain range based on gain mode and sensor temperature
			lo = -1
			hi = -1
			result = get_error(call_external(dll, 'uGetEMGainRange', lo, hi))
			out = [lo, hi]
		end

		strlowcase('uSetFanMode'): begin
			;\\ Set fan mode: 0 - on full, 1: on low, 2: off
			result = get_error(call_external(dll, 'uSetFanMode', long(in)))
		end

		strlowcase('uInitialize'): begin
			result = get_error(call_external(dll, 'uInitialize', in))
		end

		strlowcase('uShutdown'): begin
			;\\ Wait for an acquisition
			result = get_error(call_external(dll, 'uShutDown'))
		end


		;\\ GENERATE AN IDL STUCTURE CONTAINING A LIST OF CAPABILITIES
		strlowcase('uGetCapabilities'): begin

			Andor_Camera_Driver, dll, 'uGetStatus', 0, status, err

			no_camera = 0
			numADChannels = -1
			res = 'NumADChannels: ' + get_error(call_external(dll, 'uGetNumberADChannels', numAdChannels))

			;\\ GET THE BIT DEPTHS FOR EACH AD CHANNEL
			if numADChannels gt 0 then begin
				bitDepths = intarr(numADChannels)
				for adIndex = 0, numADChannels - 1 do begin
					depth = 0
					res = [res, 'BitDepth: ' + get_error(call_external(dll, 'uGetBitDepth', adIndex, depth))]
					bitDepths[adIndex] = depth
				endfor
			endif else begin
				bitDepths = -1
			endelse

			if total(bitdepths) eq 0 then begin
				;\\ Probably no camera attached! Fill rest of caps with empty vals
				no_camera = 1
			endif

			;\\ AMPLIFIERS
			numAmps = -1
			res = [res, 'NumAmps: ' + get_error(call_external(dll, 'uGetNumberAmp', numAmps))]
			if numAmps gt 0 then begin
				amps = replicate({description:'', maxHSSpeed:0.0}, numAmps)
				for ampIndex = 0, numAmps - 1 do begin
					desc = " "
					for j = 0, 20 do desc += "?"

					if no_camera eq 0 then $
						res = [res, 'AmpDesc: ' + get_error(call_external(dll, 'uGetAmpDesc', ampIndex, desc))] $
							else res = [res, '']

					pts = where(byte(desc) eq byte("?"), npts)
					if npts gt 0 then desc = strmid(desc, 0, min(pts) + 1)

					maxHsspeed = 0.0
					if no_camera eq 0 then $
						res = [res, 'AmpHSSpeed: ' + get_error(call_external(dll, 'uGetAmpMaxSpeed', ampIndex, maxHsspeed))] $
							else res = [res, '']

					amps[ampIndex].description = desc
					amps[ampIndex].maxHSSpeed = maxHSSpeed
				endfor
			endif else begin
				amps = -1
			endelse

			;\\ HORIZONTAL SHIFT SPEEDS
			hsspeeds = replicate({adchannel:0, outputamp:0, numHSSpeeds:0, speeds:fltarr(10)}, 1)
			for adchannel = 0, numADChannels - 1 do begin
				for outputamp = 0, numAmps-1 do begin
					numHSSpeeds = 0
					if no_camera eq 0 then $
						res = [res, 'NumHSSpeeds: ' + get_error(call_external(dll, 'uGetNumberHSSpeeds', adchannel, outputamp, numHSSpeeds))] $
							else res = [res, '']
					speeds = fltarr(10)
					for hsindex = 0, numHSSpeeds - 1 do begin
						hsspeed = 0.0
						res = [res, 'GetHSSpeed: ' + get_error(call_external(dll, 'uGetHSSpeed', adchannel, outputamp, hsindex, hsspeed))]
						speeds[hsindex] = hsspeed
					endfor
					hsspeeds = [hsspeeds, {adchannel:adchannel, outputamp:outputamp, numHSSpeeds:numHSSpeeds, speeds:speeds}]
				endfor
			endfor
			if n_elements(hsspeeds) gt 1 then hsspeeds = hsspeeds[1:*] else hsspeeds = -1

			;\\ PREAMP GAINS
			numPreAmpGains = -1
			res = [res, 'NumPreAmpGains: ' + get_error(call_external(dll, 'uGetNumberPreAmpGains', numPreAmpGains))]
			if numPreAmpGains gt 0 then begin
				preAmpGains = fltarr(numPreAmpGains)
				for preAmpIndex = 0, numPreAmpGains - 1 do begin
					preAmpGain = 0.0
					if no_camera eq 0 then $
						res = [res, 'GetPreAmpGain: ' + get_error(call_external(dll, 'uGetPreAmpGain', preAmpIndex, preAmpGain))] $
							else res = [res, '']
					preAmpGains[preAmpIndex] = preAmpGain
				endfor
			endif else begin
				preAmpGains = -1
			endelse

			;\\ VERTICAL SHIFT SPEEDS
			numVSSpeeds = -1
			res = [res, 'GetNumVSSpeeds: ' + get_error(call_external(dll, 'uGetNumberVSSpeeds', numVSSpeeds))]
			if numVSSpeeds gt 0 then begin
				VSSpeeds = fltarr(numVSSpeeds)
				for vsIndex = 0, numVSSpeeds - 1 do begin
					vsspeed = 0.0
					if no_camera eq 0 then $
						res = [res, 'GetVSSpeeds: ' + get_error(call_external(dll, 'uGetVSSpeed', vsIndex, vsspeed))] $
							else res = [res, '']
					VSSpeeds[vsIndex] = vsspeed
				endfor
			endif else begin
				VSSpeeds = -1
			endelse

			;\\ VERTICAL SHIFT AMPLITUDES
			numVSAmplitudes = -1
			res = 'NumVSAmplitudes: ' + get_error(call_external(dll, 'uGetNumberVSAmplitudes', numVSAmplitudes))

			;\\ FASTEST RECOMMENDED VS SPEED
			recommendedVSIndex = -1
			recommendedVSSpeed = 0.0
			res = [res, 'GetRecommendedVSSpeed: ' + get_error(call_external(dll, 'uGetFastestRecommendedVSSpeed', $
								recommendedVSIndex, recommendedVSSpeed))]

			;\\ MAXIMUM EXPOSURE TIME
			maxExpTime = 0.0
			res = [res, 'GetMaxExpTime: ' + get_error(call_external(dll, 'uGetMaximumExposure', maxExpTime))]

			;\\ GET THE TEMPERATURE RANGE
			min_temp = 0
			max_temp = 0
			res = [res, 'GetTempRange: ' + get_error(call_external(dll, 'uGetTemperatureRange', min_temp, max_temp))]
			tempRange = [min_temp, max_temp]

			;\\ GET DETECTOR PIXELS, X AND Y
			xpix = 0
			ypix = 0
			res = [res, 'GetPixels: ' + get_error(call_external(dll, 'uGetDetector', xpix, ypix))]
			pixels = [xpix, ypix]

			;\\ GET CIRCULAR BUFFER SIZE
			buffsize = 0L
			res = [res, 'GetBufferSize: ' + get_error(call_external(dll, 'uGetSizeOfCircularBuffer', buffsize))]

			;\\ GET SOFTWARE VERSIONS
			v0 = 0 & v1 = 0 & v2 = 0 & v3 = 0 & v4 = 0 & v5 = 0
			res = [res, 'SoftwareVersion: ' + get_error(call_external(dll, 'uGetSoftwareVersion', $
							v0, v1, v2, v3, v4, v5))]
			softwareVersion = [v0,v1,v2,v3,v4,v5]

			;\\ GET HEAD MODEL
			head = " "
			for j = 0, 20 do head += "?"
			res = [res, 'HeadModel: ' + get_error(call_external(dll, 'uGetHeadModel', head))]
			split = strsplit(head, '?', /extract)
			headmodel = ''
			for nn = 0, n_elements(split) - 1 do headmodel += split[nn]


			;\\ GET SERIAL NUMBER
			serno = 0
			res = [res, 'SerialNum: ' + get_error(call_external(dll, 'uGetCameraSerialNumber', serno))]
			serialno = serno

			result = res

			out = {numADChannels:numADChannels, $
				   bitDepths:bitDepths, $
				   maxExposureTime:maxExpTime, $
				   amps:amps, $
				   preAmpGains:preAmpGains, $
				   HSSpeeds:HSSpeeds, $
				   VSSpeeds:VSSpeeds, $
				   VSRecommended:{index:recommendedVSIndex, speed:recommendedVSSpeed}, $
				   numVSAmplitudes:numVSAmplitudes, $
				   tempRange:tempRange, $
				   pixels:pixels, $
				   buffer_size:buffsize, $
				   softwareVersion:softwareVersion, $
				   headmodel:headmodel, $
				   serialno:serialno}
		end

		;\\ Return a structure which could hold useful settings for this camera
		strlowcase('uGetSettingsStructure'): begin
			imageMode = {xbin:0, ybin:0, xPixStart:0, xPixStop:0, yPixStart:0, yPixStop:0}

			settings = {imageMode:imageMode, $
						acqMode:0, $
						acqMode_str:'', $
						readMode:0, $
						readMode_str:'', $
						triggerMode:0, $
						triggerMode_str:'', $
						baselineClamp:0, $
						frameTransfer:0, $
						fanMode:0, $
						coolerOn:0, $
						shutterOpen:0, $
						setTemp:0L, $
						curTemp:0.0, $
						adChannel:0, $
						bitDepth:0, $
						outAmp:0, $
						preAmpGaini:0, $
						preAmpGain:0.0, $
						expTime_set:0.0, $
						expTime_use:0.0, $
						cnvgain_set:0, $
						emgain_set:0, $
						emgain_use:0, $
						emgain_mode:0, $
						emadvanced:0, $
						vsspeedi:0, $
						vsspeed:0.0, $
						vsamplitude:0, $
						hsspeedi:0, $
						hsspeed:0.0, $
						pixels:intarr(2), $
						datatype:'counts', $
						initialized:0}

			out = settings
		end


		;\\ Given in={settings:{}, capabilities:{}}, return a default settings struc which should work
		strlowcase('uSetDefaults'): begin

			settings = in.settings
			settings.imagemode = {xbin:1, ybin:1, $
								  xpixstart:1, xpixstop:in.capabilities.pixels[0], $
								  ypixstart:1, ypixstop:in.capabilities.pixels[1] }
			settings.acqmode = 5
			settings.readmode = 4
			settings.triggermode = 0
			settings.baselineclamp = 1
			settings.frametransfer = 1
			settings.fanmode = 0
			settings.cooleron = 1
			settings.settemp = -40
			settings.adchannel = 0
			settings.bitdepth = 0
			settings.outamp = 0
			settings.preampgaini = 0
			settings.exptime_set = 0.1
			settings.emgain_set = 2
			settings.emgain_mode = 0
			settings.emadvanced = 0
			settings.vsspeedi = in.capabilities.VSRecommended.index
			settings.vsamplitude = 0
			settings.hsspeedi = 1

			out = settings
		end


		;\\ Set up the acquisition using a settings structure defined above
		;\\ in = settings_structure
		strlowcase('uApplySettingsStructure'): begin

      		res = call_external(dll, 'uAbortAcquisition')
      		res = call_external(dll, 'uFreeInternalMemory')

			Andor_Camera_Driver, dll, 'uSetReadMode', in.readMode, thisout, res
			result = 'uSetReadMode: '+ string(in.readMode, f='(i0)') + ' - '+res
			out = thisout

			Andor_Camera_Driver, dll, 'uSetAcquisitionMode', in.acqMode, thisout, res
			result = [result, 'uSetAcquisitionMode: '+ string(in.acqMode, f='(i0)') + ' - ' + res]
			out = [out, thisout]

			Andor_Camera_Driver, dll, 'uSetExposureTime', in.expTime_set, thisout, res
			result = [result, 'uSetExposureTime: '+ string(in.expTime_set, f='(f0.4)') + ' - '+res]
			out = [out, thisout]

			Andor_Camera_Driver, dll, 'uSetOutputAmplifier', in.outAmp, thisout, res
		  	result = [result, 'uSetOutputAmplifier: '+ string(in.outAmp, f='(i0)') + ' - '+res]
		  	out = [out, thisout]

		  	Andor_Camera_Driver, dll, 'uSetADChannel', in.adChannel, thisout, res
      		result = [result, 'uSetADChannel: '+ string(in.adChannel, f='(i0)') + ' - '+res]
      		out = [out, thisout]

			Andor_Camera_Driver, dll, 'uSetEMCCDGain', in.emGain_set, thisout, res
			result = [result, 'uSetEMCCDGain: ' + string(in.emgain_set, f='(i0)') + ' - ' + res]
			out = [out, thisout]

			Andor_Camera_Driver, dll, 'uSetHSSpeed', {index:in.hsspeedi, outamp:in.outamp}, thisout, res
      		result = [result, 'uSetHSSpeed(index): ' + string(in.hsspeedi, f='(i0)') + ' - ' + res]
      		out = [out, thisout]

			Andor_Camera_Driver, dll, 'uSetVSSpeed', in.vsspeedi, thisout, res
			result = [result, 'uSetVSSpeed(index): '+ string(in.vsspeedi, f='(i0)') + ' - '+res]
			out = [out, thisout]

			Andor_Camera_Driver, dll, 'uSetVSAmplitude', in.vsamplitude, thisout, res
			result = [result, 'uSetVSAmplitude: '+ string(in.vsamplitude, f='(i0)') + ' - '+res]
			out = [out, thisout]

      		Andor_Camera_Driver, dll, 'uSetPreAmpGain', 1, thisout, res ;\\ This is a hack, sometimes need to toggle the preamp
            	                                                        ;\\ or camera images will be blank.
			Andor_Camera_Driver, dll, 'uSetPreAmpGain', in.preAmpGaini, thisout, res
			result = [result, 'uSetPreAmpGain(index): '+ string(in.preAmpGaini, f='(i0)') + ' - '+res]
			out = [out, thisout]

			Andor_Camera_Driver, dll, 'uSetTriggerMode', in.triggerMode, thisout, res
			result = [result, 'uSetTriggerMode: '+ string(in.triggerMode, f='(i0)') + ' - '+res]
			out = [out, thisout]

			Andor_Camera_Driver, dll, 'uSetFrameTransferMode', in.frameTransfer, thisout, res
			result = [result, 'uSetFrameTransferMode: '+ string(in.frameTransfer, f='(i0)') + ' - '+res]
			out = [out, thisout]

			Andor_Camera_Driver, dll, 'uSetBaselineClamp', in.baselineClamp, thisout, res
			result = [result, 'uSetBaselineClamp: '+ string(in.baselineClamp, f='(i0)') + ' - '+res]
			out = [out, thisout]


		    Andor_Camera_Driver, dll, 'uSetTemperature', in.settemp, thisout, res
		    result = [result, 'uSetTemperature: '+ string(in.settemp, f='(i0)') + ' - '+res]
		    out = [out, thisout]

		    if in.coolerOn eq 1 then begin
		      	Andor_Camera_Driver, dll, 'uCoolerOn', 0, thisout, res
		      	result = [result, 'uCoolerOn: ' + res]
		      	out = [out, thisout]
		    endif else begin
		      	Andor_Camera_Driver, dll, 'uCoolerOff', 0, thisout, res
		      	result = [result, 'uCoolerOff: ' + res]
		      	out = [out, thisout]
		    endelse

		  	imSet = in.imageMode
      		Andor_Camera_Driver, dll, 'uSetImage', $
          		[imSet.(0),imSet.(1),imSet.(2),imSet.(3),imSet.(4),imSet.(5)], thisout, res
      			result = [result, 'uSetImage: ' + string([imSet.(0),imSet.(1),imSet.(2),$
        		imSet.(3),imSet.(4),imSet.(5)], f='(i0,",",i0,",",i0,",",i0,",",i0,",",i0)') + ': ' + res]
      		out = [out, thisout]

			res = call_external(dll, 'uStartAcquisition')

		end

		else: begin
			result = 'Unknown Command'
		end

	endcase

	if keyword_set(auto_acq) then begin
		;\\ Restart the acquisition if required
			if need_acq_restart eq 1 then begin
				result = get_error(call_external(dll, 'uFreeInternalMemory'))
				result = get_error(call_external(dll, 'uStartAcquisition'))
			endif
	endif

	if keyword_set(unload) then begin
		status = 0
		res = call_external(dll, 'uGetStatus', status, /unload)
	endif

end