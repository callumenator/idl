;========================================================================
;
;  This file contains code for the SDI2000 remote console.
;
;  Mark Conde, Fairbanks, November 2000.

@sdi2kprx.pro
@obj_util.pro
@sdi2k_ncdf.pro

;========================================================================
;   This program builds the main menu for the sdi2000 plotting system.
pro sdi2kc_menubuild, base
@sdi2kinc.pro

    wid_pool, 'sdi2kc_main_menu', midx, /get
    if widget_info(midx, /valid_id) then wid_pool, 'sdi2kc_main_menu', midx, /destroy

    whoami,      dir,       file
    mc_menu,     menu_desc, 'File',                         1, /new
    mc_menu,     menu_desc,   'Exit',                       2
    mc_menu,     menu_desc, 'Operations',                   1
    mc_menu,     menu_desc,   'Check if responding',        0
    mc_menu,     menu_desc,   'Force observations to start',0
    mc_menu,     menu_desc,   'Update run-times plot',      0
    mc_menu,     menu_desc,   'Change exposure time for spectra', 0
    mc_menu,     menu_desc,   'Close both shutters',        0
    mc_menu,     menu_desc,   'Close all plugin programs',  2

    menu = cw_pdmenu (base, menu_desc, /return_full_name, delimiter='|', $
                      font=host.controller.behavior.menu_font)
    wid_pool, 'sdi2kc_main_menu', menu, /add
end


;========================================================================
; Here we setup the widget interface for the sdi2000 program.
pro sdi2kc_widgets

@sdi2kinc.pro

    widget_control, /reset
    wid_pool, /init
    device, get_screen_size=box
    base = widget_base (title='SDI Remote Console', /column, /base_align_top, space=5, kill_notify=sdi2kc_end)
    wid_pool, 'sdi2kc_top', base, /add
    sdi2kc_menubuild, base

    cmd_base   = widget_base(base)
    wid_pool, 'sdi2k_widget_cbase', cmd_base, /add

    widget_message = widget_text(base, xsize=120, ysize=25, /scroll, /editable)
    wid_pool, 'sdi2k_widget_message', widget_message, /add


    lastline = widget_base(base, /row, space=100)

    note_base   = widget_base(lastline)
    wid_pool, 'sdi2k_widget_nbase', note_base, /add

    widget_now = widget_label(lastline, /align_center, /dynamic_resize)
    wid_pool, 'sdi2kc_widget_now', widget_now, /add

    wid_pool, 'sdi2k_widget_cbase', cmd_base, /get
    widget_cmd = cw_field(cmd_base, font=host.controller.behavior.menu_font, $
          /return_events, /string, title='IDL command: ', xsize=75)
    wid_pool, 'sdi2k_widget_command', widget_cmd, /add

    wid_pool, 'sdi2k_widget_nbase', note_base, /get
    widget_note = cw_field(note_base, font=host.controller.behavior.menu_font, $
            /return_events, /string, title='        User note: ', xsize=75)
    wid_pool, 'sdi2k_widget_note', widget_note, /add


    widget_control, base, /realize
    geobase = widget_info(base, /geometry)
    widget_control, base, xoffset=box(0) - geobase.xsize - 200
    widget_control, base, yoffset=10
    widget_control, base, /clear_events, /sensitive
    sdi2k_user_message, /blank
    widget_control, widget_now, set_value= dt_tm_mk(js2jd(0d)+1, dt_tm_tojs(systime()), format='h$:m$ UT')
    if host.controller.ticker.timer_ticking then begin
       widget_control, base, timer=host.controller.ticker.timer_interval
    endif
    xmanager, 'sdi2kc', base, cleanup='sdi2kc_end', /no_block
end

