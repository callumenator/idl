function cuberoot,cc
;+
; NAME:
;	CUBEROOT
; PURPOSE:
;	Real roots of a cubic equation. Complex roots set to -1.0e30.
;	Called by HALFAGAUSS.
; CALLING SEQUENCE:
;	roots = CUBEROOT(cc)
; INPUT:
;	cc = 4 element vector, giving coefficients of cubic polynomial, 
;		[c0,c1,c2,c3], where one seeks the roots of
;		c0 + c1*x + c2*x^2 + c3*x^3
; OUTPUT:
;	Function returns a vector of 3 roots. If only one root is real, then 
;	that becomes the 1st element.
; EXAMPLE:
;	Find the roots of the equation
;		3.2 + 4.4*x -0.5*x^2 -x^3 = 0
;	IDL> x = cuberoot([3.2,4.4,-0.5,-1])
;	
;	will return a 3 element vector with the real roots 
;		-1.9228, 2.1846, -0.7618
; REVISION HISTORY:
;	Henry Freudenreich, 1995
;-

on_error,2
unreal=-((10.0D) ^ 30)

a1=cc(2)/cc(3)
a2=cc(1)/cc(3)
a3=cc(0)/cc(3)

q=(a1^2.-3.*a2)/(9.)
r=(2.*a1^3.-9.*a1*a2+(27.)*a3)/(54.)

if r^2 lt q^3 then begin
;  3 real roots.
   theta=acos(r/q^(1.5))
   x1=-2.*sqrt(q)*cos(theta/(3.))-a1/3.
   x2=-2.*sqrt(q)*cos((theta+(6.2831855D))/(3.))-a1/(3.)
   x3=-2.*sqrt(q)*cos((theta-(6.2831855D))/(3.))-a1/(3.)
endif else begin
;  Get the one real root:
   a=-r/abs(r) * (abs(r)+sqrt(r^2-q^3))^.33333
   if a eq 0. then b=0. else b=q/a
   x1=(a+b)-a1/3.
   x2=unreal
   x3=unreal
endelse 

roots=[x1,x2,x3]
return,roots
end

