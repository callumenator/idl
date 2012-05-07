;***********************************************************************
pro rd_iuelo,image,h,w,flux,sigma,eps,raw,back,plt=plt,icdfile=icdfile, $
   epsvect=epsvect,helpme=helpme,stp=stp
;
if n_elements(image) eq 0 then helpme=1
if (n_params() lt 3) and (not keyword_set(plt)) and (not keyword_set(icdfile)) $
   then helpme=1
if keyword_set(helpme) then begin
   print,' '
   print,'* RD_IUELO - read in FA format IUE low dispersion data'
   print,'* calling sequence: RD_IUELO,image,h,w,flux,sigma,eps,raw,back'
   print,'*    IMAGE: image name, default extension is .MXLO  '
   print,'*    H: IUE-style header'
   print,'*    W: wavelength vector'
   print,'*    FLUX: flux vector'
   print,'*    SIGMA: uncertainties in FLUX'
   print,'*    EPS: data quality vector'
   print,'*    RAW, BACK: raw and background vectors, in DN units'
   print,'* '
   print,'* KEYWORDS:'
   print,'*    ICDFILE: name of .ICD file to store vectors, def=IUELO'
   print,'*    EPSVECT: set to store epsilon vector; default stores sigma'
   print,'*    PLT:    set to plot data'
   print,' '
   return
   endif
;
if noext(image) then image=image+'.mxlo'
if not ffile(image) then begin
   bell,3
   print,' File ',image,' not found - returning'
   return
   endif
d=readfits(image,header,/nodata)
d=readfits(image,h1,ext=1)
np=(tbget(h1,d,2))(0)
w0=(tbget(h1,d,3))(0)
dw=(tbget(h1,d,4))(0)
w=w0+dw*findgen(np)
flux=tbget(h1,d,9)
eps=tbget(h1,d,8)
sigma=tbget(h1,d,7)
back=tbget(h1,d,6)
raw=tbget(h1,d,5)
;
trim=where(sigma gt -0.9,np)
if np gt 0 then begin
   w=w(trim)
   flux=flux(trim)
   eps=eps(trim)
   sigma=sigma(trim)
   back=back(trim)
   raw=raw(trim)
   endif else print,' RD_IUELO WARNING: No data points with sigma ne -1'
;
h=intarr(400)
ncam=sxpar(header,'CAMERA')
case 1 of
   ncam eq 'LWP': h(3)=1
   ncam eq 'LWR': h(3)=2
   ncam eq 'SWP': h(3)=3
   ncam eq 'SWR': h(3)=4
   else: h(3)=0
   endcase
h(4)=fix(sxpar(header,'IMAGE'))
h(5)=fix(sxpar(header,'lexptime'))
h(7)=np
date=sxpar(header,'LDATEOBS')
h(10)=fix(strmid(date,3,2))
h(11)=fix(strmid(date,0,2))
h(12)=fix(strmid(date,6,2))+1900
time=sxpar(header,'LTIMEOBS')
h(13)=fix(strmid(time,0,2))
h(14)=fix(strmid(time,3,2))
h(15)=fix(strmid(time,6,2))
h(19)=10000
h(20)=fix(w0) & h(21)=fix(h(19)*(w0-fix(w0)))
h(22)=fix(dw) & h(23)=fix(h(19)*(dw-fix(dw)))
h(33)=40
h(100)=fix(byte(sxpar(header,'LTARGET')))
;
title='!6'+strtrim(ncam,2)+strtrim(sxpar(header,'IMAGE'),2)+': ' $
      +sxpar(header,'LTARGET')
if keyword_set(plt) then begin
   plot,w,flux,title=title
   if !d.name eq 'X' then wshow
   endif
save=0
case 1 of
   n_elements(icdfile) eq 0:
   ifstring(icdfile): save=1
   icdfile eq 0:
   else: begin
      icdfile='iuelo'
      save=1
      end
   endcase
if keyword_set(epsvect) then begin
   h(33)=0
   sig=float(eps)
   endif else sig=sigma
if save then kdat,icdfile,h,w,flux,sig,/islin
;
if keyword_set(stp) then stop,'RD_IUELO>>>'
return
end
