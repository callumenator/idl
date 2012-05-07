pro vmedian,in,width,out
;
;+
;			vmedian
;
; vector median filter routine
;
; CALLING SEQUENCE:
;	vmedian,in,width,out
;
; INPUTS:
;	in - input vector
;	width - filter width (should be odd)
; OUTPUTS:
;	out - output median filtered vector.
;		unfiltered end points are replaced with closest filtered
;		point.
;
; HISTORY
;	version 1. D. Lindler   Mar 89
;-
;------------------------------------------------------------------------------

n=n_elements(in)
out=in
w=fix(width)		;make sure we do integer arithmetic on this
if w le 1 then return	;already done
np=n-w+1		;number of output filtered points
hw=w/2			;half of filter width
wminus1=w-1
for i=0,np-1 do begin
	d=in(i:i+wminus1)	;extract region
	d=d(sort(d))		;sort it
	out(i+hw)=d(hw)		;center point
end
out(0:hw-1)=out(hw)		;extend to ends
out(n-hw:n-1)=out(n-hw-1)
return
end
