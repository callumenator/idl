;========================================================================
;
;  This file contains code for the top-level sdi analysis program.
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
pro sdi2ka_menubuild, base
@sdi2kinc.pro

    wid_pool, 'sdi2ka_main_menu', midx, /get
    if widget_info(midx, /valid_id) then wid_pool, 'sdi2ka_main_menu', midx, /destroy
    
    whoami,      dir,       file
    mc_menu,     menu_desc, 'File',                         1, /new
    mc_menu,     menu_desc,   'NCBrowse',                   0
    mc_menu,     menu_desc,   'Batch Analysis Run',         0
    mc_menu,     menu_desc,   'Level 2 File Export',        0
    mc_menu,     menu_desc,   'Exit',                       2
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
    wid_pool, 'sdi2ka_main_menu', menu, /add    
end


;========================================================================
; Here we setup the widget interface for the sdi2000 program.  
pro sdi2ka_widgets

@sdi2kinc.pro

    widget_control, /reset
    wid_pool, /init
    device, get_screen_size=box
    base = widget_base (title='SDI Analysis Control', /column, /base_align_top, space=5, kill_notify=sdi2ka_end)
    wid_pool, 'sdi2ka_top', base, /add
    sdi2ka_menubuild, base
    widget_message = widget_text(base, xsize=78, ysize=host.controller.behavior.message_lines, /scroll, /editable)
    wid_pool, 'sdi2k_widget_message', widget_message, /add
    lastline = widget_base(base, /row, /grid)
;    widget_now = widget_label(lastline, /align_center, /dynamic_resize)
;    wid_pool, 'sdi2ka_widget_now', widget_now, /add

    widget_control, base, /realize
    geobase = widget_info(base, /geometry)
    widget_control, base, xoffset=box(0) - geobase.xsize - 200
    widget_control, base, yoffset=10
    widget_control, base, /clear_events, /sensitive
    host.controller.behavior.write_log_file = 0
    sdi2k_user_message, /blank
    sdi2k_user_message, "SDI Analysis is ready"
;    widget_control, widget_now, set_value= dt_tm_mk(js2jd(0d)+1, dt_tm_tojs(systime()), format='h$:m$ UT')
    if host.controller.ticker.timer_ticking then begin
       widget_control, base, timer=host.controller.ticker.timer_interval
       sdi2k_user_message, "Control timer started."
    endif
    xmanager, 'sdi2ka', base, cleanup='sdi2ka_end', /no_block
end

