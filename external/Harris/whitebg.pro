PRO whitebg,r,g,b
;+
; NAME:			WHITEBG
;
; PURPOSE:		forces the display to have a white background and 
;			black foreground lines by defining the the  
;			!p.background index to white (255,255,255)  
;			and the !p.color index to black (0,0,0). 
;		Nb: both the !p.background and !p.color are set by this routine
;
; CATEGORY:		Display utility
;
; CALLING SEQUENCE:	whitebg
;
; INPUTS:	none
;
; OUTPUTS:	none

; COMMON BLOCKS:
;	none.
; SIDE EFFECTS:
;	none.
; MODIFICATION HISTORY:
;	Written by: Trevor Harris, Physics Dept., University of Adelaide,
;		July, 1990.
;
;-
;  This modifies the colour table such that the background is always
;  white and the axes are black
        maxcol=!d.n_colors-1
        tvlct,r,g,b,/get
        if (!d.name eq 'PS') then begin
		!p.color = 0		&	!p.background = maxcol
		;;r(0)=0 & g(0)=0 & b(0)=0
		;;r(maxcol)=255 & g(maxcol)=255 & b(maxcol)=255
	endif else begin
		!p.color = maxcol	&	!p.background = 0
		;;r(0)=255 & g(0)=255 & b(0)=255
		;;r(maxcol)=0 & g(maxcol)=0 & b(maxcol)=0
	endelse
	r(!p.color)=0 & g(!p.color)=0 & b(!p.color)=0 ;black lines on white bg
	r(!p.background)=255 & g(!p.background)=255 & b(!p.background)=255 
        tvlct,r,g,b
END   

