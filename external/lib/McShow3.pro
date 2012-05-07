; $Id: show3.pro,v 1.11 2000/07/05 21:47:49 kschultz Exp $
;
; Copyright (c) 1988-2000, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.

PRO mcshow3, image, x, y, INTERP = interp, SSCALE=sscale, E_CONTOUR=ec, $
	E_SURFACE=es, white_bg=white_bg, locolor=locolor, hicolor=hicolor, altimage=altimage
; Show an image three ways...
;+
; NAME:
;	SHOW3
;
; PURPOSE:
;	Show a 2D array three ways in a display that combines SURFACE, 
;	CONTOUR, and an image (color/gray scale pixels).
;
; CATEGORY:
;	Display, graphics.
;
; CALLING SEQUENCE:
;	SHOW3, Image [, INTERP = Interp, SSCALE = Sscale]
;
; INPUTS:
;	Image:	The 2-dimensional array to display.
;
; OPTIONAL INPUTS:
;	X = a vector containing the X values of each column of Image.
;		If omitted, columns have X values 0, 1, ..., Ncolumns-1.
;	Y = a vector containing the Y values of each row of Image.
;		If omitted, columns have Y values 0, 1, ..., Nrows-1.
; KEYWORD PARAMETERS:
;	INTERP:	Set this keyword to use bilinear interpolation on the pixel 
;		display.  This technique is slightly slower, but for small 
;		images, it makes a better display.
;
;	SSCALE:	Reduction scale for surface. The default is 1.  If this
;		keyword is set to a value other than 1, the array size 
;		is reduced by this factor for the surface display.  That is, 
;		the number of points used to draw the wire-mesh surface is
;		reduced.  If the array dimensions are not an integral multiple
;		of SSCALE, the image is reduced to the next smaller multiple.
;	E_CONTOUR: a structure containing additional keyword parameters
;		that are passed to the CONTOUR procedure.  See the example
;		below.
;	E_SURFACE: a structure containing additional keyword parameters
;		that are passed to the SURFACE procedure.  See the example
;		below.
;
; OUTPUTS:
;	No explicit outputs.
;
; COMMON BLOCKS:
;	None.
;
; SIDE EFFECTS:
;	A new plot is generated.
;
; RESTRICTIONS:
;	The display gets too "busy" when displaying larger (say 50 by 50),
;	images, especially if they are noisy.  It can be helpful to use
;	the SSCALE keyword or the SMOOTH and/or REBIN functions to smooth the 
;	surface plot.
;
;	You might want to modify the calls to CONTOUR and SURFACE slightly
;	to customize the display to your tastes, i.e., with different colors,
;	skirts, linestyles, contour levels, etc.
;
; PROCEDURE:
;	First, do a SURFACE with no data to establish the 3D to 2D scaling.
;	Then convert the coordinates of the corner pixels of the array to
;	2D.  Use POLYWARP to get the warping polynomial to warp the
;	2D image into the area underneath the SURFACE plot.  Output the image,
;	output the surface (with data) and then output the contour plot at
;	the top (z=1).
;
; EXAMPLES:
;	A = BESELJ(SHIFT(DIST(30,20), 15, 10)/2.,0)  ;Array for example
;	SHOW3, A		;Show it with default display.
;	SHOW3, A, SQRT(FINDGEN(30))  ;Make X axis proportional to sqrt
;	SHOW3, A, E_CONTOUR={C_CHARSIZE:2, DONW:1} ;Label CONTOUR lines with
;		double size characters, and include downhill tick marks.
;	SHOW3, A, E_SURFACE={SKIRT:-1, ZRANGE:[-2,2]}  ;Draw a surface with
;		a skirt and scale Z axis from -2 to 2.
; MODIFICATION HISTORY:
;	DMS. Jan, 1988.
;	Added fudges for PostScript, April, 1988.
;	Fixed bug where contour plot was occasionally clipped. Dec, 1990.
;	Added optional axis variables, and _EXTRA keywords for CONTOUR,
;		and SURFACE.  Jan, 1996.
;	DD.  Added code to ignore !ORDER for the TV of the image.  Mar 1997.
;       SJL  Fixed bug from scaling with polywarp. July, 1998.
;-
on_error,2              ;Return to caller if an error occurs
s = size(image)		;Get size of image
nx = s[1]		;Columns
ny = s[2]		;Rows

if n_elements(sscale) eq 0 then sscale = 1 ;Default scale
sscale = fix(sscale)		;To Integer

if n_elements(x) eq 0 then x = findgen(nx)	;Axis vectors
if n_elements(y) eq 0 then y = findgen(ny)

if ((nx mod sscale) ne 0) or ((ny mod sscale) ne 0) then begin
	nx = (nx/sscale) * sscale ;To multiple
	ny = (ny/sscale) * sscale
	img = image[0:nx-1, 0:ny-1]
	xx = x[0:nx-1]
	yy = y[0:ny-1]
endif else begin
	img = image
	xx = x
	yy = y
endelse

		;Set up scaling
SURFACE, img, xx, yy, /SAVE,/NODATA,XST=1,YST=1,ZAXIS=1, _EXTRA=es
empty			;Don't make 'em wait watching an empty screen.

xorig = [x[0],x[nx-1],x[0],x[nx-1]]	;4 corners X locns in image
yorig = [y[0],y[0],y[ny-1],y[ny-1]]	;4 corners Y locns

xc = xorig * !x.s[1] + !x.s[0]	;Normalized X coord
yc = yorig * !y.s[1] + !y.s[0]	;Normalized Y
			;To Homogeneous coords,  and transform
p = [[xc],[yc],[fltarr(4)],[replicate(1,4)]] # !P.T 
u = p[*,0]/p[*,3] * !d.x_vsize	;Scale U coordinates to device
v = p[*,1]/p[*,3] * !d.y_vsize	;and V
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

if (!d.flags and 512) ne 0 or keyword_set(white_bg) then $  ;White background?
	miss = 255 else miss = 0
;
	;Get polynomial coeff for warp
if !d.table_size gt 2 then top = !d.table_size -1 else top = 255
if not(keyword_set(locolor)) then locolor = 0
if keyword_set(hicolor) then top = hicolor - locolor - 2

POLYWARP, [0,nx-1,0,nx-1],[0,0,ny-1,ny-1], (u-u0)/fact, (v-v0)/fact, 1, kx, ky

base_im = img
if keyword_set(altimage) then base_im = altimage

A = POLY_2D(locolor + BYTSCL(base_im, top=top), kx, ky, KEYWORD_SET(interp), $
		su/fact,sv/fact, missing = miss) ;Warp it
TV, a, u0, v0, xsize = su, ysize = sv, order=0
SURFACE, REBIN(img, nx/sscale, ny/sscale),$
	REBIN(xx, nx/sscale), REBIN(yy, ny/sscale), _EXTRA=es, $
	/SAVE, /NOERASE, XST=1, YST=1, BOT=128 ;Show the surface
                        ; Redraw front-right Z axis.
AXIS,ZAXIS=0,/T3D
			;And finally, draw contour on top
CONTOUR, img, xx, yy,/T3D,/NOERASE,ZVAL=1.0,XST=1,YST=1, $
	C_COLOR = C_COLOR,/NOCLIP, _EXTRA=ec
end
