;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; destroy_zoom_window - remove the zoomed image display window
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

; last modified: 6-Sep-2001

pro destroy_zoom_window

@euv_imtool-commons

; -------------------
; hide clicked points
; -------------------
click_points3 -> SetProperty, hide=1

; ---------------------------------
; destroy the top-level base widget
; ---------------------------------
if (zoom_window_exists) then widget_control, /destroy, wBase3

; ------------
; set flag
; ------------
zoom_window_exists = 0

end
