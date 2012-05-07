;====================================================================================
; This is an emergency rescue routine - it will attempt to restart the video system
; if seem to have lost it:
pro sdi2k_restart_video
@sdi2kinc.pro
    sdi2k_user_message, '>>>> Attempting to restart the video system...'
    status = call_external(host.controller.behavior.dll_file, "Reset_Frame")
;    status = call_external(host.controller.behavior.dll_file, "EndGrab", /cdecl)
;    sdi2k_user_message, "Called EndGrab"
    wait, 0.5
    status = call_external(host.controller.behavior.dll_file, "Reset_Frame")
    wait, 0.1
    cfile  = host.hardware.video.camera_config_file
    status = call_external(host.controller.behavior.dll_file, "BeginGrab", scene, xfer_flag, scale, $
                           long(n_elements(scene(*,0))), $
                           long(n_elements(scene(0,*))), $
                           cfile, value=bytarr(6), /cdecl)
    sdi2k_user_message, "Called BeginGrab"
    status = call_external(host.controller.behavior.dll_file, "SetTriggerMode", $
                           host.hardware.video.external_trigger, host.hardware.video.external_trigger_high, $
                           value=bytarr(2), /cdecl)
    sdi2k_user_message, "Set trigger mode"
    status = call_external(host.controller.behavior.dll_file, "Save_Window_Handle", "IDL #93958-0 - Scanning Doppler Imager" , value=1b, /cdecl)
    wait, 1
    if host.hardware.video.interrupt_driven eq 1 then begin
       status = call_external(host.controller.behavior.dll_file, "EnableIRQ", value=bytarr(3), /cdecl)
       sdi2k_user_message, "Video interrupts enabled"
    endif
end

pro sdi2k_request_reboot, message
@sdi2kinc.pro
    sdi2k_kill_plugins
    sdi2k_user_message, message
    wait, 1
    spawn, 'd:\ntreskit\shutdown /L /R /T:30 /Y /C'
    wait, 2
end

;========================================================================
; This procedure closes all active plot plugins:
pro sdi2k_kill_plugins, select=select
    if not(keyword_set(select)) then select = 'Programs'
    if select eq 'Programs' then begin
       wid_pool, 'Settings: SDI Program - ', widx, /destroy
       wid_pool, 'SDI Program -', widx, /destroy
    endif else begin
       wid_pool, 'Settings: SDI Analysis - ', widx, /destroy
       wid_pool, 'SDI Analysis -', widx, /destroy
    endelse
end

;====================================================================================
function sdi2k_filename, prefix
@sdi2kinc.pro
   return, host.operation.logging.log_directory + $
           prefix + $
           dt_tm_mk(js2jd(0d)+1, dt_tm_tojs(systime()), format=host.operation.logging.time_name_format) + $
           '.' + host.operation.header.site_code
end

;====================================================================================
pro sdi2k_user_message, msg, no_timestamp=no_timestamp, beep=beep, blank=blank, no_prefix=no_prefix
@sdi2kinc.pro
   wid_pool, 'sdi2k_widget_message', widget_message, /get
   if not(widget_info(widget_message, /valid)) then return

   tstr = dt_tm_mk(js2jd(0d)+1, dt_tm_tojs(systime()), format='0d$ n$ Y$, h$:m$')
   if keyword_set(no_timestamp) then tstr = '                                   '
   if keyword_set(no_prefix) then tstr = ''
   if keyword_set(blank) then messline = ' ' else messline = tstr + " - " + msg

   widget_control, widget_message, set_value=messline, /append
   tline = widget_info(widget_message, /text_top_line)
   widget_control, widget_message, set_text_top_line=tline+999

   if keyword_set(beep) then beep

;--If requested, copy the messages to a log file on disk:
   if host.controller.behavior.write_log_file then begin
      widget_control, widget_message, get_value=loglines
      openw, logun, sdi2k_filename('log'), /get_lun, /append
       printf, logun, messline
      close, logun
      free_lun, logun
   endif
end

;====================================================================================
pro sdi2k_common_fields, cmd, automation=automation, geometry=geometry
@sdi2kinc.pro

if not(keyword_set(geometry)) then geometry = {geometry,   xsize: n_elements(view(*,0)), $
                                                           ysize: n_elements(view(0,*)), $
                                                         xoffset: 100, $
                                                         yoffset: 100, $
                                               menu_configurable: 0, $
                                                   user_editable: [-1]}

if not(keyword_set(automation)) then automation= {automation, timer_ticking: 0, $
                                                  timer_interval: 1., $
                                                 show_on_refresh: 0, $
                                                        gif_path: 'D:\inetpub\wwwroot\sdi_plots\', $
                                                   auto_gif_name: 'None', $
                                               auto_gif_interval: 60, $
                                                        gif_time: -9d29, $
                                               menu_configurable: 1, $
                                                   user_editable: [0,1,2,3,4,5]}

cmd = cmd+ 'automation: automation, ' + $
             'geometry: geometry, '
end

;====================================================================================
;   Setup the baseboard for etalon and shutter control:
pro sdi2k_open_baseboard
@sdi2kinc.pro
    status = call_external(host.controller.behavior.dll_file, "OpenBaseboard", /cdecl)
;---Set the port mode for 8255 that controls the etalon:
    send_baseboard, host.hardware.etalon.etalon_8255_number + 0b, '80'XB
;---Set the port mode for 8255s that control the shutters:
    send_baseboard, host.hardware.shutters.camera_8255_number + 0b, '80'XB
    send_baseboard, host.hardware.shutters.laser_8255_number + 0b, '80'XB
;---Set the port mode for 8255 that controls the LED:
    send_baseboard, host.hardware.video.LED_8255_number + 0b, '80'XB
end

pro sdi2k_set_shutters, camera=camera, laser=laser
@sdi2kinc.pro
    if not(keyword_set(camera)) then camera = 'closed'
    if not(keyword_set(laser))  then laser  = 'closed'
    camera = strupcase(camera)
    laser  = strupcase(laser)
    if (camera eq 'OPEN') then cambitz = host.hardware.shutters.camera_open_bits else $
                               cambitz = host.hardware.shutters.camera_close_bits
    if (laser  eq 'OPEN') then lasbitz = host.hardware.shutters.laser_open_bits else $
                               lasbitz = host.hardware.shutters.laser_close_bits
    send_baseboard, host.hardware.shutters.camera_8255_number + 2b, cambitz
    send_baseboard, host.hardware.shutters.laser_8255_number  + 3b, lasbitz
    sdi2k_user_message, 'Laser shutter '  + sentence_case(laser) + ', ' + $
                        'Camera shutter ' + sentence_case(camera)
