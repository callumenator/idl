;----------------------------------------------------------------------
	pro pscolour,reset=reset,grey=grey,color=color
;+
; NAME:			pscolour
;
; PURPOSE:		Toggles the colour switch
;			Part of the PSETUP Suite of procedures that provide 
;			easy and versatile 
;			customisation of the plotted page for PostScript 
;			(plus other functionality)
;
; CATEGORY:		plot Utility
;
; CALLING SEQUENCE:	pscolour
;			pscolour, /RESET, /COLOR
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
;			GREY = create gray-scale PS (.ps) 
;				This is the reverse toggle of /COLOR
;			COLOR	 = create colour PS (.cps), 
;				default = gray-scale (.ps)
;
; OUTPUTS:		none
;
; COMMON BLOCKS:
;			PSET
; SIDE EFFECTS:		sets COLOUR flag in common PSET
;	
; MODIFICATION HISTORY:
;	Written by: Trevor Harris, Physics Dept., University of Adelaide,
;		July, 1990.
;
;-

common pset, n, lfile, encaps, colour, bppix

if (n_elements(colour)) then colour = not colour*1.00 else colour = 1.00

if (keyword_set(grey)) then colour = 0.00	;force grey-scale
if (keyword_set(color)) then colour = 1.00	;force colour

print,' '
if (colour) then $
	print,' ..... Colour PostScript ENABLED ' $
else $
	print,' ..... PostScript will be in Grey_Scale '
print,' '

if (keyword_set(reset)) then n = reset-1

return
end
