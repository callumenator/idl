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

;========================================================================
;   This program builds the main menu for the sdi2000 plotting system.
pro sdi2k_menubuild, base
@sdi2kinc.pro

    wid_pool, 'sdi2k_main_menu', midx, /get
    if widget_info(midx, /valid_id) then wid_pool, 'sdi2k_main_menu', midx, /destroy
    
    whoami,      dir,       file
    mc_menu,     menu_desc, 'File',                         1, /new
    mc_menu,     menu_desc,   'Save Settings',              0
    mc_menu,     menu_desc,   'Restore Settings',           0
    mc_menu,     menu_desc,   'Restore Selected Settings',  0
    mc_menu,     menu_desc,   'Disconnect Terminal Session',1
    mc_menu,     menu_desc,   'Confirm Disconnect',         2
    mc_menu,     menu_desc,   'Exit',                       2
;---Build a configuration menu for the host structure:
    struk_menu,  menu_desc, 'Configure', host
;---Add menu items for the acquisition programs:
    mc_menu,     menu_desc, 'Programs',                     1
    mnu_pool,    search=dir+'sdi2k_prog*.pro', build=menu_desc, level=0, delimiter='|'
    mc_menu,     menu_desc,   'Close All Programs',         2
;---Add menu items for the analysis programs:
    mc_menu,     menu_desc, 'Analysis',                     1
    mnu_pool,    search=dir+'sdi2k_math*.pro', build=menu_desc, level=0, delimiter='|'
    mc_menu,     menu_desc,   'Close All Analysis',         2
    mc_menu,     menu_desc, 'Colors',                       1 
    mc_menu,     menu_desc,   'Image Palette',              0
    mc_menu,     menu_desc,   'Greyscale Palette',          0
    mc_menu,     menu_desc,   'Xpalette',                   0
    mc_menu,     menu_desc,   'Default Palette',            2
    mc_menu,     menu_desc, 'Help',                         0
       
    menu = cw_pdmenu (base, menu_desc, /return_full_name, delimiter='|', $
                      font=host.controller.behavior.menu_font)
    wid_pool, 'sdi2k_main_menu', menu, /add    
end


;========================================================================
; Here we setup the widget interface for the sdi2000 program.  
pro sdi2k_widgets

@sdi2kinc.pro

    widget_control, /reset
    wid_pool, /init
    device, get_screen_size=box
    base = widget_base (title='SDI Instrument Control', /column, /base_align_top, space=5, kill_notify=sdi2k_end)
    IRQ_widget = widget_base(base)
    widget_control, irq_widget, /managed, /update
    wid_pool, 'sdi2k_top', base, /add
    sdi2k_menubuild, base
    note_base   = widget_base(base)
    wid_pool, 'sdi2k_widget_nbase', note_base, /add
    widget_message = widget_text(base, xsize=78, ysize=host.controller.behavior.message_lines, /scroll, /editable)
    wid_pool, 'sdi2k_widget_message', widget_message, /add
    lastline = widget_base(base, /row, /grid)
    widget_rate = widget_label(lastline, /align_center, /dynamic_resize)
    wid_pool, 'sdi2k_widget_rate', widget_rate, /add
    widget_now = widget_label(lastline, /align_center, /dynamic_resize)
    wid_pool, 'sdi2k_widget_now', widget_now, /add
    widget_timez = widget_label(lastline, /align_center, /dynamic_resize)
    wid_pool, 'sdi2k_widget_timez', widget_timez, /add

    widget_control, base, /realize
    geobase = widget_info(base, /geometry)
    widget_control, base, xoffset=box(0) - geobase.xsize - 200
    widget_control, base, yoffset=10
    status = call_external(host.controller.behavior.dll_file, "Save_Widget_ID", $
             IRQ_widget, value=bytarr(3), /cdecl)
    widget_control, base, /clear_events, /sensitive
    sdi2k_user_message, /blank
    sdi2k_user_message, "SDI Control started"
    widget_control, widget_rate,  set_value='Waiting for video...               '
    widget_control, widget_now, set_value= dt_tm_mk(js2jd(0d)+1, dt_tm_tojs(systime()), format='h$:m$ UT')
    widget_control, widget_timez, set_value= '               ' + $
                    dt_tm_mk(js2jd(0d)+1, host.operation.times.observing_times(0), format='Obs: h$:m$-') + $
                    dt_tm_mk(js2jd(0d)+1, host.operation.times.observing_times(1), format='h$:m$') + 'UT'
    if host.controller.ticker.timer_ticking then begin
       widget_control, base, timer=host.controller.ticker.timer_interval
       sdi2k_user_message, "Control timer started."
    endif
    xmanager, 'sdi2k', base, cleanup='sdi2k_end', /no_block
end

;========================================================================
; This is the event handler for the sdi control program:
pro sdi2k_event, event
@sdi2kinc.pro

if (event.id eq irq_widget) then begin
   sdi2k_timer_tick
   wait, 0.002
