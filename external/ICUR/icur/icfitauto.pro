;*************************************************************
PRO ICFITauto,WAVE,F0,EPS,params,psdel=psdel,batch=batch,iplot=iplot, $
    pfile=pfile,psave=psave,ptitle=ptitle,debug=debug
; VAX version 2.0 7/17/87
; version 2 - runs with IDL version of ffit2
; INPUT PARAMETERS:
;    H=HEADER RECORD
;    WAVE=WAVELENGTH VECTOR
;    FLUX=FLUX VECTOR
;    EPS= ERROR VECTOR
;
; VERSION 2 PERMITS LASER PLOTS OF FITTED OUTPUT
;
COMMON COM1,H,IK,IFT,NSM,C,x1,x2,x3,x4,ipdv,ihcdev
COMMON COM2,A,B,FH,FIXT,ISHAPE
COMMON COMXY,X,Y,ZERR,resetscale,lu3
COMMON VARS,VAR1,VAR2,VAR3,VAR4,VAR5
common icurunits,xunits,yunits,title,c1,c2,c3,ch
common custompars,dw,lp,Cx2,Cx3,Cx4,Cx5
IF (STRUPCASE(!D.NAME) EQ 'X') OR STRUPCASE(!D.NAME EQ 'WIN') THEN IX=1 $
   ELSE IX=0
if strupcase(xunits) eq 'KM/S' then dtype=1 else dtype=0
nocap=rdbit(var3,4)
if n_elements(lp) eq 0 then LP=0.
;
if n_elements(params) lt 4 then ipar=0 else ipar=1       ;parameters passed
;
EMODE=['B variance','scaled B variance','constant variance','S/N vector']
csave=c1
psd=psdel
mt=!p.title
yt=!y.title
pchar=!p.charsize
opf=!p.font
!p.font=-1
EN0=EPS
NOQUERY=0
IF (H(33) EQ 30) AND (ABS(MEAN(EPS)-100.) LT 0.001) AND (MAX(EPS) EQ MIN(EPS)) $
   THEN H(33)=0
IF H(33) EQ 30 THEN BEGIN
   K=WHERE(EPS EQ 0.,NZ) & IF NZ GT 0 THEN En0(K)=1.
   En0=F0/En0
   ENDIF
HOLD=H
F=F0
PSSV=!p.PSYM
NIT=0
MODE=1                ;default - use variance in data
;if h(33) eq 30 then mode=4           ;use S/N vector
NFIT=0
ZS=' S enables FIX'
IMAGE=H(4)
CASE 1 OF
   NSM EQ 1: FLUX=F
   (NSM GE 3) AND (NSM LT 1000): FLUX=SMOOTH(F,NSM)
   ELSE    : FLUX=CONVOL(F,C)
   ENDCASE
IF H(3) GE 10 THEN IMAGE=H(11)+h(10)*31+(H(12)-80)*1000   ;compressed date
GO1:             ;  LABEL TO RETURN FOR RESTART
!p.charsize=1.4
GO2:             ; RETURN HERE IF PARAMETERS NOT OK
if keyword_set(iplot) then IRPLOT,WAVE,FLUX,0,0,0,0
bell,1
INITARR,1,EA     ; ZERO ARRAYS BEFORE BEGINNING
b=[0,n_elements(wave)-1,-1,-9]
;
if ipar eq 1 then begin          ;initial parameters passed
; params: flag,a(0:n), fit all bins   ; flag=-7 for flat Background
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
   goto,skipinp
   endif
;
zerr=48          ;***
GO4:             ; RETURN HERE TO PRESERVE ARRAYS
;
print,' '
icsave,-1,pfile
;IF IX THEN WSHOW
if keyword_set(debug) then begin
   PRINT,'ICFIT2: Type ? for help. 0 initiates fit'
   BLOWUP,-1    ;*************
   endif
