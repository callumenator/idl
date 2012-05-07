FUNCTION totalreg,X,Y,M, YFIT = yfit, WEIGHT = weight, CHISQ = chisq, $
	SINGULAR = sing, VARIANCE = var, COVAR = covar, FUNCT = funct, $
	LAMBDA = lambda, MINIMISE = minimise, DIRECTION = direction
;+
; NAME:
;	TOTALREG
;
; PURPOSE:
;	Perform a general total least squares fit with optional error estimates
;
;	Based on the USER routine SVDFIT and accepts/outputs all the 
;	same parameters. As for SVDFIT, a user-supplied function or a built-in
;	polynomial is fit to the data.
; 
;	NOTE: Does not use SVD to solve the set of linear equations, rather it
;	uses matrix multiplication of the normal equations.
;
;	Total regression minimises the distance from each x,y point to the 
;	normal to the fitted curve, rather than the y distance. 
;	Solution based on "Matrix Computations" by G.H. Golub and C.F. Van Loan
;
; CATEGORY:
;	Curve fitting.
;
; CALLING SEQUENCE:
;	Result = TOTALREG(X, Y, M)
;
; INPUTS:
;	X:	"Independent" variable vector.  
;
;	Y:	"Dependent" variable vector. This vector should be same length 
;		as X.
;
;	M:	The number of coefficients in the fitting function.  For 
;		polynomials, M is equal to the degree of the polynomial + 1.
;
; OPTIONAL INPUTS:
;	WEIGHT:	A vector of weights for Y(i).  This vector should be the same
;		length as X and Y.
;
;		If this parameter is ommitted, 1 is assumed.  The error for 
;		each term is weighted by Weight(i) when computing the fit.  
;		Frequently, Weight(i) = 1./Sigma(i) where Sigma is the 
;		measurement error or standard deviation of Y(i).
;
;	FUNCT:	A string that contains the name of an optional user-supplied 
;		basis function with M coefficients. If omitted, polynomials
;		are used.
;
;		The function is called:
;			R = FUNCT(X,M)
;		where X is an N element vector, and the function value is an 
;		(N, M) array of the N inputs, evaluated with the M basis 
;		functions.  M is analogous to the degree of the polynomial +1 
;		if the basis function is polynomials.  For example, see the 
;		function COSINES, in the IDL User Library, which returns a 
;		basis function of:
;			R(i,j) = cos(j*x(i)).
;		For more examples, see Numerical Recipes, page 519.
;
;		The basis function for polynomials, is R(i,j) = x(i)^j.
;
;	LAMBDA: the coupling factor that defines the relative distribution of 
;		error between X and Y.
;
;     MINIMISE:	if set then Lambda will be iterated to minimise the Chi-square,
;		If Lambda passed then this will be its starting value,
;		otherwise a value of 1 is used.
;
;    DIRECTION: The initial direction for the change in lambda (only used if
;		MINIMISE is set)
;		
; OUTPUTS:
;	TOTALREG returns a vector of M coefficients.
;
; OPTIONAL OUTPUT PARAMETERS:
;
;	YFIT:	Vector of calculated Y's.
;
;	CHISQ:	Sum of squared errors (normal to the curve) multiplied by 
;		weights if weights are specified.
;
;	COVAR:	Var-Covariance matrix of the coefficients.
;
;    VARIANCE:	Sigma squared in estimate of each coeff(M).
;
;    SINGULAR:	The number of singular values returned.  This value should
;		be 0.  If not, the basis functions do not accurately
;		characterize the data.

;     LAMBDA:	The coupling factor that defines the relative distribution of 
;		error between A and b.
;
; COMMON BLOCKS:
;	None.
;
; SIDE EFFECTS:
;	
;
; MODIFICATION HISTORY:
;	SVDFIT was adapted from SVDFIT, from the book Numerical Recipes, Press,
;	et. al., Page 518.
;	minor error corrected April, 1992 (J.Murthy) 
;	Total Regression solution based on the relevent sections of the book
;	"Matrix Computations" by G.H. Golub and C.F. Van Loan
;	December, 1992 T.J.Harris
;
;-
	ON_ERROR,2		;RETURN TO CALLER IF ERROR
;	set variables
	THRESH = 1.0E-9		;Threshold used in editing singular values


; 	lambda is a coupling factor that defines the relative distribution of 
;	error between A and b
	if (not keyword_set(lambda)) then lambda = 1	 ;equally distributed

	XX = X*1.		;BE SURE X IS FLOATING OR DOUBLE
	YY = Y*1.		;BE SURE Y IS FLOATING OR DOUBLE
	N = N_ELEMENTS(XX) 	;SIZE
	IF N NE N_ELEMENTS(YY) THEN BEGIN ;SAME # OF DATA POINTS.
	  message, 'X and Y must have same # of elements.'
	  ENDIF

	sdx = stdev(XX,meanx)	&	sdy = stdev(YY,meany)
	scale = max(abs([XX,YY]))
	XX = XX/scale		&	YY = YY/scale 	;scale the data

	if n_elements(weight) ne 0 then begin
		if n_elements(weight) ne n then begin
		  message, 'Weights have wrong number of elements.'
		  endif
	  b = YY * weight	;Apply weights
	  endif else b = YY	;No weights
