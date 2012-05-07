;----------------------------------------------------------------------------
		pro clearplt, all=all,x=x,y=y,z=z,p=p, invert=invert
;+
; NAME:			CLEARPLT
;
; PURPOSE:		This procedure will clear or zero all or a selection 
;			ofthe system plot variables
;
; CATEGORY:		Plot Utility
;
; CALLING SEQUENCE:	clearplt,/all		;clear the !p, !x, !y, !z 
;			clearplt,/x,/z		;clear the !x and !z variables 
;			clearplt,/x		;only clear the !x variable
;			clearplt,/x,/invert	;clear all except the !x 
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

	clearx = 0
	cleary = 0
	clearz = 0
	clearp = 1
	if (keyword_set(x)) then clearx = 1
	if (keyword_set(y)) then cleary = 1
	if (keyword_set(z)) then clearz = 1
	if (keyword_set(p)) then clearp = 1
	if (keyword_set(all)) then begin
		clearx = 1
		cleary = 1
		clearz = 1
		clearp = 1
	endif

	if (keyword_set(invert)) then begin
		clearx = not clearx
		cleary = not cleary
		clearz = not clearz
		clearp = not clearp
	endif

	if (clearx) then begin
		!x.ticks=1
		if (!x.range(0) ne !x.range(1)) then !x.tickv=!x.range $
		else !x.tickv = [0.0,0.001]
		!x.tickname=replicate(' ',30)
		!x.title=' '
		!x.ticklen=0.0
		!x.tickformat=''
	endif
	if (cleary) then begin
		!y.ticks=1
		if (!y.range(0) ne !y.range(1)) then !y.tickv=!y.range $
		else !y.tickv = [0.0,0.001]
		!y.tickname=replicate(' ',30)
		!y.title=' '
		!y.ticklen=0.0
		!y.tickformat=''
	endif
	if (clearz) then begin
		!z.ticks=1
		if (!z.range(0) ne !z.range(1)) then !z.tickv=!z.range $
		else !z.tickv = [0.0,0.001]
		!z.tickname=replicate(' ',30)
		!z.title=' '
		!z.ticklen=0.0
		!z.tickformat=''
	endif
	if (clearp) then begin
		!p.title=' '
		!p.subtitle=' '
		!p.ticklen=0.0
	endif

	return
	end








