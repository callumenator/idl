;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; create_zoom_window - create a window for the enlarged image display
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

; last modified: 26-Mar-2004

pro create_zoom_window

@euv_imtool-commons

; ------------------------------
; create a top-level base widget
; ------------------------------
wBase3 = widget_base(/col, xpad=10, ypad=10, title='IMAGE EUV Image Tool - Zoomed Display')

; ---------------------------------------------------------
; create a draw widget for the enlarged image display
; ---------------------------------------------------------
if(expanded_zoom) then ydim_zoom = ydim3 else ydim_zoom = ydim3/2
wDraw3 = widget_draw(wBase3,xsize=xdim3,ysize=ydim_zoom, uvalue=5, $
                     graphics_level=2,retain=backingstore,$
                     /expose_events,/button_events,/motion_events,$
                     /tracking_events)

; -------------------------------------------
; create a button to expand/shrink the window
; -------------------------------------------
if(expanded_zoom) then but_name = "Shrink" else but_name = "Expand"
expand_button = widget_button(wBase3,value=but_name,uvalue=43)
if(do_plots) then widget_control,expand_button, sensitive=0

; ---------------------------------------------------------------
; make the window visible and register it with XMANAGER to handle
; events
; ---------------------------------------------------------------
widget_control, wBase3, /realize
xmanager, 'EUV_IMTOOL_event', wBase3, event_handler='euv_imtool_event3'

; -------------------------------------------
; get window object references for future use
; -------------------------------------------
widget_control, wDraw3, get_value=window3
window3 -> Erase, color=[0,50,50]

; ------------
; set flag
; ------------
zoom_window_exists = 1

; -----------------------------------------------------
; show clicked points and center circle, if appropriate
; -----------------------------------------------------
if(nclicks ge 1) then click_points3 -> SetProperty, hide = 0
if(centered) then center_ellipse3 -> SetProperty, hide=0

; ----------------------------------
; bring the zoomed window up to date
; ----------------------------------
update_image_displays
redraw_views

end
