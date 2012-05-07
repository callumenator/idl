
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; create a modal dialog to get a user-supplied start time
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

; last modified: 26-Apr-2001

pro get_start_time, event, wtitle=wtitle, fitsout=fitsout

@euv_imtool-commons

if (keyword_set(wtitle)) then wintitle=wtitle else wintitle='Start Time'

if (keyword_set(fitsout)) then ftime = fitsout else ftime = 0

; -----------------------
; create the base widgets
; -----------------------
topw = widget_base(group_leader=event.top,/modal, $
                   title=wintitle,xoffset=300,yoffset=300,/col)
inputw = widget_base(topw,/row)
tcol1  = widget_base(inputw,/col)
tcol2  = widget_base(inputw,/col)
tcol3  = widget_base(inputw,/col)
tcol4  = widget_base(inputw,/col)
quickw = widget_base(topw,/row,/nonexclusive)
butw   = widget_base(topw,/row)

; ------------------------
; create the other widgets
; ------------------------
slabel = widget_label(tcol1,value='year')
slabel = widget_label(tcol2,value='day')
slabel = widget_label(tcol3,value='hour')
slabel = widget_label(tcol4,value='minute')

syearw = widget_text(tcol1,value=STRING(start_year,format='(i4)'), $
                     xsize=4,ysize=1,/editable)
sdoyw  = widget_text(tcol2,value=STRING(start_doy,format='(i3)'), $
                     xsize=3,ysize=1,/editable)
shourw = widget_text(tcol3,value=STRING(start_hour,format='(i2)'), $
                     xsize=2,ysize=1,/editable)
sminw  = widget_text(tcol4,value=STRING(start_minute,format='(i2)'), $
                     xsize=2,ysize=1,/editable)

ql = widget_button(quickw,value='Use quicklook data',uvalue=9)
widget_control, ql, set_button=quicklook

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
xmanager, 'EUV_IMTOOL_event', topw,event_handler='start_time_event'

end



