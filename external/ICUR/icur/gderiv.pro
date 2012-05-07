;***********************************************************************
function GDERIV,x,a   ;COMPUTES DERIVATIVE FOR FUNCTION IN FUNGUS
nterms=n_elements(a)
nx=n_elements(x)
deriv=dblarr(nx,nterms)
XI=double(Findgen(nx)-0.5)
DERIV(*,0)=1.D0
if nterms ge 2 then deriv(nx)=xi
if nterms ge 3 then deriv(nx*2)=xi*xi
IF nterms le 3 then RETURN,deriv
nlines=(nterms-3)/3
for j=0,nlines-1 do begin
   K=J*3+3
   Z=-13.>(((XI-A(K+1))/A(K+2))<13.)
   DERIV(nx*K)=EXP(-Z*Z/2.)
   DERIV(nx*(K+1))=A(K)/A(K+2)*Z*EXP(-Z*Z/2.)
   DERIV(nx*(K+2))=DERIV(*,K+1)*Z
   endfor
RETURN,deriv
END
