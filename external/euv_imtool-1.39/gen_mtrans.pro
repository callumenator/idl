;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; gen_mtrans - make transform from s/c coordinates to equatorial
;              coordinates
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

; last modified: 28-May-2003


function amint, a, b

mat = dblarr(3,3)

axb = crossp(a,b)
axaxb = crossp(a,axb)

mat(*,0) = axb
mat(*,1) = axaxb
mat(*,2) = a

return, mat
end



pro gen_mtrans

@euv_imtool-commons
;;;forward_function mint

; ----------------------------------------
; calculate IMAGE to Earth unit vector
; ----------------------------------------
im2earth = dblarr(3)
im2earth[0] = - image_x / range
im2earth[1] = - image_y / range
im2earth[2] = - image_z / range

; ----------------------------------------
; define other vectors
; ----------------------------------------
xHat = dblarr(3)
xHat = [1.0, 0.0, 0.0]

zHat = dblarr(3)
zHat = [0.0, 0.0, 1.0]

spin = dblarr(3)
spin[0] = spin_axis_x
spin[1] = spin_axis_y
spin[2] = spin_axis_z

; ----------------------------------------
; generate the transform
; ----------------------------------------
mtrans = transpose(amint(im2earth,spin)) ## amint(xHat, zHat)

end



