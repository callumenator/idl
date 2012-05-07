;----------------------------------------------------------------------
	pro psetup,file, next=next, horizontal=horizontal, vertical=vertical,$
		portrait=portrait, landscape=landscape,$
		lo_resolution=lo_resolution, med_resolution=med_resolution,$
		high_resolution=high_resolution,$
		incolour=incolour, color=color, encapsulate=encapsulate,$
		longside=longside, shortside=shortside, centre = centre,$
		longoffset=longoffset, shortoffset=shortoffset
;+
; NAME:			psetup
;
; PURPOSE:		Suite of procedures that provide easy and versatile 
;			customisation of the plotted page for PostScript 
;			(plus other functionality)
;
; CATEGORY:		plot Utility
;
; CALLING SEQUENCE:	psetup
;			psetup,filename	
;			psetup,file, /NEXT, /LANDSCAPE, /HIGH_RES, /INCOLOUR
;
; INPUTS:
;   OPTIONAL PARAMETERS:
;			file 	= the name of the created PS file 
;				  (default = idl.ps)
;	KEYWORDS:
;			NEXT 	= if set then append a number to the file name
;				  thus the default becomes idl-1.ps.
;				  This number is appended to the 
;				  file name to allow multiple files to be 
;				  generated without overwriting each other. 
;				  The number is reset with the /RESET keyword 
;				  using PSFILE
;				  The number is incremented with each call to 
;				  PSETUP,/next
;			HORIZONTAL = setup plot in landscape mode
;				(longer side aligned with x-axis)
;			LANDSCAPE = setup plot in landscape mode
;				(longer side aligned with x-axis)
;			VERTICAL = setup plot in portrait mode
;				(longer side aligned with y-axis)
;			PORTRAIT = setup plot in portrait mode
;				(longer side aligned with y-axis)
;			LO_RESOLUTION = set the PS colour (gray-scale) 
;				resolution to be 4 shades
;			MED_RESOLUTION = set the PS colour (gray-scale) 
;				resolution to be 16 shades
;			HIGH_RESOLUTION = set the PS colour (gray-scale) 
;				resolution to be 256 shades
;			INCOLOUR = create colour PS (.cps), 
;				default = gray-scale (.ps)
;			COLOR	 = create colour PS (.cps), 
;				default = gray-scale (.ps)
;			ENCAPSULATE = create encapsulated PS (.eps or .cep)
;			LONGSIDE = set the length (in cm) of the long side of  
;				the plot page. NB: this is the long side of  
;				the paper, not the x or y axis as this  
;				relationship will vary with the /LAND and  
;				/PORT keywords. The "longside" is the x-axis  
;				in landscape mode and the y-axis in potrait  
;				mode. (default = 29.7 - 8.0 cm = A4 + border)
;			SHORTSIDE = set the length (in cm) of the short side of
;				the plot page. NB: this is the short side of  
;				the paper, not the x or y axis as this  
;				relationship will vary with the /LAND and  
;				/PORT keywords. The "shortside" is the y-axis  
;				in landscape mode and the x-axis in potrait  
;				mode. (default = 21.0 - 5.3 cm = A4 + border)
;			CENTRE = set the offsets so that the diagram is 
;				centred on an A4 page. 
;				Overrides LONG/SHORTOFFSET
;			LONGOFFSET = set the length (in cm) of the long side 
;				origin offset. This will be the from the lower
;				left-hand-side of the plot.
;				NB: this is for the long side of the paper,
;				not the x or y axis as this relationship will
;				vary with the /LAND and /PORT keywords.  
;			SHORTOFFSET = set the length (in cm) of the short side 
;				origin offset. This will be the from the lower
;				left-hand-side of the plot.
;				NB: this is for the short side of the paper,
;				not the x or y axis as this relationship will
;				vary with the /LAND and /PORT keywords. 
;			NB: a default offset is used that allows room for 
;			binding and a border around the page
;
; OUTPUTS:		none
;
; COMMON BLOCKS:
;			PSET
;			colors	;to get the original colour table
;
; SIDE EFFECTS:		sets device to PS and sets PS device parameters
;	
; MODIFICATION HISTORY:
;	Written by: Trevor Harris, Physics Dept., University of Adelaide,
;		July, 1990.
;	Mods 15-Oct-93	T.J.H. allowed for the use of a different size colour 
;		table on the PS and previous plot devices.
;	Mods 22-Dec-93	T.J.H. Added ability to change the origin offset via
;		KEYWORDS CENTRE, SHORTOFFSET and LONGOFFSET
;	Mods 20-Sep-94  T.J.H. corrected intention of LONG/SHORTOFFSET. They
;		relate to the lower LHS of plot. Zero is now a valid value
;
;-

common pset, n, lfile, encaps, colour, bppix
common colors, r_orig, g_orig, b_orig, r_curr, g_curr, b_curr


a4long		= 29.7 ; cm
a4short		= 21.0 ; cm
thesis_longoffset	=  4.0 ; cm
thesis_shortoffset	=  3.5 ; cm

IF ( N_ELEMENTS(shortoffset) LE 0) THEN shortoffset = thesis_shortoffset ; cm
IF ( N_ELEMENTS(longoffset) LE 0 ) THEN longoffset  = thesis_longoffset ; cm

if ( not keyword_set(shortside)) then shortside = a4short-shortoffset-1.8 ; cm
if ( not keyword_set(longside) ) then longside  = a4long -longoffset -4.0 ; cm

