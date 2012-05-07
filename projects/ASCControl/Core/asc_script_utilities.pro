
;\\ Various utilities for the ASC scripts


;\\ This function is used internally by the scipt utilities, it allows us to control
;\\ the time value that is returned, mostly for testing scripts/debugging.
function _systime, sec = sec, ut=ut, julian=julian

	COMMON ASC_Control, info, gui, log

	if (size(info, /type) eq 0) then begin
	 	return, systime(sec=sec, ut=ut, julian=julian)
	endif else begin
		if info.debug.running eq 1 then begin
			if keyword_set(ut) then begin
				return, info.debug.time_string_ut
			endif else begin
				return, info.debug.time_string
			endelse
		endif else begin
			return, systime(sec=sec, ut=ut, julian=julian)
		endelse
	endelse

end

;\\ Return the solar zenith angle as a decimal
function SolarZenithAngle, info

	time = bin_date(_systime(/ut))
	jd = js2jd(dt_tm_tojs(_systime()))
	ut_fraction = (time(3)*3600. + time(4)*60. + time(5)) / 86400.
	sidereal_time = lmst(jd, ut_fraction, 0) * 24.
	sunpos, jd, RA, Dec
	sun_lat = Dec
	sun_lon = RA - (15. * sidereal_time)
	ll2rb, info.site_info.geo_lon, info.site_info.geo_lat, sun_lon, sun_lat, range, azimuth
	sun_elevation = refract(90 - (range * !radeg))
	return, sun_elevation

end

;\\ Return the solar zenith angle as a string
function SolarZenithAngleStr, info
	return, string( SolarZenithAngle(info), f='(f0.3)' )
end

;\\ Return the UT decimal hour
function HourUt
	time = float(strsplit( dt_tm_fromjs(dt_tm_tojs(_systime(/ut)), format='h$ m$ s$'), ' ', /extract))
	return, time[0] + time[1]/60. + time[2]/3600.
end

;\\ Return the UT hour string (HH:MM:SS)
function HourUtHHMMSS
	return, dt_tm_fromjs(dt_tm_tojs(_systime(/ut)), format='h$:m$:s$')
end

;\\ Return the UT hour string (HH:MM:SS.SSS)
function HourUtHHMMSS_SSS
  t1 = dt_tm_fromjs(dt_tm_tojs(_systime(/ut)), format='h$:m$:s$')
  sec = string( (_systime(/sec) mod 1) * 1000, f='(i03)')
  return, t1+'.'+sec
end

;\\ Return the UT hour string as an array of strings (HH, MM, SS, .SSS)
function HourUtHHMMSS_SSS_Array
  t1 = strsplit(dt_tm_fromjs(dt_tm_tojs(_systime(/ut)), format='h$|m$|s$'), '|', /extract)
  sec = string( (_systime(/sec) mod 1) * 1000, f='(i03)')
  return, [t1, sec]
end

;\\ Return the decimal hour
function Hour
	time = float(strsplit( dt_tm_fromjs(dt_tm_tojs(_systime()), format='h$ m$ s$'), ' ', /extract))
	return, time[0] + time[1]/60. + time[2]/3600.
end

;\\ Return the current seconds
function Seconds
	secs = float(strsplit( dt_tm_fromjs(dt_tm_tojs(_systime()), format='s$'), ' ', /extract))
	return, secs
end

;\\ Return the local solar time as decimal hour
function SolarHour, info
	time = float(strsplit( dt_tm_fromjs(dt_tm_tojs(_systime(/ut)), format='h$ m$ s$'), ' ', /extract))
	utHour = time[0] + time[1]/60. + time[2]/3600.
	return, utHour + info.site_info.geo_lon/15. mod 24
end

;\\ Return the day of week as a 3 character lowercase string
function DayOfWeek
	return, strlowcase( dt_tm_fromjs(dt_tm_tojs(_systime()), format='w$') )
end

;\\ Return the UT day of week as a 3 character lowercase string
function DayOfWeekUT
	return, strlowcase( dt_tm_fromjs(dt_tm_tojs(_systime(/ut)), format='w$') )
end

;\\ Return the day of year as a 3 letter string
function DayOfYearStr
	return, ( dt_tm_fromjs(dt_tm_tojs(_systime()), format='doy$') )
