;*****************************************************************
PRO SCALE,IM,WAVE,FLUX,F1                ; SCALE FLUX VECTORS
COMMON COM1,HD
COMMON COMXY,XCUR,YCUR
OFB=HD(39)
N=N_ELEMENTS(FLUX)-1
LOW=0 & HIGH=N
IF OFB GE 0 THEN HIGH=N-OFB ELSE LOW=OFB-1   ;IGNORE POINTS SHIFTED OUT
K=WHERE((FLUX GT 0.) AND (F1 GT 0.))
MFLUX=N_ELEMENTS(FLUX)-1
MF1=N_ELEMENTS(F1)-1
IF IM EQ -1 THEN S=TOTAL(FLUX(K))/TOTAL(F1(K)) ELSE BEGIN
   XL=XCUR
   i1=xindex(wave,xl)             ;TABINV,WAVE,XL,I1
   opstat,'  Waiting'
   blowup,-1
   opstat,'  Working'
   XD=XCUR
   i2=xindex(wave,xd)                ;TABINV,WAVE,XD,I2
   case 1 of
      I2 LT I1: BEGIN    ;swap
         T=I1
         I1=I2
         I2=T
         END
      I1 EQ I2: begin
         I1=0 & I2=N<(N_ELEMENTS(F1)-1)
         END
      else:
      endcase
I22=(I2<MF1)<MFLUX
   TF=TOTAL(FLUX(I1:I22))
   TF1=TOTAL(F1(I1:I22))
   S=TF/TF1
   ENDELSE
F1=F1*S
S=S*10^(FLOAT(HD(35))/100.)
HD(35)=FIX(ALOG10(S)*100.)
!ERR=0
RETURN
END
