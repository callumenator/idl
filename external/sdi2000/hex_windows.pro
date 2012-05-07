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
   host.operation.times.sea_limit = -12
   pflun = -0.05
   
   jsnow = dt_tm_tojs(systime())
   jsthen= dt_tm_tojs('01-JAN-2005')
   dlag  = jsthen - jsnow
   
   print, "HEX-II window times:"
   print
   print, '                   Time range'
   for j=0,100 do begin
	   host.operation.header.longitude = pflon
	   host.operation.header.latitude  = pflat
	   host.operation.times.safe_moon_elevation = pflun
	   host.operation.times.safe_moon_phase = 0.01
       sdi2k_get_timelimz, /update, lag=dlag + 86400d*float(j)
       date = dt_tm_mk(js2jd(0d)+1, host.operation.times.observing_times(0), format='Y$n$0d$')       
       sdi2k_get_timelimz, /update, lag=dlag + 86400d*float(j), plot='d:\users\conde\main\hex\windows\' + date + '.gif'
       pfstart = dt_tm_mk(js2jd(0d)+1, host.operation.times.observing_times(0), format='h$:m$')
       pfstop  = dt_tm_mk(js2jd(0d)+1, host.operation.times.observing_times(1), format='h$:m$')
	   if host.operation.times.observing_times(0) gt host.operation.times.observing_times(1) then begin
	      pfstart = '**:**'
		  pfstop  = '**:**'
	   endif

	   
	   tz = [pfstart, pfstop]
	   
	   date = dt_tm_mk(js2jd(0d)+1, host.operation.times.observing_times(0), format='n$ 0d$, Y$')
	   print, date, ':      ', pfstart, '-', pfstop, '

       wait, 0.01
   endfor
end


