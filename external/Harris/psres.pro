;----------------------------------------------------------------------
	pro psres,reset=reset,$
		lo_resolution=lo_resolution,med_resolution=med_resolution,$
		high_resolution=high_resolution
;+
; NAME:			psres
;
; PURPOSE:		Toggles the resolution switch
;			Part of the PSETUP Suite of procedures that provide 
;			easy and versatile 
;			customisation of the plotted page for PostScript 
;			(plus other functionality)
;
; CATEGORY:		plot Utility
;
; CALLING SEQUENCE:	psres
;			psres, /RESET, /HI
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
;			LO_RESOLUTION = set the PS colour (gray-scale) 
;				resolution to be 4 shades
;			MED_RESOLUTION = set the PS colour (gray-scale) 
;				resolution to be 16 shades
;			HIGH_RESOLUTION = set the PS colour (gray-scale) 
;				resolution to be 256 shades
;
; OUTPUTS:		none
;
; COMMON BLOCKS:
;			PSET
; SIDE EFFECTS:		sets RESOLUTION flag in common PSET
;	
; MODIFICATION HISTORY:
;	Written by: Trevor Harris, Physics Dept., University of Adelaide,
;		July, 1990.
;
;-

common pset, n, lfile, encaps, colour, bppix

if ( keyword_set(high_resolution) ) then bppix = 8 
if ( keyword_set(med_resolution)  ) then bppix = 4 
if ( keyword_set(lo_resolution)   ) then bppix = 2

if (n_elements(bppix) le 0) then bppix = 4 ;set the default (medium) resolution

print,' '

print,string(2^bppix,form='(" ..... PostScript will be in ",i3," shades")')

if (keyword_set(reset)) then n = reset-1

return
end
