;*************************************************************
PRO ICFIT3,h,WAVE,F0,EPS,params,ihlp,hcpy=hcpy,batch=batch
; VAX version 2.0 7/17/87
; version 3 - runs with IDL version of ffit2
; version 3: generalized input; called by analxcor
; INPUT PARAMETERS:
;    H=HEADER RECORD
;    WAVE=WAVELENGTH VECTOR
;    FLUX=FLUX VECTOR
;    EPS= ERROR VECTOR
; keyword batch to skip displays
;
; VERSION 2 PERMITS LASER PLOTS OF FITTED OUTPUT
;
; to access options at end of fit, !verbose must be >0
COMMON COM2,A,B,FH,FIXT,ISHAPE
COMMON COMXY,XCUR,YCUR,ZERR,hcdev
COMMON VARS,VAR1,VAR2,VAR3,VAR4,VAR5
common icurunits,xunits,yunits,label,c1,c2,c3
common com1,hd,ik,ift,nsm,c,c6,c7,c8,c9,pdv,c11
if keyword_set(batch) then ib=1 else ib=0
if n_params(0) lt 5 then ipar=0 else ipar=1   ;1 if parameters passed
if n_params(0) lt 6 then ihlp=0 else ihlp=1
if ipar eq 1 then begin
   npar=n_elements(params)
   if npar lt 4 then ipar=0   ;minimum input: flag+3 parameters
   endif
pdv=!d.name
mt=!p.title
yt=!y.title
if not keyword_set(hcpy) then hcpy=0
EN0=EPS
HOLD=H
F=F0
nsm=1
ncam=0
!p.position=[.2,.15,.9,.9]
!c=-1
if (ipar ne 1) and (ib eq 0) then begin
   plot,wave,f0,psym=10
   if !d.name eq 'X' then wshow
   endif
NIT=0
MODE=3             ;1
NFIT=0
ZS=' S enables FIX'
IMAGE=fix(H(13)*1000+h(14)*10+h(15)-80)
case 1 of
   nsm le 2: flux=f
   (NSM GE 3) AND (NSM LT 1000): FLUX=SMOOTH(F,NSM)
   ELSE: FLUX=CONVOL(F,C)
   endcase
;IF H(3) GE 10 THEN IMAGE=H(10)*1000+H(11)*10+H(12)-80
GO1:             ;  LABEL TO RETURN FOR RESTART
;IRPLOT,WAVE,FLUX,0,0,0,0              ;plot ok
GO2:             ; RETURN HERE IF PARAMETERS NOT OK
INITARR,1,EA     ; ZERO ARRAYS BEFORE BEGINNING
;
if ipar eq 1 then begin
; params: flag,a(0:n), fit all bins
; flag=-7 for flat Background
   flag=fix(params(0))
   a=params(1:*)
   fixt=fix(a*0.)+1
   ishape=n_elements(a)/3
   if flag eq -7 then begin
      fixt(1:2)=0
      a(1:2)=0.
      b=[0,n_elements(wave)-1,-1,-9]
      endif
   if flag eq -17 then begin     ;-7 plus fix FWHMs
      k=6+3*indgen(ishape-1)
      fixt(k)=0
      fixt(1:2)=0
      a(1:2)=0.
      b=[0,n_elements(wave)-1,-1,-9]
      endif
   if ihlp eq 1 then print,'A:',a
   if ihlp eq 1 then stop
   goto,skipinp
   endif
