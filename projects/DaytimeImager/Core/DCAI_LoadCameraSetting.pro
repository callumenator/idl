
;\\ Some settings need to be read back from the camera, or strings need
;\\ to be looked-up. Do that here.
pro DCAI_LoadCameraSetting_Readback, exposureTime = exposureTime, $
									 emGain = emGain, $
									 vsSpeed = vsSpeed, $
									 hsSpeed = hsSpeed, $
									 readMode = readMode, $
									 acqMode = acqMode, $
									 triggerMode = triggerMode

	COMMON DCAI_Control, dcai_global

	if keyword_set(exposureTime) then begin
		;\\ Get the actual exp time used
			andor_camera_driver, dcai_global.settings.external_dll, 'uGetAcquisitionTimings', 0, out, /auto_acq
			dcai_global.info.camera_settings.exptime_use = out.exposure
	endif

	if keyword_set(emGain) then begin
		;\\ Get the actual gain used by the camera
			andor_camera_driver, dcai_global.settings.external_dll, 'uGetEMCCDGain', 0, emgain, res, /auto_acq
			dcai_global.info.camera_settings.emgain_use = emgain
	endif

	if keyword_set(triggerMode) then begin
		trig_modes = ['Internal', 'External', 'External Start']
		if dcai_global.info.camera_settings.triggermode ge 0 and $
		   dcai_global.info.camera_settings.triggermode lt n_elements(trig_modes) then begin
			dcai_global.info.camera_settings.triggermode_str = trig_modes[dcai_global.info.camera_settings.triggermode]
		endif else begin
			dcai_global.info.camera_settings.triggermode_str = 'Error'
		endelse
	endif

	if keyword_set(acqMode) then begin
		acq_modes = ['Single Scan', 'Accumulate', 'Kinetics', $
                 'Fast Kinetics', 'Run till abort', 'Time Delayed Integration']
		if dcai_global.info.camera_settings.acqmode ge 0 and $
		   dcai_global.info.camera_settings.acqmode lt n_elements(acq_modes) then begin
			dcai_global.info.camera_settings.acqmode_str = acq_modes[dcai_global.info.camera_settings.acqmode]
		endif else begin
			dcai_global.info.camera_settings.acqmode_str = 'Error'
		endelse
	endif

	if keyword_set(readMode) then begin
		read_modes = ['Full Vertical Binning', 'Multi-Track', $
					  'Random-Track', 'Single-Track', 'Image']
		if dcai_global.info.camera_settings.readmode ge 0 and $
		   dcai_global.info.camera_settings.readmode lt n_elements(read_modes) then begin
			dcai_global.info.camera_settings.readmode_str = read_modes[dcai_global.info.camera_settings.readmode]
		endif else begin
			dcai_global.info.camera_settings.readmode_str = 'Error'
		endelse
	endif

	if keyword_set(vsSpeed) then begin
		vsspeedi = dcai_global.info.camera_settings.vsspeedi < (n_elements((*dcai_global.info.camera_caps).vsspeeds) - 1)
		vsspeedi = vsspeedi > 0
		vshift = (*dcai_global.info.camera_caps).vsspeeds[vsspeedi]
		dcai_global.info.camera_settings.vsspeed = vshift
	endif

	if keyword_set(hsSpeed) then begin
		;\\ Get the actual shift speed
			andor_camera_driver, dcai_global.settings.external_dll, 'uGetHSSpeed', $
						 {adchannel:dcai_global.info.camera_settings.adchannel, $
						  outputamp:dcai_global.info.camera_settings.outamp, $
						  hsindex:dcai_global.info.camera_settings.hsspeedi}, $
						 hshift, res, /auto_acq

			dcai_global.info.camera_settings.hsspeed = hshift
	endif
end