if keyword_set(centre) then $
   begin
     shortoffset = (a4short-shortside)/2;   -1.8 ; cm
     longoffset = (a4long-longside)/2   ;   -4.0 ; cm
   endif

if ( keyword_set(incolour) ) then colour = 1.00
if ( keyword_set(color)    ) then colour = 1.00
if ( keyword_set(encapsulated) ) then encaps = 1.00

;bppix = bits_per_pixel,     normally set to 4 =  16 shades
;if high_resolution chosen then bppix set to 8 = 256 shades
;if lo_resolution chosen  then  bppix set to 2 =   4 shades

if (n_elements(bppix) le 0) then bppix = 4 ;set the default (medium) resolution
if ( keyword_set(high_resolution) ) then bppix = 8 
if ( keyword_set(med_resolution)  ) then bppix = 4 
if ( keyword_set(lo_resolution)   ) then bppix = 2

if (n_params() lt 1) then $
	if ((n_elements(lfile) gt 0)) then file = lfile else file = 'idl'

if (n_elements(n) eq 0) then n=0

if (strupcase(!d.name) eq 'PS') then device,/close else set_plot,'ps'

horiz=0
if (keyword_set(horizontal)) then horiz=1
if (keyword_set(vertical)) then horiz=0
if (keyword_set(landscape)) then horiz=1
if (keyword_set(portrait)) then horiz=0

ps = strpos(strupcase(file),'.PS')
if (ps gt 0) then file = strmid(file,0,ps)

lfile = file
if (keyword_set(next)) then begin
	n = n+1
	file = file+'-'+string(n)
endif
if (n_elements(encaps)) then encapsulate = encaps*1b else encapsulate = 0b
if (n_elements(colour)) then incolour = colour*1b else incolour = 0b

;if ( keyword_set(incolour) ) then bppix = 4 ;force 16 colours at the moment !!

filetxt='% PSETUP: Sending'
if (keyword_set(incolour)) then begin
	if (keyword_set(encapsulate)) then begin
		file = file+'.cep' 
		filetxt = filetxt+' encapsulated'
	endif else file = file+'.cps'
	whitebg	;make the background colour white and foreground maxcol
	filetxt = filetxt+' COLOUR'
endif else begin
	if (keyword_set(encapsulate)) then begin
		file = file+'.eps' 
		filetxt = filetxt+' encapsulated'
	endif else file = file+'.ps' 
endelse
file = strcompress(file,/remove_all)
filetxt = filetxt+' PostScript output to file "'+file+'"'+string(2^bppix,form='(" (",i3," shades)")')
print, filetxt

cm = "( ' PostScript Pagesize set at ',f5.1,' x',f5.1,' cm ')"
IF (N_ELEMENTS(longside) AND N_ELEMENTS(shortside) ) THEN BEGIN
  IF ((longside * shortside) GT 0) THEN print, shortside, longside, FORM=cm $
  ELSE print, 21.0 -3.5 -1.8, 29.7 -4.0 -4.0, FORM=cm 
ENDIF ELSE print, 21.0 -3.5 -1.8, 29.7 -4.0 -4.0, FORM=cm 

cm = "( ' PostScript Page offset set at ',f5.1,' x',f5.1,' cm ')"
IF (N_ELEMENTS(longoffset) AND N_ELEMENTS(shortoffset) ) THEN $
  print, shortoffset, longoffset, FORM=cm


IF (horiz) THEN $
  device, XSIZE=longside, YSIZE=shortside, $
  XOFF=shortoffset, YOFF=a4long -longoffset, $
  $ ;;xoff=a4short-shortside-shortoffset+1.0,yoff=a4long-longoffset-1.0,$
  FILENAME=file, /LANDSCAPE, ENCAPS=encapsulate, BITS=bppix, COLOR=incolour $
ELSE device, XSIZE=shortside, YSIZE=longside, $
  XOFF=shortoffset, YOFF=longoffset, $
  FILENAME=file, /PORTRAIT, ENCAPS=encapsulate, BITS=bppix, COLOR=incolour

;stretch original colour table to fit the chosen resolution (if using colour)
if (keyword_set(incolour) and (n_elements(r_orig) gt 0)) then begin
    current_ct_sz = n_elements(r_orig)
    if (current_ct_sz ne !d.table_size) then begin ;interpolate/extrapolate
	form = '("% PSETUP: Extrapolating Current colour-table from ",i3," to ",i3," elements")'
	print,form=form,current_ct_sz,!d.table_size

	p = (lindgen(!d.table_size) * current_ct_sz) /!d.table_size

	;also need to reverse the colour table ??? 
;;	; (but keep the first and last elements the same as  
;;	; !p.color and !p.background are automatically swapped in PS)
        r_ps = reverse(r_orig(p))
        g_ps = reverse(g_orig(p))
        b_ps = reverse(b_orig(p))
;;        r_ps([0,!d.table_size-1]) = r_orig([current_ct_sz-1,0])
;;        g_ps([0,!d.table_size-1]) = g_orig([current_ct_sz-1,0])
;;        b_ps([0,!d.table_size-1]) = b_orig([current_ct_sz-1,0])

	tvlct,r_ps, g_ps, b_ps

    endif

    whitebg	; set the background to white and foreground to black

endif

return
end


