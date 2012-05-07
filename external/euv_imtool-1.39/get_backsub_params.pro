
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; create a modal dialog to get user-supplied background subtraction
; parameters
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

; last modified: 4-May-2001

pro get_backsub_params, event

@euv_imtool-commons

; -----------------------
; create the base widgets
; -----------------------
topw = widget_base(group_leader=event.top,/modal, $
                   title='Background Subtraction Parameters',xoffset=300,yoffset=300,/col)
titlew = widget_base(topw,/row)
tcol1  = widget_base(topw,/row)
tcol2  = widget_base(topw,/row)
debandw = widget_base(topw,/row,/nonexclusive)
butw   = widget_base(topw,/row)

; ------------------------
; create the other widgets
; ------------------------
slabel = widget_label(titlew,value='Background area:')

slabel = widget_label(tcol1,value='Minimum, Maximum X')
slabel = widget_label(tcol2,value='Minimum, Maximum Y')

bminxw   = widget_text(tcol1,value=STRING(bminx,format='(i3)'), $
                     xsize=3,ysize=1,/editable)
bmaxxw   = widget_text(tcol1,value=STRING(bmaxx,format='(i3)'), $
                     xsize=3,ysize=1,/editable)
bminyw   = widget_text(tcol2,value=STRING(bminy,format='(i3)'), $
                     xsize=3,ysize=1,/editable)
bmaxyw   = widget_text(tcol2,value=STRING(bmaxy,format='(i3)'), $
                     xsize=3,ysize=1,/editable)


db = widget_button(debandw,value='de-banding subtraction',uvalue=9)
widget_control, db, set_button=deband

; ----------------
; make the buttons
; ----------------
okbut=widget_button(butw,value='OK',uvalue=10)
cancelbut=widget_button(butw,value='Cancel',uvalue=11)

widget_control,topw,default_button=okbut
widget_control,topw,cancel_button=cancel

; ----------
; let it rip
; ----------
widget_control,topw,/realize
xmanager, 'EUV_IMTOOL_event', topw,event_handler='backsub_params_event'

end




