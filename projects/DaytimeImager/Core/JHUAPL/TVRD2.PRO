;-------------------------------------------------------------
;+
; NAME:
;       TVRD2
; PURPOSE:
;       Version of tvrd that allows out of bounds.
; CATEGORY:
; CALLING SEQUENCE:
;       img = tvrd2(x,y,dx,dy)
; INPUTS:
;       x,y = lower left corner of screen image to read.  in
;       dx,dy = x and y size to read.                     in
; KEYWORD PARAMETERS:
; OUTPUTS:
;       img = output image.                               out
; COMMON BLOCKS:
; NOTES:
;       Notes: allows x,y to be outside of screen image.
;         Allows dx, dy to extend outside screen image.
;         Values are in pixels.
; MODIFICATION HISTORY:
;       R. Sterner, 1 Oct, 1992
;
; Copyright (C) 1992, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
 
	function tvrd2, x, y, dx, dy, help=hlp
 
	if (n_params(0) lt 4) or keyword_set(hlp) then begin
	  print,' Version of tvrd that allows out of bounds.'
	  print,' img = tvrd2(x,y,dx,dy)'
	  print,'   x,y = lower left corner of screen image to read.  in'
	  print,'   dx,dy = x and y size to read.                     in'
	  print,'   img = output image.                               out'
	  print,' Notes: allows x,y to be outside of screen image.'
	  print,'   Allows dx, dy to extend outside screen image.'
	  print,'   Values are in pixels.'
	  return, -1
	endif
 
	lx = !d.x_size - 1		; Display limits.
	ly = !d.y_size - 1
	x1 = x>0<lx			; Keep actual read corner in bounds.
	y1 = y>0<ly
	dxc = dx<(lx-x1+1)<(x+dx)	; Keep actual read size in bounds.
	dyc = dy<(ly-y1+1)<(y+dy)
 
	if (dxc le 0) or (dyc le 0) then return, bytarr(dx, dy)	; All out.
	
	t = tvrd(x1,y1,dxc,dyc)				; Read clipped area.
        if (dxc eq dx) and (dyc eq dy) then return, t   ; all inside.
 
 
	z = bytarr(dx,dy)		; Desired output size.
	ix = -(0<x)			; Insertion point.
	iy = -(0<y)
	z(ix,iy) = t			; Insert area read from screen.
 
	return, z
 
	end
