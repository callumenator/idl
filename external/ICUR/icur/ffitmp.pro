;****************************************************************************
pro ffitmp,dtype,x1,y1,e1,A1,ifixt1,IB,NCAM,IMAGE,NSM,NIT,sigMODE,ihead, $
   cii=cii,eafudge=eafudge,noprint=noprint,quiet=quiet,mpquiet=mpquiet,pc=pc
; 
; IDL version of FFIT2.FOR, version 8.0
;             INCORPORATES VARIOUS CHANGES AND BUG FIXES, 2/92
; version FFITMP : uses MPCURVEFIT
;
;dtype = data type  :0 - standard gaussian
;                    1 - XCOR gaussian
; set lu4=-1 to suppress printouts
COMMON PLCR,YF         
COMMON CFT,X,Y,SIG,E               ;sig is 1 sigma error bar
COMMON CURVE,A,EA,IFIXT
common ffits,lu4
common icurunits,xunits,yunits,title
common fortflag,fflg
common custompars,dw,lp,x2,x3,x4,x5
COMMON COM1,HEADER,IK,IFT,NSMx,Cx,NDAT,IFSM,KBLO,H2,ipdv,ihcdev
;
MOS='JanFebMarAprMayJunJulAugSepOctNovDec'
IF N_ELEMENTS(EAFUDGE) EQ 0 THEN EAFUDGE=1.
if eafudge le 0. then eafudge=1.
if keyword_set(quiet) then noprint=1
;
if n_elements(ihead) eq 0 then ihead=' '
x=double(x1) & y=double(y1) & e=double(e1)
a=a1 & ifixt=ifixt1
CAMERA='     LWP LWR SWP SWR'
VER=10.0
IGAUS=0
;initialize
date=systime(0) & date=strmid(date,0,11)+strmid(date,20,4)+' at '+strmid(date,11,5)
nterms=n_elements(a)
nlines=(nterms-3)/3     ;number of lines
IMAX=n_elements(x)
len=IB(1)-IB(0)+1
apb=(x(imax-1)-x(0))/float(imax-1)
if len ne imax then begin
   print,' FFIT2: problem - imax=',imax
   print,' ib:',ib, 'len=',len
   stop
   endif
;
if !verbose lt 0 then noprint=1
case 1 of
   keyword_set(noprint): ffile='NL0:'
   n_elements(nit) eq 0: ffile='NL0:'
   NIT EQ 1: ffile='ffit.fit'
   NIT EQ -1:ffile='CROSS.FIT'
   else: ffile='ffit.tmp'
   endcase
;
if ffile eq 'NL0:' then lu4=-1 else get_lun,lu4    ;prepare output file
ib0=ib(0)
ib4=ib(3)
ib=ib-ib0
if ib4 eq -9 then ib(3)=ib4     ;-9 to force ffsigma to estimate S/N=100
if dtype eq 0 then fffixlines,ncam     ;are line wavelengths fixed?
;
if lu4 ne -1 then begin
   openw,lu4,ffile
   printf,lu4,' '
   printf,lu4,' '
   PRINTF,LU4,'**************************************************************'
   sver=string(ver,'(F3.1)')
   printf,lu4,'* FFIT, version ',sver,', run on ',date
   printf,lu4,'*     ',string(ihead)
   print,' FFIT, VERSION ',sver,' run on ',date,'   ',string(ihead)
   z=' '
   IF NCAM LE 5 then z='IMAGE:'+strmid(camera,ncam*4,4)+STRTRIM(image,2)   ;IUE
   IF NCAM GE 10 then begin
      yr=IMAGE/1000
      mo=(image-(yr*1000))/31
      dy=(image-(yr*1000)-mo*31)
      yr=yr+1980
      CASE 1 OF
         ncam/10 eq 10: z='GHRS data, type: '
         ncam ge  10: z='KPNO data type: '
         else: z='Unknown data type: '
         endcase
      z=z+string(NCAM,'(I3)')+' obtained on'
      z=z+string(dy,'(I3)')+' '+strmid(mos,(mo-1)*3,3)+string(yr,'(I5)')
      endif
   printf,lu4,'* '+z
   print,z
   z=' DATA SMOOTHED OVER '+string(nsm,'(I3)')+' BINS'
   IF (NSM GT 1) AND (NSM LT 1000) then printf,lu4,'* '+z
   z=' DATA SMOOTHED WITH TRIANGLE OF WIDTH'+string(-nsm,'(I3)')+' BINS'
   IF (NSM LT -1) AND (NSM GT -1000) then printf,lu4,'* '+z
   IF ABS(NSM) gt 1000 then begin    ;FIGURE OUT SMOOTHING PARAMETERS
      SMTH=float(nsm)/10.-1000.
      IF SMTH GT 0.  then IGAUS=1
      z=' Data smoothed with a Gaussian of FWHM'+string(smth,'(F4.1)')+' '+xunits
      IF SMTH GT 0.then printf,lu4,'* '+z
      z=' Data smoothed by rotational broadening of'+string(-smth,'(F5.1)')+' Km/S'
      IF SMTH LT 0. then printf,lu4,'* '+z
      endif
