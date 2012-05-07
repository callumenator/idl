;------------------------------------------------------------------
		function sigfig, range
;
;+
; NAME:
;	SIGFIG
;
; PURPOSE:
;	This function will return the number of significant figures in 
;	the value "range"
;
; CATEGORY:
;	utilities
;
; CALLING SEQUENCE:
;	result = sigfig(range)

; INPUTS:
;	range = range for the significance, may be an array.
;
; OUTPUTS:
;	result = the number of significant figures expressed in base 10,
;		Example: sigfig(1000) = 3,
;			 sigfig(0.01) = -2
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
	nonzero = where([range] ne 0,count)
	sf = range*0.0
	if (count gt 0) then begin
		value = abs(range(nonzero))
		sign = range(nonzero)/value
		logv = alog10(value)
		positive = where(logv ge 0,count)
		if (count gt 0) then sf(nonzero(positive)) = $
				sign(positive)*10^(rnd(logv(positive),/down)) 
		negative = where(logv lt 0,count)
		if (count gt 0) then sf(nonzero(negative)) = $
				sign(negative)*10^(rnd(logv(negative),/out)) 
	endif

	return,sf
	end


