;*********************************************************************8
PRO FTOT,IM,WAVE,FLUX,output,nonorm=nonorm,eps=eps      ; SUM TOTAL FLUX
; IM=0 FOR TOTAL FLUX
; IM=1 FOR MEAN
; IM=2 FOR CENTROID, CURSOR POSITION
; IM=3,4 FOR LINEAR INTERPOLATION
COMMON COM1,H,IK,IFT,NSM,C,ndat,ifsm,kblo,h2
COMMON COMXY,XCUR,YCUR,ZERR,resetscale,lu3
common icurunits,xu,yu,title,c1,c2,c3
;
if n_elements(ik) eq 0 then ik=0
IF IM EQ 2 THEN GOTO,CENT
XXL=Xcur
XL=Xcur
i1=xindex(wave,xl)              ;TABINV,WAVE,XL,I1
F=Ycur
F1=F
TKP,5,XL,F
opstat,'  Waiting'
ZERR0=ZERR
BLOWUP,-1
opstat,'  Working'
ZERR=ZERR0
XD=Xcur
i2=xindex(wave,xd)                  ;TABINV,WAVE,XD,I2
I1=FIX(I1+0.5) 
I2=FIX(I2+0.5)
F=Ycur
TKP,5,XD,F
IF I2 LT I1 THEN BEGIN
     T=I1
     I1=I2
     I2=T
     T=XD
     XD=XL
     XL=T
     ENDIF
IF IM GE 3 THEN GOTO,INTERP
NP=I2-I1+1
ik=ik+1
IF IM EQ 0 THEN BEGIN
   yp=!D.Y_SIZE*!Y.WINDOW(1)-(!D.Y_CH_SIZE+1)*FLOAT(IK)
   xp=!D.X_SIZE*!X.WINDOW(1)-!D.X_CH_SIZE*33.
   TF=TOTAL(FLUX(I1:I2))
   if not keyword_set(nonorm) then tf=tf*(XD-XL)/NP
   Z='F='+STRTRIM(STRING(TF,'(G11.3)'),2)+' W='+STRTRIM(STRING(XL,'(F9.3)'),2)
   Z=Z+'-'+STRTRIM(STRING(XD,'(F9.3)'),2)
   XYOUTs,xp,yp,Z,/DEVICE
   PRINT,Z
   if n_elements(lu3) gt 0 then begin
      PRINTF,lu3,' 1','    ;FTOT: Flux,Wavelengths'
      PRINTF,lu3,TF,XL,XD
      endif
   output=tf
   ENDIF
IF IM EQ 1 THEN BEGIN
   TF=TOTAL(FLUX(I1:I2))/FLOAT(np)
   YCUR=TF
   XT=[WAVE(I1),WAVE(I2)]
   OPLOT,XT,[TF,TF],psym=0,COLOR=15
   TK=(FLUX-TF)*(FLUX-TF)
   TK=TOTAL(TK(I1:I2))/FLOAT(NP-1)
   RMS=SQRT(TK)
   SN=ABS(TF/RMS)
   Z='M,S/N:'+STRTRIM(STRING(TF,'(G11.3)'),2)+' '+STRTRIM(STRING(SN,'(F9.3)'),2)
   PRINT,Z
   yp=!D.Y_SIZE*!Y.WINDOW(1)-(!D.Y_CH_SIZE+1)*FLOAT(IK)
   xp=!D.X_SIZE*!X.WINDOW(1)-!D.X_CH_SIZE*22.
   xyouts,xp,yp,z,/DEVICE
   output=tf
   if n_elements(lu3) gt 0 then begin
      PRINTF,lu3,' 2','  FTOT: Mean,RMS,S/N,Range'
      printf,lu3,TF,RMS,SN,XL,XD
      endif
   ENDIF
RETURN
;
CENT:  ; COMPUTE LINE CENTROID
IK=IK+1
S=SIZE(WAVE)
WL=Xcur
FL=Ycur
IF S(0) EQ 0 THEN GOTO,WAVEL  ;MEASURE CURSOR POSITION
i1=xindex(wave,wl)                      ;TABINV,WAVE,WL,I1
opstat,'  Waiting'
ZERR0=ZERR
BLOWUP,-1
opstat,'  Working'
ZERR=ZERR0
WL=Xcur
i2=xindex(wave,wl)                        ;TABINV,WAVE,WL,I2
CENTRD,WAVE,FLUX,FL,I1,I2,XCEN,FD
output=xcen
if n_elements(fd) eq 0 then return   ;i1=i2
y1=max(fd)<!y.crange(1)
y2=MIN(FD)>!y.crange(0)
!C=-1
oplot,[xcen,xcen],[y1,y2],color=12,linestyle=1
Z='CNTRD: '+STRTRIM(STRING(XCEN,'(F9.3)'),2)
yp=!D.Y_SIZE*!Y.WINDOW(1)-(!D.Y_CH_SIZE+1)*FLOAT(IK)
xp=!D.X_SIZE*!X.WINDOW(1)-!D.X_CH_SIZE*15.
xyouts,xp,yp,z,/DEVICE
PRINT,Z
if n_elements(lu3) gt 0 then begin
   PRINTF,lu3,' 3','  Centroid' & PRINTF,lu3,XCEN
   endif
RETURN
;
WAVEL:   ; PRINT OUT CURSOR POSITION
Z=STRTRIM(STRING(WL,'(F9.3)'),2)+' '+STRTRIM(STRING(FL,'(G11.3)'),2)
yp=!D.Y_SIZE*!Y.WINDOW(1)-(!D.Y_CH_SIZE+1)*FLOAT(IK)
xp=!D.X_SIZE*!X.WINDOW(1)-!D.X_CH_SIZE*20.
xyouts,xp,yp,z,/DEVICE
output=wl
if n_elements(lu3) gt 0 then begin
   printf,lu3,' 4','  Wavelength,Flux' & PRINTF,lu3,WL,FL
   endif
TKP,1,WL,FL
RETURN
;
INTERP:    ; PERFORM LINEAR INTERPOLATION BETWEEN I1,I2
NB=I2-I1
IF NB LT 1 THEN RETURN
if n_elements(lu3) gt 0 then begin
   printf,lu3,'-2','    linear interpolation between points ',I1,' and',I2
   printf,lu3,I1,I2
   endif
IF IM EQ 3 THEN BEGIN ; USE VALUES OF SURROUNDING POINTS
   SL=(FLUX(I2)-FLUX(I1))/FLOAT(NB)
   FOR I=I1+1,I2-1 DO FLUX(I)=FLUX(I1)+SL*FLOAT(I-I1)
   if n_elements(eps) gt i2 then eps(i1+1:(i2-1)>(i1+1))=-1001
   if n_elements(lu3) gt 0 then begin
      printf,lu3,'-2','    fluxes interpolated from adjacent points'
      printf,lu3,i1,i2
      endif
   ENDIF
IF IM EQ 4 THEN BEGIN ; USE CURSOR Y VALUE
; REPLACE FLUX(I2) WITH F, FLUX(I1) WITH F1
   SL=(F-F1)/FLOAT(NB)
   FOR I=I1+1,I2-1 DO FLUX(I)=F1+SL*FLOAT(I-I1)
   if n_elements(eps) gt i2 then eps(i1:i2)=-1001
   if n_elements(lu3) gt 0 then begin
      printf,lu3,'-2','    fluxes interpolated from cursor positions'
      printf,lu3,i1,i2
      endif
   ENDIF
RETURN
END
