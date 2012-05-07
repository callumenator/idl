;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; calc_sm_coords.pro - calculate SM (solar magnetic) position
;                      and velocity vectors
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

; last modified:  8-Mar-2001

pro calc_sm_coords

@euv_imtool-commons

; --------------------------------------------------------------
; first, generate all necessary transformation matrices for this
; time period
; --------------------------------------------------------------
mjd = jd - 0.5
gen_transforms,mjd,t1,t2,t3,t4,t5

; -------------------------------------------
; calculate and save SM position and velocity
; -------------------------------------------
sm_from_gci = t4##t3##t2

impos_gci=[image_x,image_y,image_z]
impos_sm = sm_from_gci##impos_gci
image_smx = impos_sm[0]
image_smy = impos_sm[1]
image_smz = impos_sm[2]

imvel_gci=[image_vx,image_vy,image_vz]
imvel_sm = sm_from_gci##imvel_gci
image_smvx = imvel_sm[0]
image_smvy = imvel_sm[1]
image_smvz = imvel_sm[2]

; -------------------------------------------------------------
; calculate and save the spacecraft longitude in the MAG system
; -------------------------------------------------------------
mag = t5##t1##impos_gci
image_maglon = atan(mag[1],mag[0]) * !RADEG
if (image_maglon lt 0.0) then image_maglon = image_maglon + 360.0


end
