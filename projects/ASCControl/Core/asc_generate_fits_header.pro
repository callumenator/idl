
@asc_script_utilities

function asc_generate_fits_header, filename, start_date, start_time, exposure_time

	COMMON ASC_Control, info, gui, log

	cs = info.camera_settings
	cp = *info.camera_caps

	;\\ Convert serial number to a string -  ## ask Don about this
		serno = string(cp.serialno, f='(i0)')

	;\\ Create a string describing the image rectangle
		imrect = string(cs.imagemode.xPixStart, f='(i0)') + ',' + $
				 string(cs.imagemode.xPixStop,  f='(i0)') + ',' + $
				 string(cs.imagemode.yPixStart, f='(i0)') + ',' + $
				 string(cs.imagemode.yPixStop,  f='(i0)')

		ixpix = cs.imagemode.xPixStop - cs.imagemode.xPixStart
		iypix = cs.imagemode.yPixStop - cs.imagemode.yPixStart
		image_x = long( (ixpix + 1L) / (cs.imagemode.xbin) )
		image_y = long( (iypix + 1L) / (cs.imagemode.ybin) )

	;\\ Get the current temperature
		andor_camera_driver, info.external_dll, 'uGetTemperatureF', 0, ccd_temp, res, /auto_acq

	;\\ Get the filter name
		if info.comms.filter.current lt 0 or $
		   info.comms.filter.current gt n_elements(info.comms.filter.lookup) then begin
			filter_string = 'Error'
		endif else begin
			filter_string = strmid(info.comms.filter.lookup[info.comms.filter.current], 0, 4)
		endelse

		filtcom = info.comms.filter.selected
		filtdet = info.comms.filter.current


	sxaddpar, h, 'SITE', 		info.site_info.name, 	'Site name'
	sxaddpar, h, 'GLAT', 		info.site_info.geo_lat, 'Geographic latitude, degrees'
	sxaddpar, h, 'GLON', 		info.site_info.geo_lon, 'Geographic longitude, degrees'
	sxaddpar, h, 'OBSDATE', 	start_date,				'UT Date on which exposure was initiated'
	sxaddpar, h, 'OBSSTART', 	start_time,				'UT Time at which exposure was initiated'
	sxaddpar, h, 'EXPTIME', 	cs.exptime_use,			'seconds'
	sxaddpar, h, 'HEAD',	 	cp.headmodel,			'Detector head model'
	sxaddpar, h, 'ACQMODE', 	cs.acqmode_str,			'Acquisition mode'
	sxaddpar, h, 'READMODE', 	cs.readmode_str,		'Readout mode'
	sxaddpar, h, 'TRIGGER', 	cs.triggermode_str,		'Trigger mode'
	sxaddpar, h, 'SERNO', 		serno,					'Serial number'
	sxaddpar, h, 'DATATYPE', 	cs.datatype,			'Data type'
	sxaddpar, h, 'DETSIZEX', 	cp.pixels[0],			'# of pixels in the X direction for the detector'
	sxaddpar, h, 'DETSIZEY', 	cp.pixels[1],			'# of pixels in the Y direction for the detector'
	sxaddpar, h, 'IMSIZEX', 	image_x,				'# of pixels in the X direction for the image'
	sxaddpar, h, 'IMSIZEY', 	image_y,				'# of pixels in the Y direction for the image'
	sxaddpar, h, 'IMBINX', 		cs.imagemode.xbin,		'Binning factor in the X direction'
	sxaddpar, h, 'IMBINY', 		cs.imagemode.ybin,		'Binning factor in the Y direction'
	sxaddpar, h, 'IMRECT', 		imrect,					'Image rectangle; xmin,xmax,ymin,ymax'
	sxaddpar, h, 'VSHIFT', 		cs.vsspeed,				'microseconds per pixel shift'
	sxaddpar, h, 'VCLK', 		cs.vsamplitude,			'V'
	sxaddpar, h, 'HSHIFT', 		cs.hsspeed,				'MHz'
	sxaddpar, h, 'PAGAIN', 		cp.preampgains[cs.preampgaini],	'Pre-amplifier gain'
	sxaddpar, h, 'OUTAMP',	 	cp.amps[cs.outamp].description,	'Gain mode'
	sxaddpar, h, 'EMGAIN', 		cs.emgain_use,			'EM Gain'
	sxaddpar, h, 'FILTCOM', 	filtcom,				'Commanded filter position'
	sxaddpar, h, 'FILTDET', 	filtdet,				'Detected filter position'
	sxaddpar, h, 'FILTWAV', 	filter_string,			'nm'
	sxaddpar, h, 'CCDTEMP', 	ccd_temp,				'degrees celcius'
	sxaddpar, h, 'CCDTCOM', 	cs.settemp,				'degrees celcius'
	sxaddpar, h, 'FWTEMP', 		0,						'degrees celcius'
	sxaddpar, h, 'FWTCOM', 		0,						'degrees celcius'
	sxaddpar, h, 'FNAME', 		file_basename(filename),'Original filename'

	return, h

end
