
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; get_sun_angle - return the angle between a line
;                 to the Sun and the left of the
;                 image display window 
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

; last modified: 28-May-2003

function angle, x, y
  return, atan(y, x)
end

function theta, v
  v1 = v[0]
  v2 = v[1]
  v3 = v[2] 

  return, angle(v3, sqrt(v1 ^ 2 + v2 ^ 2))
end

function phi, v
  v1 = v[0]
  v2 = v[1]
  v3 = v[2] 
  
  return, angle(v1, v2)
end

function M, i, j, k
  return, [[i[0], i[1], i[2]], $
           [j[0], j[1], j[2]], $
           [k[0], k[1], k[2]]]
end

function Mint, a, b
  return, M(crossp(a, b), crossp(a, crossp(a, b)), a)
end

function Mtrans, a, b, ap, bp
  return, transpose(Mint(ap, bp)) ## Mint(a, b)
end

pro get_sun_angle

;;;forward_function phi,theta,angle,M,Mint,Mtrans

@euv_imtool-commons

spin_pole = [spin_axis_x, spin_axis_y, spin_axis_z]
sun = [sun_x, sun_y, sun_z]

sun = transpose(sun / sqrt(sun[0] ^ 2D + sun[1] ^ 2 + sun[2] ^ 2))

imagesc = [image_x, image_y, image_z]
imagesc = transpose(imagesc / sqrt(imagesc[0] ^ 2 + imagesc[1] ^ 2 + imagesc[2] ^ 2))

scan = crossp(imagesc, spin_pole)
scan = scan / sqrt(scan[0] ^ 2D + scan[1] ^ 2 + scan[2] ^ 2)

T = Mtrans(scan, imagesc, transpose([1, 0, 0]), transpose([0, 0, 1]))
sunt = T ## sun

;;print, 'phi(sunt) =', (phi(sunt) / !pi * 180.0)
;;print, 'theta(sunt) =', (theta(sunt) / !pi * 180.0)

rotangle = 90.0 -(phi(sunt) / !pi * 180.0)
;;print,'rotangle = ', rotangle

end
