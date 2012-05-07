;-------------------------------------------------------------
;+
; NAME:
;       MAP_SET_SCALE
; PURPOSE:
;       Set map scaling from info embedded in a map image.
; CATEGORY:
; CALLING SEQUENCE:
;       No args.
; INPUTS:
; KEYWORD PARAMETERS:
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
;       Notes: Uses info embedded on bottom image line by
;       map_put_scale, if available.
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
	pro map_set_scale, help=hlp
 
	if keyword_set(hlp) then begin
	  print,' Set map scaling from info embedded in a map image.'
 	  print,'   No args.'
 	  print,' Notes: Uses info embedded on bottom image line by'
	  print,' map_put_scale, if available.'
	  return
	endif
 
	if !d.x_size lt 295 then return		; Image too small.
 
	t = tvrd(0,0,295,1)			; Read data rea.
	m = string(t(0:9))			; Data available flag.
	if m ne '1234567891' then return	; No map scaling info in image.
 
	s = string(t(10:*))			; Turn data into a string.
	a1=0 & a2=0. & a3=0. & a4=0.		; Set up storage.
	a5=0. & a6=0. & a7=0.
	aout = fltarr(12)
	x1=0 & x2=[0.,0.] & y1=0 & y2=[0.,0.]
	
	;-----  Extract values from string  ----------
	fmt = '(I4,F10.4,F9.4,4F13.9,12F12.6,I3,2E15.8,I3,2E15.8)'
	reads,s,a1,a2,a3,a4,a5,a6,a7,aout,x1,x2,y1,y2,form=fmt
 
	;-----  Insert values in proper places  -----
	!map.projection = a1
	!map.phioc = a2
	!map.p0lat = a3
	!map.sino = a4
	!map.coso = a5
	!map.sinr = a6
	!map.cosr = a7
	!map.out = aout
	!x.type = x1
	!x.s = x2
	!y.type = y1
	!y.s = y2
 
	return
	end