end

;\\ Return the UT day of year as a 3 letter string
function DayOfYearStrUT
	return, ( dt_tm_fromjs(dt_tm_tojs(_systime(/ut)), format='doy$') )
end

;\\ Return the day of year as a number
function DayOfYear
	return, fix( dt_tm_fromjs(dt_tm_tojs(_systime()), format='doy$') )
end

;\\ Return the UT day of year as a number
function DayOfYearUT
	return, fix( dt_tm_fromjs(dt_tm_tojs(_systime(/ut)), format='doy$') )
end

;\\ Return the month as a number
function Month
	return, fix( dt_tm_fromjs(dt_tm_tojs(_systime()), format='0n$') )
end

;\\ Return the UT month as a number
function MonthUT
	return, fix( dt_tm_fromjs(dt_tm_tojs(_systime(/ut)), format='0n$') )
end

;\\ Return the month as a 3 letter name
function MonthName
	return, ( dt_tm_fromjs(dt_tm_tojs(_systime()), format='n$') )
end

;\\ Return the UT month as a 3 letter name
function MonthNameUT
	return, ( dt_tm_fromjs(dt_tm_tojs(_systime(/ut)), format='n$') )
end

;\\ Return the UT date as YYYY-MM-DD string
function DateStringUT_YYYYMMDD
	return, ( dt_tm_fromjs(dt_tm_tojs(_systime(/ut)), format='Y$-0n$-0d$') )
end

;\\ Return the UT date as YYYY-MM-DD string
function DateStringUT_YYYYMMDD_Nosep
  return, ( dt_tm_fromjs(dt_tm_tojs(_systime(/ut)), format='Y$0n$0d$') )
end

;\\ Return the UT date as YYYY-MM-DD string
function DateString_NextUTDay_YYYYMMDD_Nosep
  return, ( dt_tm_fromjs(dt_tm_tojs(_systime(/ut)) + 24.*3600., format='Y$0n$0d$') )
end

;\\ Return the UT date as a string array (YYYY, MM, DD)
function DateStringUT_YYYYMMDD_Array
  return, strsplit( ( dt_tm_fromjs(dt_tm_tojs(_systime(/ut)), format='Y$|0n$|0d$') ), '|', /extract)
end

;\\ Return 1 if the given variable is defined, else 0
function IsDefined, variable
  if size(variable, /type) eq 0 then return, 0 else return, 1
end

;\\ Get the camera temperature as a float
function CameraTemperature, info
  Andor_Camera_Driver, info.external_dll, 'uGetTemperatureF', 0, ccd_temp, res, /auto_acq
  return, ccd_temp
end

;\\ Get the free space (in Mb by default, use keyword for Gb) in the given path
function FreeDiskSpace, path, gb=gb
  spawn, 'dir ' + path + ' | find "free"', res, err, /hide
  out = strsplit(res, ' ', /extract)  
  out = strsplit(out[2], ',', /extract)
  space = ''
  for j = 0, n_elements(out) - 1 do space += out[j]
  space = double(space) 
  space_mb = space / 1048576.
  space_gb = space / 1073741824.
  if keyword_set(gb) then return, space_gb else return, space_mb
end 

;\\ Select a filter. Filter is a number here.
pro SelectFilter, info, filter, errcode=errcode

	comms_wrapper, info.comms.filter.port, $
				   info.external_dll, $
				   type = 'com', $	;\\ Use standard windows comms
				   /write, $
				   data = 'g=' + string(filter, f='(i0)') + string(13B), $
				   errcode = errcode

	comms_wrapper, info.comms.filter.port, $
				   info.external_dll, $
				   type = 'com', $	;\\ Use standard windows comms
				   /write, $
				   data = 'GOSUB4' + string(13B), $
				   errcode = errcode

	;\\ Wait 3 seconds.
	wait, 2

	;\\ Read back the response
	comms_wrapper, info.comms.filter.port, $
				   info.external_dll, $
				   type = 'com', $	;\\ Use standard windows comms
				   /write, $
				   data = 'g=-1'  + string(13B), $
				   errcode = errcode

	comms_wrapper, info.comms.filter.port, $
				   info.external_dll, $
				   type = 'com', $
				   /write, $
				   data = 'GOSUB4' + string(13B), $
				   errcode = errcode

	comms_wrapper, info.comms.filter.port, $
				   info.external_dll, $
				   type = 'com', $
				   /read, $
				   data = read_back, $
				   errcode = errcode


	print, read_back
	help, read_back
	if (read_back ne '') then begin
	 	erc = strmid(read_back,5,1)
	 	if size(erc, /type) eq 0 then errcode = '-1' else errcode = erc
	endif else errcode = '-1'

