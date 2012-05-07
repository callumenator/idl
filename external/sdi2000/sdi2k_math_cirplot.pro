; >>>> begin comments
;==========================================================================================
;
; >>>> McObject Class: sdi2k_math_cirplot
;
; This file contains the McObject method code for sdi2k_math_cirplot objects:
;
; Mark Conde Fairbanks, October 2000.
;
; >>>> end comments
; >>>> begin declarations
;         menu_name = Wind Dial Plotter
;        class_name = sdi2k_math_cirplot
;       description = SDI Analysis - Wind Dial Plotter
;           purpose = SDI analysis
;       idl_version = 5.2
;  operating_system = Windows NT4.0 terminal server
;            author = Mark Conde
; >>>> end declarations

@sdi2k_ncdf.pro

;==========================================================================================
; This is the (required) "new" method for this McObject:

pro sdi2k_math_cirplot_new, instance, dynamic=dyn, creator=cmd
;---First, properties specific to this object:
    common cirplot_resarr, windfit
    cmd = 'instance = {sdi2k_math_cirplot, '
    cmd = cmd + 'specific_cleanup: ''sdi2k_math_cirplot_specific_cleanup'', '
    cirplot_behavior = {cirplot_behavior, prompt_for_filename: 1, $
                          menu_configurable: 0, $
                              user_editable: [1]}
    cirplot_scale = {cirplot_scale, auto_scale: 0, $
                                      yrange: [600.], $
                                 minute_step: 40., $
                           magnetic_midnight: 11.3, $
                           menu_configurable: 1, $
                               user_editable: [0,1,2,3]}
    rex = [0, n_elements(resarr)-1]

    cmd = cmd + 'behavior: cirplot_behavior, '
    cmd = cmd + 'scale: cirplot_scale, '
    cmd = cmd + 'black_bgnd: 1, '
    cmd = cmd + 'records: rex, '
;---Now add fields common to all SDI objects. These will be grouped as sub-structures:
    sdi2k_common_fields, cmd, automation=automation, geometry=geometry
;---Next, add the required fields, whose specifications are read from the 'declarations'
;   section of the comments at the top of this file:
    whoami, dir, file
    obj_reqfields, dir+file, cmd, dynamic=dyn
;---Now, create the instance:
    status = execute(cmd)
end

;==========================================================================================
; This is the event handler for events generated by the sdi2k_math_cirplot object:
pro sdi2k_math_cirplot_event, event
    common cirplot_tlist, tlist, tcen, datestr
    common cirplot_resarr, windfit
    widget_control, event.top, get_uvalue=info
    wid_pool, 'Settings: ' + info.wtitle, sidx, /get
    if not(widget_info(sidx, /valid_id)) then return
    widget_control, sidx, get_uvalue=cirplot_settings
    if widget_info(event.id, /valid_id) and cirplot_settings.automation.show_on_refresh then widget_control, event.id, /show

;---Check for a timer tick:
    if tag_names(event, /structure_name) eq 'WIDGET_TIMER' then begin
       sdi2k_math_cirplot_tik, info.wtitle
       if cirplot_settings.automation.timer_ticking then widget_control, sidx, timer=cirplot_settings.automation.timer_interval
       return
    endif

;---Get the menu name for this event:
    widget_control, event.id, get_uvalue=menu_item

    if menu_item eq 'View|Time Chooser' then begin
       mcchoice, 'Start time:', tlist, choice
       cirplot_settings.records(0) = choice.index
       mcchoice, 'End time:', tlist, choice
       cirplot_settings.records(1) = choice.index
       widget_control, sidx, set_uvalue=cirplot_settings
    endif

    if menu_item eq 'View|Toggle Background Color' then begin
       cirplot_settings.black_bgnd = 1 - cirplot_settings.black_bgnd
       widget_control, sidx, set_uvalue=cirplot_settings
    endif

    sdi2k_math_cirplot_plot, info.wtitle
    if n_elements(menu_item) eq 0 then menu_item = 'Nothing valid was selected'
end


;==========================================================================================
; This is the routine that handles timer ticks:
pro sdi2k_math_cirplot_tik, wtitle, redraw=redraw, _extra=_extra
@sdi2kinc.pro
    sdi2k_math_cirplot_plot, wtitle