;
   printf,lu4,'* Background bins used: ',STRTRIM(ib0,2),' - ',STRTRIM((ib(1)+ib0),2)
   case 1 of
      sigmode eq 4: printf,lu4,'* variance from error bars'
      else: if ib4 ne -9 then printf,lu4,'* Bins used for variance determination: ' $
               ,STRTRIM((ib(2)+ib0),2),' - ',STRTRIM((ib(3)+ib0),2)
      endcase
   print,'IB1, IB2, IB3, IB4:',ib0,ib(1:3)
   IF NTERMS EQ 4 then print,' LINE FIXED AT BIN',a(4),' WAVELENGTH=',wl
   endif
;
FFSIGMA,sigmode,IB                       ;estimate error bars sigma
;VECTSTAT,SIG
k=where(ifixt eq 0)
;
if n_elements(lp) eq 0 then lp=0.

if lu4 ne -1 then begin
if lp ne 0. then $
     printf,lu4,'** Even numbered lines offset from odd lines by ',lp,' A.'
   print,' BACKGROUND FIT: BEGINNING ESTIMATES:',A(0),a(1),a(2)
   printf,lu4,'* BACKGROUND FIT: BEGINNING ESTIMATES:',A(0),a(1),a(2)
   IF nlines ge 1 then for I=1,NLINEs do begin
      J=I*3
      SI=STRING(I,'(I2)')
      print,' LINE #',SI,': BEGINNING ESTIMATES:',a(j),a(j+1),a(j+2)
      printF,LU4,'*       LINE #',SI,': BEGINNING ESTIMATES:',a(j),a(j+1),a(j+2)
      endfor
;
   if dtype eq 0 then begin
      sapb=string(apb,'(F7.4)')
      printf,lu4,'* Reciprocal Dispersion: ',sapb,' ',xunits,' per bin'
      print,sapb,' ',xunits,' per bin'
      endif
   nfxt=n_elements(ifixt)
   nfxt1=nfxt/3
   sifixt=string(ifixt(0),'(I1)')+string(ifixt(1),'(I1)')+string(ifixt(2),'(I1)')
   if nfxt gt 3 then for i=1,nfxt1-1 do begin
      sifixt=sifixt+' '+string(ifixt(3*i),'(I1)')
      sifixt=sifixt+string(ifixt(3*i+1),'(I1)')+string(ifixt(3*i+2),'(I1)')
      endfor
   if k(0) ne -1 then $
      printf,lu4,'* Parameter fit flags (0 -> fixed): ',sifixt
   endif
;
N2=IB0+IB(1)-1
CMAX=max(y)/10.                       ;scaling factor
Y=Y/CMAX                              ; SCALE FLUXES TO MAX = 10.
sig=sig/cmax
i=indgen(3)
a(i)=a(i)/cmax                        ;scale background
if nlines gt 0 then begin             ;lines to be fit
   bsca=a(4)-IB0
   for I=0,NLINEs-1 do begin
      J=I*3+3
      a(j)=a(j)/cmax                     ;scale line amplitude
      a(j+1)=a(j+1)-ib0                  ;shift to extracted vector index
      A(j+2)=A(j+2)/2.                   ;HWHM used in FFCFIT
      endfor
   endif else bsca=0
