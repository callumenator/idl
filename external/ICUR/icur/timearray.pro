;****************************************************************************
function timearray,file,recs,wave,nozero=nozero,expand=expand,rectify=rectify, $
         scale=scale,lam=lam
if n_params(0) lt 1 then file=-1
if not ifstring(file) then begin
   print,' '
   print,'* function TIMEARRAY '
   print,'*    purpose: place spectra in array for time analysis'
   print,'*    Calling sequence: ARR=TIMEARRAY(file,recs,wave)'
   print,'*       FILE: name of ICUR-format data file'
   print,'*       RECS: list of records; defaults to 0-512'
   print,'*       WAVE: wavelength vector (first spectrum only)'
   print,'* KEYWORDS:'
   print,'*   NOZERO: set to force minimum value to least non-negative value'
   print,'*   EXPAND: set to an integer N to REBIN Y axis by factor N'
   print,'*   RECTIFY: set to rectify to first wavelength scale '
   print,'*   SCALE: set to scale flux vectors '
   print,'*   LAM: wavelength limits'
   print,' '
   return,-1
   endif
if n_params(0) eq 1 then recs=indgen(512)
ny=n_elements(recs)
gdat,file,h,wave,f,e,recs(0)
if h(0) eq -1 then return,-999
if keyword_set(lam) then begin
   if n_elements(lam) eq 2 then begin
      k=where((wave ge (lam(0)<lam(1)) and (wave le (lam(0)>lam(1))) ))
      wave=wave(k)
      f=f(k)
      endif
   endif
nx=n_elements(f)
tf=total(f)
s=size(f) & s=s(n_elements(s)-2)
if s eq 2 then arr=intarr(nx,ny) else arr=fltarr(nx,ny)
arr(0)=f
for i=1,ny-1 do begin
   gdat,file,h,w,f,e,recs(i)
   if n_elements(h) eq 1 then goto,eof
   if keyword_set(rectify) then begin
      f=[0.,0.,0.,f,0.,0.,0.]
      dw=w(1)-w(0)
      w=[dw*(indgen(3)-3)+w(0),w,max(w)+dw*(1+indgen(3))]
      f=interpol(f,w,wave)
      endif
   if keyword_set(scale) then f=f*tf/total(f)
   arr(i*nx)=f
   endfor
eof:
if keyword_set(nozero) then begin
   k=where(arr le 0.)
   ma=min(arr(where(arr ge 0.)))
   arr(k)=ma
   endif
if keyword_set(expand) then begin
   arr=rebin(arr,ny,ny*expand)
   endif
return,arr
end
