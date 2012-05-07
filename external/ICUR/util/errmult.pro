;**************************************************************************
function ERRMULT,X0,DX0,Y0,DY0,print=print,unc=unc,helpme=helpme,prt=prt
;
if n_params(0) lt 2 then helpme=1
if keyword_set(helpme) then begin
   print,' '
   print,' * ERRMULT -- return statistical error on X*Y'
   print,' *    calling sequence: UNC=ERRMULT(X,dX,Y,dY)'
   print,' *       X: first multiplicant'
   print,' *      dX: uncertainty on X'
   print,' *       Y: second multiplicant'
   print,' *      dY: uncertainty on Y'
   print,' *  KEYWORDS:'
   print,' *     PRINT: set to print result to screen'
   print,' *       UNC: set for relative uncertainty. E.g., UNC=0.1 for 10% error'
   print,' *'
   print,' *   call as UNC=ERRMULT(X,Y) to use sqrt(X),sqrt(Y) as errors'
   print,' '
   return,-999
   endif
;
if keyword_set(prt) then print=1
x=x0 & dx=dx0
fx=float(x)
if n_elements(unc) eq 0 then unc=0
if n_elements(unc) gt 0 then unc=unc(0)
unc=abs(unc)
case 1 of
   unc gt 1.: begin
      if unc lt 100. then unc=unc/100. else unc=0   ;change percent to fraction 
      end
   else:
   endcase
case 1 of
   unc gt 0: begin
      fy=float(dx)
      dx=fx*unc
      dy=fy*unc
      end
   n_params(0) eq 2: begin
      fy=float(dx)
      dx=sqrt(fx)
      dy=sqrt(fy)
      end
   n_params(0) eq 3: begin
      y=y0
      fy=float(y)
      dy=sqrt(fy)
      end
   else: begin
      y=y0
      dy=dy0
      fy=float(y)
      endelse
   endcase
;
err=SQRT(DX*DX*y*y+dy*dy*x*x)
if keyword_set(print) then print,fx*fy,'+\-',err
return,err
end
