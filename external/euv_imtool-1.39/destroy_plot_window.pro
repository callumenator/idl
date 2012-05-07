;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; destroy_plot_window - remove the plot window
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

; last modified: 7-Sep-2001

pro destroy_plot_window

@euv_imtool-commons

; ---------------------------------
; destroy the top-level base widget
; ---------------------------------
if (plot_window_exists) then widget_control, /destroy, wBaseP

; ------------
; set flag
; ------------
plot_window_exists = 0

end
