;**********************************************************************
function parabmin,xx,yy,ymin,stp=stp,prt=prt
;
if n_elements(yy) eq 0 then begin
   y=float(xx)
   xx=[0.,1.,2.]
   endif else begin
      x=float(xx) & y=float(yy)
      endelse
if n_elements(x) gt 3 then begin
   np=n_elements(x)
   k=where(y eq min(y))
   k=[k(0)-1,k(0),k(0)+1]
   if k(0) lt 0 then k=k+1
   if k(2) ge np then k=k-1
   x=float(xx(k)) & y=float(yy(k))
   endif
dx=x(1:*)-x
case 1 of
   dx(1) eq dx(0): begin          ;equal spacings
      dx=dx(0)
      a=(y(0)-2.*y(1)+y(2))/(2.*dx*dx)
      xmin=(y(0)-y(1))/(2.*a*dx) + x(0) + dx/2.
      ymin=y(0)-a*(x(0)-xmin)^2
      end
   else: begin
      dxt=x(2)-x(0)
      a1=((y(0)-y(1))/dx(0)) - (y(0)-y(2))/dxt
      a2=((x(2)*x(2)-x(0)*x(0))/dxt)-((x(1)*x(1)-x(0)*x(0))/dx(0))
      a=a1/a2
      xmin=((y(0)-y(1))/a + x(1)*x(1)-x(0)*x(0))/(2.*dx(0))
      ymin=y(0)-a*(x(0)-xmin)^2
      end
   endcase
if keyword_set(prt) then print,'Mimimum Y ',ymin,' occurs at X=',xmin
if keyword_set(stp) then stop,'PARABMIN>>>'
return,xmin
end
