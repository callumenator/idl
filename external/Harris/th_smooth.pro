;+
; NAME:		TH_SMOOTH
;
; PURPOSE:	Variant on the IDL smooth routine. Does a boxcar average but 
;		replicates the end elements in the window to get right size, 
;		hence will smooth the entire array, including the end points.
;
; CATEGORY:	Utility
;
; CALLING SEQUENCE:	result = th_smooth(input,width)
;
; INPUTS:		input = is the unsmoothed array
;			width = the widht of the boxcar
;
; OUTPUTS:		result = the smoothed array
;
; COMMON BLOCKS:
;	none.
; SIDE EFFECTS:
;	none.
; MODIFICATION HISTORY:
;	Written by: Trevor Harris, Physics Dept., University of Adelaide,
;		July, 1992.
;
;-
function th_smooth, input_array, width

n = n_elements(input_array) - 1
halfw = (fix(width)/2) < n
w = (halfw*2 + 1) < n
sm = input_array

for i = 0,n do begin
	sindex = (i-halfw) > 0
	eindex = (i+halfw) < n
	number = (float(eindex - sindex) + 1.) > 1.
	window = input_array(sindex:eindex)
	;print,sindex,eindex,number
	sm(i) = (total(window)+(w-number)*window(0)) / w
endfor

return,sm
end