;\\ Helper function for setting individual camera settings, for example
;\\ after camera has been initialized and DCAI_LoadCameraSettings used to
;\\ upload a large group of settings, this function can be used to set
;\\ exposure time or gain without affecting other camrea settings.
pro DCAI_LoadCameraSetting, camera_dll, $
							exposureTime = exposureTime, $
							emgGainMode = emGainMode, $
							emGain = emGain, $
							readMode = readMode, $
							acqMode = acqMode, $
							outputAmplifier = outputAmplifier, $
							adChannel = adChannel, $
							preAmpGainIndex = preAmpGainIndex, $
							triggerMode = triggerMode, $
							baselineClamp = baselineClamp, $
							frameTransfer = frameTransfer, $
							coolerOn = coolerOn, $
							coolerSetTemp = coolerSetTemp, $
							imageMode = imageMode, $ ;\\\ {xbin:0, ybin:0, xPixStart:0, xPixStop:0, yPixStart:0, yPixStop:0}
							vsSpeedIndex = vsSpeedIndex, $
							hsSpeedIndex = hsSpeedIndex, $
							settings_script = settings_script, $ ;\\ Load settings from a camera profile
							debug_ress = debug_ress

  COMMON DCAI_Control, dcai_global

	_res = ''

	;\\ Call the driver for the appropriate setting

		if keyword_set(readMode) then begin
			Andor_Camera_Driver, camera_dll, 'uSetReadMode', readMode, out, result, /auto_acq
			dcai_global.info.camera_settings.readmode = readMode
			_res = [_res, result]

			DCAI_LoadCameraSetting_Readback, /readMode
		endif

		if keyword_set(acqMode) then begin
			Andor_Camera_Driver, camera_dll, 'uSetAcquisitionMode', acqMode, out, result, /auto_acq
			dcai_global.info.camera_settings.acqmode = acqMode
			_res = [_res, result]

			DCAI_LoadCameraSetting_Readback, /acqMode
		endif

		if keyword_set(triggerMode) then begin
			Andor_Camera_Driver, camera_dll, 'uSetTriggerMode', triggerMode, out, result, /auto_acq
			dcai_global.info.camera_settings.triggerMode = triggerMode
			_res = [_res, result]

			DCAI_LoadCameraSetting_Readback, /triggerMode
		endif

    if size(outputAmplifier, /type) ne 0 then begin
      Andor_Camera_Driver, camera_dll, 'uSetOutputAmplifier', outputAmplifier, out, result, /auto_acq
      dcai_global.info.camera_settings.outamp = outputAMplifier
      _res = [_res, result]
    endif

    if size(adChannel, /type) ne 0 then begin
      Andor_Camera_Driver, camera_dll, 'uSetADChannel', adChannel, out, result, /auto_acq
      dcai_global.info.camera_settings.adChannel = adChannel
      _res = [_res, result]
    endif

    if size(preAmpGainIndex, /type) ne 0 then begin
      Andor_Camera_Driver, camera_dll, 'uSetPreAmpGain', preAmpGainIndex, out, result, /auto_acq
      dcai_global.info.camera_settings.preAmgGaini = preAmpGainIndex
      _res = [_res, result]
    endif

		if keyword_set(exposureTime) then begin
			Andor_Camera_Driver, camera_dll, 'uSetExposureTime', exposureTime, out, result, /auto_acq
			dcai_global.info.camera_settings.exptime_set = exposureTime
			_res = [_res, result]

			DCAI_LoadCameraSetting_Readback, /exposureTime
		endif

		if size(emGainMode, /type) ne 0 then begin
			Andor_Camera_Driver, camera_dll, 'uSetEMGainMode', emGainMode, out, result, /auto_acq
			dcai_global.info.camera_settings.emgain_mode = emGainMode
			_res = [_res, result]
		endif

		if size(emGain, /type) ne 0 then begin
			Andor_Camera_Driver, camera_dll, 'uSetEMCCDGain', emGain, out, result, /auto_acq
			dcai_global.info.camera_settings.emgain_set = emGain
			_res = [_res, result]

			DCAI_LoadCameraSetting_Readback, /emGain
		endif

		if size(baselineClamp, /type) ne 0 then begin
			Andor_Camera_Driver, camera_dll, 'uSetBaselineClamp', baselineClamp, out, result, /auto_acq
			dcai_global.info.camera_settings.baselineClamp = baselineClamp
			_res = [_res, result]
		endif

		if size(frameTransfer, /type) ne 0 then begin
			Andor_Camera_Driver, camera_dll, 'uSetFrameTransferMode', frameTransfer, out, result, /auto_acq
			dcai_global.info.camera_settings.frameTransfer = frameTransfer
			_res = [_res, result]
		endif

		if keyword_set(coolerSetTemp) then begin
			Andor_Camera_Driver, camera_dll, 'uSetTemperature', coolerSetTemp, out, result, /auto_acq
			dcai_global.info.camera_settings.setTemp = coolerSetTemp
			_res = [_res, result]
		endif

		if size(coolerOn, /type) ne 0 then begin
			if (coolerOn eq 0) then begin
				Andor_Camera_Driver, camera_dll, 'uCoolerOff', 0, out, result, /auto_acq
			endif else begin
				Andor_Camera_Driver, camera_dll, 'uCoolerOn', 0, out, result, /auto_acq
			endelse
			dcai_global.info.camera_settings.coolerOn = coolerOn
			_res = [_res, result]
		endif

		if keyword_set(imageMode) then begin
			Andor_Camera_Driver, camera_dll, 'uSetImage', $
			 [imageMode.xbin, imageMode.ybin, imageMode.xpixstart, imageMode.xpixstop, $
			  imageMode.ypixstart, imageMode.ypixstop], out, result, /auto_acq
			  dcai_global.info.camera_settings.imageMode = imageMode
			_res = [_res, result]
		endif

		if size(vsSpeedindex, /type) ne 0 then begin
			Andor_Camera_Driver, camera_dll, 'uSetVSSpeed', vsSpeedIndex, out, result, /auto_acq
			dcai_global.info.camera_settings.vsspeedi = vsSpeedIndex
			_res = [_res, result]

			DCAI_LoadCameraSetting_Readback, /vsSpeed
		endif

		if size(hsSpeedindex, /type) ne 0 then begin
			Andor_Camera_Driver, camera_dll, 'uSetHSSpeed', $
				{outamp:info.camera_settings.outamp, index:hsSpeedIndex}, out, result, /auto_acq
			dcai_global.info.camera_settings.hsspeedi = hsSpeedIndex
			_res = [_res, result]

			DCAI_LoadCameraSetting_Readback, /hsSpeed
		endif

		;\\ If a script is supplied, use that to update the camera settings
		if keyword_set(settings_script) then begin

			cam_settings = dcai_global.info.camera_settings
		 	call_procedure, settings_script, settings = cam_settings

			;\\ Upload the settings to the camera
				Andor_Camera_Driver, camera_dll, 'uApplySettingsStructure', cam_settings, outs, result, /auto_acq
				dcai_global.info.camera_settings = cam_settings
				_res = [_res, result]

			;\\ Update any values that may need to be read back from the camera
				DCAI_LoadCameraSetting_Readback, /hsSpeed, /vsSpeed, /exposureTime, $
												 /readMode, /acqMode, /triggerMode, $
												 /emGain
		endif

		debug_ress = _res

end