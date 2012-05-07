;*****************************************************************************
function vsinitmplt,vsini,ww
if vsini lt 0. then begin
   print,' '
   print,'* VSINITMPLT'
   print,'*    function to produce rotationally broadened line profile'
   print,'*    '
   print,'*   CALLING SEQUENCE: profile=VSINITMPLT(vsini,w0)'
   print,'*      VSINI: input rotational velocity (km/sec)'
   print,'*         W0: (input) velocity of line'
   print,'*             (output) wavelength scale 
   print,' '
   return,-1
   endif
if vsini eq 0. then begin
   ww=[ww-.01,ww,ww+.01]
   return,[0.,1.,0.]
   endif
gridsize=1.                ;degrees
ngrid=90./gridsize
surf=fltarr(ngrid,ngrid)
lat=0.5+findgen(ngrid)
lon=0.5+findgen(ngrid)
rad=fltarr(ngrid,ngrid)
for i=0,ngrid-1 do rad(i*ngrid)=sqrt(lon(i)*lon(i)+lat*lat)
k0=where(rad ge 90.)
rad(k0)=0.
rad=rad*0.017453
surf=0.4*(1.+1.5*cos(rad))
surf(k0)=0             ;surface intensity
sf=sum(surf,1)
sf=[0.,0.,reverse(sf),sf,0.,0.]
sf=sf/total(sf)                      ;normalize
if n_params(0) lt 2 then return,sf
;
if n_params(0) eq 0 then read,' enter Vsin i (km/sec): ',vsini
x=sin(rad(*,0))*vsini/2.99792E5    ;delta lambda / lambda
nx=n_elements(x)
mx=x(nx-1)
dx=mx-x(nx-2)
ddx=[dx,dx*2.]
x=[-reverse(mx+ddx),-reverse(x),x,mx+ddx]
if n_params(0) ge 2 then begin
   w0=ww
   x=x*w0    ;delta lambda
   mx=mx*w0
   endif else return,sf
dw=0.01
pwid=fix(0.5+mx/dw)
pw=dw*(findgen(1+2*pwid)-pwid)
pw=[pw(0)-dw,pw,max(pw)+dw]
si=interpol(sf,x,pw)
ww=pw+w0
return,si
end
