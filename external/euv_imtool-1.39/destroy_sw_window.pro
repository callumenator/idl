;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; destroy_sw_window - remove the solar wind plot window
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

; last modified: 25-Jun-2003

pro destroy_sw_window

@euv_imtool-commons

; ---------------------------------
; destroy the top-level base widget
; ---------------------------------
if (sw_plot_exists) then widget_control, /destroy, sf_base

; ------------
; set flag
; ------------
sw_plot_exists = 0

end
