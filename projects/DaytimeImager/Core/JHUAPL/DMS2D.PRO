;-------------------------------------------------------------
;+
; NAME:
;       DMS2D
; PURPOSE:
;       Convert from Degrees, MInutes, and seconds to degrees.
; CATEGORY:
; CALLING SEQUENCE:
;       d = dms2d(s)
; INPUTS:
;       s = input text string with deg, min, sec.    in
;         Ex: "3d 08m 30s" or "3 8 30".
; KEYWORD PARAMETERS:
; OUTPUTS:
;       d = returned angle in degrees.               out
; COMMON BLOCKS:
; NOTES:
;       Notes: scalar value only.  Units symbols ignored,
;         first item assumed deg, 2nd minutes, 3rd seconds.
; MODIFICATION HISTORY:
;       R. Sterner, 1998 Feb 3
;
; Copyright (C) 1998, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	function dms2d, in0, help=hlp
 
	if (n_params(0) lt 1) or keyword_set(hlp) then begin
	  print,' Convert from Degrees, MInutes, and seconds to degrees.'
	  print,' d = dms2d(s)'
	  print,'   s = input text string with deg, min, sec.    in'
	  print,'     Ex: "3d 08m 30s" or "3 8 30".'
	  print,'   d = returned angle in degrees.               out'
	  print,' Notes: scalar value only.  Units symbols ignored,'
	  print,'   first item assumed deg, 2nd minutes, 3rd seconds.'
	  return,''
	endif
 
	in = repchr(in0,',')
 
	d = getwrd(in,0)
	m = getwrd(in,1)
	s = getwrd(in,2)
 
	return, d + m/60d0 + s/3600d0
 
	end
