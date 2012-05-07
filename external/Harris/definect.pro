;---------------------------------------------------------------------
;define a colour table with the right number of colours
	pro definect, ncolours, load=load, ct=ct, $
		red=red, green=green, blue=blue
;+
; NAME:			definect
;
; PURPOSE:		defines a colour table with given number of colours
;
; CATEGORY:		Display
;
; CALLING SEQUENCE:	definect, ncolours, /load
;			definect, ncolours, /load, ct=ct
;			definect, ncolours, red=r, blue=b, green=g
;
; INPUTS:
;			ncolours = number of colours
;
;		KEYWORDS:
;			load	= load the newly defined colour table 
;				  onto the plot device
;			ct	= load the standard colour table number "ct" 
;				  and modify to have only "ncolours" colours
;
;
; OUTPUTS:
;		KEYWORDS:
;			red,green,blue = the newly defined colour table
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

	if (n_elements(ncolours) le 0) then ncolours = !d.n_colors
	;if (not keyword_set(ct)) then ct = 0

;find the current colour table arrays
;if CT set then load this colour table first

	if (keyword_set(ct)) then loadct,ct
	tvlct,r,g,b,/get

;define new colour table arrays
	ncols = n_elements(r)
	red   = replicate(r(ncols-1),256)
	green = replicate(g(ncols-1),256)
	blue  = replicate(b(ncols-1),256)


;and make them NCOLOURS number of colours
	steplength = rnd(256./float(ncolours),/up)
	step       = findgen(steplength)
	factor     = ncols/256.
	;print,steplength,factor

	for stepnumber = 0,ncolours-1 do begin
		currentstep = step+stepnumber*steplength
		colourindx  = stepnumber*steplength*factor < (ncols-1)
		;print,currentstep
		;print,stepnumber*steplength,colourindx
		red(currentstep)   = r(colourindx)+currentstep*0
		green(currentstep) = g(colourindx)+currentstep*0
		blue(currentstep)  = b(colourindx)+currentstep*0
	endfor

	;if !d.n_colors ne 256 then begin	;Interpolate
	;	p = (lindgen(!d.n_colors) * 255) / (!d.n_colors-1)
	;	red = red(p)
	;	green = green(p)
	;	blue = blue(p)
	;endif

	;red(!d.n_colors-1)   = r(ncols-1)
	;green(!d.n_colors-1) = g(ncols-1) 
	;blue(!d.n_colors-1)  = b(ncols-1)
	;red(255)   = r(ncols-1)
	;green(255) = g(ncols-1) 
	;blue(255)  = b(ncols-1)

	if (keyword_set(load)) then tvlct,red,green,blue

	return
	end







