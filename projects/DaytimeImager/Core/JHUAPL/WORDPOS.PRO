;-------------------------------------------------------------
;+
; NAME:
;       WORDPOS
; PURPOSE:
;       Gives word number in a reference string for a search word.
; CATEGORY:
; CALLING SEQUENCE:
;       l = wordpos(ref,s)
; INPUTS:
;       ref = reference string of words.                            in
;       s = word to find in ref.                                    in
; KEYWORD PARAMETERS:
; OUTPUTS:
;       l = word number in ref where s was found. 0 is first word.  out
;         -1 means not found.
; COMMON BLOCKS:
; NOTES:
;       Notes: Example: wordpos('JAN FEB MAR APR MAY JUN', 'MAY') is 4. 
; MODIFICATION HISTORY:
;       R. Sterner. 20 Aug, 1986.
;       R. Sterner, 27 Dec, 1989 --- converted to SUN.
;
; Copyright (C) 1986, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
 
	FUNCTION WORDPOS, REF, S, help=hlp
 
	if (n_params(0) lt 2) or keyword_set(hlp) then begin
	  print,' Gives word number in a reference string for a search word.'
	  print,' l = wordpos(ref,s)'
	  print,'   ref = reference string of words.                            in'
	  print,'   s = word to find in ref.                                    in'
	  print,'   l = word number in ref where s was found. 0 is first word.  out'
	  print,'     -1 means not found.'
	  print," Notes: Example: wordpos('JAN FEB MAR APR MAY JUN', 'MAY') is 4. "
	  return, -1
	endif
 
	L = 0
LOOP:	W = GETWRD(REF, L)
	IF W EQ '' THEN RETURN, -1
	IF S EQ W THEN RETURN, L
	L = L + 1
	GOTO, LOOP
	END
