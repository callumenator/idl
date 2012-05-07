;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; create_full_window - create a window for the full frame display
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

; last modified: 11-Aug-2003

pro create_full_window

@euv_imtool-commons

; ------------------------------
; create a top-level base widget
; ------------------------------
wBase4 = widget_base(/col, xpad=10, ypad=10, title='IMAGE EUV Image Tool - Full Frame Display')

; ---------------------------------------------------------
; create a draw widget for the enlarged image display
; ---------------------------------------------------------
wDraw4 = widget_draw(wBase4,xsize=mxdim,ysize=mydim, uvalue=40, $
                     graphics_level=2,retain=backingstore,$
                     /expose_events,/button_events,/motion_events,$
                     /tracking_events)

; ----------------------------------------------------
; create widgets to display ra and dec cursor readouts
; and the data vaule readout
; ----------------------------------------------------
wBase4l = widget_base(wBase4,/row)
wlabel  = widget_label(wBase4l, value="Right Ascension")
w_ra    = widget_text(wBase4l, value="",xsize=6)
wlabel  = widget_label(wBase4l, value="Declination")
w_dec   = widget_text(wBase4l, value="",xsize=6)
;;wlabel  = widget_label(wBase4l, value="Data value = ")
;;fullreadoutw = widget_text(wBase4l, value="",xsize=18,ysize=1)

; ---------------------------------------------------------------
; make the window visible and register it with XMANAGER to handle
; events
; ---------------------------------------------------------------
widget_control, wBase4, /realize
xmanager, 'EUV_IMTOOL_event', wBase4, event_handler='euv_imtool_event4'

; -------------------------------------------
; get window object references for future use
; -------------------------------------------
widget_control, wDraw4, get_value=window4
window4 -> Erase, color=[0,0,0]

; ------------
; set flag
; ------------
full_window_exists = 1

; -----------------------------------------------------
; show clicked points and center circle, if appropriate
; -----------------------------------------------------
;;if(nclicks ge 1) then click_points3 -> SetProperty, hide = 0
;;if(centered) then center_ellipse3 -> SetProperty, hide=0

; ----------------------------------
; bring the zoomed window up to date
; ----------------------------------
update_image_displays
redraw_views

end
