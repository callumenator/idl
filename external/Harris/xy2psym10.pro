;----------------------------------------------------------------------------
	pro xy2psym10,xx,yy
;+
; NAME:			xy2psym10
;
; PURPOSE:		simulate the !p.psym=10 (histogram type plotting) 
;			setting but return the actual data values used to do 
;			this. Thus filled histograms can be made using 
;			polyfill.
;			eg. given x and y, 
;				!p.psym = 0
;				xy2psym10,x,y
;				plot,x,y
;				polyfill,x,y,color=150
;
; CATEGORY:		plot utility
;
; CALLING SEQUENCE:	xy2psym10,x,y
;
; INPUTS:	x,y	= the original data to be plotted
;
; OUTPUTS:	x,y	= output data is nearly 2 X size of the input x,y
;			  contains the the vertices defining a histogram style
;			  plot
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

	num = n_elements(xx)
	inc = (xx(1)-xx(0))*0.5
	maxx = max(xx,min=minx)
	x = fltarr(2*num)
	y = x
	i = indgen(num)*2.
	x(i) = xx-inc
	y(i) = yy
	x(i+1) = xx+inc
	y(i+1) = yy
	x = ([minx,x,maxx] < maxx) > minx
	y = [0,y,0]

	xx = x
	yy = y

	return
	end


