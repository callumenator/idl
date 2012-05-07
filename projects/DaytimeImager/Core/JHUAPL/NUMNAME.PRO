;-------------------------------------------------------------
;+
; NAME:
;       NUMNAME
; PURPOSE:
;       Generate names or text strings with embedded numbers.
; CATEGORY:
; CALLING SEQUENCE:
;       name = numname(pat, i, [j, k])
; INPUTS:
;       pat = pattern of text string.                      in
;       i = number to substitute for # in pat.             in
;       j = number to substitute for $ in pat.             in
;       k = number to substitute for % in pat.             in
; KEYWORD PARAMETERS:
;       Keywords:
;         DIGITS=d number of digits to force in name (def=none).
; OUTPUTS:
;       name = resulting text string.                      out
; COMMON BLOCKS:
; NOTES:
;       Notes: Ex1: pat = 'file#.txt',  i=7, name='file7.txt'
;          Ex2: pat = 'A#B$C%D', i=1, j=2, k=3, name='A1B2C3D'
;          Ex3: pat='A#B', i=5, DIGITS=4, name='A0005B'.
;          If j and k are not given then $ and % are not changed
;          in pat if they occur.
;          Inverse of namenum, see namenum.
; MODIFICATION HISTORY:
;       R. Sterner, 11 Jan, 1990
;	R. Sterner,  3 Sep, 1992 --- fixed an integer overflow problem
;	  found by George Simon at Sac Peak NSO.
;
; Copyright (C) 1990, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
 
	function numname, pat, i, j, k, help=hlp, digits=dig
 
	if (n_params(0) lt 2) or keyword_set(hlp) then begin
	  print,' Generate names or text strings with embedded numbers.'
	  print,' name = numname(pat, i, [j, k])'
	  print,'   pat = pattern of text string.                      in'
	  print,'   i = number to substitute for # in pat.             in'
	  print,'   j = number to substitute for $ in pat.             in'
	  print,'   k = number to substitute for % in pat.             in'
	  print,'   name = resulting text string.                      out'
	  print,' Keywords:'
	  print,'   DIGITS=d number of digits to force in name (def=none).'
	  print," Notes: Ex1: pat = 'file#.txt',  i=7, name='file7.txt'"
	  print,"    Ex2: pat = 'A#B$C%D', i=1, j=2, k=3, name='A1B2C3D'"
	  print,"    Ex3: pat='A#B', i=5, DIGITS=4, name='A0005B'."
	  print,'    If j and k are not given then $ and % are not changed'
	  print,'    in pat if they occur.'
	  print,'    Inverse of namenum, see namenum.'
	  return, -1
	endif
 
	if not keyword_set(dig) then dig = 0
	z = '0000000000'			; Leading zeros.
 
	ii = strtrim(long(i),2)
	if keyword_set(dig) then ii = strmid(z,0,dig-strlen(ii)) + ii
	name = stress(pat, 'R', 0, '#', ii)
	if n_params(0) lt 3 then return, name
 
	jj = strtrim(long(j),2)
	if keyword_set(dig) then jj = strmid(z,0,dig-strlen(jj)) + jj
	name = stress(name, 'R', 0, '$', jj)
	if n_params(0) lt 4 then return, name
 
	kk = strtrim(long(k),2)
	if keyword_set(dig) then kk = strmid(z,0,dig-strlen(kk)) + kk
	name = stress(name, 'R', 0, '%', kk)
	return, name
 
	end
