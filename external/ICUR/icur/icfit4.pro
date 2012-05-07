;*************************************************************
PRO ICFIT4,h,WAVE,F0,EPS,params,ifx,debug=debug,helpme=helpme,smode=smode, $
    nooverwrite=nooverwrite,stp=stp,prt=prt,quiet=quiet,mp=mp,dtype=dtype
; VAX version 2.0 7/17/87
; version 3 - runs with IDL version of ffit2
; version 3: generalized input; called by analxcor
; version 4 - no interaction - used in ECH/ORDEXT2
;
COMMON COM2,A,B,FH,FIXT,ISHAPE
COMMON COMXY,X,Y,ZERR,RESETSCALE,lu3,zzz
common custompars,dw,lp,x2,x3,x4,ews,ldp
COMMON VARS,yn,EA,VAR3,VAR4,var5,psdel,prffit,vrot2
common icurunits,xunits,yunits,title,c1,c2,c3,ch,c4,c5,c6,c7,c8,c9
common fortflag,fflg
;
if n_params(0) lt 5 then helpme=1
if keyword_set(helpme) then begin
   print,' '
   print,'* ICFIT4 - non-interactive version of ICFIT'
   print,'*    calling sequence:ICFIT4,H,W,F,E,params,ifixt'
   print,'*       H,W,F,E : standard header, wavelength, flux, and d.q. vectors'
   print,'*                 set E=scalar if no data quality vector available'
   print,'*       params  : the A vector with the initial parameter estimates.
   print,'*        ifixt  : numbers of parameters to freeze'
   print,'*           MP  : set to 0 for FFIT; def uses MPFIT'
   print,'*'
   print,'*   output: fit overwrites F vector, inless /NOOVERWRITE set
   print,'*           fit parameters overwritten and returned in PARAMS'
   print,' '
   return
   endif
;
if n_elements(mp) eq 0 then mp=1
if not keyword_set(prt) then noprint=1 else noprint=0
if n_elements(eps) le 1 then eps=f0*0.+100
ffl=0
fflg=ffl                  ;1 to use FCURFIT (FORTRAN), 0 to use CURFIT (IDL)
EN0=EPS
HOLD=H
F=F0
nsm=1
ncam=0
NIT=0
if keyword_set(smode) then mode=smode else MODE=1
NFIT=0
if n_elements(xunits) eq 0 then xunits=''
if (strupcase(xunits) eq 'KM/S') and (n_elements(dtype) eq 0) then dtype=1
if n_elements(dtype) eq 0 then dtype=0
if dtype eq 2 then h=intarr(512)
;
if n_elements(h) gt 16 then IMAGE=fix(H(13)*1000+h(14)*10+h(15)-80) else image=h
INITARR,1,EA     ; ZERO ARRAYS BEFORE BEGINNING
;
a=params
na=n_elements(a)
fixt=intarr(na)+1
if n_elements(ifx) gt 0 then begin
   if ifx(0) ge 0 then fixt(ifx)=0
   endif
ishape=na/3
b=[0,n_elements(wave)-1,-1,-9]
;
NB=B(1)-B(0)+1
knb=b(0)+indgen(nb)
if n_elements(h) gt 4 then ncam=h(3) else ncam=0
xn=wave(knb)
yn=f0(knb)
en=en0(knb)
;
for i=1,ishape-1 do begin
   j=1+i*3
   if a(j) gt b(0)+nb then a(j)=xindex(xn,params(j))
   endfor
if keyword_set(debug) then begin
   print,a
   print,fixt
   if debug gt 1 then stop,'ICFIT4(2)>>>'
   endif
;
if dtype gt 0 then dtype0=1 else dtype0=0
;
case mp of
   0: ffit2,2,xn,yn,en,a,fixt,b,ncam,image,nsm,nit,mode,' ',noprint=noprint, $
      quiet=quiet  ;dtype=2!!!
   else: ffitmp,dtype0,xn,yn,en,a,fixt,b,ncam,image,nsm,nit,mode,tz,cii=cii, $
      eafudge=eafudge,mpquiet=1,pc=pc,quiet=quiet,noprint=noprint
   endcase

yn=en
ea=fixt
eps=yn
;
if keyword_set(debug) then irplot,wave,f0,xn,yn,-1,4
;
if not keyword_set(nooverwrite) then f0=yn
b=ea
ZERR=32
params=a
if keyword_set(stp) then stop,'ICFIT4>>>'
;
RETURN
END
