;***********************************************************************
pro linearwave,h,w,flux,eps,wfact=wfact
if not keyword_set(wfact) then wfact=30000.
ln=n_elements(w)
w0=w(0)
wmax=max(w)
dw=(max(w)-w0)/ln
ww=w0+dw*findgen(ln)
h(20)=fix(w0) & h(21)=fix((w0-h(20))*wfact)
h(22)=fix(dw) & h(23)=fix((dw-h(22))*wfact)
if h(22) eq 0 then begin                ;longlam=1
   h(22)=fix(dw*1.e4)
   h(23)=fix((dw*1.e4-h(22))*wfact)
   wfact=-wfact
   endif
h(19)=fix(wfact)
if n_elements(h) ge 200 then h(199)=333
if n_params(0) lt 3 then return        ;flux vector not passed
flux=interpol(flux,w,ww)
if n_params(0) lt 4 then return        ;epsilon vector not passed
if n_elements(eps) le 1 then return
eps=interpol(eps,w,ww)
return
end
