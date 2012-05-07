;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; freshen_all - do everything necessary after new data is loaded.
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

; last modified: 19-May-2005

pro freshen_all

@euv_imtool-commons

forward_function get_midpoint

; -------------------------------------
; reset some flags
; -------------------------------------
centered = 0
keep_center = 0
warned = 0

; --------------------------------------------------
; erase the click points and center circle and point
; --------------------------------------------------
click_points -> SetProperty, hide=1
click_points3 -> SetProperty, hide=1
click_points_full -> SetProperty, hide=1
nclicks = 0
center_ellipse -> SetProperty, hide=1
center_ellipse3 -> SetProperty, hide=1
center_ellipse_full -> SetProperty, hide=1
center_point -> SetProperty, hide=1
center_point3 -> SetProperty, hide=1
center_point_full -> SetProperty, hide=1

; ---------------------------------
; recalculate the centering circles
; ---------------------------------
gen_center_ellipses

; ------------------------------------------------------
; hide radial/azimuthal plot lines and erase plot window
; ------------------------------------------------------
hide_polylines
if (plot_window_exists) then windowpa -> Erase, color=[120,120,120]
if (plot_window_exists) then windowpr -> Erase, color=[130,130,130]

; --------------------------------------------
; update image displays and readout widgets
; --------------------------------------------
calc_sm_coords
load_display_widgets
update_image_displays
set_los_readouts, minL, tp_maglon, mlt_look, spot_average, 0
display_status, " "
redraw_views

; -------------------------------------
; reset some button states, etc.
; -------------------------------------
widget_control, keep_button, set_value="Keep Center?"

; enable various buttons
widget_control, contour_button, sensitive=1
widget_control, center_button, sensitive=1
widget_control, center_button, set_value="Define Center  "
widget_control, clear_button, sensitive=1
widget_control, autocheck, sensitive=1
widget_control, bias_droplist, sensitive=1

; disable radial/azimuthal plot button until center is defined
widget_control, plot_button, sensitive=0

; enable File menu output items
widget_control, menu_ids[3], sensitive=1
widget_control, menu_ids[4], sensitive=1
widget_control, menu_ids[5], sensitive=1
widget_control, menu_ids[6], sensitive=1

; -------------------------------------------------------------
; enable or disable the expand/shrink button in the zoom window
; depending on whether load was from UDF (of full-frame FITS)
; or small FITS image file.
; -------------------------------------------------------------
;if( zoom_window_exists ) then begin
;    if( full_frame or from_udf ) then begin
;        widget_control,expand_button,sensitive = 1
;    endif else begin
;        widget_control,expand_button,sensitive = 0
;    endelse
;endif

; ----------------------------------------------------------
; enable the plot solar wind button if the data is available
; ----------------------------------------------------------

if(not loaded_solar_data) then load_sw_data,0
if(found_solar_data) then widget_control, sw_button, sensitive=1

if(sw_plot_exists) then sf_update,get_midpoint(jd)

end
