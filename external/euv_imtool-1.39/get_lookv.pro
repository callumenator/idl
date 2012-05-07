;		procedure name: get_lookv
;		author: D. Gallagher NASA/MSFC/SD50
;		date: February 14, 2001
; ----------------------------------------------------------------------------------------------
;
;    Modified 2 August 2002 by Bill Sandel
;      to correct the transformation from pixel coordinates
;      to the look direction vector lookv.
;
;    Modified 8 August 2002 by Bill Sandel
;      to compute the intersection of the line of sight with the SM equator
;      and print results to the console.
;
;    Modified 1 July 2003 by Terry Forrester to refine the look
;		direction determination by taking into account the
;               camera-specific plate scales and offsets
;                          
;    Modified 25 July 2003 by Terry Forrester, making the pixel
;		 location in the elevation direction a floating-point
;                quantity so that each pixel from the main and zoom
;		 windows maps to a different location.
;
;                
; ----------------------------------------------------------------------------------------------
;  Procedure for obtaining a unit LOS look vector in SM coordinates
;  look vector is defined by the user ponting to a position in an image
;  and passing the indicies of that position into this routine.
;
;  (ix,iy) = indicies of position in current image where user wants LOS vector
;  (isize,jsize) = (x,y) dimensions of EUV image
;  pos = (x,y,z) position of the observer in solar magnetic (SM) coordinates
;  upvec = (x,y,z) vector in SM coordinates that defines "up" in the EUV
;           instrument field of view.  Recommended that the IMAGE spacecraft
;           velocity vector or its negative be used.
;  lookv = (x,y,z) unit vector in SM coordinates of LOS vector corresponding to
;          provided (ix,iy) image indicies
;
;  In obtaining this vector it is assumed that there are 140 pixels across in the
;  image x-direction (horizontal) and that there are 0.6 degrees per pixel.  If the
;  image referenced in calling this routine has more or less pixels in the x-direction
;  then the degrees per pixel are scaled correspondingly.
;
; ----------------------------------------------------------------------------------------------

pro get_lookv,ix,iy,isize,jsize,pos,upvec,n_overlap,xcenter,lookv

; Compute the plate scale ( in the spin direction )
scale_fact = 140.0 / float(isize)
plate_scale_spin = 140.0 / float(isize) * 0.6
;;plate_scale = plate_scale_spin ; obsolete, use for comparing old and new calculation

; Compute pixel location relative to the center in image coordinates. Image coordinates
; are defined below (cross-spin direction now handled differently).
ixrel=iy-jsize/2
;;iyrel=isize/2-ix

phi=float(ixrel)*plate_scale_spin*!pi/180.0 

center_el = true_elevation(float(xcenter) * scale_fact,n_overlap)
look_el   = true_elevation(float(ix) * scale_fact,n_overlap)
;;print, ix, center_el, look_el
rho = (center_el - look_el) * !pi/180.0

;print, "    rho, phi: ", rho*180/!pi, phi*180/!pi

; Compute LOS look vector in image coordinate system: where x is up or vertical
; in image, y is horizontal and to the left in the image, and z is toward the viewer
; in the image.  Image center is the coordinate system origin.
ilookv=fltarr(3)
ilookv(0)=  sin(phi)*cos(rho)
ilookv(1)= -sin(rho)
ilookv(2)= -sqrt(1.0-ilookv(0)^2-ilookv(1)^2)

;print,"      ilookv: ", ilookv

; determine unit vector in SM coordinates for image coordinate z-axis
uz_sm=pos/sqrt(total(pos^2))

; determine unit vector in SM coordinates for image coordinate x-axis
earthvec=-pos
temp=crossp(upvec,earthvec)
ux_sm=crossp(earthvec,temp)
ux_sm=ux_sm/sqrt(total(ux_sm^2))

; determine unit vector in SM coordinates for image coordinate y-axis
uy_sm=temp/sqrt(total(temp^2))
; compute image LOS look vector in SM coordinates
lookv=fltarr(3)
lookv(0)=ilookv(0)*ux_sm(0)+ilookv(1)*uy_sm(0)+ilookv(2)*uz_sm(0)
lookv(1)=ilookv(0)*ux_sm(1)+ilookv(1)*uy_sm(1)+ilookv(2)*uz_sm(1)
lookv(2)=ilookv(0)*ux_sm(2)+ilookv(1)*uy_sm(2)+ilookv(2)*uz_sm(2)
lookv=lookv/sqrt(total(lookv^2))

; calculate the intersection of the SM look vector with the
; SM equator (Zsm = 0).

t=-pos(2)/lookv(2)
intersection=fltarr(3)
intersection=pos+t*lookv
intr=sqrt(total(intersection^2))
intl=atan(intersection(1),intersection(0))
if(intl < 0.0 ) then begin
   intl=intl+2*!pi
endif
;;print, " "
;;print,"    look vector ", lookv
;;print," IMAGE position ", pos
;;print," look vector crosses SM equatorial plane at"
;;print,"       x,y,z ", intersection
;;print,"      r, phi ", intr,intl*180/!pi

return
end
