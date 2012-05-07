;************************************************************************
pro ffCFIT,NTR,Mode,chisq,iflag,cii=cii
; called by ffit2
;C**   CFIT - FORMERLY FWCFIT
;C**   CALLED BY FFIT; CALLS FFCURFIT
;C**   INPUTS: N=NUMBER OF POINTS
;C**           NTR = NUMBER OF FREE PARAMETERS
; version of ffcfit to call fortran version of FFCURFIT
COMMON CFT,X0,Y0,SIG0,epsvect
COMMON CURVE,A,EA,IFIXT
COMMON PLCR,YF
common fortflag,fflg
common custompars,dw,lp,x2,x3,x4,x5
;
if n_elements(fflg) eq 0 then fflg=0
chisq=0.
n=where(ifixt gt 0)
if n(0) ne -1 then nvar=n_elements(n) else nvar=0
if nvar le 0 then begin
   print,' CFIT error: Number of variables =',nvar,' - returning to main'
   return
   endif
;
n=n_elements(x0)
nfree=n-nvar                ;degrees of freedom
if nfree le 0 then return
;
x=double(x0)
y=double(y0)
sig=double(sig0)
a=double(a)
np=fix(n_elements(a))
nlines=(np-3)/3
for i=1,nlines do a(i*3+1)=a(i*3+1)-0.5      ;calibration of binning offset
NTERMS=fix(NTR)
IF NTerms LT 3 then NTerms=3
ntr=nterms
ishape=fix(nlines+1)
FLAMDA=.001D0
CHIOLD=0.D0
nt=nterms
case 1 of
   mode lt 0: weight=1./abs(y)          ;1/y weighting
   mode eq 0: weight=fltarr(n)+1.       ;uniform weighting
   else: begin
      weight=1./sig/sig         ;weighting by variance
      kbad=where(sig le -9998,nbad)
      if nbad gt 0 then weight(kbad)=0.
      end
   endcase
if fflg gt 0 then begin                 ;fixed array sized for FORTRAN calls
   x1=fltarr(750) & x1(0)=float(x0)
   y1=fltarr(750) & y1(0)=float(y0)
   w1=fltarr(750) & w1(0)=float(weight)
   a1=fltarr(18) & a1(0)=a
   ea1=fltarr(18) ; & ea1(0)=ea
   ifixt1=intarr(18) & ifixt1(0)=ifixt
   flamda=.001
   chisq1=0.
   iflag=0
   endif
;
;***  ;special setups
ni=n_elements(ifixt)
if keyword_set(cii) then begin
   if ni ge 8 then ifixt(7)=0
   if ni ge 14 then ifixt(13)=0
   endif
;***
;
for IGLOO=0,12 do begin
   case 1 of
      fflg eq 2: calltest,'FCURFIT2','FCURFIT2_EXE', $
     x1,y1,w1,a1,ea1,ishape,ifixt1,np,nt,flamda,chisq1,iflag   ;fortran version
      fflg eq 1: fCURFIT,x1,y1,w1,a1,ea1,ishape,ifixt1,np,nt,flamda,chisq1,iflag   ;fortran version
      else: FFCURFIT,Nfree,weight,FLAMDA,CHISQ,IFLAG,cii=cii  ;IDL version
      endcase
   IF IFLAG NE 0 then return
   IF(ABS(CHIOLD-CHISQ) LT .0003)then GOTO,RET
   CHIOLD=CHISQ
   endfor
;
ret:
a=float(a)
ea=float(ea)
for i=1,nlines do a(i*3+1)=a(i*3+1)+0.5      ;calibration of binning offset
return
end