end

;====================================================================================
pro sdi2k_run_script
@sdi2kinc
    jobs = findfile(host.controller.scheduler.job_directory + host.controller.scheduler.external_script_filter)
    for j=0,n_elements(jobs)-1 do begin
        if jobs(j) ne '' then begin
           openr, jobun, jobs(j), /get_lun, /delete
           sdi2k_user_message, "Executing commands from script file " + jobs(j)
           while not(eof(jobun)) do begin
                 cmd = 'Dummy'
                 readf, jobun, cmd
                 status = execute(cmd)
                 sdi2k_user_message, 'Executed command: ' + cmd
           endwhile
           close, jobun
           free_lun, jobun
        endif
    endfor
end

pro sdi2k_kill_watchdog_file
@sdi2kinc
    on_ioerror, collided
    wdogz = findfile(host.controller.scheduler.job_directory + 'sdi_watchdog\watchdog*.tmp')
    if wdogz(0) ne '' then begin
       for j=0,n_elements(wdogz)-1 do begin
           openr, dogfile, wdogz(j), /get_lun, /delete
           close, dogfile
           free_lun, dogfile
       endfor
    endif
    return
collided:
    wait, 2
    on_error, 3
    on_ioerror, catch2
    close, dogfile
    free_lun, dogfile
catch2:
end


;====================================================================================
pro sdi2k_scheduler
@sdi2kinc
    common save_thingat, thingat
    if n_elements(thingat) eq 0 then thingat = -9d9

;---Do nothing if scheduling is disabled:
    if not(host.controller.scheduler.active) then return
;---Do nothing if a scheduled job is executing:
    if host.controller.scheduler.job_semaphore ne 'No scheduled job' then return
    limsave = host.operation.times.observing_times
    sdi2k_get_timelimz
    if total(host.operation.times.observing_times) ne total(limsave) then $
          sdi2k_get_timelimz, /update, plot='d:\inetpub\wwwroot\sdi_plots\run_times.gif'
    jsnow = dt_tm_tojs(systime())
    js2ymds, jsnow, yy, mm, dd, ss
    host_select = where(tag_names(host) eq 'PROGRAMS')
    cdir = host.operation.logging.log_directory + '..\'

;---Check if we need to reboot:
    if host.controller.scheduler.daily_reboot then begin
       reboot_js = ymds2js(yy, mm, dd, 3600.*host.operation.times.reboot_decimal_hour)
       if abs(jsnow - reboot_js) lt 60 then begin
          sdi2k_request_reboot, "Requesting a daily reboot..."
          return
       endif
    endif

;---#########################################################
;   This is TEST code. We will try opening the shutter 'early_shutter' hours early, but leaving the
;   intensifier HV off. This is to look at the possibility that heat disipation by
;   the shutter solenoid is causing the wavelength drifts seen in the 2-4 hours following
;   the start of observations each day:
    early_shutter = 3.
    if jsnow gt host.operation.times.calibration_times(0) - 3600L*early_shutter and $
       jsnow lt host.operation.times.calibration_times(0) - 3600L*early_shutter then begin
       send_baseboard, host.hardware.shutters.camera_8255_number + 2b, 0b
    endif


;---Test if we need to acquire a phase map:
    if jsnow gt host.operation.times.calibration_times(0) then begin
       flis = findfile(sdi2k_filename('phc'))
       if flis(0) eq '' then begin
          sdi2k_user_message, 'Scheduler: Loading ' + host.controller.scheduler.phase_map_job
          sdi2k_load_settings, file=cdir + host.controller.scheduler.phase_map_job, host_select=host_select
          wait, 1
          return
       endif
    endif
;---Test if we need to acquire instrument profiles:
    if jsnow gt host.operation.times.calibration_times(0) then begin
       flis = findfile(sdi2k_filename('ins'))
       if flis(0) eq '' then begin
          sdi2k_user_message, 'Scheduler: Loading ' + host.controller.scheduler.insprof_job
          sdi2k_load_settings, file=cdir + host.controller.scheduler.insprof_job, host_select=host_select
          wait, 1
          return
       endif
    endif
;---Test if we need to shift the phase map for sky wavelength:
    if jsnow gt host.operation.times.calibration_times(0) then begin
       flis = findfile(sdi2k_filename('phs'))
       if flis(0) eq '' then begin
          sdi2k_user_message, 'Scheduler: Loading ' + host.controller.scheduler.phase_shift_job
          sdi2k_load_settings, file=cdir + host.controller.scheduler.phase_shift_job, host_select=host_select
          wait, 1
          return
       endif
    endif
;---Test if we should observe:
    if jsnow gt host.operation.times.observing_times(0) and $
       jsnow lt host.operation.times.observing_times(1) then begin
       sdi2k_user_message, 'Scheduler: Loading ' + host.controller.scheduler.sky_observation_job
       sdi2k_load_settings, file=cdir + host.controller.scheduler.sky_observation_job, host_select=host_select
       wait, 1
       return
    endif

;---Test if we should request an analysis job to run on \\THING:
    time_after_end = jsnow - host.operation.times.observing_times(1)
;---Time window to start analysis is 15 minutes after end of sky obs:
    if  time_after_end gt 0. and time_after_end lt 900. then begin
;-------But, only submit a job if its at least 12 hours since last submission:
        if jsnow - thingat gt 0.5*86400. then begin
           sdi2k_batch_copier, 'd:\users\sdi2000\data\', '\\thing\users\sdi2000\data\'
           whenat = dt_tm_mk(js2jd(0d)+1, jsnow+300. - 8.*3600., format='h$:m$')
           spawn, 'at \\thing ' + whenat + '  /interactive c:\sdi2k_autorun.lnk'
           sdi2k_user_message, 'Submitted analysis request: At \\thing ' + whenat + '  /interactive c:\sdi2k_autorun.lnk'
