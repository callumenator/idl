;-------------------------------------------------------------
;+
; NAME:
;       PRINT_FACT
; PURPOSE:
;       Print prime factors found by the factor routine.
; CATEGORY:
; CALLING SEQUENCE:
;       print_fact, p, n
; INPUTS:
;       p = prime factors.          in
;       n = number of each factor.  in
; KEYWORD PARAMETERS:
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
; MODIFICATION HISTORY:
;       R. Sterner  4 Oct, 1988.
;       RES 25 Oct, 1990 --- converted to IDL V2.
;       R. Sterner, 26 Feb, 1991 --- Renamed from print_factors.pro
;
; Copyright (C) 1988, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
 
	pro print_fact, p, n, help=hlp
 
	if (n_params(0) lt 2) or keyword_set(hlp) then begin
	  print,' Print prime factors found by the factor routine.'
	  print,' print_fact, p, n'
	  print,'   p = prime factors.          in'
	  print,'   n = number of each factor.  in'
	  return
	endif
 
	w = where(n gt 0)	; Find only primes used.
	pp = long(p(w))		; Drop ununsed primes.
	nn = long(n(w))		; Drop unused counts.
	;-------  Compute number from it's prime factors.  ----------
	t = 1L
	for i = 0, n_elements(pp)-1 do t = t * pp(i)^nn(i)
	;-------  Print number and prime factor powers.  ------------
	print,'    '+spc(strlen(strtrim(t,2))),nn
	;-------  Print prime factors themselves.  -----------------
	print,strtrim(t,2),' = ',pp
 
	return
	end
