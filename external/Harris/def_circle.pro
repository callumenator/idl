;-----------------------------------------------------------------
	pro def_circle, size, fill=fill,color=color,thick=thick

; this routine will define a circular symbol, use !p.sym=8 to use it
; giving it optional non-default thickness and color. 
; Optionally fills circle.		-- (default = open) 
; Size is in units of a character size	-- (default = 1.2)

;+
; NAME:			def_circle
;
; PURPOSE:		defines the user symbol (#8) to be a circle,
;			either hollow or filled. Use !p.sym=8 to use it
;
; CATEGORY:		Utility
;
; CALLING SEQUENCE:	def_circle
;			def_circle,/fill,color=120
;			def_circle,size
;
; INPUTS:
;			size	= option size of the symbol in units of 
;				  character size (default = 1.2)
;
;		KEYWORDS:
;			fill	= fill to make a solid circle. Default is open
;			color	= color index used for the filling
;			thick	= thickness of the line defining the symbol
;
; OUTPUTS:
;
; COMMON BLOCKS:
;	none.
; SIDE EFFECTS:
;	none.
; MODIFICATION HISTORY:
;	Written by: Trevor Harris, Physics Dept., University of Adelaide,
;		July, 1990.
;
;-

; this routine will define a circular symbol, use !p.sym=8 to use it
; giving it optional non-default thickness and color. 
; Optionally fills circle.		-- (default = open) 
; Size is in units of a character size	-- (default = 1.2)

	phi = findgen(9)/8.*2*!pi

	;set the size
	if (n_elements(size) le 0) then size = 1.2

	x = size*sin(phi)	&	y = size*cos(phi)

	if (not keyword_set(fill)) then fill=0
	if (not keyword_set(thick)) then thick=1
	if (not keyword_set(color)) then usersym,x,y,fill=fill,thick=thick $
	else usersym,x,y,fill=fill,thick=thick,color=color

	return
	end
	