end


;===========================================================================================
;
;   This does the actual plotting:

pro sdi2k_math_cirplot_plot, wtitle
@sdi2kinc.pro
    common cirplot_resarr, windfit
    common cirplot_tlist,  tlist, tcen, datestr
;---Get settings information for this instance of the output xwindow and this instance of
;   the plot program itself:
    wid_pool, wtitle, widx, /get
    if not(widget_info(widx, /valid_id)) then return
    widget_control, widx, get_uvalue=info
    wid_pool, 'Settings: ' + wtitle, sidx, /get
    if not(widget_info(sidx, /valid_id)) then return
    widget_control, sidx, get_uvalue=cirplot_settings


    if !d.name ne 'Z' and !d.name ne 'PS' then wset, info.wid

;---Set the parameter value scaling limits:
    parlimz = cirplot_settings.scale.yrange
    if cirplot_settings.scale.auto_scale then begin
       pv = [windfit.meridional_wind, windfit.zonal_wind]
       sv = sort(pv)
       nv = n_elements(sv)
       parlimz = [pv(sv(0.05*nv)), pv(sv(0.95*nv))]
    endif

;---Setup background and pen colors:
    if cirplot_settings.black_bgnd then begin
       bgnd      = host.colors.black
       pen_color = host.colors.white
    endif else begin
       bgnd      = host.colors.white
       pen_color = host.colors.black
    endelse
    erase, color=bgnd

    nx           = n_elements(zone_map(*,0))
    ny           = n_elements(zone_map(0,*))
    edge         = (nx < ny)/2

;---Setup the geometry:
    xsize = cirplot_settings.geometry.xsize
    ysize = cirplot_settings.geometry.ysize
    ptime = [2., 18.]
    mbox  = max([xsize, ysize])/2.
    angstep = (15.*cirplot_settings.scale.minute_step/60.)*!pi/180.
    cs    = 0.975*mbox/(1./(0.9*angstep) + 0.7)
    prad  = cs/(0.9*angstep)
    xcen  = xsize/2.
    ycen  = 0.6*ysize
    arrow, xcen, ycen, xcen, ycen+prad/4, $
	   color=pen_color, hsize=prad/25, thick=2
    arrow, xcen, ycen, xcen, ycen-prad/8, $
	   color=pen_color, hsize=prad/25, thick=2
    arrow, xcen, ycen, xcen+prad/8, ycen, $
	   color=pen_color, hsize=prad/25, thick=2
    arrow, xcen, ycen, xcen-prad/8, ycen, $
	   color=pen_color, hsize=prad/25, thick=2
    xyouts, xcen, ycen + prad/4 + prad/12, 'Sunward', alignment=0.5, $
		charsize=1.5, color=pen_color, /device
    xyouts, xcen, ycen - 0.5*prad, 'Magnetic Midnight', alignment=0.5, $
		charsize=1.8, color=pen_color, /device
    xyouts, xcen-prad/50, ycen - prad/20, 'Magnetic', alignment=1., $
		charsize=1.5, color=pen_color, /device
    xyouts, xcen+prad/50, ycen - prad/20, 'Pole', alignment=0., $
		charsize=1.5, color=pen_color, /device

    oldang  = -9e9

    for rec=(cirplot_settings.records(0) > 0), (cirplot_settings.records(1) < n_elements(windfit.vertical_wind)-1) do begin
        js2ymds, tcen(rec), yy, mm, dd, ss
        hourang = (15*(ss - 3600*cirplot_settings.scale.magnetic_midnight)/3600. - 90.)*!pi/180
        if (hourang - oldang) gt angstep then begin
            oldang = hourang
	    xx = (prad - 1.*cs)*cos(hourang) + xcen
	    yy = (prad - 1.*cs)*sin(hourang) + xcen
	    xyouts, xx, yy, tlist(rec), align=0.5, /device, color=pen_color, charthick=1, charsize=1.2
	    xx = prad*cos(hourang) + xcen
	    yy = prad*sin(hourang) + xcen
	    tvcircle, cs/2-1, xx, yy, host.colors.ash, thick=1
	    geo = {xcen: xx, ycen: yy, radius: cs/2., wscale: cirplot_settings.scale.yrange, $
		   perspective: 'Map', orientation: 'Magnetic Noon at Top'}
	    sdi2k_one_windplot, windfit, tcen, rec, geo, thick=1, color=pen_color, index_color=-1
	endif
    endfor

    scalestr = strcompress(string(cirplot_settings.scale.yrange, format='(i12)'), /remove_all) + ' m/s'
    arrow,  0.85*xsize - cs/4., 0.03*ysize, 0.85*xsize + cs/4., 0.03*ysize, hsize=cs/10, color=pen_color, thick=2, hthick=2
    xyouts, 0.85,  0.05, scalestr, align=0.5, /normal, color=pen_color, charthick=2, charsize=2
    xyouts, 0.015, 0.05, datestr, align=0., /normal, color=pen_color, charthick=2, charsize=2

