function dist3,n,major,minor	;Return a square array in which each pixel =
				;elliptical function of the euclidian distance
				;from the centre
;+
; NAME:		DIST3
; PURPOSE:	Form a square array in which each element is an elliptical
;		function proportional to its radius from the centre.
; CATEGORY:	Signal Processing.
; CALLING SEQUENCE:
;		Result = DIST3(N)
; INPUTS:
;		N = size of result.
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
;		Based on DIST2.pro
;		11/8/92 T.J.H.
;-
on_error,2              ;Return to caller if an error occurs

;check if major and minor set
if (n_elements(major) le 0) then major = 1 
if (n_elements(minor) le 0) then minor = 1
i=indgen(n)		;Make a row
x = (float(i) - (n-1)*0.5 )
a = fltarr(n,n)		;Make array
for j=0L,n-1 do $
	a(i,j) = sqrt((x(i)/float(major))^2+(x(j)/float(minor))^2) $
		*sqrt(major^2+minor^2)*2./(n-1)

return,a
end
