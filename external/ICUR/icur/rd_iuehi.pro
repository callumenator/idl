;***********************************************************************
pro rd_iuehi,image,h,ws,flux,sigma,eps,npts=np,icd=icd,do3=do3,ord=ord, $
    epsvect=epsvect,cut=cut,plt=plt, stp=stp,helpme=helpme,doall=doall
if n_elements(image) eq 0 then helpme=1
if n_params() lt 1 then helpme=1
if (n_params() lt 3) and (not keyword_set(plt)) then helpme=1
if keyword_set(helpme) then begin
   print,' '
   print,'* RD_IUEHI - read in FA format IUE High dispersion data (10/27/98)'
   print,'* calling sequence: RD_IUEHI,image,h,w,flux,sigma,eps'
   print,'*    IMAGE: image name, default extension is .MXHI '
   print,'*    H: ICUR-style header'
   print,'*    W: wavenegth vector'
   print,'*    FLUX: flux vector'
   print,'*    SIGMA: uncertainties in FLUX (from the noise vector)'
   print,'*    EPS: data quality vector'
   print,'*'
   print,'*    KEYWORDS'
   print,'*       EPSVECT: set to store epsilon vector, def stores sigma'
   print,'*       CUT: number of points to cut on ends, def=[5,100]'
   print,'*       DO3: merge and return 3 orders'
   print,'*       ICD: set to save in .ICD file, def=''IUEHI.ICD'' '
   print,'*       ORD: order number or central wavelength.'
   print,'*           (-N for order 0->M, N for true M or 0->M if< min)'
   print,'*            If not set, all orders returned'
   print,'*       NPTS: number of points per order'
   return
   endif
;
if n_elements(cut) eq 0 then cut=[5,100]
if n_elements(cut) eq 1 then cut=[cut,cut]
if noext(image) then image=image+'.mxhi'
if not ffile(image) then begin
   bell,3
   print,' File ',image,' not found - returning'
   return
   endif
; 
d=readfits(image,header,/nodata)
d=readfits(image,h1,ext=1)
nord=sxpar(h1,'naxis2')     ;number of orders
ordno=tbget(h1,d,1)
np=tbget(h1,d,2)
w0=tbget(h1,d,3)
p0=tbget(h1,d,4)    ;starting pixel
dw=tbget(h1,d,5)
flux0=tbget(h1,d,13)
eps0=tbget(h1,d,11)
noise=tbget(h1,d,10)
;back=tbget(h1,d,9)
raw=tbget(h1,d,8)
;
w=flux0*0.
p1=p0+np-1
k=where(raw eq 0,nk)
if nk gt 0 then raw(k)=1.
sigma0=noise*float(flux0)/float(raw)
for i=0,nord-1 do begin
   z0=fltarr(768)
   zw=w0(i)+dw(i)*dindgen(768)
   w(0,i)=zw
   z=flux0(p0(i):p1(i),i)
   flux0(*,i)=0.
   flux0(0,i)=z
   z=eps0(p0(i):p1(i),i)
   eps0(*,i)=-16000
   eps0(0,i)=z
   z=sigma0(p0(i):p1(i),i)
   sigma0(*,i)=0.
   sigma0(0,i)=z
   endfor
;
h=intarr(400)
ncam=strupcase(strtrim(sxpar(header,'CAMERA'),2))
ap=strtrim(sxpar(header,'aperture'),2)
if strupcase(ap) eq 'SMALL' then ap='S' else ap='L'
case 1 of
   ncam eq 'LWP': h(3)=1
   ncam eq 'LWR': h(3)=2
   ncam eq 'SWP': h(3)=3
   ncam eq 'SWR': h(3)=4
   else: h(3)=0
   endcase
h(4)=fix(sxpar(header,'IMAGE'))
h(5)=fix(sxpar(header,ap+'exptime'))
date=sxpar(header,ap+'DATEOBS')
h(10)=fix(strmid(date,3,2))
h(11)=fix(strmid(date,0,2))
h(12)=fix(strmid(date,6,2))+1900
time=sxpar(header,ap+'TIMEOBS')
h(13)=fix(strmid(time,0,2))
h(14)=fix(strmid(time,3,2))
h(15)=fix(strmid(time,6,2))
if keyword_set(epsvect) then etype=0 else etype=40
h(33)=etype
targ=sxpar(header,ap+'target')
if targ eq '0' then begin
   targ=''
   read,targ,prompt=' No target name found in header; please enter title: '
   endif
h(100)=fix(byte(targ))
;
wm=w0
for i=0,nord-1 do wm(i)=w(np(i)-1,i)    ;maximum wavelength
wmean=(w0+wm)/2.                        ;mean wavelength
maxnp=max(np)-cut(0)-cut(1)
if keyword_set(do3) then maxnp=fix(maxnp*2.25)
;
if keyword_set(do3) or (n_elements(ord) eq 1) or (n_elements(icd) eq 1) then $
   doord=1 else doord=0