;----------Save submission time in common block variable thingat:
           thingat = jsnow
        endif
    endif

end

pro sdi2k_get_timelimz, all_today=all_today, update=update, start=start, plot=plotname, lag_sec=lag_sec
@sdi2kinc
    common save_sea_lim, sea_lim
    if not(keyword_set(lag_sec)) then lag_sec = 0.
    cal_seconds = 15*60

;---Check if solar elevation angle has changed, which would require an update:
    new_sea = 0
    if n_elements(sea_lim) eq 0 then new_sea = 1 $
    else begin
       if host.operation.times.sea_limit ne sea_lim then new_sea = 1
    endelse

;---Get current time information, plus julian seconds at 00 UT on this day:
    jsnow = dt_tm_tojs(systime()) + lag_sec
    js2ymds, jsnow, yy, mm, dd, ss
    jsutz = ymds2js(yy, mm, dd, 0)
    js2ymds, host.operation.times.observing_times(0), yc, mc, dc, sc

;---Check if we want to force observations for all of today:
    if keyword_set(all_today) then begin
       host.operation.times.observing_times = [jsutz, jsutz + 86400l]
       host.operation.times.calibration_times = [host.operation.times.observing_times(0) - cal_seconds, $
                                                 host.operation.times.observing_times(0)]
       sdi2k_user_message, "Observing is now allowed for all of " + $
                            dt_tm_mk(js2jd(0d)+1, jsnow, format='0d$-n$-Y$')
       return
    endif

;---Check if the moon phase is too great for any observations at all:
    mphase, systime(/julian) + lag_sec/86400., lunphase
;    if lunphase lt host.operation.times.safe_moon_phase then begin
;       host.operation.times.observing_times = [jsutz + 86401l, jsutz + 86401l]
;       host.operation.times.calibration_times = [host.operation.times.observing_times(0) - cal_seconds, $
;                                                 host.operation.times.observing_times(0)]
;       sdi2k_user_message, "Cannot observe today, the moon's near-side is " + $
;                            string(100*lunphase, format='(i2.2)') + '% illuminated'
;       return
;    endif

;---Find, to the nearest sunres and moonres minutes, when the sun and moon have low enough elevations:
    timeres = 5.
    if abs(host.operation.times.observing_times(0) - dt_tm_tojs(systime())) gt 86399. or $
       new_sea or dd ne dc or keyword_set(update) then begin
       widget_control, /hourglass
       sea_lim = host.operation.times.sea_limit

;------Manually force an observing interval for now:
;       host.operation.times.observing_times = [jsutz + 3.5*3600l, jsutz + 15.666*3600l]
;       host.operation.times.calibration_times = [host.operation.times.observing_times(0) - cal_seconds, $
;                                                 host.operation.times.observing_times(0)]
;       sdi2k_user_message, "Observing is forced for 3.5-15.6 UT"
;       return


;       sunzd  = sun_zd(host.operation.header.longitude, $
;                      host.operation.header.latitude,  jsutz, jsutz+86400l, number = 24*60/timeres, time=timez)
;       sea   = 90. - sunzd
;------Get moon alt, azi:
       ut    = findgen(1+24*60/timeres)*timeres/(24*60); UT in days.
       jd    = systime(/julian) + lag_sec/86400. - (jsnow - jsutz)/86400. + ut
       moonpos, jd, ra, dec, dis, geolong, geolat
       st    = lmst(systime(/julian) + lag_sec/86400.  - (jsnow - jsutz)/86400., ut, 0)*24
       lunlat= dec
       lunlng= ra - 15.*st
       ll2rb, host.operation.header.longitude, host.operation.header.latitude, lunlng, lunlat, rr, lunazi
       lunalt= refract(90-rr*!radeg)
       luntst= lunalt
       if lunphase lt host.operation.times.safe_moon_phase then luntst = luntst - 180.

;------Get sun alt, azi:
       sunpos,  jd, ra, dec
       sunlat= dec
       sunlng= ra - 15.*st
       ll2rb, host.operation.header.longitude, host.operation.header.latitude, sunlng, sunlat, rr, sunazi
       sunalt= refract(90-rr*!radeg)
       sea   = sunalt

       timez = jsutz + findgen(n_elements(sea))*3600d*timeres/60.
       nobs  = 0
       obs   = where(sea    lt host.operation.times.sea_limit and $
                     luntst lt host.operation.times.safe_moon_elevation, nobs)
       if nobs le 1 then return
       timez = timez(obs)
       timez = timez(sort(timez))

       ct = median(timez)
       ht = where(timez eq ct, nn)
       j  = ht(0)
       k  = ht(0)
    if n_elements(timez) gt 2 then begin
          repeat begin
              j = j-1
              j = j > (0)
          endrep until j eq 0 or timez(j+1) - timez(j) gt 65.*timeres
          if timez(j+1) - timez(j>0) gt 65.*timeres then j = j + 1
    endif

       k  = ht(0)
    if n_elements(timez) gt 2 then begin
       repeat begin
        k = k+1
        k = k > 1
    endrep until k eq nobs-1 or timez(k) - timez(k-1) gt 65.*timeres
          if timez(k) - timez(k-1) gt 65.*timeres then k = k - 1
    endif
       timelimz = [timez(j > 0), timez(k < nobs-1)]
       host.operation.times.observing_times   = timelimz
       host.operation.times.calibration_times = [timelimz(0) - cal_seconds, timelimz(0)]

