;*****************************************************************************
PRO FOLD,IP,X,W,F,F1              ; FOLD DATA ON ITSELF, PMNT SMOOTHING
COMMON COM1,H,IK,IFT,NSM,C,ndat,ifsm,kblo,h2
IF IP EQ -1 THEN BEGIN        ;MAKE SMOOTHING PERMANENT
   IF (NSM GT 1) AND (NSM LT 1000) THEN F=SMOOTH(F,NSM) ELSE F=CONVOL(F,C)
   NSM=1
   RETURN
   ENDIF
h2=h
NDAT=1
IK=-777
XL=X
i0=fix(xindex(w,xl)+0.5)      ;TABINV,W,XL,I0
S=N_ELEMENTS(W)
T=REVERSE(F)
I0=-(S-2*I0)              ;INITIAL OFFSET
GO1:
F1=F
F1=SHIFT(T,I0)
PLDATA,0,W,F,PSM=10
PLDATA,1,W,F1,PSM=0
READ,'0 if OK. Else enter additional shift in bins (+ to right): ',I1
I1=FIX(I1)
IF I1 EQ 0 THEN RETURN
I0=I0+I1
GOTO,GO1
END
