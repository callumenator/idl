;***************************************************************
function makegkernel,s,nd    ;gaussian kernel
if s le 1 then return,1   ;s is FWHM in pixels
if n_params(0) lt 2 then nd=1
z=indgen((s+1)*2)
z=z*z/2./s/s
c=exp(-z)
c=[reverse(c(1:*)),c]
if nd eq 2 then begin
   nc=n_elements(c)
   z=fltarr(nc,nc)
   for i=0,nc-1 do z(0,i)=c
   c=z*rotate(z,1)
   endif
c=c/total(c)
return,c
end