;------The start keyword forces us to start running now, by setting the start time to
;      00 ut on this day. The ephemeris still determines the stop time, however:
       if keyword_set(start) then begin
          host.operation.times.observing_times(0) = jsutz
          host.operation.times.calibration_times = [host.operation.times.observing_times(0) - cal_seconds, host.operation.times.observing_times(0)]
       endif
    endif

    if keyword_set(plotname) and n_elements(sunalt) gt 0 then begin
       set_plot, 'Z'
       device, set_resolution=[1000,600]
       erase, color=host.colors.white

       ut = ut*24.
       nt = n_elements(ut)
       lohour = (host.operation.times.observing_times(0) - jsutz)/3600.
       hihour = (host.operation.times.observing_times(1) - jsutz)/3600.
       plot, ut, sunalt, xthick=2, ythick=2, charthick=2, charsize=2, /nodata, $
             xtitle='Time [Hours UT]', ytitle='Elevation Angle [Degrees]', $
             /xstyle, /ystyle, xrange=[0,24], yrange=[-60, 45], xticks=12, xminor=4, $
             color=host.colors.black, /noerase, title='SDI2000 Run Times, ' + $
             dt_tm_mk(js2jd(0d)+1, host.operation.times.observing_times(0), format='d$-n$-Y$')
       for j=lohour,hihour,0.05 do begin
           oplot, [j, j], [-60, 45], color=host.colors.wheat, thick=2
       endfor
       oplot, [lohour, lohour], [-60, 45], color=host.colors.red,   thick=2
       oplot, [hihour, hihour], [-60, 45], color=host.colors.green, thick=2
       plot, ut, sunalt, xthick=2, ythick=2, charthick=2, charsize=2, /nodata, $
             xtitle='Time [Hours UT]', ytitle='Elevation Angle [Degrees]', $
             /xstyle, /ystyle, xrange=[0,24], yrange=[-60, 45], xticks=12, xminor=4, $
             color=host.colors.black, /noerase, title='SDI2000 Run Times, ' + $
             dt_tm_mk(js2jd(0d)+1, host.operation.times.observing_times(0), format='d$-n$-Y$')
       oplot, [0,24], [host.operation.times.safe_moon_elevation, host.operation.times.safe_moon_elevation], $
              linestyle=1, thick=2, color=host.colors.blue
       oplot, [0,24], [host.operation.times.sea_limit, host.operation.times.sea_limit], $
              linestyle=1, thick=2, color=host.colors.orange
       oplot, [0,24], [0, 0], $
              linestyle=1, thick=1, color=host.colors.ash

       nn = 0
       oplot, ut, sunalt, color=host.colors.orange, thick=1, linestyle=1
       lowz = where(sunalt lt host.operation.times.sea_limit, nn)
       plots, ut(lowz(0)), sunalt(lowz(0))
       for j=1,nn-1 do begin
           if ut(lowz(j)) - ut(lowz(j-1)) lt 2.*timeres/60 then cont=1 else cont=0
           plots, ut(lowz(j)), sunalt(lowz(j)), color=host.colors.orange, thick=2, cont=cont
       endfor

       oplot, ut, lunalt, color=host.colors.blue, thick=1, linestyle=1
       lowz = where(lunalt lt host.operation.times.safe_moon_elevation, nn)
       plots, ut(lowz(0)), lunalt(lowz(0))
       for j=1,nn-1 do begin
           if ut(lowz(j)) - ut(lowz(j-1)) lt 2.*timeres/60 then cont=1 else cont=0
           plots, ut(lowz(j)), lunalt(lowz(j)), color=host.colors.blue, thick=2, cont=cont
       endfor

       mp = strcompress('Phase:' + string(lunphase*100, format='(i)') + '%')
       losun = where(sunalt eq min(sunalt))

       xyouts, ut(losun(0)),  min(sunalt)-5.,  'Sun',  align=0.5, charsize=2, charthick=2, color=host.colors.orange
       xyouts, ut(nt-1)-1, lunalt(nt-1)-1, 'Moon', align=1, charsize=2, charthick=2, color=host.colors.blue
       xyouts, ut(nt-1)-1, -55, mp, align=1, charsize=2, charthick=2, color=host.colors.blue
       if lohour gt 2. then begin
          delh   = -0.3
          halign = 1
       endif else begin
          delh   = 0.3
          halign = 0
       endelse
       xyouts, lohour + delh, 35, 'Start!C' + dt_tm_mk(js2jd(0d)+1, host.operation.times.observing_times(0), format='h$:m$'), $
               align=halign, charsize=2, charthick=2, color=host.colors.red
       xyouts, hihour+0.3, 35, 'Stop!C' + dt_tm_mk(js2jd(0d)+1, host.operation.times.observing_times(1), format='h$:m$'), $
               align=0, charsize=2, charthick=2, color=host.colors.green
       img = tvrd()
       tvlct, r, g, b, /get
       write_gif, plotname, img, r, g, b
       set_plot, 'WIN'
    endif
end

;====================================================================================
;   This is a diagnostic procedure, to flash a test LED attached to the baseboard's
;   first 8255 "A" port.
pro flash_LED
@sdi2kinc.pro
common port_byte_saver, port_byte
    if n_elements(port_byte) eq 0 then port_byte = 0b
    port_byte = port_byte xor 'FF'XB
    send_baseboard, host.hardware.video.LED_8255_number+3, port_byte
end

;====================================================================================
;   This procedure sends a byte, 'byteval' to the baseboard register 'bport':
pro send_baseboard, bport, byteval
@sdi2kinc.pro
    status = call_external(host.controller.behavior.dll_file, $
                           "SendBaseboard", bport, byteval, value=bytarr(2), /cdecl)
end

;====================================================================================
;   This procedure sets the gap of etalon leg number 'leg' to the specified 'gapin':
pro sdi2k_etalon_leggap, leg, gapin
@sdi2kinc.pro
        port = host.hardware.etalon.etalon_8255_number
        gap  = gapin + host.hardware.etalon.parallelism_offset[leg-1]
        send_baseboard, port + 1b, byte(leg+4)
        send_baseboard, port + 2b, byte(gap and 255us)
        send_baseboard, port + 3b, byte((gap and '300'xu)/256)
;-------Send bit C4 hi,lo to strobe new spacing to the etalon:
        send_baseboard, port + 1b, byte(leg+20)
        send_baseboard, port + 1b, byte(leg+4)
end

;====================================================================================
;   This procedure sets the gap of all 3 etalon legs:
pro sdi2k_etalon_gap
@sdi2kinc.pro
    sdi2k_etalon_leggap, 1, host.hardware.etalon.current_spacing
    sdi2k_etalon_leggap, 2, host.hardware.etalon.current_spacing
    sdi2k_etalon_leggap, 3, host.hardware.etalon.current_spacing
end

