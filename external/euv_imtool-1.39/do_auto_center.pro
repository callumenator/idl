
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; do_auto_center - set the Earth center automatically
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

; last modified: 18-Sep-2003

pro do_auto_center

@euv_imtool-commons
; -----------------------------------------------------------------
; calculate the Sun angle and generate the image for auto-centering
; -----------------------------------------------------------------
get_sun_angle
mag = range0 / range[0]

ref = rot(ref_image,rotangle,mag)

; ---------------
; find the center 
; ---------------
correl_optimize,workarray[*,75:224],ref,x_offset,y_offset,/numpix,magnification=2
xxbias =  cbias * cos(rotangle*!DTOR)
yybias =  -cbias * sin(rotangle*!DTOR)
xnew = 139 + x_offset*2 + xxbias
ynew = 149 + y_offset*2 + yybias

; ------------------------------------------------
; define the centers for the main and zoom windows
; ------------------------------------------------
center_x2 = xnew
center_y2 = ynew
center_x3 = fix((center_x2 / 2.0) * 3.0)
center_y3 = fix((center_y2 / 2.0) * 3.0)

; -------------------------------------------
; define the center for the full frame window
; -------------------------------------------
center_full_x = dtstart + xoff + fix(center_y2/2.0)
center_full_y = 139 - fix(center_x2/2.0)
gen_mtrans

; ---------------------------------
; draw the center and center circle
; ---------------------------------
draw_center_ellipse,xnew,ynew,0,0
draw_center_ellipse,xnew,ynew,0,1
center_ellipse  -> SetProperty, hide=0
center_ellipse3  -> SetProperty, hide=0
center_ellipse_full  -> SetProperty, hide=0

; --------------------------------------
; set misc flags and button states, 
; then display status message
; --------------------------------------
centered=1
defining_center = 0
widget_control, center_button, set_value="Redefine Center"
widget_control, plot_button, sensitive=1
widget_control, keep_button, sensitive=0

display_status, $
  string(center_x2,center_y2,format='("Autocentering at ",I4,2x,I4)')

redraw_views

end
