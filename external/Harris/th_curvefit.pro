FUNCTION CURVEFIT,X,Y,W,A,SIGMAA,CHISQR=CHISQR
;+
; NAME:
;	CURVEFIT
; PURPOSE:
;	Non-linear least squares fit to a function of an
;	arbitrary number of parameters.
;	Function may be any non-linear function where
;	the partial derivatives are known or can be approximated.
; CATEGORY:
;	E2 - Curve and Surface Fitting
; CALLING SEQUENCE:
;	YFIT = CURVEFIT(X,Y,W,A,SIGMAA)
; INPUTS:
;	X = Row vector of independent variables.
;	Y = Row vector of dependent variable, same length as x.
;	W = Row vector of weights, same length as x and y.
;		For no weighting
;		w(i) = 1., instrumental weighting w(i) =
;		1./y(i), etc.
;	A = Vector of nterms length containing the initial estimate
;		for each parameter.  If A is double precision, calculations
;		are performed in double precision, otherwise in single prec.
;
; OUTPUTS:
;	A = Vector of parameters containing fit.
;	Function result = YFIT = Vector of calculated
;		values.
; OPTIONAL OUTPUT PARAMETERS:
;	Sigmaa = Vector of standard deviations for parameters
;		A.
;	
; COMMON BLOCKS:
;	NONE.
; SIDE EFFECTS:
;	The function to be fit must be defined and called FUNCT.
;	For an example see FUNCT in the IDL User's Libaray.
;	Call to FUNCT is:
;	FUNCT,X,A,F,PDER
; where:
;	X = Vector of NPOINT independent variables, input.
;	A = Vector of NTERMS function parameters, input.
;	F = Vector of NPOINT values of function, y(i) = funct(x(i)), output.
;	PDER = Array, (NPOINT, NTERMS), of partial derivatives of funct.
;		PDER(I,J) = DErivative of function at ith point with
;		respect to jth parameter.  Optional output parameter.
;		PDER should not be calculated if parameter is not
;		supplied in call (Unless you want to waste some time).
; RESTRICTIONS:
;	NONE.
; PROCEDURE:
;	Copied from "CURFIT", least squares fit to a non-linear
;	function, pages 237-239, Bevington, Data Reduction and Error
;	Analysis for the Physical Sciences.
;
;	"This method is the Gradient-expansion algorithm which
;	compines the best features of the gradient search with
;	the method of linearizing the fitting function."
;
;	Iterations are perform until the chi square changes by
;	only 0.1% or until 15 attempts at minimisation (with maximum of
;	20 iterations) have been performed.
;
;	The initial guess of the parameter values should be
;	as close to the actual values as possible or the solution
;	may not converge.
;
; MODIFICATION HISTORY:
;	Written, DMS, RSI, September, 1982.
;	       Amended to output CHISQR, and to set A=0 if no convergence
;	T.J.Harris, Dept. of Physics, University of Adeliade,  August 1990.
;-
	ON_ERROR,2		;RETURN TO CALLER IF ERROR
	A = 1.*A		;MAKE PARAMS FLOATING
	NTERMS = N_ELEMENTS(A)	;# OF PARAMS.
	NFREE = (N_ELEMENTS(Y)<N_ELEMENTS(X))-NTERMS ;Degs of freedom
	IF NFREE LE 0 THEN STOP,'Curvefit - not enough data points.'
	FLAMBDA = 0.001		;Initial lambda
	DIAG = INDGEN(NTERMS)*(NTERMS+1) ;SUBSCRIPTS OF DIAGONAL ELEMENTS
;
	print,'> CURVEFIT: Minimising CHISQR.....attempt '
	FOR ITER = 1,15 DO BEGIN	;Iteration loop
;
;		EVALUATE ALPHA AND BETA MATRICIES.
;
		FUNCT,X,A,YFIT,PDER	;COMPUTE FUNCTION AT A.
		BETA = (Y-YFIT)*W # PDER
		ALPHA = TRANSPOSE(PDER) # (W # (FLTARR(NTERMS)+1)*PDER)
	;
		CHISQ1 = TOTAL(W*(Y-YFIT)^2)/NFREE ;PRESENT CHI SQUARED.
	;
	;	INVERT MODIFIED CURVATURE MATRIX TO FIND NEW PARAMETERS.
	;
		count = 0
		PRINT,format="(i3,': ',$)",iter

		REPEAT BEGIN
			count = count + 1
			C = SQRT(ALPHA(DIAG) # ALPHA(DIAG))
			An_Array = ALPHA/C
			An_Array(DIAG) = 1.+FLAMBDA
			An_Array = INVERT(An_Array)
			B = A+ An_Array/C # TRANSPOSE(BETA) ;NEW PARAMS
			FUNCT,X,B,YFIT		;EVALUATE FUNCTION
			CHISQR = TOTAL(W*(Y-YFIT)^2)/NFREE ;NEW CHISQR
			FLAMBDA = FLAMBDA*10.	;ASSUME FIT GOT WORSE
			PRINT,format="(i3,$)",count
		ENDREP UNTIL ((CHISQR LE CHISQ1) or (count ge 20))
		print,' ****'
	;
		FLAMBDA = FLAMBDA/100.	;DECREASE FLAMBDA BY FACTOR OF 10
		A=B			;SAVE NEW PARAMETER ESTIMATE.
		;PRINT,'ITERATION =',ITER,' ,CHISQR =',CHISQR
		;PRINT,A
		IF ((CHISQ1-CHISQR)/CHISQ1) LE .001 THEN GOTO,DONE ;Finished?

	ENDFOR			;ITERATION LOOP
;
;	message, 'Failed to converge', /INFORMATIONAL
	print, ' >>>> CURVEFIT : ....Failed to converge. Sorry... '
	A = findgen(NTERMS)*0.0
;
DONE:	SIGMAA = SQRT(An_Array(DIAG)/ALPHA(DIAG)) ;RETURN SIGMA'S
	RETURN,YFIT		;RETURN RESULT
END