;====================================================================================
;   This procedure scans the etalon:
pro sdi2k_etalon_scan, reset=reset, lambda=lambda
@sdi2kinc.pro
    if not(keyword_set(lambda)) then lambda = host.operation.calibration.sky_wavelength
    if keyword_set(reset) then begin
       host.hardware.etalon.dwell_count = 9999
       host.hardware.etalon.current_channel = 9999
    endif
    host.hardware.etalon.dwell_count = host.hardware.etalon.dwell_count + 1
    if host.hardware.etalon.dwell_count ge host.hardware.etalon.dwell_frames then begin
       host.hardware.etalon.dwell_count = 0
       scan_gain = lambda /(2.*host.hardware.etalon.nm_per_step*host.hardware.etalon.scan_channels);
       if host.hardware.etalon.current_channel lt host.hardware.etalon.scan_channels - 1 then begin
          host.hardware.etalon.current_channel = host.hardware.etalon.current_channel + 1
          host.hardware.etalon.current_spacing = host.hardware.etalon.start_spacing + $
                                            host.hardware.etalon.current_channel * scan_gain
       endif else begin
          host.hardware.etalon.current_channel = 0
          host.hardware.etalon.current_spacing = host.hardware.etalon.start_spacing
       endelse
       sdi2k_etalon_gap
    endif
end

;====================================================================================
;   This procedure loads a phase map:
pro sdi2k_load_phase_map, mapfile
@sdi2kinc.pro
    restore, mapfile, /relaxed
    phase = fix(phase*host.hardware.etalon.scan_channels/(2*!pi))
    phase = phase - min(phase)
    host.programs.phase_map = pmap_host.programs.phase_map
    stm = host.programs.phase_map.start_time
    etm = host.programs.phase_map.start_time + host.programs.phase_map.integration_seconds
    sdi2k_user_message, 'Loaded phase map file ' + mapfile + ' from ' + $
                         dt_tm_mk(js2jd(0d)+1, stm, format='0d$-n$-Y$') + ' (DOY ' + $
                         dt_tm_mk(js2jd(0d)+1, stm, format='doy$).')
    sdi2k_user_message, 'Phase map exposed ' + $
                         dt_tm_mk(js2jd(0d)+1, stm, format='h$:m$:s$-') + $
                         dt_tm_mk(js2jd(0d)+1, etm, format='h$:m$:s$.'), /no_timestamp
end

;====================================================================================
;   This procedure builds a zone map at the current video resolution:
pro sdi2k_build_zone_map, canvas_size = cs, map_project=map_project
@sdi2kinc.pro
       widget_control, /hourglass
       sdi2k_user_message, 'Building zone map'
       nz = total(host.operation.zones.sectors(0:host.operation.zones.fov_rings-1))
       zone_centers = fltarr(nz, 3)
       nx           = n_elements(view(*,0))
       ny           = n_elements(view(0,*))
       edge         = (nx < ny)/2
       zone_map     = intarr(nx, ny)
       nzones       = 0
       map_radii    = host.operation.zones.ring_radii
       if keyword_set(map_project) then begin
          print, 'WARNING: Sky_FOV hard-limited to 68 degrees in build_zone_map!'
          map_radii = tan(!pi*(host.operation.calibration.sky_fov < 68.)*map_radii/(100.*180))
          map_radii = max(host.operation.zones.ring_radii)*map_radii/max(map_radii)
       endif
 
       
       for xi=0,nx-1 do begin
           x = xi - host.operation.zones.x_center
           for yi=0,ny-1 do begin
               y = yi - host.operation.zones.y_center
               rsqrd  =  x*x + y*y
               if (x eq 0 and y eq 0) then angle = 0 $
                  else angle  = atan(y, x)*!radeg
               if (angle lt 0) then angle = angle + 360.
               ring   = 0b
               zone   = 0b
               while  ((rsqrd gt ((map_radii(ring)/100.)*edge)^2) and $
                       (ring lt host.operation.zones.fov_rings)) do begin
                       zone = zone + byte(host.operation.zones.sectors(ring))
                       ring = ring + 1
               endwhile
               sector = byte(angle/(360./host.operation.zones.sectors(ring)))
               zone   = zone + sector
               if (ring ge host.operation.zones.fov_rings) then zone = -1
               if (rsqrd gt edge^2) then zone = -1
               zone_map(xi, yi) = zone
               if (zone ge 0) then begin
                   zone_centers(zone, 0) = zone_centers(zone, 0) + x
                   zone_centers(zone, 1) = zone_centers(zone, 1) + y
                   zone_centers(zone, 2) = zone_centers(zone, 2) + 1
               endif
            endfor
   wait, 0.01
       endfor

;------Build the zone canvas:
       nbad = 0
       bads = where(zone_centers(*,2) eq 0, nbad)
       if (nbad gt 0) then zone_centers(bads,2) = 1
       ncul = host.colors.imgmax - host.colors.imgmin - 2
       zone_canvas = zone_map((host.operation.zones.x_center - edge + 1) > 0:(host.operation.zones.x_center + edge - 1) < nx-1, $
                              (host.operation.zones.y_center - edge + 1) > 0:(host.operation.zones.y_center + edge - 1) < ny-1)
       zone_canvas(where(zone_canvas eq -1)) = 0
       zone_canvas = 16*zone_canvas mod ncul
       nxzc        = n_elements(zone_canvas(*,0))
       nyzc        = n_elements(zone_canvas(0,*))
       if not(keyword_set(cs)) then cs = [host.programs.spectra.window_xsize, host.programs.spectra.window_ysize]
       zone_canvas = host.colors.imgmin + congrid(zone_canvas, cs(0), cs(1))
       zone_centers(*, 0) = zone_centers(*, 0)/zone_centers(*, 2)
       zone_centers(*, 0) = zone_centers(*, 0)/float(2*edge)
       zone_centers(*, 1) = zone_centers(*, 1)/zone_centers(*, 2)
       zone_centers(*, 1) = zone_centers(*, 1)/float(2*edge)
       sdi2k_user_message, 'Zone Map Built.'

;------Build the zone table:
       nz = fix(total(host.operation.zones.sectors(0:host.operation.zones.fov_rings-1)))
       nn = 0l
       maxpix = 0l
;------Find how big we need to make the table:
       for j=0,nz-1 do begin
           thesepix = where(zone_map eq j, nn)
           maxpix = nn > maxpix
       endfor
