;********************************************************************
PRO IFEAT,WAVE,FINP,eps0,ftot,fnet,noprint=noprint,nonorm=nonorm,stp=stp
; MEASURE THE EW, FLUX OF A FEATURE
; VERSION 1 BY SALLY HEAP  22 APR 1981
; *** PARED DOWN BY FMW 9/17/82 FOR USE IN ICUR
; MODIFIED 6/18/86 TO REQUIRE ONLY 2 KEYSTROKES, BUT 3 WILL WORK
; INPUT:  WAVE=WAVELENTH VECTOR
;         FLUX=FLUX VECTOR
; OUTPUT = PRINTOUT OF ATTRIBUTES OF FEATURE
COMMON COM1,H,IK,IFT,NSM,C
COMMON COMXY,Xcur,Ycur,ZERR,rsc,lu3
common vars,var1,var2,var3
common icurunits,xu,yu,title,c1,c2,c3
if n_elements(c2) eq 0 then c2=85
if n_elements(c3) eq 0 then c3=25
!c=-1
if n_elements(eps0) gt 0 then eps=eps0
if n_elements(nsm) eq 0 then nsm=1
if (h(33) ge 30) and (n_elements(eps0) gt 1) then ieb=1 else ieb=0
IF n_elements(eps0) lt n_elements(finp) then ieb=0
if ieb then case 1 of
   h(33) eq 30: begin
      k=where(eps eq 0,nk)
      if nk gt 0 then eps(k)=1
      eps=finp/eps         ;convert sigmas to error bars
      if nk gt 0 then eps(k)=0.
      end
   else:
   endcase
if ieb then e2=eps*eps
DELWAV=(WAVE(N_ELEMENTS(WAVE)-1)-WAVE(0))/N_ELEMENTS(WAVE)
NAX=rdbit(var3,1)
FLUX=FINP
IF NAX EQ 1 THEN FLUX=FINP ELSE $
     IF ((NSM GT 2) AND (NSM LT 1000)) THEN FLUX=SMOOTH(FINP,FIX(NSM)) $
          ELSE IF N_ELEMENTS(C) GT 1 THEN FLUX=CONVOL(FINP,C)
PRINT,''
; MEASURE TEKTRONIX COORDINATES OF CONTINUUM ENDPOINTS
W=FLTARR(2)
F=W
W(0)=Xcur & F(0)=Ycur      ;first point
TKP,1,W(0),F(0)
NIT=0
RETRY: NIT=NIT+1    ; SECOND POINT
opstat,'  Waiting'
zerr0=zerr
BLOWUP,-1
opstat,'  Working'
IF ZERR EQ 48 THEN GOTO, DONE ; 0 TO EXIT     "60
ZERR=zerr0
W(1)=Xcur & F(1)=Ycur            ;second point
TKP,1,W(1),F(1)
IF (W(1) EQ W(0)) AND (NIT EQ 1) THEN BEGIN
   F(0)=F(1)
   GOTO,RETRY
   ENDIF
IF (W(1) EQ W(0)) AND (NIT GT 1) THEN RETURN
IF W(1) LE W(0) THEN BEGIN
     T=W(0)
     W(0)=W(1)
     W(1)=T
     T=F(0)
     F(0)=F(1)
     F(1)=T
     ENDIF
; FIND DATA-POINTS ASSOCIATED WITH W - DATAPT (FLT), I0,I1 (INT)
   datapt=xindex(wave,w)                 ;TABINV,WAVE,W,DATAPT
   I0=LONG(DATAPT(0))+ 1
   I1=LONG(DATAPT(1))
   DI=(I1-I0)>1
CENTRD,WAVE,FINP,F(0),DATAPT(0),DATAPT(1),XCEN,FD
; DRAW IN FEATURE WITH VERTICAL LINES BETWEEN CONTINUUM AND PROFILE
FOR I=I0,I1 DO oplot,[wave(i),wave(i)],[flux(i),f(0)+(i-I0)*(f(1)-f(0))/Di], $
      color=c2,linestyle=0
;
FCONT=.5*(F(0) + F(1))     ; MEASURE EQUIVALENT WIDTH
ACONT=(W(1)-W(0))*FCONT
ILO=LONG(DATAPT(0))
IHI=LONG(DATAPT(1))
N=IHI-ILO       ; DETERMINE NUMBER OF TRAPEZOIDS
IF N GT 0 THEN BEGIN
   Z=FLUX(ILO+1:ILO+N)+FLUX(ILO:ILO+N-1)
   DWAVE=(WAVE(ILO+1:ILO+N)-WAVE(ILO:ILO+N-1))
   ENDIF ELSE BEGIN
   z=0.
   dwave=wave(ilo+1)-wave(ilo)
   endelse
