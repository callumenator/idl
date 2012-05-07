;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; calc_radec.pro - calculate the right ascension and declination
;                  corresponding to the mouse cursor position
;                  in the full frame window.
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

; last modified: 25-Jul-2003

pro calc_radec, ix, iy, ra, dec

@euv_imtool-commons

;;theta_corr = - 2.0
;;theta_corr = 0.0

; -------------------------------------------------------
; compute phi and theta angles from the X,Y position and
; the Earth position
; -------------------------------------------------------
phi = (center_full_x - ix) * 0.6
;;theta = 90.0 - ((iy - 69.5) * 0.6) + theta_corr
theta = true_elevation(float(iy),n_overlap) + 90.0


cos_phi   = cos(phi/!RADEG)
sin_phi   = sin(phi/!RADEG)
cos_theta = cos(theta/!RADEG)
sin_theta = sin(theta/!RADEG)

; -------------------------------------------------------
; calculate the equatorial unit vector from phi and
; theta, using the transformation matrix (calculated in
; gen_mtrans)
; -------------------------------------------------------
field = dblarr(3)
field = [sin_theta*cos_phi, sin_theta* sin_phi, cos_theta]

equat = mtrans ## field

; -------------------------------------------------------
; calculate the ra and dec
; -------------------------------------------------------
ra = atan(equat[1], equat[0]) * !RADEG
if ( ra lt 0.0) then ra = ra + 360.0
if ( ra gt 360.0) then ra = ra - 360.0

dec = asin(equat[2]/vmag(equat[0],equat[1],equat[2])) * !RADEG

end
