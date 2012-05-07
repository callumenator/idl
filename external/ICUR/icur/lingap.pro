;**************************************************************************
pro lingap,h,w,f,e
; linearize file with gaps 
;
ngap=h(900)
if ngap le 0 then return ;no gaps
;
wgap0=double(h(901))+h(902)/30000.D0
k=where(w lt wgap0) & k=max(k)         ;last point before gap
wl=max(w)                              ;end of wavelength vector
dw=float(h(22))+float(h(23))/10000.    ;dispersion
nw=(wl-wgap0)/dw                       ;number of bins
ww=w(k-1)+dw*findgen(nw)                 ;linear wavelength vector
ff=interpol(f,w,ww)
ee=interpol(e,w,ww)
w=[w(0:k-2),ww]
f=[f(0:k-2),ff]
e=[e(0:k-2),ee]
stop
kgap,h,w,wgap,ngap,e,0
f=avspt(f,e)
return
end
