;-----------------------------------------------------------------
	function clean_phase, input, period, open=open, suppress=suppress
;+
; NAME:			clean_phase
;
; PURPOSE:		"unravels" phase and other cyclic data
; 			function will add or subtract PERIOD in order to make 
; 			the phases more logical in sequence
; 			Uses first element as reference
;
; CATEGORY:		Utility
;
; CALLING SEQUENCE:	result = clean_phase(modulo_period_data, period)
;
; INPUTS:
;			modulo_period_data = input data (VECTOR) which can be
;						 cyclic in period
;
;			period = the basic periodicity of the data 
;				EG. 2!pi, or 360 degrees, T
;
;		KEYWORDS:
;			open	= unravel as far as it can go
;					The default operation is to only 
;					unravel out to +/- 1.5*period
;
;			suppress = keep those informative message to itself
;
; OUTPUTS:
;			result	= the cleaned up phases
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

	; this function will add or subtract PERIOD in order to make 
	; the phases more logical in sequence
	; Uses first element as reference

	; INPUT assumed to be a vector

	if (not keyword_set(suppress)) then print,'......cleaning up the phases '
	n = n_elements(input)
	phases = input
	
	;for i=0,n-2 do begin
	;	diff = (phases(i+1) - phases(i))
	;	if (not keyword_set(open)) then num = 1 $
	;	else num = fix(abs(diff)/period)+1
	;	
	;	CASE (1) OF
	;		diff lt -0.5*period: phases(i+1)=phases(i+1)+num*period
	;		diff gt +0.5*period: phases(i+1)=phases(i+1)-num*period
	;		else: ;leave as is
	;	ENDCASE
	;
	;endfor
	for i=0,n-2 do begin
		diff = (phases(i+1) - phases(i))
		
		CASE (1) OF
			diff lt -0.5*period: phases(i+1:n-1)=phases(i+1:n-1)+period
			diff gt +0.5*period: phases(i+1:n-1)=phases(i+1:n-1)-period
			else: ;leave as is
		ENDCASE

	endfor
		
	if (not keyword_set(open)) then begin ;shift phases to [-0.5,1.5]*T
		lobound = where(phases lt -0.5*period,count)
		if (count gt 0) then phases = phases + period
		hibound = where(phases gt 1.5*period,count)
		if (count gt 0) then phases = phases - period

		lobound = where(phases lt -0.5*period,count)
		if (count gt 0) then phases(lobound) = phases(lobound) + period
		hibound = where(phases gt 1.5*period,count)
		if (count gt 0) then phases(hibound) = phases(hibound) - period
	endif 

	return,phases
	end