;--Stamp the first few bytes of the image to acknowledge that it has been seen by IDL:
   scene(1, 0:4) = host.hardware.video.scene_stamp
   status = call_external(host.controller.behavior.dll_file, "GrabAnother")
   status = call_external(host.controller.behavior.dll_file, "EnableIRQ", value=bytarr(3), /cdecl)
   wait, 0.001
   return
endif else begin
   if widget_info(event.top, /valid_id) and host.controller.behavior.show_on_refresh then begin
      wid_pool, 'sdi2k_main_menu', me, /get
      if widget_info(me, /valid_id) then widget_control, me, /show
   endif
   if tag_names(event, /structure_name) eq 'WIDGET_TIMER' then begin
;------Check if we need to some updating of slow-rate items:
       host.controller.ticker.job_count = host.controller.ticker.job_count + 1
       if host.controller.ticker.job_count ge host.controller.ticker.job_frames then begin
          host.controller.ticker.job_count = 0
          sdi2k_scheduler
          sdi2k_run_script
          sdi2k_kill_watchdog_file
       endif
;------Check if we still seem to be getting video:
       video_age = systime(1) - host.hardware.video.frame_time
       if video_age gt 5. then begin
          sdi2k_user_message, "Long video gap detected: " + $
                              strcompress(string(video_age, format='(f10.1)')) + $
                              " seconds"
          wait, 0.5
          if video_age gt 60 then sdi2k_request_reboot, "Lost video, trying to reboot..."
          if video_age gt 20 then sdi2k_restart_video
          if total(abs((scene(1,0:4) - host.hardware.video.scene_stamp))) eq 0 then begin
             sdi2k_user_message, "Calling 'GrabAnother' after video gap of " + strcompress(string(video_age, format='(f10.1)')) + " seconds"
             status = call_external(host.controller.behavior.dll_file, "Reset_Frame")
             wait, 0.1
             status = call_external(host.controller.behavior.dll_file, "GrabAnother")
          endif
       endif
;------Reset the timer, so that this routine will get invoked again:
       if host.controller.ticker.timer_ticking then widget_control, event.top, timer=host.controller.ticker.timer_interval
       return
   endif
   
   mnu_pool, dispatch=event
   if event.value eq 'File|Restore Settings'              then sdi2k_load_settings
   if event.value eq 'File|Restore Selected Settings'     then sdi2k_load_settings, /query
   if event.value eq 'File|Save Settings'                 then sdi2k_save_settings
   if event.value eq 'File|Exit'                          then sdi2k_end
   if event.value eq 'Programs|Close All Programs'        then sdi2k_kill_plugins, select='Programs'
   if event.value eq 'Analysis|Close All Analysis'        then sdi2k_kill_plugins, select='Analysis'
   if event.value eq 'Colors|Image Palette'               then $
      xloadct, bottom=host.colors.imgmin, ncolors=host.colors.imgmax - host.colors.imgmin + 1
   if event.value eq 'Colors|Greyscale Palette'           then $
      xloadct, bottom=host.colors.greymin, ncolors=host.colors.greymax - host.colors.greymin + 1
   if event.value eq 'Colors|Xpalette'                    then xpalette
   if event.value eq 'Colors|Default Palette'             then load_pal, culz, proportion=0.5
   if event.value eq 'File|Disconnect Terminal Session|Confirm Disconnect' then sdi2k_terminal_disconnect

   fields    = str_sep(event.value, '|', /remove_all)
   if n_elements(fields) gt 0 then begin
      if fields(0) eq 'Configure' then begin
         pstring = 'host'
         sd2k_extract_substruk, host, fields(1:*), pstring
         item = host
         status = execute('item = ' + pstring)
         obj_edt, item, tagz=item.user_editable
         status = execute(pstring + ' = item')
      endif
   endif
   wid_pool, 'sdi2k_widget_note', widget_note, /get
   if event.id eq widget_note then sdi2k_ncdf_putnote
   wait, 0.001
endelse

if widget_info(event.id, /valid) then widget_control, event.id, /sensitive
end

;========================================================================
; This is the timer tick handler for the sdi control module:
pro sdi2k_timer_tick
@sdi2kinc.pro

    wid_pool, 'sdi2k_top', widx, /get
;---Check if a new (unstamped) frame has arrived:
    if total(abs((scene(1,0:4) - host.hardware.video.scene_stamp))) ne 0 then begin
       host.hardware.video.frame_count = host.hardware.video.frame_count + 1
       if viewscale ne 1 then begin
          view = transpose(reverse(rebin(scene, host.hardware.video.columns, host.hardware.video.rows, sample=host.hardware.video.rebin_sample)))
       endif else view = scene
