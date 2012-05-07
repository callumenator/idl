;*************************************************************
PRO ICFIT2,WAVE,F0,EPS,params,psdel=psdel,batch=batch,iplot=iplot,cii=cii, $
    auto=auto,pfile=pfile,psave=psave,ptitle=ptitle,dtype=dtype,yfit=yfit, $
    notitle=notitle
; VAX version 2.0 7/17/87
; version 2 - runs with IDL version of ffit2
; INPUT PARAMETERS:
;    WAVE=WAVELENGTH VECTOR
;    FLUX=FLUX VECTOR
;    EPS= ERROR VECTOR
;
; VERSION 2 PERMITS LASER PLOTS OF FITTED OUTPUT
;
COMMON COM1,HOLD,IK,IFT,NSM,C,NDAT,x2,x3,x4,ipdv,ihcdev
COMMON COM2,A,B,FH,FIXT,ISHAPE
COMMON COMXY,X,Y,ZERR,resetscale,lu3
COMMON VARS,VAR1,VAR2,VAR3,VAR4,VAR5
common icurunits,xunits,yunits,title,c1,c2,c3,ch
common custompars,dw,lp,flatback,CX3,EAFUDGE,Cx5
if n_elements(c1) eq 0 then c1=!p.color
if n_elements(var1) eq 0 then var1=0
if n_elements(nsm) eq 0 then nsm=1
if n_elements(xunits) eq 0 then xunits=''
;
if not keyword_set(auto) then auto=0
if auto and n_elements(pfile) eq 0 then begin
   print,' To run in AUTO mode you must specify a fit using the PFILE keyword'
   return
   endif
IF (STRUPCASE(!D.NAME) EQ 'X') OR STRUPCASE(!D.NAME EQ 'WIN') THEN IX=1 $
   ELSE IX=0
if auto then ix=0
if (strupcase(xunits) eq 'KM/S') and (n_elements(dtype) eq 0) then dtype=1
if n_elements(dtype) eq 0 then dtype=0
nocap=rdbit(var3,4)
if n_elements(lp) eq 0 then LP=0.
if lp ne 0 then print,' WARNING: LP=',lp
if n_elements(hold) eq 0 then hold=intarr(512)
H=hold
if dtype eq 2 then h=intarr(512)
flatback=0                     ;not flat background
if n_elements(hold) gt 3 then begin
   if hold(3)/10 eq 10 then ghrs=1 else ghrs=0
   endif else ghrs=0
;
if n_elements(params) lt 4 then ipar=0 else ipar=1       ;parameters passed
;
EMODE=['B variance','scaled B variance','constant variance','S/N vector']
csave=c1
if not keyword_set(psdel) then psdel=0
psd=psdel
mt=!p.title
yt=!y.title
pchar=!p.charsize
opf=!p.font
!p.font=-1
EN0=EPS
NOQUERY=0
;IF (H(33) EQ 30) AND (ABS(MEAN(EPS)-100.) LT 0.001) AND (MAX(EPS) EQ MIN(EPS)) $
;   THEN H(33)=0
IF H(33) EQ 30 THEN BEGIN       ;convert sigms to error bars
   K=WHERE(EPS EQ 0.,NZ) & IF NZ GT 0 THEN En0(K)=1.
   KB=WHERE(EPS LT -1000.,NZ)
   En0=ABS(F0)/En0
   IF NZ GT 0 THEN en0(kb)=eps(kb)           ;restore bad data flags
   h(33)=40
   ENDIF
F=F0
PSSV=!p.PSYM
NIT=0
MODE=1                ;default - use variance in data
if h(33) eq 40 then mode=4           ;use S/N vector
if h(33) ge 30 then maxmode=5 else maxmode=4
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
b=[-1,n_elements(wave)-1,-1,-9]
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
      b=[-1,n_elements(wave)-1,-1,-9]
      endif
   if flag eq -17 then begin     ;-7 plus fix FWHMs
      k=6+3*indgen(ishape-1)
      fixt(k)=0
      fixt(1:2)=0
      a(1:2)=0.
      b=[-1,n_elements(wave)-1,-1,-9]
      endif
   goto,skipinp
   endif
;
GO4:             ; RETURN HERE TO PRESERVE ARRAYS
;
if auto then begin
   icsave,-1,pfile 
   zerr=48
   endif else print,' '
IF IX and not auto THEN WSHOW
PRINT,'ICFIT2: Type ? for help. 0 initiates fit'
BLOWUP,-1
WHILE ZERR NE 48 DO BEGIN
if zerr eq 26 then goto,ret    ;ctrl-z
if zerr eq 63 then begin       ;<?>
   if flatback then zb='discontinue' else zb='set'
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
   print,'   V: reset (view) plot corners (2 keystrokes)'
   print,'   X: delineate region to exclude from fit (U to restore)'
   print,'   Y: ',zb,' flat background'
   print,'   Z: Stop'
   print,'   1,2,3,4,L: locations and peaks of lines 1,2,3,4,5, respectively'
   print,'   5,6,7,8,9: lower half width of line 1,2,3,4,5, respectively'
   print,'   %,^,&,*,(: upper half width of line 1,2,3,4,5, respectively'
   print,'   0: (zero) Done with inputs - start the fit.
   PRINT,'   -: remove last line from fit '
   endif
