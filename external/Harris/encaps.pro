;----------------------------------------------------------------------
	pro encaps,reset=reset
;+
; NAME:			encaps
;
; PURPOSE:		Toggles Encapsulate PS switch
;			Part of the PSETUP Suite of procedures that provide 
;			easy and versatile 
;			customisation of the plotted page for PostScript 
;			(plus other functionality)
;
; CATEGORY:		plot Utility
;
; CALLING SEQUENCE:	encaps
;			encaps,/RESET
;
; INPUTS:
;	KEYWORDS:
;			RESET	= reset the number that the /NEXT keyword in 
;				  PSETUP uses. This number is appended to the 
;				  file name to allow multiple files to be 
;				  generated without overwriting each other. 
;				  The number is reset = RESET
;				  The number is incremented with each call to 
;				  PSETUP,/next
;
; OUTPUTS:		none
;
; COMMON BLOCKS:
;			PSET
; SIDE EFFECTS:		sets ENCAPS flag in common PSET
;	
; MODIFICATION HISTORY:
;	Written by: Trevor Harris, Physics Dept., University of Adelaide,
;		July, 1990.
;
;-

common pset, n, lfile, encaps, colour, bppix


if (n_elements(encaps)) then encaps = not encaps*1.00 else encaps = 1.00

print,' '
if (encaps) then $
	print,' ..... Encapsulation of PostScript files ENABLED ' $
else $
	print,' ..... Encapsulation of PostScript files DISABLED '
print,' '

if (keyword_set(reset)) then n = reset-1

return
end