end


;\\ Home the filter wheel. Docs say we shgould do this at the start of each night.
pro HomeFilterWheel, info, errcode=errcode

	errcode = ''
	ASC_Log, 'Homing Filter Wheel...please wait...'

  ;\\ Drive to a middle position
  SelectFilter, info, 4
  
	;\\ Run subroutine 5
	comms_wrapper, info.comms.filter.port, $
				   info.external_dll, $
				   type = 'com', $	;\\ Use standard windows comms
				   /write, $
				   data = 'GOSUB5' + string(13B), $
				   errcode = errcode

	;\\ Wait for the motor to return "HOME:1"
	wait, 5.
	homed = 0
  home_start = systime(/sec)
	while homed eq 0 do begin

		comms_wrapper, info.comms.filter.port, $
					   info.external_dll, $
					   type = 'com', $
					   /read, $
					   data = read_back, $
					   errcode = errcode
					   
		
		print, '|', strmid(read_back, 0, 6), '|'

		if strmid(read_back, 0, 6)  eq 'HOME:1' then begin
			homed = 1
			ASC_Log, 'Filter wheel homed'
		endif else begin
			print, 'Homing filter wheel... ' + read_back
			wait, .05
		endelse
		
		if systime(/sec) - home_start gt 20 then begin
		  ASC_Log, 'Been homing too long - breaking...'
      break
    endif

	endwhile

end


;\\ Control the shutter
pro SetShutter, info, position, errcode=errcode

	if position eq 'open' then shutter_str = 'd=1' else shutter_str = 'd=0'

	comms_wrapper, info.comms.filter.port, $
				   info.external_dll, $
				   type = 'com', $	;\\ Use standard windows comms
				   /write, $
				   data = shutter_str + string(13B), $
				   errcode = ec

	comms_wrapper, info.comms.filter.port, $
				   info.external_dll, $
           type = 'com', $	;\\ Use standard windows comms
				   /write, $
				   data = 'GOSUB1' + string(13B), $
				   errcode = ec

	;\\ Wait 3 seconds
	wait, 3.

	;\\ Read back the response
	comms_wrapper, info.comms.filter.port, $
				   info.external_dll, $
				   type = 'com', $	;\\ Use standard windows comms
				   /write, $
				   data = 'd=-1'  + string(13B), $
				   errcode = ec

	comms_wrapper, info.comms.filter.port, $
				   info.external_dll, $
				   type = 'com', $
				   /write, $
				   data = 'GOSUB1' + string(13B), $
				   errcode = ec

	comms_wrapper, info.comms.filter.port, $
				   info.external_dll, $
				   type = 'com', $
				   /read, $
				   data = read_back, $
				   errcode = ec

	print, read_back
  	help, read_back
	if (read_back ne '') then begin
   		erc = strmid(read_back,5,1)
   		if size(erc, /type) eq 0 then errcode = '-1' else errcode = erc
  	endif else errcode = '-1'
 
end

;\\ Set the camera exposure time
pro SetExposureTime, info, time, errcode=errcode
	ASC_LoadCameraSetting, info.external_dll, $
						   exposureTime = time, $
						   debug_ress = errcode
end

;\\ Set the camera EM gain
pro SetEMGain, info, gain, errcode=errcode
	ASC_LoadCameraSetting, info.external_dll, $
						   emGain = gain, $
						   debug_ress = errcode
end

;\\ Set the camera read mode (4 = image)
pro SetReadMode, info, mode, errcode=errcode
	ASC_LoadCameraSetting, info.external_dll, $
						   readMode = mode, $
						   debug_ress = errcode
end

;\\ Set the camera acquisition mode (1 = single scan)
pro SetAcqMode, info, mode, errcode=errcode
	ASC_LoadCameraSetting, info.external_dll, $
						   acqMode = mode, $
						   debug_ress = errcode
end





