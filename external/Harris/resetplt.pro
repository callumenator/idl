;----------------------------------------------------------------------------
		pro resetplt, all=all,x=x,y=y,z=z,p=p, invert=invert
;+
; NAME:			RESETPLT
;
; PURPOSE:		This procedure will reset all or a selection 
;			of the system plot variables to their initial values
;
; CATEGORY:		Plot Utility
;
; CALLING SEQUENCE:	resetplt,/all		;clear the !p, !x, !y, !z 
;			resetplt,/x,/z		;clear the !x and !z variables 
;			resetplt,/x		;only clear the !x variable
;			resetplt,/x,/invert	;clear all except the !x 
;
; INPUTS:		
;	KEYWORDS:
;		x,y,z,p	= clear the appropriate variable
;		all	= clear all, this is equivalent to /x,/y,/z,/p
;		invert	= invert the logic. Clear all unselected variables.
;			  Therefore "clearplt,/all,/invert" does nothing.
;
; OUTPUTS:	none
;
; COMMON BLOCKS:
;	none.
; SIDE EFFECTS:
;		The sytem plot variables are changed.
;	
; MODIFICATION HISTORY:
;	Written by: Trevor Harris, Physics Dept., University of Adelaide,
;		July, 1990.
;
;-

	resetx = 0b
	resety = 0b
	resetz = 0b
	resetp = 0b
	if (keyword_set(x)) then resetx = 1b
	if (keyword_set(y)) then resety = 1b
	if (keyword_set(z)) then resetz = 1b
	resetp = not (resetx or resety or resetz) 
	if (keyword_set(p)) then resetp = 1b
	if (keyword_set(all)) then begin
		resetx = 1b
		resety = 1b
		resetz = 1b
		resetp = 1b
	endif

	if (keyword_set(invert)) then begin
		resetx = not resetx
		resety = not resety
		resetz = not resetz
		resetp = not resetp
	endif

	if (resetx) then begin
		!x.thick=0.0
		!x.charsize=0.0
		!x.ticks=0
		!x.tickv=0
		!x.tickname=''
		!x.title=' '
		!x.range=0
		!x.ticklen=0.02
		!x.style=0
		!x.margin = [10,3]
		!x.tickformat=''
	endif
	if (resety) then begin
		!y.thick=0.0
		!y.charsize=0.0
		!y.ticks=0
		!y.tickv=0
		!y.tickname=''
		!y.title=' '
		!y.range=0
		!y.ticklen=0.02
		!y.style=0
		!y.margin = [4,2]
		!y.tickformat=''
	endif
	if (resetz) then begin
		!z.thick=0.0
		!z.charsize=0.0
		!z.ticks=0
		!z.tickv=0
		!z.tickname=''
		!z.title=' '
		!z.range=0
		!z.ticklen=0.02
		!z.style=0
		!z.margin = [0,0]
		!z.tickformat=''
	endif
	if (resetp) then begin
		!p.title=' '
		!p.subtitle=' '
		!p.ticklen=0.02
		!p.charsize=1.0
		!p.charthick=1.0
		!p.thick=1.0
		!p.linestyle=0
		!p.region = [0,0,0,0]
		!p.position = [0,0,0,0]
		!p.psym = 0
		!p.nsum = 0
	endif

	return
	end