WHILE ZERR NE 48 DO BEGIN
if zerr eq 26 then goto,ret    ;ctrl-z
if zerr eq 63 then begin       ;<?>
   print,' '
   print,'ICFIT2 Initial Fit Commands'
   print,'   A: Mark beginning of fit region and mean background level (X+Y)'
   print,'   B: Mark end of fit region'
   print,'   C: Mark beginning of region of S/N estimation'
   print,'   D: Mark end of region of S/N estimation'
   print,'   E: Mark minimum of parabola for quadratic background (optional)'
   print,'   G: Restore previous fit parameters from disk'
   print,'   I: fix wavelength interval, current interval = ',lp
   print,'   K: Save current fit parameters to disk'
   print,'   M: Change error estimation mode, currently',abs(MODE),' (',emode((abs(mode)-1)>0),')'
   if mode le 0 then z='Exclude ' else z='Include '
   print,'   N: ',z,'bad data (as indicated by epsilon vector)'
   print,'   Q: Quit and return'
   if nfit eq 1 then begin
      if noquery eq 0 then z=' off' else z=' on'
      print,'   P: Set to turn',z,' query about fixed parameters'
      endif
   print,'   R: Restart'
   if nfit eq 0 then print,'   S: Enable freezing of parameters'
   if nfit eq 1 then print,'   T: Disable freezing of parameters'
   print,'   X: delineate region to exclude from fit (U to restore)'
   print,'   Z: Stop'
   print,'   1,2,3,4,L: locations and peaks of lines 1,2,3,4,5, respectively'
   print,'   5,6,7,8,9: lower half width of line 1,2,3,4,5, respectively'
   print,'   %,^,&,*,(: upper half width of line 1,2,3,4,5, respectively'
   print,'   0: (zero) Done with inputs - start the fit.
   endif
IF (ZERR EQ 71) or (zerr eq 103) THEN BEGIN      ;<G> restore fit parameters
   ICSAVE,-1  
   GOTO,OUTLOOP                                  ;does fit, JEN skips
   ENDIF
IF (ZERR EQ 73) or (zerr eq 105) THEN BEGIN      ;<I> set LP
   read,lp,prompt=' Enter distance in Angstroms between line pairs'
   endif
IF (ZERR EQ 75) or (zerr eq 107) THEN ICSAVE,1   ;<K> save fit parameters
IF (ZERR EQ 77) or (zerr eq 109) THEN begin      ;<M>
   MODE=(1+ABS(MODE)) MOD 4
   print,' Error estimation mode = ',strtrim(mode,2)
   endif
IF (ZERR EQ 78) or (zerr eq 110) THEN MODE=-MODE ;<N>  Epsilon vectors ignored if MODE<0
IF (ZERR EQ 80) or (zerr eq 112) THEN begin      ;<P>
   if nfit eq 1 then noquery=((noquery+1) mod 2) else noquery=0
   endif
IF (ZERR EQ 81) or (zerr eq 113) THEN GOTO,RET   ;<Q,q>
IF (ZERR EQ 82) or (zerr eq 114) THEN GOTO,GO1   ;<R>
IF (ZERR EQ 83) or (zerr eq 115) THEN BEGIN      ;<S>
   NFIT=1
   noquery=0
   print,'Parameter freezing enabled'
   endif
IF (ZERR EQ 84) or (zerr eq 116) THEN BEGIN      ;<T>
   NFIT=0  
   fixt=fix(a*0.)+1
   print,'Parameter freezing disabled'
   endif
IF (ZERR EQ 85) or (zerr eq 117) THEN begin          ;<U> undelete deleted points
   en0=eps
   IF H(33) EQ 30 THEN BEGIN
      K=WHERE(EPS EQ 0.,NZ) & IF NZ GT 0 THEN En0(K)=1.
      En0=F0/En0
      ENDIF
   end
;IF (ZERR EQ 88) or (zerr eq 120) THEN begin               ;<X> X done in IPRM
IF (ZERR EQ 90) or (zerr eq 122) THEN STOP,'ICFIT2'       ;<Z> 
IF (ZERR GT 122) OR (ZERR LT 26) THEN ZRECOVER
IPRM,WAVE,F,EN0
;IF IX THEN WSHOW
BLOWUP,-1
ENDWHILE
;
OUTLOOP:
PARTST,WAVE,H(3),NFIT,EX,noquery,cii=cii
IF EX EQ -1 THEN GOTO,GO4
;
skipinp:           ;skip to here if parameters are passed
;
VAR1=VAR1+1
;
NB=B(1)-B(0)+1
knb=b(0)+indgen(nb)
b0=b(0)
tid=''
;PRINT,' '
if n_elements(ptitle) gt 0 then tid=ptitle
;case 1 of
;   strupcase(xunits) eq 'KM/S': begin
;      if n_elements(title) eq 0 then read,'Enter output title: ',tid else tid=title
;      end
;    else: read,'Enter output title: ',tid
;    endcase
tz=tid
;
ncam=h(3)
nit=fix(var1)
xn=wave(knb)
dw=xn(1)-xn(0)
yn=flux(knb)
en=en0(knb)
if ncam gt 3 then begin
   if strlen(tz) gt 0 then tz=strtrim(BYTE(h(100:159))>32b,2)+', '+tz else $
      tz=strtrim(BYTE(h(100:159))>32b,2)
   endif
