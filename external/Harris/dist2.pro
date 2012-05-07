function dist2,n,ANGLE=angle	;Return a square array in which each pixel =
				;either the euclidian distance from the centre
				;  or   the angle clockwise from 0-360, North=0
;+
; NAME:		DIST2
; PURPOSE:	Form a square array in which each element is proportional
;		to its radius from the centre.
; CATEGORY:	Signal Processing.
; CALLING SEQUENCE:
;	Result = DIST2(N)
; INPUTS:
;	N = size of result.
;	ANGLE = if set output angle not distance array
; OUTPUTS:
;	Result = (N,N) floating array in which:
;	R(i,j) = sqrt(F(i)^2 + F(j)^2)   where:
;		F(i) = i - (n-1)*0.5
;	or (if ANGLE set) = (atan(F(i)/F(j))*180/pi + 360) mod 360
;
; SIDE EFFECTS:	None.
; RESTRICTIONS: None.
; PROCEDURE:	Straightforward.  Done a row at a time.
; MODIFICATION HISTORY:
;		Based on DIST.pro
;		1/8/91 T.J.H.
;-
on_error,2              ;Return to caller if an error occurs
i=indgen(n)		;Make a row
x = (float(i) - (n-1)*0.5 )
a = fltarr(n,n)		;Make array
if (keyword_set(angle)) then $
	for j=0L,n-1 do a(i,j) = (atan(x(i),x(j))*180./!pi + 360.) mod 360. $
else $
	for j=0L,n-1 do a(i,j) = sqrt(x(i)^2+x(j)^2)*2./(n-1)

return,a
end
