
;\\ Various utilities for the ASC scripts


;\\ This function is used internally by the scipt utilities, it allows us to control
;\\ the time value that is returned, mostly for testing scripts/debugging.
function _systime, sec = sec, ut=ut, julian=julian

	COMMON DCAI_Control, dcai_global

	if (size(info, /type) eq 0) then begin
	 	return, systime(sec=sec, ut=ut, julian=julian)
	endif else begin
		if dcai_global.info.debug.running eq 1 then begin
			if keyword_set(ut) then begin
				return, dcai_global.info.debug.time_string_ut
			endif else begin
				return, dcai_global.info.debug.time_string
			endelse
		endif else begin
			return, systime(sec=sec, ut=ut, julian=julian)
		endelse
	endelse

end

;\\ Return the solar zenith angle as a decimal
function SolarZenithAngle

	COMMON DCAI_Control, dcai_global

	time = bin_date(_systime(/ut))
	jd = js2jd(dt_tm_tojs(_systime()))
	ut_fraction = (time(3)*3600. + time(4)*60. + time(5)) / 86400.
	sidereal_time = lmst(jd, ut_fraction, 0) * 24.
	sunpos, jd, RA, Dec
	sun_lat = Dec
	sun_lon = RA - (15. * sidereal_time)
	ll2rb, dcai_global.settings.site.geo_lon, dcai_global.settings.site.geo_lat, sun_lon, sun_lat, range, azimuth
	sun_elevation = refract(90 - (range * !radeg))
	return, sun_elevation

end

;\\ Return the solar zenith angle as a string
function SolarZenithAngleStr
	return, string( SolarZenithAngle(), f='(f0.3)' )
end

;\\ Return the UT decimal hour
function HourUt
	time = float(strsplit( dt_tm_fromjs(dt_tm_tojs(_systime(/ut)), format='h$ m$ s$'), ' ', /extract))
	return, time[0] + time[1]/60. + time[2]/3600.
end

;\\ Return the UT hour string (HH:MM:SS)
function HourUtHHMMSS, separator = separator
	if not keyword_set(separator) then sep = ':' else sep = separator
	return, dt_tm_fromjs(dt_tm_tojs(_systime(/ut)), format='h$'+sep+'m$'+sep+'s$')
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

;\\ Return the Year (UT...) as a string
function Year
	return, ( dt_tm_fromjs(dt_tm_tojs(_systime(/ut)), format='Y$') )
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
function CameraTemperature
	COMMON DCAI_Control, dcai_global
  	Andor_Camera_Driver, dcai_global.settings.external_dll, 'uGetTemperatureF', 0, ccd_temp, res, /auto_acq
  	return, ccd_temp
end


;\\ Set the camera exposure time
pro SetExposureTime, info, time, errcode=errcode
	DCAI_LoadCameraSetting, settings.external_dll, $
						   exposureTime = time, $
						   debug_ress = errcode
end

;\\ Set the camera EM gain
pro SetEMGain, info, gain, errcode=errcode
	DCAI_LoadCameraSetting, settings.external_dll, $
						   emGain = gain, $
						   debug_ress = errcode
end

;\\ Set the camera read mode (4 = image)
pro SetReadMode, info, mode, errcode=errcode
	DCAI_LoadCameraSetting, settings.external_dll, $
						   readMode = mode, $
						   debug_ress = errcode
end

;\\ Set the camera acquisition mode (1 = single scan)
pro SetAcqMode, info, mode, errcode=errcode
	DCAI_LoadCameraSetting, settings.external_dll, $
						   acqMode = mode, $
						   debug_ress = errcode
end