;
a=a(0:ishape*3-1)
ifixt=fixt(0:ishape*3-1)
;
ffit2,dtype,xn,yn,en,a,ifixt,b,ncam,image,nsm,nit,mode,tz,cii=cii
b=b+b0
yn=en
ea=ifixt
;
if n_elements(lu3) eq 1 then begin
   PRINTF,lu3,' 8'       ; WRITE TO .LST FILE
   PRINTF,lu3,tZ
   PRINTF,lu3,B(0),B(1),B(2),B(3)
   PRINTF,lu3,ISHAPE,' ;ISHAPE=1+# lines; (parameters, errors)'
   FOR I=0,ISHAPE*3-1 DO PRINTF,lu3,A(I),EA(I)
   endif
;
IM=-1
IGO=4
!y.title=ytit(0)
!p.title=tz
sr=0
out=-1
hcplt=0
ieb=0
if not keyword_set(debug) then begin   ;**********************************
   x1=!x.range(0) & x2=!x.range(1)            ;setup for hardcopy
   y1=!y.range(0) & y2=!y.range(1)
   SP,ihcdev
   IGO=4
   IM=-1
   hcplt=1
   endif
;
;if h(33) eq 30 then ieb=1 else ieb=0
;
GO3:                      ; REPLOT data
;IF (STRUPCASE(!D.NAME) EQ 'X') OR STRUPCASE(!D.NAME EQ 'WIN') THEN WSHOW
!p.charsize=1.4
IRPLOT,WAVE,FLUX,XN,YN,IM,IGO,out,en0,sr=sr,ieb=ieb
IM=1
GO5:
if not nocap then IPRA,NSM,HOLD,TZ,SIZE=1.0
if keyword_set(batch) then goto,ret
;
if (!d.name eq ihcdev) and (hcplt eq 1) then begin   ;reset for screen
   if dtype eq 1 then goto,ret             ;finish plot in ANALXCOR
   if rdbit(psd,0) or rdbit(psd,1) then begin
      file=strcompress(tid,/remove_all)
      if strlen(file) le 0 then file='icfit'
      file=file+'.ps'
      lplt,ipdv,nodelete=rdbit(psd,0),noplot=rdbit(psd,1),file=file
      psd=0
      print,' Plot saved to file ',file,'; PSDEL reset to 0'
      endif else lplt,ipdv
   c1=csave
   hcplt=0
   x1=!x.range(0) & x2=!x.range(1)
   y1=!y.range(0) & y2=!y.range(1)
   setxy,x1,x2,y1,y2
   endif
IF IX THEN BEGIN
   z='                                                       '
   XYOUTS,!x.crange(0),!y.crange(0)-(!y.crange(1)-!y.crange(0))/10.,z
   ENDIF
ZK=[67,68,69,70,73,75,77+INDGEN(8),90]
ZKEYS=[33,41,48,63,ZK,ZK+32]
;PRINT,STRING(7B)
;print,' Enter ICFIT option, ? for help, Q to return to calling routine '
zerr=32
igo=0
if not keyword_set(debug) then zerr=81             ;***
ploop:
;IF (STRUPCASE(!D.NAME) EQ 'X') OR STRUPCASE(!D.NAME EQ 'WIN') THEN WSHOW
if keyword_set(debug) then blowup,-1
K=WHERE(ZERR EQ ZKEYS,CZK)
IF CZK EQ 0 THEN BEGIN
   BELL,3
   PRINT,' INVALID COMMAND:',STRING(BYTE(ZERR))
   ENDIF