if keyword_set(epsvect) then etype=0 else etype=40
title=string(byte(h(100:159)>32b))
h(25)=cut
;
if keyword_set(doall) then begin
   i1=0 & i2=nord-1
   if keyword_set(do3) then begin
      i1=i1+1 & i2=i2-1
      endif
   endif else begin
   i1=1 & i2=1
   endelse
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
for iloop=i1,i2 do begin
   if keyword_set(doall) then ord=iloop
   if doord and (n_elements(ord) eq 0) then begin   ;which order?
      zords=strtrim(fix(min(ordno)),2)+' - '+strtrim(fix(max(ordno)),2)
      z=' Enter central order ('+zords+') or wavelength: '
      read,ord,prompt=z
      ord=fix(ord)
      endif
   if doord then begin
      if ord lt 0 then ord=ordno(0)-abs(ord)     ;absolute order number
      if (ord gt min(ordno)) and (ord lt 900) then ord=(where(ord eq ordno))(0) ; 0-n
      if ord le (nord-1) then begin     ;order number
         if ord lt 0 then ord=fix(median(ordno)-min(ordno))   ;middle order
         endif else begin                 ;wavelength
         d=abs(ord-wmean)
         ord=(fix(where(d eq min(d))))(0)
         endelse
      endif            ;doord
;
   if n_elements(ord) eq 1 then case 1 of
      keyword_set(do3): begin           ;do3
print,' Order: ',ord
         ord=1>(ord<(nord-2))
         j=ord-1
         ff1=flux0(*,j)
         rf=reverse(ff1)
         k=(where(rf ne 0.0))(0)>0           ;zeros
         cr=cut(1)+k
         ww1=(w(*,j))(cut(0):np(j)-1-cr)
         ff1=ff1(cut(0):np(j)-1-cr)
         ee1=(eps0(*,j))(cut(0):np(j)-1-cr)
         ss1=(sigma0(*,j))(cut(0):np(j)-1-cr)
         kb=where(ee1 lt -5000,nk) & if nk gt 0 then ss1(kb)=-ss1(kb)  ;make large EB
         j=ord
         ff2=flux0(*,j)
         rf=reverse(ff2)
         k=(where(rf ne 0.0))(0)>0           ;zeros
         cr=cut(1)+k
         ww2=(w(*,j))(cut(0):np(j)-1-cr)
         ff2=ff2(cut(0):np(j)-1-cr)
         ee2=(eps0(*,j))(cut(0):np(j)-1-cr)
         ss2=(sigma0(*,j))(cut(0):np(j)-1-cr)
         kb=where(ee2 lt -5000,nk) & if nk gt 0 then ss2(kb)=-ss2(kb)
         if etype eq 0 then ss1=ee1
         if etype eq 0 then ss2=ee2
         vmerge,0,ww1,ff1,ss1,0,ww2,ff2,ss2,0,ww0,ff0,ss0,etype=etype,/weight
         if etype eq 0 then ss0=-ss0
         j=ord+1
         ff3=flux0(*,j)
         rf=reverse(ff3)
         k=(where(rf ne 0.0))(0)>0           ;zeros
         cr=cut(1)+k
         ww3=(w(*,j))(cut(0):np(j)-1-cr)
         ff3=ff3(cut(0):np(j)-1-cr)
         ee3=(eps0(*,j))(cut(0):np(j)-1-cr)
         ss3=(sigma0(*,j))(cut(0):np(j)-1-cr)
         kb=where(ee3 lt -5000,nk) & if nk gt 0 then ss3(kb)=-ss3(kb)
         if etype eq 0 then ss3=ee3
         vmerge,0,ww0,ff0,ss0,0,ww3,ff3,ss3,0,ww,ff,sn,etype=etype,/weight
         if etype eq 0 then sn=-sn
         ws=ww & flux=ff 
         sigma=sn
         dw1=ws(1)-ws(0)
         h(7)=n_elements(ws)
         h(19)=10000
         h(20)=fix(ws(0)) & h(21)=fix(h(19)*(ws(0)-fix(ws(0))))
         h(22)=fix(dw1) & h(23)=fix(h(19)*(dw1-fix(dw1)))
         end
      else: begin                     ;single order
         if (ord ge 0) then begin
            flux=flux0(*,ord)
            k0=(where(flux ne 0.0))(0)>0           ;zeros
            cr0=cut(0)+k0
            rf=reverse(flux)
            k1=(where(rf ne 0.0))(0)>0           ;zeros
            cr1=cut(1)+k1
            cr2=n_elements(flux)-1-cr1
            ws=(w(*,ord))(cr0:cr2)
            flux=flux(cr0:cr2)
            eps=(eps0(*,ord))(cr0:cr2)
            sigma=(sigma0(*,ord))(cr0:cr2)
            h(7)=n_elements(flux)
            h(19)=30000
            h(20)=fix(ws(0)) & h(21)=fix(h(19)*(ws(0)-fix(ws(0))))
            h(22)=fix(dw(ord)) & h(23)=fix(h(19)*(dw(ord)-fix(dw(ord))))
            endif
         end
      endcase
;
   if (total(flux) eq 0.0) and (max(flux) eq 0.0) then nodata=1 else nodata=0
   if nodata then print,' No data order',ord else begin
      if keyword_set(plt) then begin
         plot,ws,flux,title='!6'+strtrim(title,2)
         if !d.name eq 'X' then wshow
         endif
;
      if n_elements(icd) eq 1 then begin                 ;save data
         if strtrim(string(icd),2) ne '0' then begin
            if ifstring(icd) then file=icd else file='iuehi'
            kdat,file,h,ws,flux,sigma,-1,/islin,vlen=maxnp
            endif
         endif
      endelse
   endfor     ;iloop
;
if keyword_set(stp) then stop,'RD_IUELO>>>'
return
end
