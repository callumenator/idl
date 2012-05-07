;-------------------------------------------------------------
;+
; NAME:
;       D2DMS
; PURPOSE:
;       Function to convert from degrees to deg, min, sec.
; CATEGORY:
; CALLING SEQUENCE:
;       s = d2dms( deg)
; INPUTS:
;       deg = input in degrees.             in
; KEYWORD PARAMETERS:
;       Keywords:
;         DIGITS=n  Force degrees to have n digits.
; OUTPUTS:
;       s = output string.                  out
; COMMON BLOCKS:
; NOTES:
; MODIFICATION HISTORY:
;       R. Sterner, 1997 Jan 17
;
; Copyright (C) 1997, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	function d2dms, a, help=hlp, digits=digits
 
	if (n_params(0) lt 1) or keyword_set(hlp) then begin
	  print,' Function to convert from degrees to deg, min, sec.'
	  print,' s = d2dms( deg)'
	  print,'   deg = input in degrees.             in'
	  print,'   s = output string.                  out'
	  print,' Keywords:'
	  print,'   DIGITS=n  Force degrees to have n digits.'
	  return,''
	endif
 
	;----  Break degrees into deg, min, sec  -----------
	sn = a lt 0.	; Sign.
	aa = abs(a)
	d = fix(aa)	; Degrees.
	t = (aa-d)*60.
	m = fix(t)	; Minutes.
	s = round((t-m)*60.)
	if s eq 60 then begin	; Deal with seconds > 59.5.
	  m = m + 1
	  s = 0
	endif
 
	;----  Format output string  --------------
	ds = string(179B)	; Deg symbol.
	ms = string(39B)
	ss = string([39B,39B])
 
	if n_elements(digits) gt 0 then begin
	  frm = '(I'+strtrim(digits,2)+'.'+strtrim(digits,2)+')'
	  dt = string(d,form=frm)
	endif else dt = strtrim(d,2)
	if sn eq 1 then dt='-'+dt else dt=' '+dt
	dt = dt+ds
 
	mt = string(m,form='(I2.2)')
	st = string(s,form='(I2.2)')
 
	out = dt+' '+mt+ms+' '+st+ss
 
	return,out
	end
