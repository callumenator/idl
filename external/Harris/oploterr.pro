PRO OPLOTERR,X,Y,ERR, psym=PSYM, symsize=SYMSIZE, xaxis=xaxis, yaxis=yaxis, lerr=lerr, uerr=uerr
;
;+
; NAME:
;	PLOTERR
; PURPOSE:
;	Plot data points with accompanying error bars.
; CATEGORY:
; CALLING SEQUENCE:
;	OPLOTERR, [ X ,]  Y , ERR [, PSYM = psym] [,symsize=SYMSIZE] [,/xaxis] [,/yaxis] [,lerr=lerr, uerr=uerr]
; INPUTS:
;	X = array of abcissae.
;	Y = array of Y values.
;	ERR = array of error bar values.
; OPTIONAL INPUT KEYWORD PARAMETERS:
;	PSYM = plotting symbol array (default = +7)
;	SYMSIZE = plotting symbol size  (default = 1)
;	XAXIS,YAXIS = the direction of the error (defaults to yaxis)
;	LERR,UERR = lower and upper error values (overrides ERR)
; COMMON BLOCKS:
;	None.
; SIDE EFFECTS:
;	None.
; RESTRICTIONS:
;	Arrays must not be of type string.  There must be enough points to
;	plot. Assumes linear-linear plot of the data
; PROCEDURE:
;	A plot of X versus Y with error bars drawn from Y-ERR to Y+ERR 
;	(or X-ERR to X+ERR if /XAXIS set) is over-written to the output device.
; MODIFICATION HISTORY:
;	William Thompson	Applied Research Corporation
;	July, 1986		8201 Corporate Drive
;				Landover, MD  20785
;	DMS, April, 1989	Modified for Unix
;	TJH, July,  1990	Modified to overplot and allows different
;				symbols for each point
;	TJH, September, 1991	Modified to allow x or y error bars (not both)
;-
;
;  Interpret the input parameters.
;

on_error,2
np = n_params(0)
if (keyword_set(lerr)) then begin
	np = np + 1
	err = lerr
endif
if np lt 2 then begin
	print,'*** ploterr must be called with 2 or 3 parameters:'
	print,'        [ x ,] y, err'
	print,' or with 1 or 2 parameters and the keywords LERR and or UERR '
	print,'        x, y, lerr=lerr [, uerr=uerr] '
	return
endif else if np eq 2 then begin	;only y and err passed.
	yerr = abs(y)
	yy = x
	xx = indgen(n_elements(yy))
	if (keyword_set(xaxis)) then begin
		tmp = xx
		xx = yy
		yy = xx
	endif
endif else begin
	yerr = abs(err)
	yy = y
	xx = x
endelse
;

if (keyword_set(lerr)) then ylerr = abs(lerr) else ylerr = abs(yerr)
if (keyword_set(uerr)) then yuerr = abs(uerr) else yuerr = abs(ylerr)

n = n_elements(xx) < n_elements(yy)

if n lt 1 then begin
	print,'*** no points to plot, routine ploterr.'
	return
endif

nerr = n_elements(ylerr) < n_elements(yuerr)
if nerr lt 1 then begin
	print,'*** no error points to plot, routine ploterr.'
	return
endif else begin
	tmp = ylerr
	while (n_elements(tmp) lt n) do tmp = [tmp,ylerr]
	ylerr = tmp
	tmp = yuerr
	while (n_elements(tmp) lt n) do tmp = [tmp,yuerr]
	yuerr = tmp
endelse

npsym = n_elements(psym)
if n_elements(symsize) eq 0 then symsize = 1
if npsym eq 0 then begin
	ppsym = replicate(7,n)
endif else begin
	ppsym = psym
	while (n_elements(ppsym) lt n) do ppsym = [ppsym,psym]
endelse

xx = xx(0:n-1)
yy = yy(0:n-1)

if (keyword_set(xaxis)) then begin
	xlerr = ylerr(0:n-1)
	xuerr = yuerr(0:n-1)
	xlo = xx - xlerr
	xhi = xx + xuerr
	;
	;  oplot the error bars.
	;
	for i = 0,n-1 do plots,[xlo(i),xhi(i)], [yy(i), yy(i)],psym=ppsym(i),symsize=symsize,noclip=0
endif else begin
	ylerr = ylerr(0:n-1)
	yuerr = yuerr(0:n-1)
	ylo = yy - ylerr
	yhi = yy + yuerr
	;
	;  oplot the error bars.
	;
	for i = 0,n-1 do plots,[xx(i),xx(i)], [ylo(i), yhi(i)],psym=ppsym(i),symsize=symsize,noclip=0
endelse
return
end

