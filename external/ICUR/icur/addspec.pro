;**************************************************************************
pro addspec,w,f,w1,f1,e0,w0,f0
w0=w
f0=f
nw0=n_elements(w0)
nw1=n_elements(w1)
dw=(w0(nw0-1)-w0(0))/(nw0-1)
ov1=where((w1 gt w0(0)) and (w1 lt w0(nw0-1)))    ;overlap region
ov0=where((w0 gt w1(0)) and (w0 lt w1(nw1-1)))    ;overlap region
f1=f1*mean(f(ov0))/mean(f1(ov1))                 ;set scaling
if n_elements(e0) eq nw0 then f0=f*e0 else e0=intarr(nw0)+1
;
if w1(0)+dw lt w0(0) then begin   ;second vector starts first
   np1=(w0(0)-w1(0))/dw
   w0=[w0(0)-np1*dw+dw*findgen(np1),w0]
   endif else np1=0
nw0=n_elements(w0)
;
if w1(nw1-1)-dw gt w0(nw0-1) then begin   ;second vector ends last
   np2=(w1(nw1-1)-w0(nw0-1))/dw
   w0=[w0,w0(nw0-1)+dw+dw*findgen(np2)]
   endif else np2=0
;
np1=fix(np1+0.5)
np2=fix(np2+0.5)
np=n_elements(w0)
e=intarr(np)
f2=fltarr(np)
f2(np1)=f0
e(np1)=e0
;
f3=interpol(f1,w1,w0)
k=where(w0 le w1(0)+dw)
if k(0) ge 0 then begin
   f3(k)=0.
   km=max(k)+1
   endif else km=0
k=where(w0 ge w1(nw1-1)-dw)
kgood=k(0)
if kgood gt -1 then f3(k)=0.
if kgood eq -1 then kgood=n_elements(f3)-1 
np=kgood-km     ;+1
k=km+indgen(np)
e(k)=e(k)+1
f0=f2+f3
k=where(e gt 0)
e=e(k)
f0=f0(k)
w0=w0(k)
f0=f0/e
e0=e
if n_params(0) lt 7 then begin
   w=w0
   f=f0
   endif
return
end