;========================================================================
; This is the event handler for the sdi control program:
pro sdi2ka_event, event
@sdi2kinc.pro

   if widget_info(event.top, /valid_id) and host.controller.behavior.show_on_refresh then begin
      wid_pool, 'sdi2ka_main_menu', me, /get
      if widget_info(me, /valid_id) then widget_control, me, /show
   endif

   if tag_names(event, /structure_name) eq 'WIDGET_TIMER' then begin
       if host.controller.ticker.timer_ticking then widget_control, event.top, timer=host.controller.ticker.timer_interval
       return
   endif
   
   mnu_pool, dispatch=event
   if event.value eq 'File|NCBrowse'                      then ncbrowse, path='d:\users\sdi2000\data', filter=['sky*.pf', 'ins*.pf']
   if event.value eq 'File|Batch Analysis Run'            then begin
                                                               sdi2k_user_message, 'Starting analysis batch run...'
							       skylo = dialog_pickfile(filter='sky*.pf', path='d:\users\sdi2000\data\', title='First file to process?', get_path=path)
							       skyhi = dialog_pickfile(filter='sky*.pf', path=path, title='Last file to process?', get_path=path)
							       skylo = strupcase(skylo)
							       skyhi = strupcase(skyhi)
							       optns = ['None', 'Fit Winds', 'Fit Spectra and Winds', 'Cancel']
							       mcchoice, 'Analysis Phase?', optns, choice
							       if choice.name ne 'Cancel' then begin
							          optns = ['Yes', 'No']
							          mcchoice, 'Plot Also?', optns, plot_choice
                                                                  sdi2k_batch_ncquery, file_desc, path=path
							          for j=0,n_elements(file_desc)-1 do begin
                                                                      if file_desc(j).name ge skylo and file_desc(j).name le skyhi then begin
                                                                         sdi2k_user_message, 'Processing - ' + file_desc(j).name
                                                                         if choice.name eq 'Fit Spectra and Winds' then begin
                                                                            sdi2k_batch_spekfitz, file_desc(j).name, file_desc(j).insfile
                                                                         endif
                                                                         if choice.name eq 'Fit Winds' then begin
                                                                            sdi2k_batch_windfitz, file_desc(j).name, resarr, windfit
                                                                         endif
                                                                         if plot_choice.name eq 'Yes' then sdi2k_batch_plotz, file_desc(j).name, resarr, windfit ;####################
   								      endif
							          endfor
							          sdi2k_user_message, "Analysis batch run complete."
							       endif
                                                          endif
   if event.value eq 'File|Level 2 File Export'           then begin
                                                               sdi2k_user_message, 'Starting file export...'
							       skylo = dialog_pickfile(filter='sky*.pf', path='d:\users\sdi2000\data\', title='First file to export?', get_path=path)
							       skyhi = dialog_pickfile(filter='sky*.pf', path=path, title='Last file to export?', get_path=path)
							       skylo = strupcase(skylo)
							       skyhi = strupcase(skyhi)
                                                                  sdi2k_batch_ncquery, file_desc, path=path
							          for j=0,n_elements(file_desc)-1 do begin
                                                                      if file_desc(j).name ge skylo and file_desc(j).name le skyhi then begin
                                                                         if file_desc(j).analysis_level eq 'Winds Fitted' then begin
                                                                            sdi2k_user_message,   'Processing - ' + file_desc(j).name
                                                                            sdi2k_batch_distiller, file_desc(j).name, resfile, log_filter={s_logfil, key: 'SDI', desired_values: ['GOOD'], default: 'REJECT'}
                                                                         endif
   								      endif
							          endfor
							          sdi2k_user_message, "File export complete."
                                                          endif
   if event.value eq 'File|Exit'                          then sdi2ka_end
   if event.value eq 'Programs|Close All Programs'        then sdi2k_kill_plugins, select='Program'
   if event.value eq 'Analysis|Close All Analysis'        then sdi2k_kill_plugins, select='Analysis'
   if event.value eq 'Colors|Image Palette'               then $
      xloadct, bottom=host.colors.imgmin, ncolors=host.colors.imgmax - host.colors.imgmin + 1
   if event.value eq 'Colors|Greyscale Palette'           then $
      xloadct, bottom=host.colors.greymin, ncolors=host.colors.greymax - host.colors.greymin + 1
   if event.value eq 'Colors|Xpalette'                    then xpalette
   if event.value eq 'Colors|Default Palette'             then load_pal, culz, proportion=0.5

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
   wait, 0.001

if widget_info(event.id, /valid) then widget_control, event.id, /sensitive
end

;========================================================================
; This is the timer tick handler for the sdi control module:
pro sdi2ka_timer_tick
@sdi2kinc.pro

    wid_pool, 'sdi2ka_top', widx, /get
;------Check if we need to some updating of slow-rate items:
       if host.controller.ticker.job_count ge host.controller.ticker.job_frames then begin
          host.controller.ticker.job_count = 0
          wid_pool, 'sdi2ka_widget_timez', widget_timez, /get
          widget_control, widget_timez, set_value= '               ' + $
                          dt_tm_mk(js2jd(0d)+1, host.operation.times.observing_times(0), format='Obs: h$:m$-') + $
                          dt_tm_mk(js2jd(0d)+1, host.operation.times.observing_times(1), format='h$:m$') + 'UT'
       endif
end

;========================================================================
; This is the cleanup procedure to be called when sdi_analysis exits:
pro sdi2ka_end, dummy
@sdi2kinc.pro
    sdi2k_user_message, 'SDI analysis is shutting down'
    sdi2k_ncdf_close
    wid_pool, 'sdi2ka_', widx, /destroy
    wait, 0.1
    if host.controller.behavior.close_idl_on_exit then exit
end

;========================================================================
;  This is the MAIN procedure for the analysis.  It merely does
;  all the required setting-up, then passes control to the XMANAGER
;  procedure which dispatches to the event handler if an event
;  occurs from a widget defined in this program:
@sdi2kinc.pro

wid_pool, 'sdi2ka_top', widx, /get
if not(widget_info(widx, /valid_id)) then begin
   device,   decomposed=0, retain=2
   window
   while !d.window ge 0 do wdelete
   load_pal, culz, proportion=0.5

   sdi2k_data_init, culz
   host.controller.ticker.timer_ticking = 0
   view = transpose(view)
   sdi2k_ncdf_close
   sdi2ka_widgets
   empty
   wait, 0.1
endif else begin
   status = dialog_message('Cannot run more than one instance of SDI analysis', /error, title='Message from SDI analysis:') 
endelse

end


