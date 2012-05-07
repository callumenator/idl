;----------------------------------------------------------------------
	pro psfile,file,reset=reset,encapsulate=encapsulate,$
		incolour=incolour,ingrey=ingrey,color=color,$
		lo_resolution=lo_resolution,med_resolution=med_resolution,$
		high_resolution=high_resolution
;+
; NAME:			psfile
;
; PURPOSE:		Set the PS file name and resoltuion 
;			(sets plot device to PS)
;			Part of the PSETUP Suite of procedures that provide 
;			easy and versatile 
;			customisation of the plotted page for PostScript 
;			(plus other functionality)
;
; CATEGORY:		plot Utility
;
; CALLING SEQUENCE:	psfile
;			psfile,filename	
;			psfile,file, /RESET, /HIGH_RES, /INCOLOUR
;
; INPUTS:
;   OPTIONAL PARAMETERS:
;			file 	= the name of the created PS file 
;				  (default = idl.ps)
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
;			INGREY = create gray-scale PS (.ps) 
;				This is the reverse toggle of /INCOLOUR
;			INCOLOUR = create colour PS (.cps), 
;				default = gray-scale (.ps)
;			COLOR	 = create colour PS (.cps), 
;				default = gray-scale (.ps)
;			ENCAPSULATE = create encapsulated PS (.eps or .cep)
;
; OUTPUTS:		none
;
; COMMON BLOCKS:
;			PSET
; SIDE EFFECTS:		sets device to PS and sets PS device parameters
;	
; MODIFICATION HISTORY:
;	Written by: Trevor Harris, Physics Dept., University of Adelaide,
;		July, 1990.
;	Mods 15-Oct-93	T.J.H. allowed for the use of a different size colour 
;		table on the PS and previous plot devices.
;
;-

common pset, n, lfile, encaps, colour, bppix

if (keyword_set(encapsulate)) then encaps = 1.00	;force encapsulated
if (keyword_set(ingrey)) then colour = 0.00		;force grey-scale
if (keyword_set(incolour)) then colour = 1.00		;force colour
if (keyword_set(color)   ) then colour = 1.00		;force colour
if ( keyword_set(high_resolution) ) then bppix = 8	;256 shades 
if ( keyword_set(med_resolution)  ) then bppix = 4	;16 shades  
if ( keyword_set(lo_resolution)   ) then bppix = 2	;4 shades 

previous_device = !d.name
;;removed 5/2/93 TJH
;;if (!d.name eq 'PS') then device,/close else set_plot,'ps'
set_plot,'ps'

if (n_params() ge 1) then lfile = file else lfile = 'idl'
ps = strpos(lfile,'.ps')
if (ps gt 0) then lfile = strmid(lfile,0,ps)

if (keyword_set(reset)) then n = reset-1

return
end
