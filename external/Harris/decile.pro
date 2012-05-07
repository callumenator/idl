;----------------------------------------------------------------------------
FUNCTION Decile, vector, percentile_values
;+
; NAME:
;	FUNCTION DECILE
;
; PURPOSE:
;	This function will compute the 10,50 and 90 %iles from the given
;	input vector unless the second parameter is supplied, in which case 
;	those values will be used.
;
; CATEGORY:
;	utilities
;
; CALLING SEQUENCE:
;	coeff = DECILE (vector)
;	coeff = DECILE (vector, percentile_values)
;
; INPUTS:
;	vector = any vector
;	percentile_values (optional) = a vector containing percentile values 
;		to be calculated (as %ages 0-100)
;
; OUTPUTS:
;	coeff = [lowerdecile,median,upperdecile]
;		a 3 element vector, fltarr(3)
;	coeff = [percentiles] as for parameter percentile_values
;		NOTE: if coefficient is a SINGLE element then it is a SCALAR,
;			OTHERWISE it is a VECTOR
;
; COMMON BLOCKS:
;	none.
;
; SIDE EFFECTS:
;	none.
;
; MODIFICATION HISTORY:
;	Written by: Trevor Harris, Physics Dept., University of Adelaide,
;		September, 1990.
;	Modified April 8, 1991, T.J.H. to give variable percentage input.
;       Modified September 9, 1994, T.J.H.
;		If input decile is a scalar value then output is a scalar
;
;-

;	on_error,2
  
  n = N_ELEMENTS(vector) 

  IF (N_ELEMENTS(percentile_values) LE 0) THEN percentile_values = [ 10., 50., 90.]

  percentile_values = (percentile_values > 0.) < 100.

  nper = N_ELEMENTS(percentile_values) 
  coeff = fltarr(nper) 
  i = 0
  IF (n GT 0) THEN BEGIN
    indices = sort(vector) 
    WHILE ( i LT nper ) DO BEGIN
      index = long(percentile_values(i) * 0.01 *(n -1) + 0.5) 
      coeff(i) = vector(indices(index) ) 
      i = i +1
    ENDWHILE
  ENDIF
  
  ;;make output coefficients a scalar if input is a scalar
  IF (N_ELEMENTS(coeff) LE 1) THEN coeff = coeff(0) 
  RETURN, coeff
END 


