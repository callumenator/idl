;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; update_image_displays - refresh the image displays with new images
;                   and (optionally) contour map overlays
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

; last modified: 21-Aug-2003

pro update_image_displays

@euv_imtool-commons

; ---------------------
; update image displays
; ---------------------
image -> SetProperty, data=bytscl(darray)

if(zoom_on) then begin
    if(expanded_zoom) then begin
        image3 -> SetProperty, data=bytscl(darray3)
    endif else begin
        image3 -> SetProperty, data=bytscl(darray3[*,225:674])
    endelse
endif

if(full_window_exists) then image4 -> SetProperty, data=bytscl(full)

; -------------------------------
; redraw the contour map overlays
; -------------------------------
contour -> SetProperty,  data = darray
contour -> SetProperty, hide=1-overlay_contour

if(zoom_on) then begin

    if(expanded_zoom) then begin
        contour3 -> SetProperty,  data = darray3
    endif else begin
        contour3 -> SetProperty,  data = darray3[*,225:674]
    endelse

    contour3 -> SetProperty, hide=1-overlay_contour3
endif

end
