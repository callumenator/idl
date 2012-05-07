
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; create a template image of the bright emission
; horseshoe for a range of 51630 km. This will be
; scaled and rotated to form an image to correlate
; with the EUV image (for auto centering).
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

; last modified:  9-May-2003

pro create_ref_image

; last updated: 9-May-2003

@euv_imtool-commons

newval=600
x_cen= 70
y_cen= 75
r0start=12
r0end=16
r0center = 14

for r=r0start,r0end do begin

  for i=1,115 do begin
    ang=(!PI/180)*i
    x = x_cen + r*cos(ang)
    y = y_cen + r*sin(ang)
    ref_image[x,y]=newval - abs(r-r0center) * 200
;;    ref_image[x,y]=newval
  endfor

  for i=245,360 do begin
    ang=(!PI/180)*i
    x = x_cen + r*cos(ang)
    y = y_cen + r*sin(ang)
    ref_image[x,y]=newval - abs(r-r0center) * 200
;;    ref_image[x,y]=newval
  endfor

  for i=116,244 do begin
    ang=(!PI/180)*i
    x = x_cen + r*cos(ang)
    y = y_cen + r*sin(ang)
    ref_image[x,y]=0
;;    ref_image[x,y]=newval
  endfor


endfor


end