IF ZERR EQ 63 THEN begin      ;<?>  help
   print,' ICFIT output commands '
   print,'  ?: generate this help display'
   print,'  !: toggle plot device, current device=',!d.name
   print,'  C: overplot components '
   print,'  D: redisplay '
   if h(33) eq 30 then print,'  E: set error bars for overplotting'
   print,'  F: fractional residuals '
   print,'  I: restart '  
   print,'  K: save fit parameters to disk'
   print,'  M: set to enable residual smoothing, current value=',sr
   print,'  N: print out plot; save plotfile as disk file'
   print,'  O: overwrite data '
   print,'  P: print out plot and delete disk file'
   print,'  Q: return to calling routine'
   print,'  R: plot residuals to fit '
   print,'  S: subtract components '
   print,'  T: tweak fit '  
   print,'  Z: stop'
   PRINT,'  0: Draw zero line'
   PRINT,'  ): Toggle figure captions'
   print,'  else: no effect'
   goto,ploop
   endif
if zerr eq 41 then begin               ;<)>
   ibit,var3,4,-1
   nocap=rdbit(var3,4)
   endif
if zerr eq 33 then begin               ;<!>
   if strupcase(!d.name) eq strupcase(ipdv) then begin
      sp,ihcdev 
      c1=ch
      endif else lplt,ipdv
      goto,ploop
   endif
if (zerr eq 67) or (zerr eq 99) then igo=4               ;<C>
if (zerr eq 68) or (zerr eq 100) then igo=2              ;<D>
if ((zerr eq 69) or (zerr eq 101)) and (h(33) eq 30) then ieb=(ieb+1) mod 2  ;<E>
if (zerr eq 70) or (zerr eq 102) then begin              ;<F>
   if n_elements(out) gt 1 then begin
       !y.title='!6 fractional residuals'
       plot,wave,out
       DRLIN,0,LS=1
       hcplt=1
       goto,go5
       endif
   endif
if (zerr eq 73) or (zerr eq 105) THEN BEGIN     ;<I>
   IRPLOT,WAVE,FLUX,XN,YN,-1,4
   GOTO,GO2
   ENDIF
IF (ZERR EQ 75) or (zerr eq 107) THEN begin     ;<K> save fit parameters
   OA=A & OFIXT=FIXT ;& OEA=EA
   IF ISHAPE GT 1 THEN INITARR,0,WAVE
   ICSAVE,1   
   A=OA & FIXT=OFIXT ;& EA=OEA
   goto,ploop
   endif
if (zerr eq 77) or (zerr eq 109) then begin     ;<M> enable residual smoothing
   sr=(sr+1) mod 2
   endif
if (zerr eq 78) or (zerr eq 110) then begin     ;<N> PLOT AND SAVE PLOT FILE
   psd=1
   if rdbit(psdel,1) eq 1 then ibit,psd,1
   zerr=80
   endif
if (zerr eq 79) or (zerr eq 111) then begin     ;<O>
   F0=FLUX
   IGO=0
   NSM=1
   endif
if (zerr eq 80) or (zerr eq 112) or (zerr eq 61) then begin     ;<P,=>
   x1=!x.range(0) & x2=!x.range(1)
   y1=!y.range(0) & y2=!y.range(1)
   SP,ihcdev
   IGO=4
   IM=-1
   hcplt=1
   endif
IF (ZERR EQ 81) or (zerr eq 113)  THEN goto,ret   ;<Q>  quit
IF (ZERR EQ 82) or (zerr eq 114)  THEN begin      ;<R>  plot residuals
   igo=1
   hcplt=1
   endif
IF (ZERR EQ 83) or (zerr eq 115)  THEN BEGIN      ;<S>
   igo=-1
   endif
IF (ZERR EQ 84) or (zerr eq 116)  THEN BEGIN      ;<T>
   IRPLOT,WAVE,FLUX,XN,YN,-1,4
   INITARR,0,WAVE
   tn=fltarr(18)     ;reset EA (rest done in INITARR)
   tn(0)=ea
   ea=tn
   if mode eq 3 then b(3)=-9
   goto,go4
   endif
IF (ZERR EQ 90) or (zerr eq 122)  THEN begin      ;<Z> 
   STOP,'ICFIT'
   goto,ploop
   endif
IF ZERR EQ 48 THEN BEGIN                          ;<0>
   DRLIN,0,LS=1
   goto,ploop
   ENDIF
; 
IF IGO NE 0 THEN GOTO,GO3
goto,ploop
RET: 
if dtype eq 1 then b=ea
print,' ICFIT done.'
ZERR=70
!p.PSYM=PSSV
!p.charsize=pchar
!p.font=opf
!p.title=mt
!y.title=yt
c1=csave
IK=0
RETURN
END