;========================================================================
; This is the event handler for the sdi control program:
pro sdi2kc_event, event
@sdi2kinc.pro

   if widget_info(event.top, /valid_id) and host.controller.behavior.show_on_refresh then begin
      wid_pool, 'sdi2kc_main_menu', me, /get
      if widget_info(me, /valid_id) then widget_control, me, /show
   endif

   if tag_names(event, /structure_name) eq 'WIDGET_TIMER' then begin
       sdi2kc_timer_tick
       if host.controller.ticker.timer_ticking then widget_control, event.top, timer=host.controller.ticker.timer_interval
       return
   endif

   if event.value eq 'File|Exit'                              then sdi2kc_end
   if event.value eq 'Operations|Check if responding'         then sdi2kc_send_command, 'sdi2k_user_message, dt_tm_mk(js2jd(0d)+1, dt_tm_tojs(systime()), format="Y$-n$-0d$, h$:m$:s$ UT")'
   if event.value eq 'Operations|Force observations to start' then sdi2kc_send_command, 'sdi2k_get_timelimz, /update, /start'
   if event.value eq 'Operations|Update run-times plot'       then sdi2kc_send_command, 'sdi2k_get_timelimz, /update, plot="d:\inetpub\wwwroot\sdi_plots\run_times.gif" '
   if event.value eq 'Operations|Close both shutters'         then sdi2kc_send_command, 'sdk2k_set_shutters, laser="closed", camera="closed" '
   if event.value eq 'Operations|Close all plugin programs'   then sdi2kc_send_command, 'sdi2k_kill_plugins'
   if event.value eq 'Operations|Change exposure time for spectra' then begin
      mcchoice, 'Exposure minutes?', ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10'], choice
      scnds = 60*(choice.index + 1)
      sdi2kc_send_command, 'host.programs.spectra.integration_seconds = ' + string(scnds)
   endif

   wid_pool, 'sdi2k_widget_command', widget_cmd, /get
   if event.id eq widget_cmd then begin
      widget_control, widget_cmd, get_value=user_command
      widget_control, widget_cmd, set_value=' '
   sdi2kc_send_command, user_command
   endif
   wait, 0.001

   wid_pool, 'sdi2k_widget_note', widget_note, /get
   if event.id eq widget_note then begin
      widget_control, widget_note, get_value=user_command
      widget_control, widget_note, set_value=' '
   sdi2kc_send_command, 'sdi2k_ncdf_putnote, note="' + user_command + ' " '
   endif
   wait, 0.001

if widget_info(event.id, /valid) then widget_control, event.id, /sensitive
end

;=======================================================================================
pro sdi2kc_send_command, user_command
      fname = '\\sdi2000.dyn.pfrr.alaska.edu\data\users\sdi2000\sdi2k_script_command.pro'
      openw, 2, fname
   printf, 2, user_command
   close, 2
end

;==========================================================================
pro sdi2kc_read_log
    oneline = 'dummy'
    flush, 1
 fs = fstat(1)

READ_LOG:
 on_ioerror, no_more
    readf, 1, oneline
    sdi2k_user_message, oneline, /no_prefix
 goto, READ_LOG
NO_MORE:
 fs = fstat(1)
    flush, 1
end

;========================================================================
; This is the timer tick handler for the sdi control module:
pro sdi2kc_timer_tick
@sdi2kinc.pro

    wid_pool, 'sdi2kc_top', widx, /get
 oneline = 'Dummy'
    sdi2kc_read_log
;------Check if we need to some updating of slow-rate items:
       if host.controller.ticker.job_count ge host.controller.ticker.job_frames then begin
          host.controller.ticker.job_count = 0
          wid_pool, 'sdi2kc_widget_timez', widget_timez, /get
          widget_control, widget_timez, set_value= '               ' + $
                          dt_tm_mk(js2jd(0d)+1, host.operation.times.observing_times(0), format='Obs: h$:m$-') + $
                          dt_tm_mk(js2jd(0d)+1, host.operation.times.observing_times(1), format='h$:m$') + 'UT'
       endif
end

pro sdi2kc_open_logfile
@sdi2kinc.pro
    fname = sdi2k_filename('log')
 fname = '\\sdi2000.dyn.pfrr.alaska.edu\data' + strmid(fname, 2, 22) + '*.*'
 flis  = findfile(fname)
 flis  = flis(sort(flis))
 fname = flis(n_elements(flis)-1)
 openr, 1, fname
 sdi2kc_read_log
end

;========================================================================
; This is the cleanup procedure to be called when sdi_analysis exits:
pro sdi2kc_end, dummy
@sdi2kinc.pro
    close, 1
    wid_pool, 'sdi2kc_', widx, /destroy
    wait, 0.1
    if host.controller.behavior.close_idl_on_exit then exit
end

;========================================================================
;  This is the MAIN procedure for the analysis.  It merely does
;  all the required setting-up, then passes control to the XMANAGER
;  procedure which dispatches to the event handler if an event
;  occurs from a widget defined in this program:
@sdi2kinc.pro

wid_pool, 'sdi2kc_top', widx, /get
if not(widget_info(widx, /valid_id)) then begin
   device,   decomposed=0, retain=2
   window
   while !d.window ge 0 do wdelete
   load_pal, culz, proportion=0.5

   sdi2k_data_init, culz
   host.controller.behavior.write_log_file = 0
   view = transpose(view)
   sdi2kc_widgets
   empty
   wait, 0.1
   sdi2kc_open_logfile
   host.controller.ticker.timer_interval = 1.
endif else begin
   status = dialog_message('Cannot run more than one instance of SDI console', /error, title='Message from SDI analysis:')
endelse

end


