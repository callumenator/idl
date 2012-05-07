;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; gen_center_ellipses - construct the data for the two centering
;                       ellipses to be used in the main and zoom
;                       windows.
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

; last modified: 11-Aug-2003

pro gen_center_ellipses

@euv_imtool-commons

ellipse  = fltarr(2,37)
ellipse3 = fltarr(2,37)
ellipse_full = fltarr(2,37)
dx = fltarr(1)
dy = fltarr(1)

; ----------------------------------
; generate the data for the ellipses
; ----------------------------------

; calculate Earth radius in pixels (in spin direction)
pscale=0.3
b_main = (asin(1.0/range_re) * !RADEG) / pscale

; Earth radius in pixels (in elevation direction)
a_main = 1.03942 * b_main

zoom_factor = 1.5
full_factor = 0.5

npts = 37
dang = 10.0
ang  = 0.0
for i=0,npts-1 do begin
    ar = ang / !RADEG
    radius_main = 1.0 / sqrt( ((cos(ar) / a_main) ^ 2) +  ((sin(ar) / b_main) ^ 2))
    ix = fix(radius_main*cos(ar))
    iy = fix(radius_main*sin(ar))
    ellipse[0,i] = float(ix)
    ellipse[1,i] = float(iy)
    ellipse3[0,i] = float(ix) * zoom_factor
    ellipse3[1,i] = float(iy) * zoom_factor
    ellipse_full[0,i] = float(ix) * full_factor
    ellipse_full[1,i] = float(iy) * full_factor
    ang = ang + dang
endfor

center_ellipse  -> SetProperty, data=ellipse[*,*]
center_ellipse3 -> SetProperty, data=ellipse3[*,*]
center_ellipse_full -> SetProperty, data=ellipse_full[*,*]

end
