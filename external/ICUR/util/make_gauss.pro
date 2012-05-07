;************************************************************************
function make_gauss,x0=x0,sig=sig,amp=amp,norm=norm,noise=noise,back=back, $
     helpme=helpme,stp=stp
common poisseed,seed,seed2
;
if keyword_set(helpme) then begin
   print,' '
   print,'* FUNCTION MAKE_GAUSS - makes 2-D gaussian array'
   print,'* calling sequence: arr=MAKE_GAUSS()'
   print,'* '
   print,'* KEYWORDS:'
   print,'*    AMP:  amplitude of gaussian, def=1.0'
   print,'*    BACK: Background level, def=0.0'
   print,'*    NOISE: if set, add poisson noise'
   print,'*    NORM: if set, volume is normalized to this value'
   print,'*    SIG:  gaussian sigma, def=1.0'
   print,'*    X0:   position of center; def=20, array size is 2*X0+1'
   return,0
   endif
if n_elements(x0) eq 0 then x0=20.     ;make 41x41 array
if n_elements(sig) eq 0 then sig=1.     ;HWHM
if n_elements(amp) eq 0 then amp=1.     ;amplitude
if n_elements(back) eq 0 then back=0.     ;background
;
r=fix(x0)
np=2*r+1
x=findgen(np)
z=(x-x0)*(x-x0)/sig/2.
k=where(z ge 50.,nk)
y=exp(-(z<50.))
if nk gt 1 then y(k)=0.
yy=transpose(y)
arr=amp*(y#yy)
if keyword_set(norm) then begin
   t=total(arr)
   arr=arr/t*norm
   endif
arr=arr+back
if keyword_set(noise) then begin
   arr=fix(arr+0.5)
   arr=poiss2(arr,minv=0.1)
   endif
if keyword_set(stp) then stop,'MAKE_GAUSS>>>'
return,arr
end
