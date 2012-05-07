PRO	FUNCT,X,A,F,PDER
;+
; NAME:
;	FUNCT
; PURPOSE:
;	EVALUATE THE SUM OF A GAUSSIAN AND A CONSTANT
;	AND OPTIONALLY RETURN THE VALUE OF IT'S PARTIAL DERIVATIVES.
;	NORMALLY, THIS FUNCTION IS USED BY CURVEFIT TO FIT THE
;	SUM OF A SPECTRAL LINE AND A VARYING BACKGROUND TO ACTUAL DATA.
;
; CATEGORY:
;	E2 - CURVE AND SURFACE FITTING.
; CALLING SEQUENCE:
;	FUNCT,X,A,F,PDER
; INPUTS:
;	X = VALUES OF INDEPENDENT VARIABLE.
;	A = PARAMETERS OF EQUATION DESCRIBED BELOW.
; OUTPUTS:
;	F = VALUE OF FUNCTION AT EACH X(I).
;
; OPTIONAL OUTPUT PARAMETERS:
;	PDER = (N_ELEMENTS(X),4) ARRAY CONTAINING THE
;		PARTIAL DERIVATIVES.  P(I,J) = DERIVATIVE
;		AT ITH POINT W/RESPECT TO JTH PARAMETER.
; COMMON BLOCKS:
;	NONE.
; SIDE EFFECTS:
;	NONE.
; RESTRICTIONS:
;	NONE.
; PROCEDURE:
;	F = A(0)*EXP(-Z^2) + A(3) 
;	Z = (X-A(1))/A(2)
; MODIFICATION HISTORY:
;	WRITTEN, DMS, RSI, SEPT, 1982.
;
;	MOD,	Amended to use only constant term, a3, in the poly fit
;		and removed error messages for EZ
;		and a2 is now the 1/e width not 1/2 width as before !!
;	T.J.Harris, Dept. of Physics, University of Adeliade,  August 1990.
;-
	ON_ERROR,2                        ;Return to caller if an error occurs

;	NOTE: A(2) is the 1/e width so should always be >= 0.
	A(2) = abs(A(2))
	Z = (X-A(1))/A(2)	;GET Z
;	EZ = EXP(-Z^2/2.)*(ABS(Z) LE 7.) ;GAUSSIAN PART IGNORE SMALL TERMS
	useZ = (ABS(Z) LE 7.) ;SMALL TERMS for GAUSSIAN
	EZ = EXP((-Z^2)*useZ)*useZ ;GAUSSIAN PART IGNORE SMALL TERMS
	F = A(0)*EZ + A(3) ;FUNCTIONS.
	IF N_PARAMS(0) LE 3 THEN RETURN ;NEED PARTIAL?
;
	PDER = FLTARR(N_ELEMENTS(X),4) ;yes, make array
	PDER(0,0) = EZ		;COMPUTE PARTIALS
	PDER(0,1) = A(0) * EZ * 2.*Z/A(2)
	PDER(0,2) = PDER(*,1) * Z
	PDER(*,3) = 1.
	RETURN
END


Function Gaussfit, x, y, a, init=init, sigma=sigma, weights=weights
;+
; NAME:
;	GAUSSFIT
; PURPOSE:
; 	Fit y=f(x) where:
; 	F(x) = a0*exp(-z^2) + a3 
; 		and z=(x-a1)/a2
;	a0 = height of exp, a1 = center of exp, a2 = 1/e width,
;	a3 = constant term
; 	Estimate the parameters a0,a1,a2,a3 and then call curvefit.
; CATEGORY:
;	?? - fitting
; CALLING SEQUENCE:
;	yfit = gaussfit(x,y,a)
; INPUTS:
;	x = independent variable, must be a vector.
;	y = dependent variable, must have the same number of points
;		as x.
; OPTIONAL INPUT PARAMETERS:
;	init = a four element vector containing initial estimates of the
;		 parameters 'a'.
;	weights = weightings for the data points
; OUTPUTS:
;	yfit = fitted function.
; OPTIONAL OUTPUT PARAMETERS:
;	a = coefficients. a four element vector as described above.
;	sigma = the standard deviations of the parameters 'a'
;
; COMMON BLOCKS:
;	None.
; SIDE EFFECTS:
;	None.
; RESTRICTIONS:
;	The peak or minimum of the gaussian must be the largest
;	or respectively the smallest point in the Y vector.
; PROCEDURE:
;	If the (max-avg) of Y is larger than (avg-min) then it is assumed
;	the line is an emission line, otherwise it is assumed there
;	is an absorbtion line.  The estimated center is the max or min
;	element.  The height is (max-avg) or (avg-min) respectively.
;	The width is foun by searching out from the extrem until
;	a point is found < the 1/e value.
; MODIFICATION HISTORY:
;	DMS, RSI, Dec, 1983.
;
;		Reduced the poly fit to be only a constant term, a3
;		Added optional input and output parameters.
;	T.J.Harris, Dept. of Physics, University of Adeliade,  August 1990.
;-
;
on_error,2                      ;Return to caller if an error occurs
a=fltarr(4)			;coefficient vector

n = n_elements(y)		;# of points.
c = poly_fit(x,y,1,yf)		;fit a straight line.
yd = y-yf			;difference.

ymax=max(yd) & xmax=x(!c) & imax=!c	;x,y and subscript of extrema
ymin=min(yd) & xmin=x(!c) & imin=!c
if abs(ymax) gt abs(ymin) then i0=imax else i0=imin ;emiss or absorp?
i0 = i0 > 1 < (n-2)		;never take edges
dy=yd(i0)			;diff between extreme and mean
del = dy/exp(1.)		;1/e value
i=0
while ((i0+i+1) lt n) and $	;guess at 1/2 width.
	((i0-i) gt 0) and $
	(abs(yd(i0+i)) gt abs(del)) and $
	(abs(yd(i0-i)) gt abs(del)) do i=i+1
a = [yd(i0), x(i0), abs(x(i0)-x(i0+i)), c(0)] ;estimates

if (n_elements(init) gt 0) then begin
	sz = size(init) < 4
	a(0:sz(sz(0)+2)-1) = init(0:sz(sz(0)+2)-1)
endif
if (n_elements(weights) eq 0) then weights = replicate(1.,n)
!c=0				;reset cursor for plotting
return,curvefit(x,y,weights,a,sigma) ;call curvefit
end

