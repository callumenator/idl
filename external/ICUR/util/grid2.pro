;***************************************************************
PRO GRID2,ACEN,DCEN,DDEC,DUP,DDN,AMIN,AMAX,ISW,size_leg=size_leg,image=image
; PROCEDURE TO PLOT COORDINATE GRID
; S=SCALE (DEGREES/INCH) 
; ACEN,DCEN : PLOT CENTER IN DEGREES
; AT,DT : TANGENT PLANE CENTER IN RADIANS
common grid,s,at,dt
DR=0.0174532925D0
PI=3.1415926536D0
PI2=90.D0*DR
if not keyword_set(size_leg) then sz=1.4 else sz=size_leg
ndig=0
dxplt=!x.crange(1)-!x.crange(0)
xoff=(!x.crange(1)-!x.crange(0))/(!d.x_vsize*(!x.window(1)-!x.window(0)))
;
case 1 of
   strupcase(!d.name) eq 'PS': begin   ;TALARIS laser printer
      xscale=10.32
      yscale=10.71
      end
   else:          begin    ;terminal
      xscale=1.0
      yscale=1.0
      end
   endcase
AC=ACEN*DR  ; CONVERT TO RADIANS
DC=DCEN*DR
ANGLE=DDEC/4.               ;to get 5 dec bands
ia=2
case 1 of
   ANGLE GT 1.   : ANGLE=FIX(ANGLE)
   ANGLE GT 0.75 : ANGLE=1.
   ANGLE GE 0.3  : ANGLE=0.5
   ANGLE GE 0.1  : ANGLE=0.25
   ANGLE GE 0.05 : ANGLE=0.1     ;6 arcmin
   ANGLE GE 0.02 : ANGLE=0.05    ;3 arcmin
   ANGLE GE 0.01 : ANGLE=1./60.  ;1 arcmin
   ANGLE GE 0.005 : ANGLE=0.01   ;36 arcsec
   ANGLE GE 0.002 : ANGLE=1./360.  ;10 arcsec
   else: angle=1./3600.            ;1 arcec
   endcase
case 1 of
   angle ge 1. :begin
      ia=0  & ndig=0
      end
   angle lt 0.1 : begin
      ia=3 & ndig=1
      end
   else: ia=2
   endcase
NDEC=FIX(DDEC/ANGLE)+4
ANG=ANGLE*DR
IPOLE=0   ;CIRCUMPOLAR?
;
IF (DCEN-DDEC/2.) LT -90. THEN IPOLE=-1
IF (DCEN+DDEC/2.) GT 90. THEN IPOLE=1
IF IPOLE NE 0 THEN BEGIN
   DEL=(DCEN+IPOLE*DDEC/2.)-90.
   ENDIF ELSE DEL=0.
;
INDX=INDGEN(NDEC+1)
IF ANGLE GE 1. THEN DCT=FIX(DCEN) ELSE DCT=FIX(DCEN*10.)/10. ;nearest 0.1 deg
;
; lines of constant dec
;
D1=DCT+ANGLE*(INDX-FIX((NDEC+1)/2.))    ;DECLINATION BANDS
FOR I=0,NDEC-1 DO BEGIN
   DLIN=D1(I)
   IF (DLIN LT -90.) OR (DLIN GT 90.) THEN GOTO,NOLIN
   IF (IPOLE NE 0) AND (ABS(90.*IPOLE-DLIN) LE DEL) THEN BEGIN  ;CP
      AMIN=0. & AMAX=360.
      ALPHA=FINDGEN(361)
      ENDIF ELSE BEGIN    ; NORMAL
      IF ISW EQ 0 THEN DRA=AMAX-AMIN ELSE DRA=360.-AMAX-AMIN
      ALPHA=(FINDGEN(600)-50.)*DRA/500.
      IF ISW EQ 0 THEN ALPHA=ALPHA+AMIN ELSE ALPHA=ALPHA+AMAX
      ENDELSE
   ADTXY,ALPHA*DR,DLIN*DR,X,Y
   k=where((y ge !y.crange(0)) and (y le !y.crange(1)) and $
           (x ge !x.crange(0)) and (x le !x.crange(1)))
   if k(0) ne -1 then begin
      !C=-1
      OPLOT,X(k),Y(k),psym=0,linestyle=1
      nm=n_elements(x)-1
      X1=X(nm)
      Y1=Y(nm)
      IF (Y1 GT !y.crange(0)) AND (Y1 LT !y.crange(1)) THEN BEGIN
         z=admss(dlin,ndig,l)
         l=l*sz*!d.x_ch_size*xoff
         if keyword_set(image) then begin
            xyouts,!x.crange(0),y1,z,size=sz
            endif else xyouts,!x.crange(0)-l,y1,z,size=sz     ;-0.07*dxplt
         ENDIF
      endif     ;line in bounds
   NOLIN:
   ENDFOR
