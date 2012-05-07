;*****************************************************************
pro specarr,arr,w0,files,recs,dl=dl,dw=dw,w00=w00
dl0=200.
dw0=0.2
wave0=6460.
if not keyword_set(dl) then dl=dl0
if dl le 0. then dl=dl0
if not keyword_set(dw) then dw=dw0
if dw le 0. then dw=dw0
np=dl/dw
if not keyword_set(w00) then w00=wave0
if w00 le 0. then w00=wave0
w0=w00+dw*findgen(np)             ;wavelength array
if n_params(0) lt 3 then begin
   files=['apr04','may24','may25','may26','may26','may27','may27']  ;,'bme1','bme1']
;   files=[files,'bme2','bme2','bme3','bme3','bme3']
;   files=[files,'bme4','bme4','bme5','bme5','bme5','bme6','bme6']
   recs=[1,1,3,1,2,2,32]    ;,1,2,2,3,5,6,7,1,2,1,2,3,0,1]
   endif
nf=n_elements(files)
nr=n_elements(recs)
if nr ne nf then print,' warning! nf=',nf,' nr=',nr
nl=nf<nr
arr=fltarr(np,nl)
for i=0,nl-1 do begin
   gdat,'ddisk:[fwalter.icur.data]'+files(i),h,w,f,e,recs(i)
   ff=interpol(f,w,w0)
   ff=ff*100./total(ff(2:101))                ;normalize
   arr(i*np)=ff
   endfor
return
end
