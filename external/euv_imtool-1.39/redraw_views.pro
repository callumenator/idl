;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; redraw_views - refresh the view(s)
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

; last modified: 11-Aug-2003

pro redraw_views

@euv_imtool-commons

; ----------------
; redraw the views
; ----------------
window -> Draw, imview

if (zoom_window_exists) then window3 -> Draw, imview3
if (full_window_exists) then window4 -> Draw, imview4
if (plot_window_exists and centered) then windowpa -> Draw, imviewPa
if (plot_window_exists and centered) then windowpr -> Draw, imviewPr

end
