;***********************************************************************
PRO BBODY,W,F,EPS,temp=temp      ; COMPUTE AND OVERPLOT BLACK BODY SPECTRUM
COMMON COM1,H,IK,IFT,NSM,C
COMMON COMXY,Xcur,Ycur,zerr
common icurunits,xunits,yunits,title,col1,col2,col3
IMULT=0 & IPT=0
if n_params(0) lt 2 then return
if n_params(0) lt 3 then eps=fix(w)*0+100
if max(eps) eq 0 then eps=eps+100
E=FLOAT(EPS/(ABS(EPS)>1))
E=E>0.
if n_elements(col2) eq 0 then opcol=!p.color else opcol=col2
REENT:
case 1 of
   !d.name eq 'PS' : begin
      read,'BBody: scale to all (1), point (2), or range(3), - for multiple: ',itype
      if abs(itype) le 1 then begin
         x1=min(w) & x2=max(w)
         endif
      if abs(itype) eq 2 then begin
         read,' enter wavelength of point: ',x1
         ipt=1
         x2=x1
         endif
      if abs(itype) eq 3 then read,' enter wavelength limits: ',x1,x2
      if itype lt 0 then imult=1
      I1=FIX(xindex(w,x1)) & I2=FIX(xindex(w,x2))
      y1=f(i1)
      if ipt eq 1 then i2=0
   end
;
   else: begin         ;plot to screen
      print,'BBody: scale to all (0,N), point (1,P), or select range(<space> ,M)'
      opstat,'  Waiting'
      BLOWUP,-1
      opstat,'  Working'
      IF ZERR EQ 90 THEN BEGIN
         STOP,' BBODY STOP
         GOTO,REENT
         ENDIF
      IF (zERR EQ 77) OR (ZERR EQ 109) THEN IMULT=1 ;<M>
      IF (zERR EQ 80) OR (ZERR EQ 112) THEN BEGIN   ;<P>
         IMULT=1 & IPT=1
         ENDIF
      IF zERR EQ 49 THEN IPT=1   ;<1>
      IF (zERR EQ 78) OR (ZERR EQ 110) THEN BEGIN   ;<N>
         IMULT=1 & zERR =48
         ENDIF
      IF zERR EQ 48 THEN BEGIN   ;<0>
         I1=0
         I2=N_ELEMENTS(W)-1
         GOTO,GOON
         ENDIF
      IF (ZERR EQ 90) OR (ZERR EQ 122) THEN STOP,'BBODY'    ;<Z,Z>
      IF (ZERR EQ 81) OR (ZERR EQ 113) OR (ZERR EQ 26) THEN RETURN   ;<Q,Q,^Z>
      X1=Xcur
      I1=FIX(xindex(w,x1))         ;TABINV,W,X1,I1
      IF IPT EQ 1 THEN BEGIN   ;<1,P>
         I2=0
         Y1=Ycur
         ENDIF ELSE BEGIN   ;SECOND INPUT
         opstat,'  Waiting'
         BLOWUP,-1
         opstat,'  Working'
         X1=Xcur
         I2=FIX(xindex(w,x1))           ;   TABINV,W,X1,I2
   IF I2 LT I1 THEN BEGIN
      T=I2 & I2=I1 & I1=T
      ENDIF
   IF I2 EQ I1 THEN BEGIN
      I2=0
      Y1=F(I1)
      ENDIF                      ;ELSE I2=I2-I1+1  ;# POINTS
   ENDELSE
      end
   endcase
GOON:
z='($," Enter BB temperature (K) ")'
if not keyword_set(temp) then begin
   print,format=z
   READ,TEMP
   endif
C1=3.7412E-5 & C2=1.43879
W1=W/1.E8   ;CM
MPLT:  BB=C1/W1^5/(EXP(C2/W1/TEMP)-1.)
BB=BB/1.E25                           ; NORMALIZE FLUX
FP=F*E
BP=BB*E
IF I2 EQ 0 THEN NORM=Y1/BB(I1) ELSE NORM=TOTAL(FP(I1:I2))/TOTAL(BP(I1:I2))
OPLOT,W,BB*NORM,color=opcol
IK=IK+1
Z='BB:T='+STRTRIM(STRING(TEMP),2)+' N='+STRTRIM(STRING(NORM),2)
print,z
IF IMULT EQ 0 THEN RETURN ELSE BEGIN
   z='($,"Enter T, <0 to end ")'
   print,format=z
   READ,TEMP
   IF TEMP LE 0. THEN RETURN
   GOTO,MPLT
   ENDELSE
END