;------For each zone, record the pixel addresses mapped to that zone:
       zone_table = lonarr(nz, maxpix+1)
       for j=0,nz-1 do begin
           thesepix = where(zone_map eq j, nn)
           zone_table(j, 0) = nn
           zone_table(j, 1:nn) = thesepix
       endfor

       end

;========================================================================
pro sd2k_extract_substruk, struk, fields, pstring
    tnames  = tag_names(struk)
    sel     = where(sentence_case(tnames) eq fields(0))
    selstr  = strcompress(string(sel(0)), /remove_all)
    pstring = pstring + '.(' + selstr + ')'
    if n_elements(fields) gt 1 then begin
       sd2k_extract_substruk, struk.(sel(0)), fields(1:*), pstring
    endif
end

;========================================================================
;   This procedure will request a terminal server session disconnect:
pro sdi2k_terminal_disconnect
@sdi2kinc.pro
    sdi2k_user_message, "Requesting terminal disconnect"
    status = call_external(host.controller.behavior.dll_file, "Disconnect_Terminal_Session", /cdecl)
end

;====================================================================================
pro sdi2k_reset_spectra
@sdi2kinc.pro
    nz      = total(host.operation.zones.sectors(0:host.operation.zones.fov_rings-1))
    spectra = 0*ulonarr(nz, host.hardware.etalon.scan_channels)
end

;========================================================================
; Save the current program settings:
pro sdi2k_save_settings, file=file
@sdi2kinc.pro
    common conf_path, conf_path
    if n_elements(conf_path) eq 0 then conf_path = host.operation.logging.log_directory

;---First, check if the top-level widget is still valid:
    wid_pool, 'sdi2k_top', widx, /get
    if not(widget_info(widx, /valid_id)) then return

;---Next, get the save file name, either from the "file" keyword, or from
;   a user dialog:
    if not(keyword_set(file)) then begin
       file = dialog_pickfile(file=host.controller.behavior.config_file, filter='*.sdi', group=widx, $
                              title='Filename to save sdi display settings:', /write, $
                              path=conf_path, get_path=conf_path)
    endif
;---Handle the case where the user pressed the "Cancel" button at file selection:
    if file eq '' then return
    host.controller.behavior.config_file = file

;---Make copies of the settings info in heap. Create an array of pointers to
;   each heap variable.  Start with the control module:
    state = [ptr_new(host)]
    state = [state, ptr_new(widget_info(widx, /geometry))]

;---Locate and save settings for each plugin:
    nr = 0
    wid_pool, 'Sdi Program', plotz, /get
    nplug = n_elements(plotz)
    for j=0,nplug-1 do begin
        if widget_info(plotz(j), /valid_id) then begin
           widget_control, plotz(j), get_uvalue=info
           didx = plotz(j)
           settings = 'Dummy'
           ns = 0
           if size(info, /tname) eq 'STRUCT' then begin
              wt = where(tag_names(info) eq 'WTITLE', ns)
              if ns gt 0 then begin
                 wid_pool, 'Settings: ' + info.wtitle, widx, /get
                 if widget_info(widx, /valid) then begin
                    widget_control, widx, get_uvalue=settings
                    tloc   = where(tag_names(info) eq 'DRAWID', nr)
                    if nr gt 0 then didx = info.drawid
                 endif
              endif
           endif
           state = [state, ptr_new(info)]
           state = [state, ptr_new(widget_info(plotz(j), /geometry))]
           state = [state, ptr_new(widget_info(didx,     /geometry))]
           state = [state, ptr_new(settings)]
        endif
    endfor

;---Save the heap copies in an IDL save file:
    save, state, file=file
    for j=0,n_elements(state)-1 do ptr_free, state(j)
end

;========================================================================
; Restore previously-saved program settings:
pro sdi2k_load_settings, file=file, query=query, host_select=host_select
@sdi2kinc.pro
    common conf_path, conf_path
    if n_elements(conf_path)   eq 0 then conf_path   = host.operation.logging.log_directory
    if n_elements(host_select) eq 0 then host_select = indgen(n_tags(host))

;---First, check if the top-level widget is still valid:
    wid_pool, 'sdi2k_top', widx, /get
    if not(widget_info(widx, /valid_id)) then return

;---Get the save file name, either from the "file" keyword, or from
;   a user dialog:
    if not(keyword_set(file)) then begin
       file = dialog_pickfile(file=host.controller.behavior.config_file, filter='*.sdi', group=widx, $
                              title='Filename to restore sdi display settings:', /must_exist, $
                              path=conf_path, get_path=conf_path)
    endif
    if not(fexist(file)) then return

;---Read copies of the saved information into a set of heap variables, pointed to
;   by an array of pointers that will be named "state"
    on_ioerror, IO_trubble
    restore, file, /relaxed_structure_assign

    host.controller.behavior.config_file = file

;---Kill any plugins that are currently running:
    if keyword_set(query) then rthis = dialog_message('Close any currently open modules first?', /question) eq 'Yes' $
                          else rthis = 1
    if rthis then sdi2k_kill_plugins

    host_functions = sentence_case(tag_names((*state(0))))
;---Restore the control settings:
       for j=0,n_elements(host_select)-1 do begin
           if keyword_set(query) then rthis = dialog_message('Restore host settings for ' + host_functions(j) + '?', /question) eq 'Yes' $
                          else rthis = 1
           if rthis then begin
              dest = host.(host_select(j))
              struct_assign, (*state(0)).(host_select(j)), dest
              host.(host_select(j)) = dest
           endif
       endfor

;---Restore the window geometry of the xwindow:
    tnames = tag_names((*state(1)))
    for k=0,1 do begin
        tval   = (*state((1))).(k)
        cmd    = 'widget_control, widx, ' + tnames(k) + '=tval'
        if rthis then status = execute(cmd)
    endfor
;---Go back to the default palette:
    load_pal, culz, proportion=0.5

;---Restore the various plugins:
    for j=2,n_elements(state)-4,4 do begin
        if keyword_set(query) then rthis = dialog_message('Restore:  "' +  (*state(j)).wtitle + '" ?', /question) eq 'Yes' $
                              else rthis = 1
        if rthis then begin
           info = 'Empty'
