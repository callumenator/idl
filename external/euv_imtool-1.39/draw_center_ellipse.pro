;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; draw_center_ellipse - draw an ellipse the size of the Earth on
;                       the image display to aid in defining the
;                       Earth center. If set_center is true,
;                       also mark the center itself.
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

; last modified: 18-Aug-2003

pro draw_center_ellipse, mousex, mousey, from, set_center

@euv_imtool-commons

forward_function x_main_to_zoom,y_main_to_zoom,$
  x_main_to_full,y_main_to_full,x_zoom_to_main,y_zoom_to_main

; -------------------------------------------------    
; draw the circle at the mouse cursor position
; -------------------------------------------------

case from of
    0: begin
        xc      = mousex
        yc      = mousey
        xc3     = x_main_to_zoom(xc)
        yc3     = y_main_to_zoom(yc)
        xc_full = x_main_to_full(yc)
        yc_full = y_main_to_full(xc)
    end
    1: begin
        xc3 = mousex
        yc3 = mousey
        xc  = x_zoom_to_main(xc3)
        yc  = y_zoom_to_main(yc3)
        xc_full = x_main_to_full(yc)
        yc_full = y_main_to_full(xc)
    end
    2: begin
        xc_full = mousex
        yc_full = mousey
        xc = x_full_to_main(yc_full)
        yc = y_full_to_main(xc_full)
        xc3 = x_main_to_zoom(xc)
        yc3 = y_main_to_zoom(yc)
    end
endcase


immodelc  -> Reset
immodelc  -> Translate, xc, yc,  0
immodel3c -> Reset
immodel3c -> Translate, xc3, yc3,  0
immodelc_full -> Reset
immodelc_full -> Translate, xc_full, yc_full,  0

if(not click_in_full) then center_ellipse_full -> SetProperty,hide=1

; ---------------------------------------------------
; set the center, drawing the circle and center point
; ---------------------------------------------------
if(set_center) then begin

    dx  = fltarr(1)
    dy  = fltarr(1)

    dx[0] = xc
    dy[0] = yc
    center_point  -> SetProperty, datax=dx, datay=dy, hide=0

    dx[0] = xc3 
    dy[0] = yc3 
    center_point3  -> SetProperty, datax=dx, datay=dy, hide=0

    if(click_in_full) then begin
        dx[0] = xc_full 
        dy[0] = yc_full
        center_point_full  -> SetProperty, datax=dx, datay=dy, hide=0
    endif

endif

end
