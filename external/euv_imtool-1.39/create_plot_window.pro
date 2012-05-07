;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; create_plot_window - create a window to hold the radial and
;                      azimuthal plots
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

; last modified: 12-May-2003

pro create_plot_window

@euv_imtool-commons

; ------------------------------
; create a top-level base widget
; ------------------------------
wBaseP = widget_base(/col, xpad=10, ypad=10, title='IMAGE EUV Image Tool - Plot Window')
wBasePplt = widget_base(wBaseP,/row)
wBasePdmp = widget_base(wBaseP,/row)


; ----------------------------------------------------------
; create draw widgets for the radial/azimuthal plot windows
; ----------------------------------------------------------
wDrawPa = widget_draw(wBasePplt,xsize=xplotsize,ysize=yplotsize, uvalue=6, $
                      graphics_level=2,retain=backingstore,/expose_events)
wDrawPr = widget_draw(wBasePplt,xsize=xplotsize,ysize=yplotsize, uvalue=7, $
                      graphics_level=2,retain=backingstore,/expose_events)

; create a button to dump the data to a file
wDump = widget_button(wBasePdmp, value='dump data', uval=15)
label = widget_label(wBasePdmp,value='base file name (.rad and .azi will be added):')
dumpfilew = widget_text(wBasePdmp,value='',xsize=20,ysize=1,/editable)

; -------------------------------------------------------------------
; create a checkboxs for y axis log scaling and addition of stretched
; plot overlay
; -------------------------------------------------------------------
wBaseChk = widget_base(wBasePdmp, /row,/nonexclusive)
lsw = widget_button(wBaseChk,value='log scale',uvalue=9)
widget_control, lsw, set_button=ra_log_scale

psw = widget_button(wBaseChk,value='overlay stretched plot',uvalue=8)
widget_control, psw, set_button=plot_stretch

wBaseDrop = widget_base(wBasePdmp, /row)
mult_list_label = widget_label(wBaseDrop, value='Multiplier:')
mult_list = widget_droplist(wBaseDrop,uvalue=10,value=multiplier_choices)

if(not plot_stretch) then begin
    widget_control, mult_list_label, sensitive=0
    widget_control, mult_list, sensitive=0
endif

; ---------------------------------------------------------------
; make the window visible and register it with XMANAGER to handle
; events.
; ---------------------------------------------------------------
widget_control, wBaseP, /realize
xmanager, 'EUV_IMTOOL_event', wBaseP, event_handler='plot_window_event'

; -------------------------------------------
; get window object references for future use
; -------------------------------------------
widget_control, wDrawPa, get_value=windowpa
widget_control, wDrawPr, get_value=windowpr

; ------------
; set flag
; ------------
plot_window_exists = 1

end