;

	; define coeff matrix, a, and the scaling, s
	if n_elements(funct) eq 0 then begin ;Use polynomial?
	  a = fltarr(n,m) & scl = fltarr(m,m)	;COEFF and scaling MATRICES
	  if n_elements(weight) ne 0 then tmp = float(weight) $
	  else tmp = replicate(1.,n)	;Weights are 1.
	  stmp = 1.
	  for i=0,m-1 do begin		;Make design matrix
		a(0,i) = tmp	&	scl(i,i) = stmp
		tmp = tmp * XX	&	stmp = stmp /scale
		endfor
	endif else begin		;Call user's function
		z = execute('a='+funct+'(XX,m)')
		if z ne 1 then begin
			message, 'Error calling user fcn: ' + funct
			endif
		if n_elements(weight) ne 0 then $
		  a = a * (weight # replicate(1.,m)) ;apply wts to A
	endelse

	svd,a,w,u,v			;Do the svd for a

	keep_w = double(w)

	w = keep_w
	ab = fltarr(n,m+1)	& ab(0,0) = a	& ab(*,m) = lambda*b
	svd,ab,wb			;Do the svd for a:b 
	;(lambda is a coupling factor that defines the relative distribution 
	;of error between A and b)

	;find the minimum singular values	
	; note that w is an n elements array of the singular values for A, 
	; which equals the diagonals of the analytic SVD array W
	mins = min(w)	&	minsn = min(wb)

	if (mins lt minsn) then begin
		message, 'Total least squares solution does not exist',/cont
	        covar = fltarr(m,m)
		var = fltarr(m) 
		coeff = fltarr(m)
		yfit = YY*0.0
		chisq = 99999.
		return,coeff
	endif

	good = where(w gt (max(w) * thresh), ng) ;Cutoff for sing values
	sing = m - ng		;# of singular values
	if sing ne 0 then begin
		message, 'Warning:' + strcompress(sing, /REMOVE) + $
			' singular values found.'
;modified J.M.
small=where(w le max(w)*thresh)
w(Small)=0
;
		if ng eq 0 then return,undefined
		endif
;modified J.M

; Solve the equation AX = b 
;
; This is the normal solution for linear least squares, 
; assuming all the error lies in the b (the y deviations are minimised)
;	X = inverse(transpose(A)#A) # transpose(A) # b
; or	X = V # [(1/w)#I] # (transpose(U) # b)	
; note that w is an n elements array of the singular values for A, 
; which equals the diagonals of the SVD array W
;
; can solve the equation AX = b by backsubstitution of the SVD arrays
;;;;;;;      svbksb,u,w,v,b,coeff
; for total regression we assume that the error is  distributed between the 
; A and b, thus must minimise the deviations normal to the curve
;	X = inverse(transpose(A)#A - minsn^2#I) # transpose(A) # b
; or	X = V # [1./(w*w - minsn*minsn)]*I # transpose(w#I) # (transpose(U)#b)

	; Use the SVD variables since we already have them.....
	;;j = dindgen(n)	& I = dblarr(n,n)	& I(j,j) = 1. ;identity matrix
	;;j = j*0+1	;make it all ones
	;;uu = i*0	&	uu(0,0) = u
	;;new_inv_w = 1./(w*w - minsn*minsn)#j*I(0:m-1,0:m-1) # transpose(j#w*I)
	;;coeff = v # new_inv_w # (transpose(uu) # b)
	;
	; ...OR...
	; simply use the normal equations for solutions
	j = dindgen(m)	& I = dblarr(m,m)	& I(j,j) = 1. ;identity matrix
	covar = invert(transpose(a)#a - minsn^2*I)
	coeff = covar # (transpose(a)#b)

	wt = fltarr(m)
	wt(good)=1./w(good)
	;;;NO.. wt(good)=new_inv_w(good)	;I think ??

	if n_elements(funct) eq 0 then yfit = poly(XX,coeff) $
	else begin 
		yfit = fltarr(n)
		for i=0,m-1 do yfit = yfit + coeff(i) * a(*,i) $
			/ weight	;corrected J.M.
	endelse

	;Compute first chisq
	chisq = (YY - yfit)
	if n_elements(weight) ne 0 then chisq = chisq * weight
	chisq = total(chisq^2) $
				/(1+transpose(coeff(1:*))#coeff(1:*)) 
				;/(1+transpose(coeff)#coeff)  
				;extra factor for the perp distance 
	chisq = chisq(0)	;ensure it is a scalar
	goodcoeff = coeff
	goodyfit = yfit

	if (keyword_set(minimise)) then loops = 0 else loops = 999
	cchisq = 0
	lastchisq = chisq
	inc = 2.
	if (not keyword_set(direction)) then direction = -1
	;lambda = lambda + inc
	lambdan = lambda 
	lambdad = 1.

	;;resetplt,/all
	;;plot,XX,YY,psym=8

	pdiff = (cchisq - chisq)/chisq

WHILE ((abs(pdiff) ge 0.00) and (loops lt 60)) DO BEGIN

	print,loops,lambda,chisq,cchisq
	if (direction gt 0) then lambdan = lambdan * inc $
	else lambdad = lambdad * inc
	lambda = lambdan / lambdad
	oplot,XX,yfit

	w = keep_w

	ab = fltarr(n,m+1)	& ab(0,0) = a	& ab(*,m) = lambda*b
	svd,ab,wb			;Do the svd for a:b 
	;(lambda is a coupling factor that defines the relative distribution 
	;of error between A and b)

	;find the minimum singular values	
	; note that w is an n elements array of the singular values for A, 
	; which equals the diagonals of the analytic SVD array W
	mins = min(w)	&	minsn = min(wb)

	if (mins lt minsn) then begin
		loops = 999
		goto, endd
		endif

	good = where(w gt (max(w) * thresh), ng) ;Cutoff for sing values
	sing = m - ng		;# of singular values
	if sing ne 0 then begin
		message, 'Warning:' + strcompress(sing, /REMOVE) + $
			' singular values found.'
		small=where(w le max(w)*thresh)
		w(Small)=0
		if ng eq 0 then return,undefined
		endif

	; Use the SVD variables since we already have them.....
	;;j = dindgen(n)	& I = dblarr(n,n)	& I(j,j) = 1. ;identity matrix
	;;j = j*0+1	;make it all ones
	;;uu = i*0	&	uu(0,0) = u
	;;new_inv_w = 1./(w*w - minsn*minsn)#j*I(0:m-1,0:m-1) # transpose(j#w*I)
	;;coeff = v # new_inv_w # (transpose(uu) # b)
	;
	; ...OR...
	; simply use the normal equations for solutions
	j = dindgen(m)	& I = dblarr(m,m)	& I(j,j) = 1. ;identity matrix
	covar = invert(transpose(a)#a - minsn^2*I)
	coeff = covar # (transpose(a)#b)

	wt = fltarr(m)
	wt(good)=1./w(good)

	if n_elements(funct) eq 0 then yfit = poly(XX,coeff) $
	else begin 
		yfit = fltarr(n)
		for i=0,m-1 do yfit = yfit + coeff(i) * a(*,i) $
			/ weight	;corrected J.M.
	endelse

	;Compute chisq
	cchisq = (YY - yfit)
	if n_elements(weight) ne 0 then cchisq = cchisq * weight
	cchisq = total(cchisq^2) $
				/(1+transpose(coeff(1:*))#coeff(1:*)) 
				; /(1+transpose(coeff)#coeff) 
				;extra factor for the perp distance 
	cchisq = cchisq(0)	;ensure it is a scalar

	pdiff = (cchisq - chisq)/chisq

	if (pdiff gt 0.05) then begin
		direction = -direction		;change the direction
	endif else begin
		chisq = lastchisq
		lastchisq = cchisq
		goodcoeff = coeff
		goodyfit = yfit
	endelse
	pdiff = (cchisq - chisq)/chisq
	loops = loops + 1
	print,loops,lambda,chisq,cchisq,direction

endd:
ENDWHILE

	coeff = goodcoeff
	yfit = goodyfit 

	wt = wt*wt		;Use squared w


	;UNDO THE EFFECTS OF SCALING THE DATA

	covar = invert((1./scl)#(transpose(a)#a - minsn^2*I)#(1./scl))
	; this is an un-normalised VAR-COV matrix for the fitted y values

	var = fltarr(m)         &       j = indgen(m)
        var(j) = covar(j,j)	;*sdy^2	;or not ?

	coeff = scl#coeff*scale
	yfit = yfit*scale

	;Compute the correct chisq
	chisq = (YY*scale - yfit)
	if n_elements(weight) ne 0 then chisq = chisq * weight
	chisq = total(chisq^2) $
				/(1+transpose(coeff(1:*))#coeff(1:*)) 
				;/(1+transpose(coeff)#coeff)  
				;extra factor for the perp distance 
	chisq = chisq(0)	;ensure it is a scalar

	return,coeff
end

