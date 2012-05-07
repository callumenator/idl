;****************************************************************************
pro ffit2,dtype,x1,y1,e1,A1,ifixt1,IB,NCAM,IMAGE,NSM,NIT,sigMODE,ihead, $
   cii=cii,EAFUDGE=EAFUDGE,noprint=noprint,quiet=quiet
; 
; IDL version of FFIT2.FOR, version 8.0
;             INCORPORATES VARIOUS CHANGES AND BUG FIXES, 2/92
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
;
if n_elements(ihead) eq 0 then ihead=' '
x=x1 & y=y1 & e=e1
a=a1 & ifixt=ifixt1
CAMERA='     LWP LWR SWP SWR'
VER=8.0
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
;if !verbose lt 0 then noprint=1 else noprint=0
if not keyword_set(noprint) then noprint=0
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
if lp ne 0. then $
     printf,lu4,'** Even numbered lines offset from odd lines by ',lp,' A.'
;
if lu4 ne -1 then begin
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
;ebar=sig                              ;sig=variance
;kbad=where(sig eq -9999,nkbad)
;k=where(ebar eq 0,nz)
;if nz gt 0 then ebar(k)=(ebar((k-1)>0)+ebar((k+1)<IB(1)))/2.
;ebar=y*ebar                           ;1 sigma error bar  S*N/S
;IF NKBAD GT 0 THEN ebar(kbad)=0.
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
ffCFIT,NTERMS,CFITMODE,chisq,iflag,cii=cii          ;do fit
;
Y=Y*CMAX                              ;rescale parameters
sig=sig*cmax
;sig=ebar                              ;1 sigma error bar
yf=yf*cmax
i=indgen(3)
a(i)=a(i)*cmax                        ;scale background
ea(i)=ea(i)*cmax                      ;scale background errors
if nlines gt 0 then for I=1,NLINEs do begin        
   j=i*3
   a(j)=a(j)*cmax  & ea(j)=ea(j)*cmax      ;rescale amplitudes
   A(j+2)=ABS(A(j+2))*2.& EA(j+2)=EA(j+2)*2.   ;HWHM -> FWHM; force positive
   endfor
EA=EA*EAFUDGE      ;  FUDGE ON EA - NEEDS TO BE VERIFIED
;
if lu4 ne -1 then fffitstat,chisq,iflag,bsca
   case 1 of     ; estimate resolution (pixels)
      ncam le 0: wlin=0.0
      ncam/10 eq 10: begin          ;GHRS
         if n_elements(header) gt 7 then wlin=(float(header(7)/500)*1.2)>2. $
            else wlin=3.5
         end
      NCAM EQ 10: WLIN=3.7
      NCAM/10 EQ 10: WLIN=4.4  ;GHRS comb added             ;was 3.5
      NCAM GE 20: WLIN=2.0
      NCAM le 4: wlin=5.0
      else: WLIN=2.0
      endcase
   if not keyword_set(quiet) then fflpfw,dtype,ncam,igaus,smth,lwid=wlin,quiet=quiet
if lu4 ne -1 then begin
   IF dtype eq 0 then ffINFLUX
   CLOSE,lu4
   free_lun,lu4
   if not noprint and (nit gt 1) then begin
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
