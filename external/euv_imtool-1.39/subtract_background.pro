
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; subtract a background from the image
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

; last modified: 24-Nov-2003

pro subtract_background

@euv_imtool-commons

; --------------------------------------------------------
; subtracting using workarray (original-scale image, so
; have to convert the x,y coordinates to the 140x300 
; workarray frame
; --------------------------------------------------------
wminx = bminx / 2
wmaxx = bmaxx / 2
wminy = (bminy / 2) + 75
wmaxy = (bmaxy / 2) + 75
im = workarray

; ----------------------------------------
; define an array for the background image
; ----------------------------------------
back = fltarr(xdim,ydim*2)

if (deband) then begin
    temp = rebin(im[*,wminy:wmaxy],xdim,1)
    back = rebin(temp,xdim,ydim*2)
endif else begin
    temp = rebin(im[wminx:wmaxx,wminy:wmaxy],1,1)
    back = rebin(temp,xdim,ydim*2)
    display_status,STRING(temp,format='("Average value subtracted = ", f5.1)')
endelse

; ---------------------------------------
; do the subtraction in the working array
; ---------------------------------------
im = im - back
workarray = im

; -------------------------------------
; do the subtraction in the full frame
; -------------------------------------
fminx = x_main_to_full(bminy)
fmaxx = x_main_to_full(bmaxy)
fminy = y_main_to_full(bmaxx)
fmaxy = y_main_to_full(bminx)

im = working_dmap
back = fltarr(mxdim,mydim)
;;print, fminx,fmaxx,fminy,fmaxy

if (deband) then begin
    temp = rebin(im[fminx:fmaxx,*],1,mydim)
    back = rebin(temp,mxdim,mydim)
endif else begin
    temp = rebin(im[fminx:fmaxx,fminy:fmaxy],1,1)
    back = rebin(temp,mxdim,mydim)
endelse

im = im - back
working_dmap = im

; -------------------------
; reload the display arrays
; -------------------------
redo_arrays

end




