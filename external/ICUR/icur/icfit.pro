;*************************************************************
PRO ICFIT,WAVE,F0,EPS,notitle=notitle
; VAX version 2.0 7/17/87
; INPUT PARAMETERS:
;    H=HEADER RECORD
;    WAVE=WAVELENGTH VECTOR
;    FLUX=FLUX VECTOR
;    EPS= ERROR VECTOR
;
; VERSION 2 PERMITS LASER PLOTS OF FITTED OUTPUT
;
COMMON COM1,H,IK,IFT,NSM,C,NDAT,ifsm,kblo,h1,ipdv,ihcdev
COMMON COM2,A,B,FH,FIXT,ISHAPE
COMMON COMXY,X,Y,ZERR
COMMON VARS,VAR1,VAR2,VAR3,VAR4,VAR5
COMMON ICDISK,ICURDISK,ICURDATA,ISMDAT
dev=!d.name
mt=!p.title
yt=!y.title
opchar=!p.charsize & opf=!p.fonts
EN0=EPS
HOLD=H
F=F0
PSSV=!P.pSYM
NIT=0
MODE=1
NFIT=0
ZS=' S enables FIX'
IMAGE=H(4)
IF (NSM GE 1) AND (NSM LT 1000) THEN FLUX=SMOOTH(F,NSM) ELSE FLUX=CONVOL(F,C)
IF H(3) GE 10 THEN IMAGE=H(10)*1000+H(11)*10+H(12)-80
GO1:             ;  LABEL TO RETURN FOR RESTART
IRPLOT,WAVE,FLUX,0,0,0,0
GO2:             ; RETURN HERE IF PARAMETERS NOT OK
INITARR,1,EA     ; ZERO ARRAYS BEFORE BEGINNING
GO4:             ; RETURN HERE TO PRESERVE ARRAYS
;
Z='Set cursor and hit:(0 TO END); '+ZS+'; M='+STRING(MODE,'($I3)')+'   '
Z1='1-4,L at X,Y of lines 1-4,5; M to change mode; N>-M '
Z2='A,B=background, C,D=Var reg,  FWHM=(5,%)(6,^)(7,&)(8,*)(9,() '
PRINT,' '
PRINT,Z
PRINT,Z1
PRINT,Z2
BLOWUP,-1
WHILE ZERR NE "60 DO BEGIN
if zerr eq 26 then goto,ret    ;ctrl-z
IF ZERR EQ 71 THEN ICSAVE,-1  ;<G> restore fit parameters
IF ZERR EQ 75 THEN ICSAVE,1   ;<K> save fit parameters
IF ZERR EQ 77 THEN MODE=1+ABS(MODE) MOD 3  ;<M>
IF ZERR EQ 78 THEN MODE=-MODE ;<N>  Epsilon vectors ignored if MODE<0
IF (ZERR EQ 81) or (zerr eq 113) THEN GOTO,RET   ;<Q,q>

IF ZERR EQ 82 THEN GOTO,GO1   ;<R>
IF ZERR EQ 83 THEN BEGIN      ;<S>
   NFIT=1
   ZS='T disables FIX'
   endif
IF ZERR EQ 84 THEN BEGIN      ;<T>
   NFIT=0  
   ZS='S enables FIX'
   endif
IF (ZERR GE 77) AND (ZERR LE 84) THEN BEGIN   ;<M>-<T>
   Z='Set cursor and hit:(0 TO END); '+ZS+'; M='+STRING(MODE,'($I3)')+'   '
   XYOUTS,!X.crange(0),!Y.crange(1)-DY,Z
   ENDIF