;
GO4:             ; RETURN HERE TO PRESERVE ARRAYS
;
Z='Set cursor and hit:(0 TO END); '+ZS+'; M='+STRING(MODE,'(I3)')+'   '
Z1='1-4,L at X,Y of lines 1-4,5; M to change mode; N>-M '
Z2='A,B=background, C,D=Var reg, E for parab, FWHM=(5,%)(6,^)(7,&)(8,*)(9,() '
print,z
print,z1
print,z2
BLOWUP,-1
WHILE ZERR NE "60 DO BEGIN
if zerr eq 26 then goto,ret    ;ctrl-z
IF (ZERR EQ 71) or (zerr eq 103) THEN ICSAVE,-1  ;<G> restore fit parameters
IF (ZERR EQ 75) or (zerr eq 107) THEN ICSAVE,1   ;<K> save fit parameters
IF (ZERR EQ 77) or (zerr eq 109) THEN MODE=1+ABS(MODE) MOD 3  ;<M>
IF (ZERR EQ 78) or (zerr eq 110) THEN MODE=-MODE ;<N>  Epsilon vectors ignored if MODE<0
IF (ZERR EQ 81) or (zerr eq 113) THEN GOTO,RET   ;<Q,q>
IF (ZERR EQ 82) or (zerr eq 114) THEN GOTO,GO1   ;<R>
IF (ZERR EQ 83) or (zerr eq 115) THEN BEGIN      ;<S>
   NFIT=1
   ZS='T disables FIX'
   endif
IF (ZERR EQ 84) or (zerr eq 116) THEN BEGIN      ;<T>
   NFIT=0  
   ZS='S enables FIX'
   endif
IF (ZERR GE 77) AND (ZERR LE 84) THEN BEGIN   ;<M>-<T>  ;do not use O,P
   Z='Set cursor and hit:(0 TO END); '+ZS+'; M='+STRING(MODE,'(I3)')+'   '
   print,z
   ENDIF
IF (ZERR EQ 90) or (zerr eq 122) THEN STOP       ;<Z> 
IF (ZERR GT 122) OR (ZERR LT 26) THEN ZRECOVER
IPRM,WAVE,F,EN0
BLOWUP,-1
ENDWHILE
;
PARTST,WAVE,H(3),NFIT,EX
IF EX EQ -1 THEN GOTO,GO4
;
skipinp:
;
VAR1=VAR1+1
;
NB=B(1)-B(0)+1
knb=b(0)+indgen(nb)
if n_elements(label) eq 0 then begin
   tz=''
   PRINT,' '
   read,'Enter output title',tz 
   endif else tz=label
!p.title=tz
;
ncam=h(3)
nit=fix(var1)
xn=wave(knb)
yn=flux(knb)
en=en0(knb)
;
a=a(0:ishape*3-1)
fixt=fixt(0:ishape*3-1)
;
if b(3) eq -1 then b(3)=-9
ffit2,1,xn,yn,en,a,fixt,b,ncam,image,nsm,nit,mode,tz
yn=en
ea=fixt
eps=yn
;
IM=-1
IGO=4
!y.title='!6Correlation coefficient'
!x.title='!6Lag'
if strmid(strupcase(xunits),0,4) eq 'KM/S' then !x.title='!6km s!U-1!N'
; set plot scale
dx=400.
xc=a(4)          ;plot center
if abs(xc) lt 100. then xc=0.
if a(5) gt 20 then dx=700.
setxy,(xc-dx)>wave(0),(xc+dx)<(max(wave))
;
iloop=0
GO3:                      ; REPLOT data
iloop=iloop+1
!c=-1
case 1 of
   ib eq 0: IRPLOT,WAVE,FLUX,XN,YN,IM,IGO
   (ib eq 1) and (iloop eq 2): IRPLOT,WAVE,FLUX,XN,YN,IM,IGO
   else:
   endcase
;IM=1
if (ib eq 0) or ((ib eq 1) and (iloop eq 2)) then IPRA,NSM,HOLD,TZ
PRINT,STRING(7B)
if (hcpy ne 0) and (iloop eq 1) then begin
   if ipar eq 1 then zerr=80 else begin           ;query if interactive
      rst: print,' type P for a hard copy plot, T to tweak'
      blowup,-1
      endelse
   if (zerr eq 80) or (zerr eq 112) then begin
      sp,hcdev
      goto,go3
      endif
   if (zerr eq 84) or (zerr eq 116) then begin
      initarr,0,wave
      tn=fltarr(18) & tn(0)=ea & ea=tn
      goto,go4
      endif
   if (zerr eq 90) or (zerr eq 122) then begin
      stop
      goto,rst
      endif
   endif
RET: 
b=ea
ZERR=32
!p.title=mt
!y.title=yt
if ihlp eq 1 then stop,'ICFIT3'
RETURN
END
