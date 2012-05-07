FUNCTION GAUSSIAN_FIT,X,Y,YFIT,YBAND,WEIGHT = WEIGHT
;+
; NAME:
;	GAUSSIAN_FIT
; PURPOSE:
;	Fits a gaussian using a least square polynomial fit (poly_fit) 
;	to the log of the data.
; CATEGORY:
;	?? - CURVE FITTING.
; CALLING SEQUENCE:
;	COEFF = GAUSSIAN_FIT(X,Y[,YFIT,YBAND,WEIGHT = WEIGHT] )
; INPUTS:
;	X = independent variable vector.
;	Y = dependent variable vector, should be same length as x.
;
; OUTPUTS:
;	Function result= Coefficient vector, length 2.
;	first coeff is the 1/e width,
;	second coeff is the x value of the peak
;	third coeff is the peak y value
;   OPTIONAL PARAMETERS:
;	YFIT = Vector of calculated Y's.  Has error + or - YBAND.
;	YBAND = Error estimate for each point = 1 sigma (untested)
;	WEIGHT = weighting of data for fitting
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
;	ON_ERROR,2		;RETURN TO CALLER IF ERROR
	XX = X*1.		;BE SURE X IS FLOATING OR DOUBLE
	N = N_ELEMENTS(X) 	;SIZE
	IF N NE N_ELEMENTS(Y) THEN $
	  message,'X and Y must have same # of elements'
;
	case (n_params(0)) of
		0	: message,'X and Y must be given'
		1	: message,'X and Y must be given'
		else	: ;continue
	endcase
	
	coeff = fltarr(3)
	yvar  = fltarr(3)
	YFIT = fltarr(N)
	YBAND = fltarr(N)

	coeff = [0.0,0.0,0.0]
	goodpts = where(Y gt 0, count)

	if (count gt 0) then begin

		ylimit = min(Y(goodpts))/10.  
		yy = alog(Y > ylimit)

		if (not keyword_set(WEIGHT)) then begin
			ymax = max(Y,maxi)
			xwt = 1/(1+(X - X(maxi))^2*10.)
			;WEIGHT = Y > ylimit
			;WEIGHT = WEIGHT*xwt
			WEIGHT = xwt
		endif
	
		polycoeff = svdfit(X,yy,3,weight=WEIGHT,yfit=YFIT,var=yvar)

		coeff(0) = 1/sqrt(-polycoeff(2))
		coeff(1) = -0.5*polycoeff(1)/polycoeff(2)
		
		YFIT = exp(YFIT)
		tmp = exp( -(X-coeff(1))^2 / coeff(0)^2 )
		coeff(2) = median (YFIT/tmp)
		YBAND = (sqrt(yvar)#[X*X,X,1])*YFIT
	
	endif 

	return,coeff
END
