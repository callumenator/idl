pro disp3, image, interp = interp, sscale=sscale, $
	title=title,subtitle=subtitle,xtitle=xtitle,ytitle=ytitle,ztitle=ztitle,$
	ax=ax,az=az

    ;Show an image three ways...
;+
; NAME:		DISP3
; PURPOSE:
;	Show a 2d array three ways in a display that combines  
;		SHADE_SURF, CONTOUR, and an IMAGE.
; CATEGORY:
;	Display, graphics.
; CALLING SEQUENCE:
;	DISP3, Image [, Interp = Interp]
; INPUTS:
;	Image = a 2 dimensional array to display.
; OPTIONAL INPUT PARAMETERS:
;	Interp keyword, set to interpolate pixel display.  Slightly
;		slower, but for small images makes a better display.
;	Sscale = Reduction scale for surface.  Default = 1.  If not 1 then
;		the image size is reduced by this factor for the surface
;		display.  If the image dimensions are not an integral multiple
;		of Sscale the image is reduced to the next smaller multiple.
;	ax,az = passed to shade_surf
;	other parameters passed to contour
;
; OUTPUTS:
;	No explicit outputs.
; COMMON BLOCKS:
;	None.
; SIDE EFFECTS:
;	Display is changed.
; RESTRICTIONS:
;	The display gets too "busy" when displaying larger (say 50 by 50),
;	images, especially if they are noisy.  It might be a good idea
;	to use SMOOTH or REBIN or both to smooth the surface plot.
;
;	You might want to modify the calls to contour and surface slightly
;	to customize the display to your tastes, i.e. with different colors,
;	skirts, linestyles, contour levels, etc.
;
; PROCEDURE:
;	First, do a SURFACE with no data to establish the 3d to 2d scaling.
;	Then convert the coordinates of the corner pixels of the array to
;	2d using.  Use POLYWARP to get the warping polynomial to warp the
;	2d image into the area underneath the surface plot.  Output the image,
;	output the surface (with data) and then output the contour plot at
;	the top (z=1).
; MODIFICATION HISTORY:
;	Modified from SHOW3 by	DMS. April, 1988.
;	Added axis rotation options and automated the separation of the
;	surface from the image so that they dont overwrite each other.
;						T.J.Harris April 1991
;-
on_error,2              ;Return to caller if an error occurs
s = size(image)		;Get size of image
nx = s(1)		;Columns
ny = s(2)		;Rows

if n_elements(sscale) eq 0 then sscale = 1 ;Default scale
sscale = fix(sscale)		;To Integer

if ((nx mod sscale) ne 0) or ((ny mod sscale) ne 0) then begin
	nx = (nx/sscale) * sscale ;To multiple
	ny = (ny/sscale) * sscale
	img = image(0:nx-1, 0:ny-1)
  endif else img = image

if (not keyword_set(ax)) then ax = 20
if (not keyword_set(az)) then az = 30

;make the distance between the shade_surface and the image large enough so
;they dont overlap when plotted in 2-d
if (!z.range(0) lt !z.range(1)) then dz = (!z.range(1)-!z.range(0)) $
else dz = (max(image)-min(image))*1.1
dz = dz*sin(ax*!pi/180)*(abs(cos(az*!pi/180.))+abs(sin(az*!pi/180.)))
zrange = [!z.range(0)-dz,!z.range(1)+dz*0.4]

		;Set up scaling
surface,img,/save,/nodata,xst=1,yst=1,zaxis=1,zrange=zrange,zst=1,ax=ax,az=az,charsize=1.5
empty			;Don't make 'em wait watching an empty screen.

xorig = [0.,nx-1,0.,nx-1]	;4 corners X locns in image
yorig = [0.,0.,ny-1,ny-1]	;4 corners Y locns

x = xorig * !x.s(1) + !x.s(0)	;Normalized X coord
y = yorig * !y.s(1) + !y.s(0)	;Normalized Y
			;To Homogeneous coords,  and transform
p = [[x],[y],[fltarr(4)],[replicate(1,4)]] # !P.T 
u = p(*,0)/p(*,3) * !d.x_vsize	;Scale U coordinates to device
v = p(*,1)/p(*,3) * !d.y_vsize	;and V
;
;	Now, the 4 corners of the place for the image are in u and v
;
u0 = min(u) & v0 = min(v)		;Lower left corner of screen box
su = max(u)- u0+1 & sv = max(v) - v0+1	;Size of new image
if (!d.flags and 1) eq 1 then begin	;Scalable pixels (PostScript)?
	fact = 50		;Yes, shrink it
	miss = 255		;Missing values are white
	c_color=[0,0]		;Contour in only one color, black
 endif else begin
	fact = 1 		;one pixel/output coordinate
	miss = 0		;missing is black
	c_color=[150,200,250]
 endelse
;
	;Get polynomial coeff for warp
if !d.n_colors gt 2 then top = !d.n_colors -1 else top = 255
polywarp, xorig, yorig, (u-u0)/fact, (v-v0)/fact, 1, kx, ky 
if n_elements(interp) eq 0 then interp = 0
a = poly_2d(bytscl(img, top=top), kx, ky, interp,su/fact,sv/fact,$
		 missing = miss) ;Warp it

if (not keyword_set(title)) then title = !p.title
if (not keyword_set(subtitle)) then subtitle = !p.subtitle
if (not keyword_set(xtitle)) then xtitle = !x.title
if (not keyword_set(ytitle)) then ytitle = !y.title
if (not keyword_set(ztitle)) then ztitle = !z.title

save_x = !x
save_y = !y
save_z = !z
save_p = !p
!x.title = ' '
!y.title = ' '
!z.title = ' '
!p.title = ' '
!p.subtitle = ' '

			;Show the surface
shade_surf,rebin(img,nx/sscale, ny/sscale),$
	/t3d,/zst, zrange=zrange,charsize=1.5

			;Show the image at the bottom
tv,a,u0,v0,xsize = su, ysize = sv 
contour,img,/t3d,/noerase,/nodata,zval=0.0,xst=1,yst=1,c_color = c_color,$
	charsize=1.5

			;And finally, draw contour on top
contour,img,/t3d,/noerase,zval=1.0,xst=1,yst=1,c_color = c_color,$
	charsize=1.5

xyouts,0.5,0.0,z=0.0,text=0,/t3d,xtitle,/norm,alignment=0.5,size=3
xyouts,0.0,0.5,z=0.0,text=0,/t3d,ytitle,/norm,alignment=0.5,size=3,orient=-90
xyouts,0.05,1.0,z=0.5,text=1,/t3d,ztitle,/norm,alignment=0.5,size=3,orient=90
xyouts,0.5,1.0,title,size=1.5,/norm,alignment=0.5
xyouts,0.5,-0.2,subtitle,size=0.8,/norm,alignment=0.5

!x = save_x
!y = save_y
!z = save_z
!p = save_p
end
