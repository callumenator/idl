

;\\ Use this version for loading a group of camera settings, i.e. during initialization
pro ASC_LoadCameraSettings, camera_dll, $
							settings_script = settings_script, $
							exposureTime = exposureTime, $
							emgGainMode = emGainMode, $
							emGain = emGain, $
							readMode = readMode, $
							acqMode = acqMode, $
							baselineClamp = baselineClamp, $
							frameTransfer = frameTransfer, $
							coolerOn = coolerOn, $
							coolerSetTemp = coolerSetTemp, $
							xBin= xBin, $
							yBin = yBin, $
							xPixStart = xPixStart, $
							xPixStop = xPixStop, $
							yPixStart = yPixStart, $
							yPixStop = yPixStop, $
							loaded_settings = loaded_settings, $
							debug_outs = debug_outs, $
							debug_ress = debug_ress

	;\\ Query capabilities.
		Andor_Camera_Driver, camera_dll, 'uGetCapabilities', in, caps, result
		Andor_Camera_Driver, camera_dll, 'uGetSettingsStructure', 0, settings, result

	;\\ Here we set some default, mostly sensible, values
		settings.expTime_set = 0.1
		settings.emgain_set = 2
		settings.emgain_mode = 0
		settings.readMode = 4
		settings.acqMode = 1
		settings.baselineClamp = 1
		settings.frameTransfer = 1
		settings.coolerOn = 0
		settings.setTemp = 0
		settings.hsspeedi = 0
		settings.vsspeedi = caps.vsrecommended.index
		settings.imageMode = {xbin:1, ybin:1, xPixStart:1, xPixStop:caps.pixels[0], yPixStart:1, yPixStop:caps.pixels[1]}


	;\\ If a settings script has been supplied, use that to fill up settings first
		if keyword_set(settings_script) then call_procedure, settings_script, settings = settings

	;\\ Now apply any keyword supplied values
		if keyword_set(exposureTime) then settings.expTime_set = exposureTime
		if keyword_set(emGainMode) then settings.emgain_mode = emGainMode
		if keyword_set(emGain) then settings.emgain_set = emGain
		if keyword_set(readMode) then settings.readMode = readMode
		if keyword_set(acqMode) then settings.acqMode = acqMode
		if keyword_set(baselineClamp) then settings.baselineClamp = baselineClamp
		if keyword_set(frameTransfer) then settings.frameTransfer = frameTransfer
		if size(coolerOn, /type) ne 0 then settings.coolerOn = coolerOn
		if keyword_set(coolerSetTemp) then settings.setTemp = coolerSetTemp
		if keyword_set(xBin) then settings.imageMode.xBin = xBin
		if keyword_set(yBin) then settings.imageMode.yBin = yBin
		if keyword_set(xPixStart) then settings.imageMode.xPixStart = xPixStart
		if keyword_set(xPixStop) then settings.imageMode.xPixStop = xPixStop
		if keyword_set(yPixStart) then settings.imageMode.yPixStart = yPixStart
		if keyword_set(yPixStop) then settings.imageMode.yPixStop = yPixStop

	;\\ Upload the settings to the camera
		Andor_Camera_Driver, camera_dll, 'uApplySettingsStructure', settings, outs, ress
		loaded_settings = settings
		debug_outs = outs
		debug_ress = ress
end