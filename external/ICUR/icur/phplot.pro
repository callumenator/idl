PRO PHPLOT,arr,w,delta,PHI=phi,recs=recs,files=files,dl=dl,dw=dw,w0=w0,xr=xr,yl=yl
iget=0 & ihlp=0
if n_params(0) eq 0 then iget=1
if (n_params(0) ge 2) and (n_elements(arr) eq 0) then iget=1
if iget eq 1 then begin
    ;make array here
    if (not keyword_set(files)) and (not keyword_set(recs)) then ihlp=1
    if ihlp ne 1 then begin
       files=keyword_set(files)
       recs=keyword_set(recs)
       if not keyword_set(dl) then dl=-1.
       if not keyword_set(dw) then dw=-1.
       if not keyword_set(w0) then w0=-1.
       specarr,arr,w,files,recs,dl=dl,dw=dw,w0=w0
       endif
    endif
s=size(arr)
if s(0) ne 2 then ihlp=1    ;not a 2-D array
if ihlp eq 1 then begin
   print,' '
   print,'* PHPLOT,arr,w,delta'
   print,'*   arr: optional array containing spectra'
   print,'*   w:   corresponding wavelength vector'
   print,'*   delta: controls vertical spacing, default=1.0'
   print,'*  KEYWORDS:'
   print,'*    PHI: phases of observations'
   print,'*    XR:   x axis range (2-element vector)'
   print,'*    YL:   Y scaling range (2-element vector; pixels)'
   print,'* If the data are not passed in an array, they may be read from ICUR data files'
   print,'*    files: list of data files'
   print,'*    recs: corresponding records'
   print,'*    W0: initial wavelength of W vector'
   print,'*    DL: length of wavelength array (A)'
   print,'*    DW: wavelength grid spacing'
   print,'
   return
   endif
;
nx=s(1)
ny=s(2)
if not keyword_set(phi) then phi=findgen(ny)/ny
if not keyword_set(xr) then xr=[0,0]
if not keyword_set(yl) then yl=[0,0]
nyl=yl(1)-yl(0)
;
if n_params(0) lt 3 then delta=1.
phs=sort(phi)    ;sorted
P=PHI
kmin=where(phi eq min(phi))
kmax=where(phi eq max(phi))
if nyl gt 0 then f0=nyl*arr(*,kmin)/total(arr(yl(0):yl(1),kmin)) else $
   f0=nx*arr(*,kmin)/total(arr(*,kmin))
ymin=(delta*p(kmin)+min(f0)-1.)/delta
if nyl gt 0 then f1=nyl*arr(*,kmax)/total(arr(yl(0):yl(1),kmax)) else $
   f1=nx*arr(*,kmax)/total(arr(*,kmax))
ymax=(delta*p(kmax)+max(f1)-1.)/delta
setxy,xr(0),xr(1),ymin,ymax
!c=-1
!x.title='!6Angstroms'
!y.title='!6Phase'
PLOT,W,arr(*,0)*0.,ystyle=1,/nodata
FOR I=0,ny-1 DO BEGIN
     if nyl gt 0 then f=nyl*arr(*,i)/total(arr(yl(0):yl(1),i)) else $
        f=nx*arr(*,i)/total(arr(*,i))
;        OPLOT,W,F+DELTA*P(i)
        OPLOT,W,(F+DELTA*P(i)-1.)/delta
     ENDFOR
RETURN
END
