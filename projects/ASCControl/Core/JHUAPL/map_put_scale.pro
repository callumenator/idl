;-------------------------------------------------------------
;+
; NAME:
;       MAP_PUT_SCALE
; PURPOSE:
;       Embed map scaling info in image.
; CATEGORY:
; CALLING SEQUENCE:
;       map_put_scale
; INPUTS:
; KEYWORD PARAMETERS:
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
;       Notes: Must use after a map_set command, before any other
;         commands that change scaling (like plot).
;         Needs 295 pixels along the image bottom.
;         Allows an image of a map to be loaded later and have
;         data overplotted or positions read.
;         See also map_set_scale which sets up embedded scaling.
; MODIFICATION HISTORY:
;       R. Sterner, 1996 Mar 20
;
; Copyright (C) 1996, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro map_put_scale, help=hlp
 
	if keyword_set(hlp) then begin
	  print,' Embed map scaling info in image.'
	  print,' map_put_scale'
	  print,'   No args.'
	  print,' Notes: Must use after a map_set command, before any other'
	  print,'   commands that change scaling (like plot).'
	  print,'   Needs 295 pixels along the image bottom.'
	  print,'   Allows an image of a map to be loaded later and have'
	  print,'   data overplotted or positions read.'
	  print,'   See also map_set_scale which sets up embedded scaling.'
	  return
	endif
 
	if !x.type ne 2 then begin
 	  print,' Error in map_put_scale: Map scaling not available.'
	  print,'   Must call this routine after map_set and before'
	  print,'   any other routine (like plot) resets scale.'
	  return
	endif
 
	;----  Set up needed values  ----------
	m = 1234567891		; Value to flag map scale availability.
	a1 = !map.projection	; Needed map structure items.
	a2 = !map.phioc
	a3 = !map.p0lat
	a4 = !map.sino
	a5 = !map.coso
	a6 = !map.sinr
	a7 = !map.cosr
	!map.out(0) = !map.out(0)>(-180)<180
	!map.out(1) = !map.out(1)>(-90)<90
	aout = !map.out
	x1 = !x.type		; Needed X structure items.
	x2 = !x.s
	y1 = !y.type		; Needed Y structure items.
	y2 = !y.s
 
	;-----  Format string  -------------------
	fmt = '(I10,I4,F10.4,F9.4,4F13.9,12F12.6,I3,2E15.8,I3,2E15.8)'
 
	;-----  Create scaling string  ------------
	s = string(m,a1,a2,a3,a4,a5,a6,a7,aout,x1,x2,y1,y2,form=fmt)
 
	;------  Convert to bytes and write to image  --------
	tv,byte(s),0,0
 
	return
	end