;------Send an event to each registered SDI program to advise of the new frame:
       wid_pool, 'Settings: SDI Program - ', proglis, /get
       if proglis(0) ne -1L then begin
          for j=0,n_elements(proglis)-1 do begin
              widget_control, proglis(j), send_event={id: widx, $
                                                     top: widx, $
                                                 handler: proglis(j), $
                                                    name: 'NewFrame'}
          endfor
       endif
    endif
       if host.hardware.video.frame_count ge host.controller.ticker.refresh_frames then begin
          host.hardware.video.frame_rate = (host.hardware.video.frame_count)/(systime(1) - host.hardware.video.frame_time)
          host.hardware.video.frame_count = 0
          host.hardware.video.frame_time = systime(1)
          frate = "   Frame Rate: " + strcompress(string(host.hardware.video.frame_rate, format='(f7.1)') + " Hz               ")
          wid_pool, 'sdi2k_widget_now',   widget_now,   /get
          widget_control, widget_now, set_value= dt_tm_mk(js2jd(0d)+1, dt_tm_tojs(systime()), format='h$:m$ UT')
          wid_pool, 'sdi2k_widget_rate',  widget_rate,  /get
          wid_pool, 'sdi2k_widget_timez', widget_timez, /get
          if widget_info(widget_rate, /valid) then widget_control, widget_rate, set_value=frate
          widget_control, widget_timez, set_value= '               ' + $
                          dt_tm_mk(js2jd(0d)+1, host.operation.times.observing_times(0), format='Obs: h$:m$-') + $
                          dt_tm_mk(js2jd(0d)+1, host.operation.times.observing_times(1), format='h$:m$') + 'UT'

;---------Update the MV-1000 digitizing levels:
          status = call_external(host.controller.behavior.dll_file, "SetLevels", $
                                 host.hardware.video.top_level_a2d, $
                                 host.hardware.video.bottom_level_a2d, $
                                 host.hardware.video.clamp_level, $
                                 host.hardware.video.gain, $
                                 host.hardware.video.offset, $
                                 host.hardware.video.clamp_mode, value=bytarr(5), /cdecl)
;---------Update the MV-1000 filter settings:
          status = call_external(host.controller.behavior.dll_file, "SetFilter", $
                                  host.hardware.video.frequency_cutoff, $
                                  host.hardware.video.high_frequency_boost, value=bytarr(2), /cdecl)
;---------Update the MV-1000 trigger mode:
          status = call_external(host.controller.behavior.dll_file, "SetTriggerMode", $
                                  host.hardware.video.external_trigger, $
                                  host.hardware.video.external_trigger_high, value=bytarr(2), /cdecl)
          flash_LED
       endif
end

;========================================================================
; This is the cleanup procedure to be called when sdi2000 exits:
pro sdi2k_end, dummy
@sdi2kinc.pro
    sdi2k_user_message, 'SDI control shutting down'
    sdi2k_set_shutters, camera='closed', laser='closed'
    status = call_external(host.controller.behavior.dll_file, "EndGrab", /cdecl)
    status = call_external(host.controller.behavior.dll_file, "CloseBaseboard", /cdecl)
    sdi2k_ncdf_close
    wid_pool, 'sdi2k_', widx, /destroy
    wait, 0.1
    if host.controller.behavior.close_idl_on_exit then exit
end

;========================================================================
;  This is the MAIN procedure for the sdi2000 program.  It merely does
;  all the required setting-up, then passes control to the XMANAGER
;  procedure which dispatches to the event handler if an event
;  occurs from a widget defined in this program:
@sdi2kinc.pro

wid_pool, 'sdi2k_top', widx, /get
if not(widget_info(widx, /valid_id)) then begin
   device,   decomposed=0, retain=2
   window
   while !d.window ge 0 do wdelete
   load_pal, culz, proportion=0.5

   sdi2k_data_init, culz
   sdi2k_ncdf_close
   sdi2k_widgets
   empty
   wait, 0.1
   sdi2k_get_timelimz, /update, plot='d:\inetpub\wwwroot\sdi_plots\run_times.gif'
;   sdi2k_default_config
   cfile  = host.hardware.video.camera_config_file
   status = call_external(host.controller.behavior.dll_file, "BeginGrab", scene, xfer_flag, scale, $
                          long(n_elements(scene(*,0))), $
                          long(n_elements(scene(0,*))), $
                          cfile, value=bytarr(6), /cdecl)
   status = call_external(host.controller.behavior.dll_file, "SetTriggerMode", $
                          host.hardware.video.external_trigger, host.hardware.video.external_trigger_high, $
                          value=bytarr(2), /cdecl)
   status = call_external(host.controller.behavior.dll_file, "Save_Window_Handle", "IDL #93958-0 - Scanning Doppler Imager" , value=1b, /cdecl)
   if host.hardware.video.interrupt_driven eq 1 then begin
      status = call_external(host.controller.behavior.dll_file, "EnableIRQ", value=bytarr(3), /cdecl)
      sdi2k_user_message, "Video interrupts enabled"
   endif
   sdi2k_open_baseboard
   sdi2k_set_shutters, camera='closed', laser='closed'
   status = sdi2k_filter_interface(command='2 mv')  ; #####
endif else begin
   status = dialog_message('Cannot run more than one instance of SDI2000', /error, title='Message from sdi2000:') 
endelse

end


