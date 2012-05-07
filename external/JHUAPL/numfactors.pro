;-------------------------------------------------------------
;+
; NAME:
;       NUMFACTORS
; PURPOSE:
;       Gives the number of factors of a number.
; CATEGORY:
; CALLING SEQUENCE:
;       nf = numfactors(x)
; INPUTS:
;       x = number to factor.         in
; KEYWORD PARAMETERS:
; OUTPUTS:
;       nf = number of factors of x.  out
;         Does not include 1 and x.
; COMMON BLOCKS:
; NOTES:
;       Note: let the factors of x be described by p, the array
;         of prime factors, and n, the count of each prime factor.
;         The i'th prime factor, p(i), may occur from 0 to n(i)
;         times (that is, up to n(i)+1 times) in any given factor
;         of x.  The total number of factors is the product of the
;         maximum number of occurences of each prime factor.
;         For example: let n = [3,1,1], then the total number of
;         factors, nf = 4*2*2.  To exclude 1 and x subtract 2.
;         (From a conversation with Robert Jensen, JHU/APL.)
;         See also prime, factor, print_fact.
; MODIFICATION HISTORY:
;       R. Sterner, 25 Oct, 1990
;       R. Sterner, 26 Feb, 1991 --- Renamed from num_factors.pro
;       R. Sterner,  5 Feb, 1993 --- Modified to handle arrays.
;
; Copyright (C) 1990, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
 
	function numfactors, x, help=hlp
 
	if (n_params(0) lt 1) or keyword_set(hlp) then begin
	  print,' Gives the number of factors of a number.'
	  print,' nf = numfactors(x)'
	  print,'   x = number to factor.         in'
	  print,'   nf = number of factors of x.  out'
	  print,'     Does not include 1 and x.'
	  print,' Note: let the factors of x be described by p, the array'
	  print,'   of prime factors, and n, the count of each prime factor.'
	  print,"   The i'th prime factor, p(i), may occur from 0 to n(i)"
	  print,'   times (that is, up to n(i)+1 times) in any given factor'
	  print,'   of x.  The total number of factors is the product of the'
	  print,'   maximum number of occurences of each prime factor.'
	  print,'   For example: let n = [3,1,1], then the total number of'
	  print,'   factors, nf = 4*2*2.  To exclude 1 and x subtract 2.'
	  print,'   (From a conversation with Robert Jensen, JHU/APL.)'
	  print,'   See also prime, factor, print_fact.'
	  return, -1
	endif
 
	nf = fix(x)		; Just set up an array to hold # factors.
	for j=0,n_elements(x)-1 do begin	; Loop through numbers.
	  factor, x(j), p, n			; Factor x(j).
	  t = 1L
	  for i = 0, n_elements(n)-1 do t = t*(n(i)+1)  ; # factors.
	  nf(j) = t-2				; Store # factors for x(j).
	endfor
 
	return, nf
 
	end
