; >>>> begin comments
;==========================================================================================
;
; >>>> McObject Class: sdi2k_prog_scanmon
;
; This file contains the McObject method code for sdi2k_prog_scanmon objects:
;
; Mark Conde (Mc), Fairbanks, Septemebr 2000.
;
; >>>> end comments
; >>>> begin declarations
;         menu_name = Scan Monitor
;        class_name = sdi2k_prog_scanmon
;       description = SDI Program - Scan Monitor
;           purpose = SDI operation
;       idl_version = 5.2
;  operating_system = Windows NT4.0 terminal server 
;            author = Mark Conde
; >>>> end declarations


;==========================================================================================
; This is the (required) "new" method for this McObject:

pro sdi2k_prog_scanmon_new, instance, dynamic=dyn, creator=cmd
;---First, properties specific to this object:
    cmd = 'instance = {sdi2k_prog_scanmon, '
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
; This is the event handler for events generated by the sdi2k_prog_scanmon object:
pro sdi2k_prog_scanmon_event, event
    widget_control, event.top, get_uvalue=info
    wid_pool, 'Settings: ' + info.wtitle, widx, /get
    if not(widget_info(widx, /valid_id)) then return
    widget_control, widx, get_uvalue=scanmon_settings
    if widget_info(event.id, /valid_id) and scanmon_settings.automation.show_on_refresh then widget_control, event.id, /show

;---Check for a new frame event sent by the control module:
    nm      = 0
    matched = where(tag_names(event) eq 'NAME', nm)
    if nm gt 0 then begin
       if event.(matched(0)) eq 'NewFrame' then sdi2k_prog_scanmon_tik, info.wtitle
       return
    endif

;---Get the menu name for this event:
    widget_control, event.id, get_uvalue=menu_item
    if n_elements(menu_item) eq 0 then menu_item = 'Nothing valid was selected'
;---Handle other menu events:
    if (menu_item eq 'Exit') then sdi2k_scanmon_end

end

;==========================================================================================
; This is the routine that updates the actual plot:
pro sdi2k_prog_scanmon_tik, wtitle, redraw=redraw, _extra=_extra
@sdi2kinc.pro

;---Get settings information for this instance of the output xwindow and this instance of 
;   the plot program itself:
    wid_pool, wtitle, widx, /get
    if not(widget_info(widx, /valid_id)) then return
    widget_control, widx, get_uvalue=info
    wid_pool, 'Settings: ' + wtitle, sidx, /get
    if not(widget_info(sidx, /valid_id)) then return
    widget_control, sidx, get_uvalue=scanmon_settings
    
    stripoff = 'Parallelism: ' + string(host.hardware.etalon.parallelism_offset(0), format='(i3.3)') + ', ' + $
                                 string(host.hardware.etalon.parallelism_offset(1), format='(i3.3)') + ', ' + $
                                 string(host.hardware.etalon.parallelism_offset(2), format='(i3.3)') 
    widget_control, info.chan,   set_slider_max=host.hardware.etalon.scan_channels
    widget_control, info.espc,   set_slider_max=1024.
    widget_control, info.chan,   set_value=host.hardware.etalon.current_channel
    widget_control, info.espc,   set_value=host.hardware.etalon.current_spacing
    widget_control, info.paroff, set_value=stripoff

;---Check if we need to make a GIF file:
    ;sdi2k_plugin_gif, info, js_time=timlimz(1)
end

pro sdi2k_scanmon_end, dummy
@sdi2kinc.pro
    wid_pool, 'SDI Program - Scan Monitor', widx, /get
    if not(widget_info(widx, /valid_id)) then return
    wid_pool, 'SDI Program - Scan Monitor', widx, /destroy
end


;==========================================================================================
; This is the (required) "autorun" method for this McObject. If no autorun action is 
; needed, then this routine should simply exit with no action:

pro sdi2k_prog_scanmon_autorun, instance
@sdi2kinc.pro
;---Return if we already have an instance running:
    wid_pool, 'SDI Program - Scan Monitor', widx, /get
    if widget_info(widx, /valid_id) then begin
       status = dialog_message('Cannot start a second instance of the scan monitor.')
       return
    endif

;---Create the control window:
    wtitle = 'SDI Program - Scan Monitor'
    wid_pool, 'sdi2k_top', widx, /get
    top = WIDGET_BASE(title=wtitle, /column)
    instance.id = top
;---Create a dummy base widget inside the top-level base for the xwindow.  We will 
;   use the user-value field of this widget to store the properties settings for this plugin:
    settings = widget_base(top, /align_center, /column, group_leader=top)
    chan     = widget_slider(settings, xsize=280, title="Scan Channel")
    espc     = widget_slider(settings, xsize=280, title="Etalon Spacing")
    paroff   = widget_label(settings, /align_center, /dynamic_resize)
    info = {wtitle: wtitle, drawid: top, paroff: paroff, chan: chan, espc: espc}

    widget_control, top, set_uvalue=info

;---Register the plot xwindow name and top-level widget index with "wid_pool":
    widget_control, top, get_uvalue=info
    wid_pool, info.wtitle, top, /add

    widget_control, top, /realize
    xmanager, 'sdi2k_prog_scanmon', top, group_leader=widx, cleanup='sdi2k_scanmon_end', /no_block

    wid_pool, 'Settings: ' + info.wtitle, settings, /add
    widget_control, settings, set_uvalue=instance
end

;==========================================================================================
; This is the (required) class method for creating a new instance of the sdi2k_prog_scanmon object. It
; would normally be an empty procedure.  Nevertheless, it MUST be present, as the last procedure in 
; the methods file, and it MUST have the same name as the methods file.  By calling this
; procedure, the caller forces all preceeding routines in the methods file to be compiled, 
; and so become available for subsequent use:

pro sdi2k_prog_scanmon
end
