;*********************************************************
PRO RESIDUAL,IGO,WAVE,FLUX,XN,YN,out,sr=sr
COMMON COM1,H,IK,IFT,NSM,C
COMMON COM2,A,B,FH,FIXT,ISHAPE
common icurunits,xunits,yunits,title,c1,c2,c3,ch
ZTIME=systime(0)
ZTIME='!XICUR '+STRMID(ZTIME,0,11)
NB=N_ELEMENTS(XN)
Ii=xindex(wave,xn(0))                ;TABINV,WAVE,XN(0),I
TF=FLUX(II:II+NB-1)
IF IGO EQ -1 THEN GOTO,SUBLIN
FN=TF-YN
FV=TOTAL(ABS(FN/TF))/FLOAT(NB)
M=TOTAL(FN)/FLOAT(NB)   ;MEAN RESIDUAL
RMS=SQRT(TOTAL((FN-M)*(FN-M))/FLOAT(NB-1))
!y.range(*)=0.
PRINT,' '
NSM0=NSM
C0=C
NSM=1.
if keyword_set(sr) then ROTVEL,-1,WAVE
!p.PSYM=10
IK=-777
PLDATA,0.,XN,FN,Pcol=c1
DRLIN,0.
IF NSM GT 1000. THEN NSM=NSM/10.-1000. ELSE NSM=0.
IF NSM GT 0. THEN NSTR=STRING(format='(F4.2)',NSM) ELSE NSTR='0.'
IF NSM GT 0. THEN Z=' Residuals smoothed by '+NSTR+' A;' $
     ELSE Z=' Unsmoothed residuals;'
Z=Z+' RMS='+STRING(format='(E9.2)',RMS)+' mean='+STRING(format='(E9.2)',M)
Z=Z+' Fv='+STRING(format='(E9.2)',FV)
x0=!x.crange(0)+0.01*(!x.crange(1)-!x.crange(0))
yd=!y.crange(0)+0.92*(!y.crange(1)-!y.crange(0))
XYOUTs,x0,yd,Z,charsize=1.0
NSM=NSM0
C=C0
k=where(tf eq 0.,czero)
if czero gt 0 then tf(k)=0.
o=fn/tf              ;fractional deviation 
if czero gt 0 then o(k)=0.
out=flux
out(II)=o
RETURN
;
SUBLIN:
PRINT,' '
LF=INTARR(ISHAPE)-9
Z=STRING(format='(I1)',ISHAPE-1)
PRINT,' Enter line(s) (1-',Z,') to subtract; B=0, all lines=-2, -1 for all,-9 to end'
NLIN=0
FOR J=0,ISHAPE-1 DO BEGIN
   READ,K
   LF(J)=FIX(K)
   IF K LT 0 THEN GOTO,SUBTR
   NLIN=NLIN+1
   ENDFOR
;
SUBTR:
IF LF(0) EQ -9 THEN RETURN       ;NO COMMANDS ENTERED
DB=(XN(NB-1)-XN(0))/(NB-1)
XB=FINDGEN(NB)+0.5
YB=A(0)+A(1)*XB+A(2)*XB*XB
XB=XN-DB/2.
;
bsub=where((lf le 0) and (lf ge -1),nbsub)
if nbsub ge 1 then bsub=1 else bsub=0
CASE 1 OF
   lf(0) lt 0: begin        ;SUBTRACT ALL
      IND=LF(0)
      TF=TF-YN                ;subtract fit
;      YN=YN*0.
      IF IND EQ -2 THEN BEGIN
         TF=TF+YB   ; restore LINES ONLY 
;         YN=YB
         ENDIF
      N0=-3*(1+IND)      ;ZERO FIT ARRAYS
      A(N0:*)=0.
      FIXT(N0:*)=1
      ISHAPE=ABS(IND)-1
      GOTO,RETN
      END
   else: begin
      FOR K=0,NLIN-1 DO BEGIN
         IND=LF(K)
         case 1 of
            IND EQ 0: BEGIN                 ;SUBTRACT BACKGROUND
               TF=TF-YB 
;               YN=YB
               FOR J=0,2 DO A(J)=0.
               NL=NLIN-1
               ENDIF 
            IND gt 0: begin                 ;SUBTRACT LINES
               IK=IND*3+1
               Z=(XB-A(IK))/A(IK+1)/DB
               Z=Z*Z*2. <7. 
               TF=TF-(A(IK-1)*EXP(-Z))
;               YN=YN-(A(IK-1)*EXP(-Z))
               FOR J=-1,1 DO A(IK+J)=0.
               NL=NLIN
               END
            else:
            endcase
         ENDFOR
      end
   endcase
; COMPRESS A ARRAY
ATMP=A(3:2+(ISHAPE-1)*3)
K=WHERE(ATMP EQ 0.)+3   ;INDEX OF ZERO VALUES
IF K(0) EQ 2 THEN GOTO, RETN   ;NO ZERO VALUES
L=K MOD 3
M=K(WHERE(L EQ 0))/3   ; ONLY LINE INDICES
NK=N_ELEMENTS(M)
K=INTARR(NK+1)
K(1)=M
WHILE NK GE 1 DO BEGIN
   K=K(1:NK)
   IK=K(0)
   if ik lt (ishape-1) then FOR J=IK*3+3,ISHAPE*3-1 DO BEGIN   ;SHIFT INDICES
      A(J-3)=A(J)
      FIXT(J-3)=FIXT(J)
      ENDFOR
   FOR J=ISHAPE*3-3,ISHAPE*3-1 DO A(J)=0.   ;ZERO END
   NK=NK-1
   K=K-1  ; SHIFT INDICES
   ENDWHILE
;
ISHAPE=ISHAPE-NL
RETN:
FLUX(II)=TF
;
NB=N_ELEMENTS(YN)
XB=FINDGEN(NB)-0.5
YN=A(0)+A(1)*XB+A(2)*XB*XB
XB=XN-DB/2.
IF ISHAPE GT 1 THEN FOR I=1,ISHAPE-1 DO BEGIN
   IK=I*3+1
   IF A(IK+1) EQ 0. THEN GOTO,ZWID
   Z=(XB-A(IK)+0.5*db)/A(IK+1)/db
   Z=Z*Z*2. <7.
   YN=YN+A(IK-1)*EXP(-Z)
   ZWID:
   ENDFOR
; 
if bsub then begin
   ifact=fltarr(n_elements(wave))
   good=where((wave ge xn(0)) and (wave le max(xn)),ng)
   if ng gt 0 then ifact(good)=1.
   SETXY,!X.CRANGE(0),!X.CRANGE(1),0.,0.
   endif ELSE IFACT=1.
;
FLUX=FLUX*IFACT
PLOT,WAVE,FLUX,psym=10
out=flux
opdate,'ICFIT'
RETURN
END