;---Check if we need to make a GIF file:
    ;sdi2k_plugin_gif, info, js_time=timlimz(1)
end

;==========================================================================================
;   Cleanup jobs:
pro sdi2k_math_cirplot_specific_cleanup, widid
@sdi2kinc.pro
;    ncdf_close, host.netcdf(0).ncid
;    host.netcdf(0).ncid = -1
end

;==========================================================================================
; This is the (required) "autorun" method for this McObject. If no autorun action is
; needed, then this routine should simply exit with no action:

pro sdi2k_math_cirplot_autorun, instance
@sdi2kinc.pro
    common cirplot_resarr, windfit
    common cirplot_tlist, tlist, tcen, datestr
    device, get_screen_size=box
    instance.geometry.xsize = 0.9*box(0)
    instance.geometry.ysize = 0.85*min(box) + 100
    instance.automation.timer_interval = 1.
    instance.automation.timer_ticking = 0
    if instance.behavior.prompt_for_filename then begin
       spekfile = dialog_pickfile(file=skyfile, $
                                 filter='sky*.' + host.operation.header.site_code, $
                                 group=widx, title='Select a file of sky spectra: ', $
                                 path=host.operation.logging.log_directory)
    endif

    sdi2k_ncopen, spekfile, ncid, 0
    sdi2k_build_windres, ncid, windfit
    if n_elements(zone_map) lt 1 then sdi2k_build_zone_map, canvas_size = [0.95*min(box), 0.95*min(box)]
    ncdf_diminq, ncid, ncdf_dimid(ncid, 'Time'),    dummy,  maxrec
    record = 0
    tlist = strarr(maxrec)
    tcen  = dblarr(maxrec)
    for rec=record,maxrec-1 do begin
        sdi2k_read_exposure, ncid, rec
        tcen(rec) = host.programs.spectra.start_time + host.programs.spectra.integration_seconds/2
        hhmm = dt_tm_mk(js2jd(0d)+1, tcen(rec), format='h$:m$')
        tlist(rec) =  hhmm
    endfor
    sdi2k_read_exposure, host.netcdf(0).ncid, 0
    ctime = host.programs.spectra.start_time + host.programs.spectra.integration_seconds/2
    datestr = dt_tm_mk(js2jd(0d)+1, ctime, format='0d$ n$ Y$')

    ncdf_close, host.netcdf(0).ncid
    host.netcdf(0).ncid = -1
    instance.records = [0, n_elements(tlist)-1]

    mc_menu, extra_menu, 'View',                     1, event_handler='sdi2k_math_cirplot_event', /new
    mc_menu, extra_menu, 'Time Chooser',             0, event_handler='sdi2k_math_cirplot_event'
    mc_menu, extra_menu, 'Toggle Background Color',  0, event_handler='sdi2k_math_cirplot_event'
    mc_menu, extra_menu, 'Redraw',                   2, event_handler='sdi2k_math_cirplot_event'
    mnu_xwindow_autorun, instance, topname='sdi2ka_top', extra_menu=extra_menu

    sdi2k_math_cirplot_plot, instance.description
end

;==========================================================================================
; This is the (required) class method for creating a new instance of the sdi2k_math_cirplot object. It
; would normally be an empty procedure.  Nevertheless, it MUST be present, as the last procedure in
; the methods file, and it MUST have the same name as the methods file.  By calling this
; procedure, the caller forces all preceeding routines in the methods file to be compiled,
; and so become available for subsequent use:

pro sdi2k_math_cirplot
end
