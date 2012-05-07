Function Gaussfit, x, y, a,order=order,noback=noback,stp=stp
;+
; NAME:
;	GAUSSFIT
;
; PURPOSE:
; 	Fit the equation y=f(x) where:
;
; 		F(x) = A0*EXP(-z^2/2) + A3 + A4*x + A5*x^2
; 			and
;		z=(x-A1)/A2
;
;	A0 = height of exp, A1 = center of exp, A2 = sigma (the width).
;	A3 = constant term, A4 = linear term, A5 = quadratic term.
; 	The parameters A0, A1, A2, A3 are estimated and then CURVEFIT is 
;	called.
;
; CATEGORY:
;	?? - fitting
;
; CALLING SEQUENCE:
;	Result = GAUSSFIT(X, Y [, A])
;
; INPUTS:
;	X:	The independent variable.  X must be a vector.
;	Y:	The dependent variable.  Y must have the same number of points
;		as X.
;
; OUTPUTS:
;	The fitted function is returned.
;
; OPTIONAL OUTPUT PARAMETERS:
;	A:	The coefficients of the fit.  A is a six-element vector as 
;		described under PURPOSE.
;
; COMMON BLOCKS:
;	None.
;
; SIDE EFFECTS:
;	None.
;
; RESTRICTIONS:
;	The peak or minimum of the Gaussian must be the largest
;	or smallest point in the Y vector.
;
; PROCEDURE:
;	If the (MAX-AVG) of Y is larger than (AVG-MIN) then it is assumed
;	that the line is an emission line, otherwise it is assumed there
;	is an absorbtion line.  The estimated center is the MAX or MIN
;	element.  The height is (MAX-AVG) or (AVG-MIN) respectively.
;	The width is found by searching out from the extrema until
;	a point is found less than the 1/e value.
;
; MODIFICATION HISTORY:
;	DMS, RSI, Dec, 1983.
;       FMW - to adjust background components and to pass A
;-
;
on_error,2                      ;Return to caller if an error occurs
n = n_elements(y)		;# of points.
c = poly_fit(x,y,1,yf)		;fit a straight line.
yd = y-yf			;difference.
;
ymax=max(yd) & xmax=x(!c) & imax=!c	;x,y and subscript of extrema
ymin=min(yd) & xmin=x(!c) & imin=!c
if not keyword_set(order) then order=3
if order lt 0 then noback=1
na=n_elements(a)
if na gt 1 then begin
   a0=a
   if na ge 1 then a1=a0(0)
   if na ge 2 then a2=a0(1)
   if na ge 3 then a3=a0(2)
   if na ge 4 then a4=a0(3)
   endif else begin
;
   if abs(ymax) gt abs(ymin) then i0=imax else i0=imin ;emiss or absorp?
   i0 = i0 > 1 < (n-2)		;never take edges
   dy=yd(i0)			;diff between extreme and mean
   del = dy/exp(1.)		;1/e value
   i=0
   while ((i0+i+1) lt n) and $	;guess at 1/2 width.
   	((i0-i) gt 0) and $
   	(abs(yd(i0+i)) gt abs(del)) and $
   	(abs(yd(i0-i)) gt abs(del)) do i=i+1
;a = [yd(i0), x(i0), abs(x(i0)-x(i0+i))]
;
   a1=yd(i0)
   a2=x(i0)
   a3=abs(x(i0)-x(i0+i))
   a4=c(0)
   endelse
a=[a1,a2,a3]
;
case 1 of
   keyword_set(noback):
   order eq 1: a=[a,c(0)]
   order eq 2: a=[a,c(0),c(1)]
   else: a=[a,c(0),c(1),0.]
   endcase
!c=0				;reset cursor for plotting
;print,a
yy=curvefit(x,y,replicate(1.,n),a,sigmaa, $
		function_name = "GAUSS_FUNCT") ;call curvefit
if keyword_set(stp) then stop,'GAUSSFIT>>>'
return,yy
end
