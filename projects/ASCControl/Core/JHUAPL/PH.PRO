;-------------------------------------------------------------
;+
; NAME:
;       PH
; PURPOSE:
;       Return the phase of a complex number.
; CATEGORY:
; CALLING SEQUENCE:
;       p = ph(z)
; INPUTS:
;       z = a complex number or array.    in
; KEYWORD PARAMETERS:
;       Keywords:
;         /DEGREES returns result in degrees.
; OUTPUTS:
;       p = phase of z.                   out
; COMMON BLOCKS:
; NOTES:
;       Notes: results between -Pi and Pi (-180 and 180 deg).
;         Undefined phases are set to 999.
; MODIFICATION HISTORY:
;       R. Sterner, 13 May, 1993
;
; Copyright (C) 1993, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
 
	function ph, z, degrees=deg, help=hlp
 
	if (n_params(0) lt 1) or keyword_set(hlp) then begin
	  print,' Return the phase of a complex number.'
	  print,' p = ph(z)'
	  print,'   z = a complex number or array.    in'
	  print,'   p = phase of z.                   out'
	  print,' Keywords:'
	  print,'   /DEGREES returns result in degrees.'
	  print,' Notes: results between -Pi and Pi (-180 and 180 deg).'
	  print,'   Undefined phases are set to 999.'
	  return, -1
	endif
 
	n = n_elements(z)			; Array size.
	p = make_array(size=size(float([z])))   ; Set up results array.
	w = where(z ne 0.,c)			; Find non-zero elements.
	wz = where(z eq 0.,cz)			; Find zero elements.
	if c gt 0 then p(w) = atan(z(w))	; Do non-zero elements.
	if keyword_set(deg) then p = p*!radeg	; Convert to degrees.
	if cz gt 0 then p(wz) = 999.		; Flag undefined phases.
	if n eq 1 then p = p(0)			; Return a scalar.
 
	return,p
	end
