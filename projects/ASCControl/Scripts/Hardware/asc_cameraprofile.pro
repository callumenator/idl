

pro asc_cameraprofile, settings = settings

	settings.imagemode = {xbin:2, ybin:2, xpixstart:1, xpixstop:1024, ypixstart:1, ypixstop:1024}
	settings.acqmode = 1
	settings.acqmode_str = ""
	settings.readmode = 4
	settings.readmode_str = ""
	settings.triggermode = 0
	settings.triggermode_str = ""
	settings.baselineclamp = 0
	settings.frametransfer = 0
	settings.fanmode = 0
	settings.cooleron = 1
	settings.shutteropen = 0
	settings.settemp = -40
	settings.curtemp = 0.0000000000
	settings.adchannel = 0
	settings.bitdepth = 0
	settings.outamp = 0
	settings.preampgaini = 1
	settings.preampgain = 0.0000000000
	settings.exptime_set = 0.0099999998
	settings.exptime_use = 1.0000000000
	settings.cnvgain_set = 0
	settings.emgain_set = 2
	settings.emgain_use = 7
	settings.emgain_mode = 0
	settings.emadvanced = 0
	settings.vsspeedi = 1
	settings.vsspeed = 0.0000000000
	settings.vsamplitude = 0
	settings.hsspeedi = 0
	settings.hsspeed = 10.0000000000
	settings.pixels = [0, 0]
	settings.datatype = "counts"
	settings.initialized = 0

end