if zerr eq 45 then begin                 ;<-> subtract last line
   na=n_elements(a)/3-1
   aline=3*(1+indgen(na))
   k=where(a(aline) ne 0.,nk)
   case 1 of
      nk eq 0: print,' No lines to subtract'
      else: begin
         k=max(k)
         j=k*3+3
         a(j:j+2)=0.
         print,' line ',k,' deleted
         end
      endcase
   endif
IF (ZERR EQ 71) or (zerr eq 103) THEN BEGIN      ;<G> restore fit parameters
   ICSAVE,-1  
   if auto then GOTO,OUTLOOP                     ;starts fit
   ENDIF
IF (ZERR EQ 73) or (zerr eq 105) THEN BEGIN      ;<I> set LP
   read,lp,prompt=' Enter distance in Angstroms between line pairs: '
   endif
IF (ZERR EQ 75) or (zerr eq 107) THEN ICSAVE,1   ;<K> save fit parameters
IF (ZERR EQ 77) or (zerr eq 109) THEN begin      ;<M>
   MODE=(1+ABS(MODE)) MOD maxmode
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
IF (ZERR EQ 87) or (zerr eq 119) THEN begin      ;<V,v>  reset plot corners
    irinit,wave
    iplot=1
    goto,go1
    end
;IF (ZERR EQ 88) or (zerr eq 120) THEN begin               ;<X> X done in IPRM
IF (ZERR EQ 89) or (zerr eq 121) THEN BEGIN                ;<Y>
   flatback=(flatback+1) mod 2
   if flatback then print,' Constant background' else $
      print,' Quadratic background'
   endif
IF (ZERR EQ 90) or (zerr eq 122) THEN BEGIN                ;<Z> 
   STOP,'ICFIT2'
   PSD=PSDEL
   ENDIF
IF (ZERR GT 122) OR (ZERR LT 26) THEN ZRECOVER
IPRM,H,WAVE,F,EN0
IF IX and not auto THEN WSHOW
BLOWUP,-1
ENDWHILE
;
OUTLOOP:
if b(0) eq -1 then begin
   b(0)=0
   if n_elements(yn) gt 2 then a(0)=median(yn) else a(0)=median(f0)
   endif
PARTST,WAVE,H(3),NFIT,EX,noquery
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
case 1 of
   n_elements(ptitle) gt 0: tid=ptitle
   n_elements(title) gt 0: tid=title
   keyword_set(notitle): ptitle=''
   else:
   endcase
if not auto and n_elements(ptitle) EQ 0 then begin
   PRINT,' '
   case 1 of
    strupcase(xunits) eq 'KM/S': begin
      if n_elements(title) eq 0 then read,'Enter output title: ',tid else tid=title
      end
     else: read,'Enter output title: ',tid
     endcase
   endif
tz=tid
;
ncam=h(3)
nit=(fix(var1))(0)
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
if dtype gt 0 then dtype0=1 else dtype0=0
ffit2,dtype0,xn,yn,en,a,ifixt,b,ncam,image,nsm,nit,mode,tz,cii=cii, $
   eafudge=eafudge
b=b+b0
yn=en
ea=ifixt
yfit=yn
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
if auto then begin                            ;setup for hardcopy
   x1=!x.range(0) & x2=!x.range(1)            
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
IF ((STRUPCASE(!D.NAME) EQ 'X') OR STRUPCASE(!D.NAME EQ 'WIN')) and $
   not auto THEN WSHOW
!p.charsize=1.4
IRPLOT,WAVE,FLUX,XN,YN,IM,IGO,out,en0,sr=sr,ieb=ieb
IM=1
GO5:
if not nocap then IPRA,NSM,H,TZ,SIZE=1.0
if keyword_set(batch) then goto,ret
;
if n_elements(ihcdev) eq 0 then ihcdev='ps'
if n_elements(ipdv) eq 0 then case 1 of
   strupcase(!d.name) ne 'PS': ipdv=!d.name
   !version.arch eq 'vax': ipdv='X'
   !version.arch eq 'alpha': ipdv='X'
   else: ipdv='WIN'
   endcase
if (!d.name eq ihcdev) and (hcplt eq 1) then begin   ;reset for screen
   if dtype eq 1 then goto,ret             ;finish plot in ANALXCOR
   if rdbit(psd,0) or rdbit(psd,1) then begin
      file=strcompress(tid,/remove_all)
      if strlen(file) le 0 then file='icfit'
      file=file+'.ps'
      lplt,ipdv,nodelete=rdbit(psd,0),noplot=rdbit(psd,1),file=file
      psd=PSDEL
      print,' Plot saved to file ',file    ;,'; PSDEL reset to 0'
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
ZK=[67,68,69,70,73,75+INDGEN(8),90]
ZKEYS=[33,41,48,61,63,ZK,ZK+32]
if not auto then begin
   PRINT,STRING(7B)
   print,' Enter ICFIT option, ? for help, Q to return to calling routine '
   zerr=32
   endif else zerr=81
igo=0
ploop:
IF ((STRUPCASE(!D.NAME) EQ 'X') OR STRUPCASE(!D.NAME EQ 'WIN')) and $
   not auto THEN WSHOW
if not keyword_set(auto) then blowup,-1
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
   if ghrs then print,'  L: overplot LSA aperture profile'
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
if ghrs and ((zerr eq 76) or (zerr eq 108)) then op_lsa,wave,flux,en0,yn   ;<L> oplot LSA profile
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
   STOP,'ICFIT2'
   PSD=PSDEL
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
if dtype ge 1 then b=ea
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
