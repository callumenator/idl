;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; expand_zoom_window - enlarge the zoom window, doubling the size in
;                      the spin direction
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

; last modified: 27-Aug-2003

pro expand_zoom_window

@euv_imtool-commons

new_y = fltarr(1)

expanded_zoom = 1
widget_control, expand_button, set_value="Shrink"
widget_control, wDraw3, draw_ysize=ydim3
viewp3 = [0,0,xdim3,ydim3]
to_new_y = 225

; ------------------
; reset the viewport
; ------------------
imview3 -> SetProperty, viewplane_rect=viewp3

; ---------------------
; move the click points
; ---------------------
if(nclicks gt 0) then begin
    for i=0,nclicks-1 do begin
        yclick3[i] = yclick3[i] + to_new_y
    endfor
    click_points3 -> SetProperty, datay=yclick3[0:nclicks-1]
endif

; ---------------------
; move the center point
; ---------------------
center_point3  -> GetProperty, data=pdata
new_y[0] = pdata[1] + to_new_y
center_point3  -> SetProperty, datay=new_y

immodel3c -> Translate, 0, to_new_y,  0

center_y3 = center_y3 + to_new_y

; -----------------
; update everything
; -----------------
update_image_displays
redraw_views

end