MDW=MEAN(DWAVE)
MDW2=MDW*MDW
ALINE=TOTAL((Z/2.)*DWAVE)
if ieb then ze=TOTAL(e2(ILO+1:ILO+N))*MDW2 ;sum of squares of errors
HI=DATAPT(1)-IHI
LO=DATAPT(0)-ILO
IF IHI LT DATAPT(1) THEN $
 ALINE=ALINE+(WAVE(IHI+1)-WAVE(IHI))*HI*(FLUX(IHI)+HI/2*(FLUX(IHI+1)-FLUX(IHI)))
ALINE=ALINE-(WAVE(ILO+1)-WAVE(ILO))*LO*(FLUX(ILO)+LO/2*(FLUX(ILO+1)-FLUX(ILO)))
if fcont eq 0. then ew=0. else ew=(acont-aline)/fcont
if ieb eq 1 then begin
   IF IHI LT DATAPT(1) THEN ze=ze+e2(ihi)*HI*MDW2
   ze=ze-e2(ilo)*lo*MDW2
   zc=ABS(acont)/ABS(aline)*ze
   ze=sqrt(abs(ze))     ;error on total
   zc=sqrt(abs(zc))     ;estimated error in continuum alone
   znet=sqrt(ze*ze+zc*zc) ;estimated error on net flux
   endif
;
ftot=aline
fnet=aline-acont
;
; FWHM
fw='---'
yd=mean(f)          ;mean continuum
FD=FLUX(i0:(i1>(I0+1)))-YD
iem=1
IF TOTAL(fd) LT 0 THEN begin
   FD=-FD    ;make positive
   iem=-1
   endif
height=abs(max(fd))/2.
k=where(fd gt height)     ;points above FWHM
k0=k(0)>1
km=max(k)<(n_elements(fd)-2)
if km le k0 then goto,prtres                      ;too narrow
f1=i0+k0-1+(height-fd(k0-1))/(fd(k0)-fd(k0-1))          ;bin number
f2=i0+km+(height-fd(km))/(fd(km+1)-fd(km))
p1=f1 & fp1=LONG(p1)
dw=wave(p1+1)-wave(p1)
w1=wave(fp1)+(p1-fp1)*dw
p2=f2 & fp2=LONG(p2)
w2=wave(fp2)+(p2-fp2)*dw
fw=w2-w1
!c=-1
x=[w1,w2]
if !p.psym eq 10 then x=x-0.5*dw
oplot,x,[yd+iem*height,yd+iem*height],color=c3,linestyle=0
;
if keyword_set(noprint) then goto,done
;
prtres:      ; PRINT OUT RESULTS AT RIGHT OF PAGE
if keyword_set(noprint) then goto,done
if n_elements(ift) eq 0 then ift=0
IFT=IFT+4
IF DELWAV GT 0.1 THEN SX=STRING(XCEN,'(F8.2)') ELSE SX=STRING(XCEN,'(F9.3)')
PRINT,'CTRD:',SX
if ieb then print,'Ftot:',string(aline,'(G10.3)'), $
      ' +/- ',string(ze,'(G10.3)'),'   sigma=',string(ABS(aline/ze),'(F7.2)') $
   else PRINT,'FTOT:',STRING(ALINE,'(G10.3)')
if ieb then print,'Fnet:',string(aline-acont,'(G10.3)'),' +/- ' $
   ,string(Znet,'(G10.3)'),'   sigma=',string(ABS((aline-acont)/znet),'(F7.2)') $
 else PRINT,'FNET:',STRING(ALINE-ACONT,'(G10.3)')
if not ifstring(fw) then print,'FWHM:',string(fw,'(F9.3)')
IF ABS(EW) GE 1. THEN SX=EW ELSE SX=1000.*EW
IF DELWAV GT 0.1 THEN SX=STRING(SX,'(F7.2)') ELSE SX=STRING(SX,'(F8.3)')
IF ABS(EW) GE 1. THEN PRINT,'EW-A:',SX ELSE PRINT,'EW-MA:',SX
if n_elements(lu3) eq 1 then begin
   printf,LU3,' 5','    IFEAT: Ctrd,F,Ft,EW'
   if ieb then printf,lu3,XCEN,ALINE-ACONT,ALINE,EW,ze,znet else $
      printf,lu3,XCEN,ALINE-ACONT,ALINE,EW
   endif
;
DONE:  ZERR=zerr0
!c=-1
if keyword_set(stp) then stop,'IFEAT>>>'
RETURN
END