;
CFITmode=1
;
;ffCFIT,NTERMS,CFITMODE,chisq,iflag,cii=cii          ;do fit  ;*************
case 1 of
   cfitmode lt 0: weight=1./abs(y)          ;1/y weighting
   cfitmode eq 0: weight=fltarr(n)+1.       ;uniform weighting
   else: begin
      weight=1./sig/sig         ;weighting by variance
      kbad=where(sig le -9998,nbad)
      if nbad gt 0 then weight(kbad)=0.
      end
   endcase
parinfo=replicate({value:0.d0,fixed:0,limited:[0,0],limits:[0.d0,0.d0], $
                   tied:''},nterms)
k=where(ifixt eq 0,nk) & if nk gt 0 then parinfo(k).fixed=1
if keyword_set(cii) then lp=1.175
if keyword_set(lp) then begin
   slp=strtrim(lp,2)
   if nlines ge 2 then parinfo(6).tied='p(3)+'+slp
   if nlines ge 4 then parinfo(12).tied='p(9)+'+slp
   if nlines ge 6 then parinfo(18).tied='p(15)+'+slp
   endif
if n_elements(pc) eq 0 then pc=strarr(n_elements(a))
s=strlen(pc) & k=where(s gt 1,nk)
if nk gt 0 then for i=0,nk-1 do parinfo(k(i)).tied=pc(k(i))
if nk gt 0 then print,parinfo.tied
;stop,' About to call MPCURVEFIT'
for i=1,nlines do a(i*3+1)=a(i*3+1)-0.5      ;calibration of binning offset
yf=mpcurvefit(x,y,weight,a,ea,function_name='mpfungus', $
   chisq=chisq,covar=covar,errmsg=errmsg, $
   iter=iter,parinfo=parinfo,quiet=mpquiet,status=iflag)
chisq=chisq/(n_elements(x)-n_elements(a)+total(parinfo.fixed))   ;reduced chisq
for i=1,nlines do a(i*3+1)=a(i*3+1)+0.5      ;calibration of binning offset
;
if n_elements(ea) lt n_elements(a) then begin
   print,' *** FFITMP WARNING:  EA truncated. Check fit *** '
   npad=n_elements(ea)-n_elements(a)
   ea=[ea,fltarr(npad)+99.]
   endif
Y=Y*CMAX                              ;rescale parameters
sig=sig*cmax
yf=yf*cmax
i=indgen(3)
a(i)=a(i)*cmax                        ;scale background
ea(i)=ea(i)*cmax                      ;scale background errors
if nlines gt 0 then for I=1,NLINEs do begin        
   j=i*3
   a(j)=a(j)*cmax  & ea(j)=ea(j)*cmax      ;rescale amplitudes
   A(j+2)=ABS(A(j+2))*2. & EA(j+2)=EA(j+2)*2.   ;HWHM -> FWHM; force positive
   endfor
;
if lu4 ne -1 then fffitstat,chisq,iflag,bsca
   case 1 of     ; estimate resolution (pixels)
      ncam le 0: wlin=0.0
      ncam/10 eq 10: begin          ;GHRS
         if n_elements(header) gt 7 then wlin=(float(header(7)/500)*1.2)>2. $
            else wlin=3.5
         end
      NCAM EQ 10: WLIN=3.7
      NCAM EQ 100: WLIN=3.5
      NCAM GE 20: WLIN=2.0
      NCAM le 4: wlin=5.0
      else: WLIN=2.0
      endcase
   if not keyword_set(quiet) then fflpfw,dtype,ncam,igaus,smth,lwid=wlin,quiet=quiet
if lu4 ne -1 then begin
   IF dtype eq 0 then ffINFLUX
   CLOSE,lu4
   free_lun,lu4
   if (!verbose ge 0) and (nit gt 1) then begin
      if !version.os eq 'vms' then z='append ffit.tmp ffit.fit' else $
         z=' cat ffit.tmp >> ffit.fit'
      spawn,z
      if !version.os eq 'vms' then z='delete/nolog ffit.tmp;*' else $
         z=' rm ffit.tmp'
      spawn,z
      endif
   endif
a1=a
ifixt1=ea
e1=yf
return
end
