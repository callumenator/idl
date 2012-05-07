;*********************************************************************
PRO FUN3,IM,IND,X1,INP,OUTP             ; AXIS UNIT, TITLE CHANGES
COMMON COMXY,X,Y,ZERR
IF IM EQ -1 THEN BEGIN  ;X AXIS
   Z='Angstroms.Frequency.Velocity. Microns.    '
   nz=4
 LW: ZS='Current X axis is '+STRMID(Z,IND*10,10)+'  Hit 0 if OK, other to alter'
   print,zs
   BLOWUP,-1
   IF ZERR EQ 48 THEN GOTO,WRET
   IND=(IND+1) MOD nz
   IF IND EQ 0 THEN begin   ;WAVELENGTH SCALE
      OUTP=INP
      !x.title='Angstroms'     ;'!3'+string(byte("305))
      endif
   IF IND EQ 1 THEN begin   ;Hertz
      OUTP=3.E18/INP
      !x.title='Hertz'
      endif
   IF IND EQ 2 THEN BEGIN   ;VELOCITY SCALE
      WL=X
      S=SIZE(INP)
      S=S(1)-1
      OUTP=299792.*(INP-WL)/WL
      !x.title='Km/s'
      ENDIF
   IF IND EQ 3 THEN begin   ;microns
      OUTP=INP/1.e4
      !x.title='!7!m!6m'
      endif
   GOTO,LW
   WRET: !X.range(*)=0.
   bell
   ZERR=98
   RETURN
   ENDIF
IF IM EQ 1 THEN BEGIN  ; Y AXIS
   Z='Flambda   Fnu       -Magnitude'
   nz=3
 LF: ZS='Current Y axis is '+STRMID(Z,IND*10,10)+' Hit 0 if OK, other to alter'
   print,zs
   BLOWUP,-1
   IF ZERR EQ 48 THEN GOTO,FRET
   IND=(IND+1) MOD nz
   IF IND EQ 0 THEN begin   ;F-lambda
      OUTP=INP
      !y.title=ytit(0)
      endif
   IF IND EQ 1 THEN begin  ;F-nu
      OUTP=INP*X1*X1/3.E18
      !y.title=ytit(3)
      endif
   IF IND EQ 2 THEN begin  ;MINUS MAGNITUDE SCALE
      OUTP=2.5*ALOG10((INP>1.E-18)/3.92E-9)
      !y.title=ytit(4)
      endif
   GOTO,LF
   FRET:  !Y.range(*)=0.
   bell
   ZERR=98
   RETURN
   ENDIF
IF IM EQ 0 THEN BEGIN              ; replace title
   L=BYTARR(60)
   NT=' '
   print,nt
   READ,'Enter new title: ',nt
   L(0)=BYTE(NT)
   INP(100)=L
   OUTP(100)=L
   !p.title='!6'+nt
   RETURN
   ENDIF
RETURN
END
