;-----------------------------------------------------------------
	pro plot_circle, size, fill=fill,$
		color=color,thick=thick,overplot=overplot
;+
; NAME:			plot_circle
;
; PURPOSE:		plots a circle on the current plot device
;
; CATEGORY:		plot utility
;
; CALLING SEQUENCE:	plot_circle, size, /FILL, COLOR=c, THICK=t, /OVERPLOT
;
; INPUTS:		size	= radius of circle in data units
;
;	KEYWORDS:
;			FILL	= solid fill the circle
;			COLOR	= colour to fill with
;			THICK	= thickness of the line defining the circle
;			OVERPLOT = overplot rather than create a new plot
;
; OUTPUTS:		none
;
; COMMON BLOCKS:
;	none.
; SIDE EFFECTS:		plots to current plot device
;	
; MODIFICATION HISTORY:
;	Written by: Trevor Harris, Physics Dept., University of Adelaide,
;		July, 1990.
;
;-

; this routine will plot a circle of specified radius
; giving it optional non-default thickness and color. 
; Optionally fills circle.		-- (default = open) 

	phi = findgen(90)/89.*2*!pi

	;set the size
	if (n_elements(size) le 0) then size = max(abs([!x.crange,!y.crange]))
	if ((size) le 0) then size = max(abs([!x.range,!y.range]))

	x = size*sin(phi)	&	y = size*cos(phi)

	if (not keyword_set(thick)) then thick=1

	if (keyword_set(overplot)) then begin
		if (not keyword_set(color)) $
		then oplot,x,y,thick=thick $
		else oplot,x,y,thick=thick,color=color
	endif else begin
		!x.style = 5 	&	!y.style = 5
		if (not keyword_set(color)) $
		then plot,x,y,thick=thick,/noclip $
		else plot,x,y,thick=thick,/noclip,color=color
	endelse

	if (keyword_set(fill)) then begin
	if (keyword_set(color)) then polyfill,x,y,col=color else polyfill,x,y
	endif

	return
	end
	
