;*************************************************************************
PRO WSHIFT,IM,WAVE,FLUX,EPS,F1,E1,E,W1,ofb   ; SHIFT WAVELENGTH SCALE
COMMON COM1,HD,IK,IFT,NSM,C,ndat,ifsm,kblo,h2
common comxy,xcur,ycur,zerr
common icurunits,xu,yu,title,c1,c2
S=N_ELEMENTS(FLUX)-1
S1=N_ELEMENTS(F1)-1
DISP=(WAVE(S-1)-WAVE(0))/FLOAT(S)
IF IM EQ 0 THEN BEGIN  ; AUTOMATIC ZERO POINT SHIFT
   OFB=FIX((WAVE(0)-W1(0))/DISP)
   IF ABS(OFB) GE S THEN BEGIN
      PRINT,' ***ERROR***  Wavelength ranges incompatible. OFB=',OFB
      E=EPS
      GOTO,RETN
      ENDIF
   ENDIF ELSE BEGIN  ; ALIGN DATA MANUALLY 
   IK=-777
   PLDATA,0,WAVE,FLUX,PCOL=C1,psm=10
   PLDATA,1,WAVE,F1,PCOL=C2,psm=0
   z='MARK TARGET LINE (HIST), THEN COMP. LINE, ''X'' for cross correlation'
   print,z
   opstat,'  Waiting'
   blowup,-1
   IF (ZERR EQ 81) OR (ZERR EQ 48) OR (ZERR EQ 113) THEN GOTO,RETN
   if (zerr eq 88) or (zerr eq 120) then begin   ;cross correlation
      ICCOR,2,WAVE,FLUX,WAVE,F1,0,a
      IF A(1) GT 0 THEN SIGN=+1. ELSE SIGN=-1.
      OFB=FIX(A(1)+SIGN*0.5)
      endif else begin
      XD=Xcur
      i0=xindex(wave,xd)                         ;TABINV,WAVE,XD,I0
      opstat,'  Waiting'
      blowup,-1
      opstat,'  Working'
      XD=Xcur
      i1=xindex(wave,xd)                         ;TABINV,WAVE,XD,I1
      D=(I1-I0)/(ABS(I1-I0)>0.5)
      OFB=FIX((I1-I0)+D*0.5)
      ENDELSE
   ENDELSE   ;END MANUAL SHIFTING
;
F1=SHIFT(F1,-OFB)
E1=SHIFT(E1,-OFB)
IF OFB LT 0 THEN BEGIN
   K=INDGEN(-OFB)
   F1(K)=0.
   E1(K)=-1000
   ENDIF
IF OFB GT 0 THEN BEGIN
   K=S1-INDGEN(OFB)
   IF K(0) NE -1 THEN BEGIN
      F1(K)=0.
      E1(K)=-1000
      ENDIF
   ENDIF
z='OFFSET = '+strtrim(STRING(OFB),2)
print,z
if n_elements(hd) ge 40 then HD(39)=HD(39)+OFB
E=EPS<E1
ZERR=98
W1=WAVE
RETN:
IK=0
IFT=0
RETURN 
END