IF ZERR EQ 90 THEN STOP       ;<Z> 
IF (ZERR GT 122) OR (ZERR LT 26) THEN ZRECOVER
IPRM,WAVE,F,EN0
BLOWUP,-1
ENDWHILE
;
PARTST,WAVE,H(3),NFIT,EX
IF EX EQ -1 THEN GOTO,GO4
;
NIT=NIT+1
VAR1=VAR1+1
;
;  WRITE DATA TO DISK FOR FORTRAN ACCESS
GET_LUN,LU
OPENW,LU,'IUEDAT.TMP/UNF'
FORWRT,LU,A,B,ISHAPE,H(3),IMAGE,FIX(NSM),FIX(VAR1),MODE,FIXT
NB=B(1)-B(0)+1
YN=FLUX(B(0):B(0)+NB-1)
XN=WAVE(B(0):B(0)+NB-1)
EN=EN0(B(0):B(0)+NB-1)
FORWRT,LU,YN
FORWRT,LU,XN
FORWRT,LU,EN
zz='                                        '   ;40 CHARACTERS
tz=''
PRINT,' '
if not keyword_set(notitle) then read,'Enter output title',tz
strput,zz,tz,1
TZ=TZ+'!X'
forwrt,LU,BYTE(zz)
;
CLOSE,LU
FREE_LUN,LU
;XYOUT,100,680,''
zfit='RUN '+icurdisk+'FFIT2'
SPAWN,zfit  ;  SPAWN TO FFIT2 FOR COMPUTATIONS
GET_LUN,LU
OPENR,LU,'IUEDAT.TMP/UNF'
FORRD,LU,YN
YN=YN(0:NB-1)
FORRD,LU,A
FORRD,LU,EA
CLOSE,LU
FREE_LUN,LU
;
PRINTF,3,' 8'       ; WRITE TO .LST FILE
PRINTF,3,ZZ
PRINTF,3,B(0),B(1),B(2),B(3)
PRINTF,3,ISHAPE,' ;ISHAPE=1+# lines; (parameters, errors)'
FOR I=0,ISHAPE*3-1 DO PRINTF,3,A(I),EA(I)
;
IM=-1
IGO=4
!y.title=ytit(0)
!p.title=tz
;
GO3:                      ; REPLOT data
!p.fonts=-1 & !p.charsize=7./5.
IRPLOT,WAVE,FLUX,XN,YN,IM,IGO
IM=1
!p.charsize=1.
IPRA,NSM,HOLD,TZ
if !d.name eq 'PS' then begin   ;reset for screen
   lplt,dev
   x1=!x.range(0) & x2=!x.range(1)
   y1=!y.range(0) & y2=!y.range(1)
   setxy,x1,x2,y1,y2
   !p.position=[.15,.15,.9,.9]
   endif
PRINT,bell(1)
print,' Enter ICFIT option, ? for help, '
zerr=32
igo=0
ploop:
blowup,-1
IF ZERR EQ 63 THEN begin      ;<H>  help
   print,' ICFIT output commands '
   print,'  ?: generate this help display'
   print,'  C: overplot components'
   print,'  D: redisplay '
   print,'  I: restart '  
   print,'  O: overwrite data '
   print,'  P: print '
   print,'  R: plot residuals to fit '
   print,'  S: subtract components '
   print,'  T: tweak fit'  
   print,'  Z: stop '
   print,'  else: return to calling routine'
   goto,ploop
   endif
if zerr eq 64 then igo=4     ;<C>
if zerr eq 65 then igo=2     ;<D>
if zerr eq 73 then goto,go2  ;<I>
if zerr eq 79 then begin     ;<O>
   F0=FLUX
   IGO=0
   NSM=1
   endif
if zerr eq 80 then begin     ;<P>
   x1=!x.range(0) & x2=!x.range(1)
   y1=!y.range(0) & y2=!y.range(1)
   SP,ihcdev
   SETXY,X1,X2,Y1,Y2
   IGO=4
   IM=-1
   endif
IF ZERR EQ 82 THEN begin      ;<R>
   igo=1
   endif
IF ZERR EQ 83 THEN BEGIN      ;<S>
   igo=-1
   endif
IF ZERR EQ 84 THEN BEGIN      ;<T>
   IF ISHAPE GT 1 THEN INITARR,0,WAVE
   goto,go4
   endif
IF ZERR EQ 90 THEN begin      ;<Z> 
   STOP
   goto,ploop
   endif
; 
IF IGO NE 0 THEN GOTO,GO3
RET: 
ZERR=32
!P.pSYM=PSSV
!p.fonts=opf & !p.charsize=opchar      ;!fancy=ofancy
!p.title=mt
!y.title=yt
IK=0
RETURN
END