;----------Start a new instance of the restored plugin:
           if size((*state(j+3)), /tname) eq 'STRUCT' then begin
              new_obj, (*state(j+3)).class_name, instance
              status = execute((*state(j+3)).class_name + '_autorun, instance')
              if widget_info(instance.id, /valid) then begin
                 xwidx  = instance.id
                 widget_control, xwidx, get_uvalue=info
                 wid_pool, 'Settings: ' + info.wtitle, xwset, /get

   ;-------------Copy the restored settings to the new instance's settings:
                 widget_control, xwset, get_uvalue=settings
                 if size(settings, /tname) eq 'STRUCT' then begin
                    struct_assign, (*state(j+3)), settings
                    widget_control, xwset, set_uvalue=settings
                 endif
   ;-------------Now, selectively copy some restored xwindow info to the new instance's xwindow:
                 cfields = ['XSIZE', 'YSIZE', 'TLBXSIZE', 'TLBYSIZE', $
                            'R', 'G', 'B', 'WCOLORS', 'BOTTOM', 'PROTECT', 'NOMENU', 'NOCHANGE', $
                            'ERASE', 'NCOLORS', 'BACKGROUND', 'OUTPUT', $
                            'PS', 'PSLOCAL', 'GIF', 'JPEG', 'TIFF']
                 for k=0,n_elements(cfields)-1 do begin
                     nsrc = 0
                     ndst = 0
                     stag = where(tag_names((*state(j))) eq cfields(k), nsrc)
                     dtag = where(tag_names(info)        eq cfields(k), ndst)
                     if nsrc gt 0 and ndst gt 0 then begin
                        info.(dtag(0)) = (*state(j)).(stag(0))
                     endif
                 endfor
              endif else begin
                 wid_pool, 'Dummy', widlis, /all
                 xwidx = widlis(n_elements(widlis)-1)
              endelse
   ;----------Restore the window geometry of the window:
              tnames = tag_names((*state(j+1)))
              for k=0,1 do begin
                  tval   = (*state((j+1))).(k)
                  cmd    = 'widget_control, xwidx, ' + tnames(k) + '=tval'
                  status = execute(cmd)
              endfor
   ;----------Restore the window colors:
              nt = 0
              ng = 0
              nb = 0
              if size(info, /tname) eq 'STRUCT' then begin
                 tloc   = where(tag_names(info) eq 'R', nr)
                 tloc   = where(tag_names(info) eq 'G', ng)
                 tloc   = where(tag_names(info) eq 'B', nb)
                 if nr gt 0 and ng gt 0 and nb gt 0 then tvlct, info.r, info.g, info.b
                 widget_control, xwidx, set_uvalue=info
              endif
   ;----------For Xwindows, restore the window geometry of the draw widget:
              if size(info, /tname) eq 'STRUCT' then begin
                 tloc   = where(tag_names(info) eq 'DRAWID', nr)
                 if nr gt 0 then begin
                    tnames = tag_names((*state(j+2)))
                    for k=0,5 do begin
                        tval   = (*state((j+2))).(k)
                        cmd    = 'widget_control, info.drawid, ' + tnames(k) + '=tval'
                        status = execute(cmd)
                    endfor
                 endif
              endif
              if (*state((j+1))).xoffset eq -32000.0 and (*state((j+1))).yoffset eq -32000.0 then $
                  widget_control, xwidx, /iconify
           endif
        endif
    endfor

;---Cleanup the heap copies of the settings info:
    for j=0,n_elements(state)-1 do ptr_free, state(j)
IO_trubble:
    catch, err_var
end


function sdi2k_config_tryload, trypath
@sdi2kinc.pro
    status = 0
    if trypath eq '' then return, status
    file = dialog_pickfile(file=prsepath(trypath) + 'sdi2000.sdi', $
                           filter='*.sdi', $
                           title='Filename to restore SDI2000 display settings:')
    if file ne '' and fexist(file) then begin
       sdi2k_load_settings, file=file
       host.controller.behavior.config_file = file
       status = 1
    endif
    return, status
end

;========================================================================
;   This routine loads a default setup file upon startup:

pro sdi2k_default_config
@sdi2kinc.pro
    whoami, dir, file
    host.controller.behavior.config_file = prsepath(dir) + 'sdi2000.sdi'

;---Well, we didn't have a complete setup file specified. So now we try
;   looking around in some directories for one:

    file = getenv('sdiDisplayConfigFile')
    if file ne '' then begin
       if fexist(file) then begin
          sdi2k_load_settings, file=file
          host.controller.behavior.config_file = file
          return
       endif
    endif

    goodload = sdi2k_config_tryload(getenv('userprofile'))
    if goodload then return

    goodload = sdi2k_config_tryload(getenv('homedrive'))
    if goodload then return

    goodload = sdi2k_config_tryload(getenv('home'))
    if goodload then return

    goodload = sdi2k_config_tryload(getenv('sdiDisplayConfigPath'))
    if goodload then return
end

;========================================================================
; A procedure to automatically make GIF files, by sending an appropriate
; event to xwindow, if needed:
pro sdi2k_plugin_gif, info, now=now

    js_time = dt_tm_tojs(systime())

;---Do nothing here if we're already gif-ing:
    if !d.name eq 'Z'  then return
    if !d.name eq 'PS' then return

;---Get settings and widget IDs:
    wid_pool, info.wtitle, topidx, /get
    if not(widget_info(topidx, /valid_id)) then return
    wid_pool, 'Settings: ' + info.wtitle, widx, /get
    if not(widget_info(widx, /valid_id)) then return
    widget_control, widx, get_uvalue=settings

;---Check if are making GIFs at all:
    if settings.automation.auto_gif_name eq 'None' then return
;---Check if its time to make a new GIF:
    if js_time - settings.automation.gif_time lt settings.automation.auto_gif_interval and $
       not(keyword_set(now)) then return
;---Check if the specified xwindow plugin is still valid:
    if not(widget_info(topidx, /valid_id)) then return
;---Make the GIF:
    namesave = info.gif.filename
    info.gif.filename = settings.automation.gif_path + strcompress(dt_tm_mk(js2jd(0d)+1, js_time, format=settings.automation.auto_gif_name), /remove_all)
    widget_control, topidx, set_uvalue=info
    widget_control, info.gifid, send_event={id:info.gifid, top:topidx, handler:0l}
;    info.gif.filename = namesave
;    widget_control, topidx, set_uvalue=info
    settings.automation.gif_time = js_time
    widget_control, widx, set_uvalue=settings
