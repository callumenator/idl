function dist4,n,major,minor,steps=steps 
			;Return a square array in which each pixel =
			;elliptical function of the euclidian distance
			;from the centre stepped by 100% for steps times
;+
; NAME:		DIST4
; PURPOSE:	Form a square array in which each element is an elliptical
;		function proportional to its radius from the centre.
;		This is then stepped steps times
; CATEGORY:	Signal Processing.
; CALLING SEQUENCE:
;		Result = DIST4(N)
; INPUTS:
;		N 	= size of result.
;		major	= major axis length
;		minor 	= minor axis length
;	KEYWORDS:
;		STEPS	= number of steps to create (default = 0)
; OUTPUTS:
;	Result = (N,N) floating array in which:
;	R(i,j) = sqrt((F(i)/major)^2 + (F(j)/minor)^2)   where:
;		F(i) = i - (n-1)*0.5
;
; SIDE EFFECTS:	None.
; RESTRICTIONS: None.
; PROCEDURE:	Straightforward.  Done a row at a time.
; MODIFICATION HISTORY:
;		Based on DIST3.pro
;		11/8/92 T.J.H.
;-
on_error,2              ;Return to caller if an error occurs

;check if major and minor set
if (n_elements(major) le 0) then major = 1 
if (n_elements(minor) le 0) then minor = 1
if (not keyword_set(steps)) then steps = 0
i=indgen(n)		;Make a row
x = (float(i) - (n-1)*0.5 )
a = fltarr(n,n)		;Make array
fmt = '(i4,$)'
for j=0L,n-1 do begin
	r = sqrt((x(i)/float(major))^2+(x(j)/float(minor))^2)
	;;a(i,j) = r* ( 1 - fix(2*r*(steps+1)/(n-1)) )  
	minr = min(r,max=maxr)	&	count = 99	&	s = 0 
	print,form='(" STEP: ",$)'
	;while (count gt 0) do begin
	;	tmp = where((r-minr) gt (maxr-minr)/(steps+1),count)
	;	if (count gt 0) then r(tmp) = r(tmp) - min(r(tmp)) + minr 
	;	print,s,form=fmt
	;	s = s+1
	;endwhile
    	while (count gt 0) do begin
		tmp = where(r gt maxr/(steps+1),count)
		if (count gt 0) then r(tmp) = r(tmp) - min(r(tmp)) 
		print,s,form=fmt
		s = s+1
	endwhile    
	a(i,j) = r
	print
endfor 

return,a*sqrt(major*minor)*2./(n-1)
end