;
; DRAW LINES OF CONSTANT RA
;
DELTA=AMAX-AMIN
IF ISW EQ 1 THEN DELTA=360.-DELTA
IF IPOLE NE 0 THEN ANGLE=30. ELSE BEGIN
   ANGLE=DELTA/5.         ;************ was 10
   IF ANGLE GE 1. THEN ANGLE=FIX(ANGLE+0.6) else case 1 of
   ANGLE GT 0.75 : ANGLE=1.
   ANGLE GE 0.3  : ANGLE=0.5
   ANGLE GE 0.1  : ANGLE=0.25
   ANGLE GE 0.05 : ANGLE=0.1     ;6 arcmin
   ANGLE GE 0.02 : ANGLE=0.05    ;3 arcmin
   ANGLE GE 0.01 : ANGLE=1./60.  ;1 arcmin
   ANGLE GE 0.005 : ANGLE=0.01   ;36 arcsec
   ANGLE GE 0.002 : ANGLE=1./360.  ;10 arcsec
   else: angle=1./3600.            ;1 arcec
   endcase
   ENDELSE
IF (ANGLE GE 1.) THEN ACT=FIX(ACEN) ELSE ACT=FIX(ACEN*10.)/10.
if angle ge 1. then ia=0 else ia=2
NRA=6+FIX(DELTA/ANGLE)
nra=nra*2
INDX=INDGEN(NRA)
A1=1.*(ACT+ANGLE*(INDX-FIX((NRA+1)/2.)))
FOR I=0,NRA-1 DO BEGIN
   ALIN=A1(I)   ;DEGREES
   DH=DUP>DDN & IF IPOLE EQ 1 THEN DH=90.
   DL=DUP<DDN & IF IPOLE EQ -1 THEN DL=-90.
   IF IPOLE EQ 0 THEN DEC=(DL+(FINDGEN(140)-20.)*(DH-DL)/100.)
   IF IPOLE NE 0 THEN DEC=(DL+(FINDGEN(120)-20.*IPOLE)*(DH-DL)/100.)
   ADTXY,ALIN*DR,DEC*DR,X,Y
   k=where((y ge !y.crange(0)) and (y le !y.crange(1)) and $
           (x ge !x.crange(0)) and (x le !x.crange(1)))
   if k(0) ne -1 then begin
      !C=-1
      OPLOT,X(k),Y(k),psym=0,linestyle=1
      IF IPOLE EQ -1 THEN INDX=99  ELSE INDX=0
      IF INDX EQ 99 THEN ISIGN=1 ELSE ISIGN=-1
      X1=X(INDX)
      Y1=Y(INDX)
      IF ALIN LT 0. THEN ALIN=ALIN+360.
      if alin gt 360. then alin=alin-360.
      z=ahmss(alin,ndig)
      if (x1 lt !cxmax) and (x1 gt !cxmin) then begin
         if keyword_set(image) then begin
             xyouts,x1,!y.crange(0),z,size=sz,orient=90.
             endif else xyouts,x1,y1,z,size=sz
         endif
      endif
   NORAL:
   ENDFOR
RETURN
END
