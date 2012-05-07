;*************************************************************
PRO CENTRD,WAVE,FLUX,YD,I1,I2,XCEN,FD ;CENTROID
; input I1,I2 in bins
; output xcen in units of wave
XCEN=-1.
IF I2 LT I1 THEN BEGIN
     T=I2
     I2=I1
     I1=T
     ENDIF
i1=(i1>0)                   ;force I1 > 0
np=n_elements(wave)-1
i2=i2<np  ;force i2 < greatest element
IF (I2-I1) LE 1. THEN RETURN
FD=FLUX-YD
IF TOTAL(FD(i1+1:(i2-1)>(I1+1))) LT 0 THEN FD=-FD
Q=WAVE 
P=WAVE*FD
; THE FOLLOWING CODE IS MODIFIED FROM [177,1]INTEG
ILO=LONG(I1+1)
IHI=LONG(I2)
; COMPUTE SUM OF WAVE*FD
xcen=total(p(ilo:ihi))
xcen=xcen+p(ilo-1)*(float(ilo)-i1)+p((ihi+1)<np)*(i2-float(ihi))
; NOW COMPUTE SUM OF FLUX VECTOR
P=FD
xc=total(p(ilo:ihi))
xc=xc+p(ilo-1)*(float(ilo)-i1)+p((ihi+1)<np)*(i2-float(ihi))
XCEN=XCEN/XC       ; CENTROID IS SUM WAVE*FD / SUM OF FD
fd=flux(i1:i2)
RETURN
END
