
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; delete_click_point - remove a point from the
;                      clicked points arrays
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

; last modified: 26-Aug-2003

pro delete_click_point, ix, iy, from

@euv_imtool-commons

; ---------------------------------------------------------
; generate position from either the main or zoom windows
; ---------------------------------------------------------
case from of
    0: begin
        xd = float(ix)
        yd = float(iy)
    end
    1: begin
        xd = x_zoom_to_main(ix)
        yd = y_zoom_to_main(iy)
    end
    2: begin
        xd = x_full_to_main(iy)
        yd = y_full_to_main(ix)
    end
endcase

; -------------------------------------------------
; search for the closest point and return its index
; -------------------------------------------------
radius = 500.0
for i=0,nclicks-1 do begin
    r = sqrt( (float(xclick[i]) - xd)^2 + (float(yclick[i]) - yd)^2 )
    if(r lt radius) then begin
        radius = r
        which = i
    endif
end

; -----------------------------------------------
; remove the selected point from the click arrays
; -----------------------------------------------
nclicks = nclicks - 1

if(nclicks eq 0) then begin     ; all points have been removed
    click_points -> SetProperty, hide=1
    click_points3 -> SetProperty, hide=1
    click_points_full -> SetProperty, hide=1
    widget_control, record_file, sensitive=0

endif else begin

    xctemp = intarr(nclicks)
    yctemp = intarr(nclicks)
    xctemp3 = intarr(nclicks)
    yctemp3 = intarr(nclicks)
    xctemp_full = intarr(nclicks)
    yctemp_full = intarr(nclicks)

    if(which eq 0) then begin
        xctemp = xclick[1:nclicks]
        yctemp = yclick[1:nclicks]
        xctemp3 = xclick3[1:nclicks]
        yctemp3 = yclick3[1:nclicks]
        xctemp_full = xclick_full[1:nclicks]
        yctemp_full = yclick_full[1:nclicks]
    endif else if (which eq nclicks) then begin
        xctemp = xclick[0:nclicks-1]
        yctemp = yclick[0:nclicks-1]
        xctemp3 = xclick3[0:nclicks-1]
        yctemp3 = yclick3[0:nclicks-1]
        xctemp_full = xclick_full[0:nclicks-1]
        yctemp_full = yclick_full[0:nclicks-1]
    endif else begin
        xctemp[0:which-1] = xclick[0:which-1]
        xctemp[which:nclicks-1] = xclick[which+1:nclicks]
        yctemp[0:which-1] = yclick[0:which-1]
        yctemp[which:nclicks-1] = yclick[which+1:nclicks]
        xctemp3[0:which-1] = xclick3[0:which-1]
        xctemp3[which:nclicks-1] = xclick3[which+1:nclicks]
        yctemp3[0:which-1] = yclick3[0:which-1]
        yctemp3[which:nclicks-1] = yclick3[which+1:nclicks]
        xctemp_full[0:which-1]   = xclick_full[0:which-1]
        xctemp_full[which:nclicks-1] = xclick_full[which+1:nclicks]
        yctemp_full[0:which-1] = yclick_full[0:which-1]
        yctemp_full[which:nclicks-1] = yclick_full[which+1:nclicks]
    endelse

    xclick[0:nclicks-1]  = xctemp
    yclick[0:nclicks-1]  = yctemp
    xclick3[0:nclicks-1] = xctemp3
    yclick3[0:nclicks-1] = yctemp3
    xclick_full[0:nclicks-1] = xctemp_full
    yclick_full[0:nclicks-1] = yctemp_full

; -------------------------------------
; reload the data into the plot objects
; -------------------------------------
    click_points -> SetProperty, datax=xclick[0:nclicks-1], datay=yclick[0:nclicks-1]
    click_points3 -> SetProperty, datax=xclick3[0:nclicks-1], datay=yclick3[0:nclicks-1]
    click_points_full -> SetProperty, datax=xclick_full[0:nclicks-1], datay=yclick_full[0:nclicks-1]
endelse

redraw_views

end
