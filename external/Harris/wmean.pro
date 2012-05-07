;----------------------------------------------------------------------------
	function wmean, data, wts, sd = sd
;+
; NAME:		WMEAN
;
; PURPOSE:	trivial function to produce the weighted mean of a set of data
;
; CATEGORY:	Mathematical utilities
;
; CALLING SEQUENCE: 
;		result = wmean( data, weights, sd=sd)
;
; INPUTS:
;	
;
; OUTPUTS:
;
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

	sum = total(wts*data)
	sumsq = total(wts*data*data)
	n   = total(wts)

	mean = sum/n
	sd = sqrt((sumsq-mean*mean*n)/(n-1))

	return, mean
	end


