;========================================================================
;
;  This file contains code for the top-level SDI2000 control program.
;  Routines in here are directly related to creating and managing
;  the SDI2000 control panel.  Support routines are found in
;  "sdi2kprx.pro".  Individual plot and analysis plugins are coded 
;  in files named "sdi2k_plot_*.pro" and "sdi2k_math_*.pro", respectively.
;  Various general-use IDL library routines are needed as well.
;
;  Mark Conde, Fairbanks, July 2000.

@sdi2kprx.pro
@obj_util.pro
@sdi2k_ncdf.pro

@sdi2kinc.pro

   device,   decomposed=0, retain=2
   window
   while !d.window ge 0 do wdelete
   load_pal, culz, proportion=0.5

   sdi2k_data_init, culz
   empty
   wait, 0.1
   
   pflon = host.operation.header.longitude
   pflat = host.operation.header.latitude
   pflun = host.operation.times.safe_moon_elevation
   
   ivlon = -133.72
   ivlat =  68.35
   
   print, "FPS observing times, UT:"
   print
   print, '                   Poker Flat       Inuvik           Either'
   for j=0,180 do begin
	   host.operation.header.longitude = pflon
	   host.operation.header.latitude  = pflat
	   host.operation.times.safe_moon_elevation = pflun
       sdi2k_get_timelimz, /update, lag=86400d*float(j)
       pfstart = dt_tm_mk(js2jd(0d)+1, host.operation.times.observing_times(0), format='h$:m$')
       pfstop  = dt_tm_mk(js2jd(0d)+1, host.operation.times.observing_times(1), format='h$:m$')
	   if host.operation.times.observing_times(0) gt host.operation.times.observing_times(1) then begin
	      pfstart = '**:**'
		  pfstop  = '**:**'
	   endif

	   host.operation.header.longitude = ivlon
	   host.operation.header.latitude  = ivlat
	   host.operation.times.safe_moon_elevation = 200.
       sdi2k_get_timelimz, /update, lag=86400d*float(j)
       ivstart = dt_tm_mk(js2jd(0d)+1, host.operation.times.observing_times(0), format='h$:m$')
       ivstop  = dt_tm_mk(js2jd(0d)+1, host.operation.times.observing_times(1), format='h$:m$')
	   if host.operation.times.observing_times(0) gt host.operation.times.observing_times(1) then begin
	      ivstart = '**:**'
		  ivstop  = '**:**'
	   endif
	   
	   tz = [pfstart, pfstop, ivstart, ivstop]
	   goodz = where(tz ne '**:**')
	   aa = min(tz(goodz))
	   bb = max(tz(goodz))
	   
	   date = dt_tm_mk(js2jd(0d)+1, host.operation.times.observing_times(0), format='n$ 0d$, Y$')
	   print, date, ':      ', pfstart, '-', pfstop, '      ', ivstart, '-', ivstop, $
	                '      ', aa, '-', bb

       wait, 0.01
   endfor
end


