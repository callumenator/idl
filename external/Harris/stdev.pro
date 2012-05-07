;----------------------------------------------------------------------------
	Function STDEV, Array, Mean
;
;+
; NAME:
;	STDEV
; PURPOSE:
;	Compute the standard deviation and optionally the
;	mean of any array.
; CATEGORY:
;	G1- Simple calculations on statistical data.
; CALLING SEQUENCE:
;	Result = STDEV( ARRAY)  ... or:
;	Result = STDEV( ARRAY, MEAN)
; INPUTS:
;	Array =data array, may be any type except string.
;
; OUTPUTS:
;	function result = standard deviation (sample variance
;		because the divisor is N-1) of array.
;		
; OPTIONAL OUTPUT PARAMETERS:
;	MEAN = mean of data array.
; COMMON BLOCKS:
;	None.
; SIDE EFFECTS:
;	None.
; RESTRICTIONS:
;	None.
; PROCEDURE:
;	Mean = total(array)/n_elements(array)
;	stdev = sqrt((total(array^2) - n*mean^2)/(n-1))
; MODIFICATION HISTORY:
;	DMS, RSI, Sept. 1983.
;	TJH, rewrote to add half max range , Oct. 1991
;	TJH, changed the stdev calc to use (sumsq - meansq) as this is more 
;		precise (doesnt take sum of differences), Nov, 1992
;-
	on_error,2		;return to caller if error
	n = n_elements([array])	;# of points.
	if n lt 1 then message, 'Number of data points must be > 0'
;
;
	mean = total([array])/n	
	if n le 6 then begin	;use half the maximum range as the error
		minval = min([array],max=maxval)
		return,(maxval-minval)*0.5
	endif else $		;return the std deviation
		return,sqrt((total([array]^2) - n*mean^2)/(n-1)) 
end

