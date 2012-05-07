
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; add_click_point - add a point to the clicked
;                   points arrays
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

; last modified: 18-Aug-2003


pro add_click_point, ix, iy, from

@euv_imtool-commons

forward_function x_main_to_zoom,y_main_to_zoom,$
  x_main_to_full,y_main_to_full,x_zoom_to_main,y_zoom_to_main

; ------------------------------------------------------
; generate coordinates in both the main and zoom windows
; ------------------------------------------------------
case from of
    0: begin
        xclick[nclicks] = ix
        yclick[nclicks] = iy
        xclick3[nclicks] = x_main_to_zoom(ix)
        yclick3[nclicks] = y_main_to_zoom(iy)
        xclick_full[nclicks] = x_main_to_full(iy)
        yclick_full[nclicks] = y_main_to_full(ix)
    end
    1: begin
        xclick3[nclicks] = ix
        yclick3[nclicks] = iy
        xclick[nclicks] = x_zoom_to_main(ix)
        yclick[nclicks] = y_zoom_to_main(iy)
        xclick_full[nclicks] = x_main_to_full(yclick[nclicks])
        yclick_full[nclicks] = y_main_to_full(xclick[nclicks])
    end
    2: begin
        if(click_in_full) then begin
            xclick_full[nclicks] = ix
            yclick_full[nclicks] = iy
            xclick[nclicks] = x_full_to_main(iy)
            yclick[nclicks] = y_full_to_main(ix)
            xclick3[nclicks] = x_main_to_zoom(xclick[nclicks])
            yclick3[nclicks] = y_main_to_full(yclick[nclicks])
        endif
    end
endcase

; ------------------------------------
; load the data into the plot objects
; ------------------------------------
click_points -> SetProperty, datax=xclick[0:nclicks], datay=yclick[0:nclicks]
click_points3 -> SetProperty, datax=xclick3[0:nclicks], datay=yclick3[0:nclicks]
click_points_full -> SetProperty, datax=xclick_full[0:nclicks], datay=yclick_full[0:nclicks]

nclicks = nclicks + 1

; ---------------------------------------
; after the first point is defined, set 
; points' visibility and enable record
; file button
; ---------------------------------------
if(nclicks eq 1) then begin 
    widget_control, record_file, sensitive=1
    click_points -> SetProperty, hide = 0
    if(zoom_on) then begin
        click_points3 -> SetProperty, hide = 0
    endif
    if(full_window_exists and click_in_full) then begin
        click_points_full -> SetProperty, hide = 0
    endif
endif

redraw_views

end