end

pro sdi2k_physical_units, resarr
@sdi2kinc.pro

    nmps = host.hardware.etalon.nm_per_step
    scan_gain = host.operation.calibration.sky_wavelength/(2.*nmps*host.hardware.etalon.scan_channels )
    channel_spacing = nmps*scan_gain

    c=2.997925e8
    amu=1.66053e-27
    bk=1.380658e-23
    f = 1e-6*c*channel_spacing / host.hardware.etalon.gap
    g = host.operation.calibration.sky_mass*amu/(2*bk)

    vzero = 0.
    if n_elements(resarr) gt 3 then vzero = median(resarr.velocity(0))
    resarr.velocity = f*(resarr.velocity - vzero)
    resarr.sigma_velocity = f*resarr.sigma_velocity

end


pro sdi2k_drift_correct, resarr, source_file=sf, force=fdc, data_based=dbase
@sdi2kinc.pro

;---Find out if we actually need to do drift corrections:
    if not keyword_set(fdc) then begin
       mcchoice, 'Correct for wavelength drift?', ['Yes, Laser Based', 'Yes, Data Based','No'], choice
       fdc   = strpos(choice.name, 'Yes')  ge 0
       dbase = strpos(choice.name, 'Data') ge 0
    endif else fdc = 1
    if not fdc then return

;---Find out the drift calibration file name:
    if keyword_set(sf) then begin
       skyspot = strpos(strupcase(sf), 'SKY')
       drfile  = strmid(sf, 0, skyspot) + 'ins' + strmid(sf, skyspot+3, 999)
    endif else begin
       drfile = dialog_pickfile(file=fitfile, $
                                filter='ins*.' + host.operation.header.site_code, $
                                group=widx, title='Select a file of sky spectra: ', $
                                path=host.operation.logging.log_directory)
    endelse

    if keyword_set(dbase) then goto, data_corr

;---Build an array of drift results:
    sdi2k_ncopen, drfile, ncid, 1
    sdi2k_build_fitres, ncid, driftarr
    ncdf_close, ncid
    host.netcdf(1).ncid = -1

    ndrft  = n_elements(driftarr)
    driftarr = [driftarr(0), driftarr, driftarr(ndrft-1)]
    driftarr(0).start_time = driftarr(0).start_time - 300.
    driftarr(0).end_time = driftarr(0).end_time - 300.
    driftarr(ndrft+1).start_time = driftarr(ndrft-1).start_time + 300.
    driftarr(ndrft+1).end_time = driftarr(ndrft-1).end_time + 300.

;---Get drift times and sky times:
    dt = (driftarr.start_time + driftarr.end_time)/2.
    st = (resarr.start_time  + resarr.end_time)/2.

    nz     = total(host.operation.zones.sectors(0:host.operation.zones.fov_rings-1))
    nobs   = n_elements(resarr.velocity(0))
    ndrft  = n_elements(driftarr)
    drvals = fltarr(ndrft)

;---Find where we have good drift spectra:
    nn     = 0
    goodrex= where(driftarr.signal2noise(0) gt 5000., nn)
    if nn gt 2 then begin
;------Find any bad drift spectra:
       badrex  = where(driftarr.signal2noise(0) le 5000., nn)
;------Replace bad drift spectra with the most recent good one:
       if nn gt 0 then begin
          badrex = badrex(sort(driftarr(badrex).record))
          for jj=0,nn-1 do begin
              kk=badrex(jj)
              if kk gt 0 then driftarr(kk) = driftarr(kk-1)
          endfor
       endif

;------Even if we are doing data-based drift correction, we'd still like to correct for drifts in relative
;      position between zones. Thus, we remove the median value from each drift measurement, but keep the
;      relative variations:
       if keyword_set(dbase) then begin
         for j=0,ndrft-1 do begin
              driftarr(j).velocity = driftarr(j).velocity - median(driftarr(j).velocity )
   endfor
       endif

       for zidx=0,nz-1 do begin
;---------get a time series of drift values:
   drvals = driftarr.velocity(zidx)
   drvals = drvals - drvals(0)

;---------Interpolate the calibration drift data onto the sky times, and subtract it from the sky data:
   drift = interpol(drvals, dt, st)
   for j=0,nobs-1 do begin
       if strupcase(getenv('SDI2K_LASER_DRIFTCORR')) ne 'NO' then resarr(j).velocity(zidx) = resarr(j).velocity(zidx) - drift(j)
   endfor
       endfor
    endif

;---Do a data-based drift correction:
data_corr:
    nobs  = n_elements(resarr.velocity(0))
    nz    = total(host.operation.zones.sectors(0:host.operation.zones.fov_rings-1))
    aparr = fltarr(nobs)
    for j=0,nobs-1 do begin
;--------Whole-sky median doesn't work well in many cases. Try just central 11 zones:    
;        zdat     = resarr(j).velocity
;        zdat     = zdat(sort(zdat))
;        aparr(j) = total(zdat(0.15*nz:0.85*nz))/n_elements(zdat(0.15*nz:0.85*nz))
        zdat     = resarr(j).velocity(0:11)
        zdat     = zdat(sort(zdat))
        aparr(j) = total(zdat(3:7))/n_elements(zdat(3:7))
    endfor

;---Check for data at start and end of the night that may be lasers rather than skies. Replace aparr entries that look suspect:
    for j=min([nobs-2,10]),0,-1 do begin
        if median(resarr(j).temperature) lt 150. then begin
           aparr(j) =aparr(j+1)
        endif
    endfor
    for j=max([nobs-12,1]),nobs-1 do begin
        if median(resarr(j).temperature) lt 150. then begin
           aparr(j) =aparr(j-1)
        endif
    endfor
    

    if keyword_set(dbase) then begin
       if n_elements(aparr) gt 10 then begin
          st = (resarr.start_time  + resarr.end_time)/2.
          mcpoly_filter, st, aparr, /lowpass
          for j=0,nobs-1 do begin
              resarr(j).velocity = resarr(j).velocity - aparr(j)
          endfor
       endif
    endif

;---Force zero-median vertical velocity over the whole night:
    if n_elements(resarr) gt 3 then resarr.velocity = resarr.velocity - median(resarr.velocity(0))
end

