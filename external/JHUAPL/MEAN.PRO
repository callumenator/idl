;-------------------------------------------------------------
;+
; NAME:
;       MEAN
; PURPOSE:
;       Returns the mean of an array.
; CATEGORY:
; CALLING SEQUENCE:
;       m = mean(a)
; INPUTS:
;       a = input array.     in
; KEYWORD PARAMETERS:
; OUTPUTS:
;       m = array mean.      out
; COMMON BLOCKS:
; NOTES:
; MODIFICATION HISTORY:
;       Ray Sterner,  11 Dec, 1984.
;       Johns Hopkins University Applied Physics Laboratory.
;
; Copyright (C) 1984, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
 
	function mean,x, help=hlp
 
	if (n_params(0) lt 1) or keyword_set(hlp) then begin
	  print,' Returns the mean of an array.' 
	  print,' m = mean(a)' 
	  print,'   a = input array.     in'
	  print,'   m = array mean.      out' 
	  return, -1
	endif
 
	return, total(x)/n_elements(x)
	end
