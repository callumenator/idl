;*********************** Copyright 1996, Dan Weimer/MRC ***********************
;
; IDL routines to calculate the electric potentials from the Weimer '96 model of
; the polar cap ionospheric electric potentials.
;
; To use, first call procedure ReadCoef once.
; Next, call SetModel with the specified input parameters.
; The function EpotVal(gLAT,gMLT) can then be used repeatively to get the
; electric potential at the desired location in geomagnetic coordinates.
;
; This code is protected by copyright and is
; distributed for research or educational use only.
; Commerical use without written permission from Dan Weimer/MRC is prohibited.
;
;*********************** Copyright 1996, Dan Weimer/MRC ***********************
FUNCTION PLGNDR,l,m,x
; Compute the associated Legendre polynomial P_l^m(x)
; Uses the algorithm described in Chapter 6 of "Numerical Recipes"
; Adopted to IDL return arrays of values with same dimensions as input array.
IF (m LT 0 OR m GT l ) THEN BEGIN
  Print,'Bad arguments to PLGNDR'
  RETURN,0.
ENDIF
S=SIZE(x)
IF S(0) EQ 1 THEN Pmm=REPLICATE(1.,S(1)) ELSE Pmm=REPLICATE(1.,S(1),S(2))
IF m GT 0 THEN BEGIN
    sx2=SQRT( (1.-x)*(1.+x) )
    fact=1.
    FOR i=1,m DO BEGIN
      Pmm=-Pmm*fact*sx2
      fact=fact+2.
    ENDFOR
ENDIF

IF l EQ m THEN RETURN,Pmm

pmmp1=x*(2.*m +1.) * Pmm
IF l EQ m+1 THEN RETURN,pmmp1 $
ELSE FOR ll=m+2,l DO BEGIN
    Pll=( x*(2*ll-1)*pmmp1 -(ll+m-1)*Pmm ) / (ll-m)
    Pmm=pmmp1
    pmmp1=Pll
      ENDFOR

RETURN,Pll
END
;*********************** Copyright 1996, Dan Weimer/MRC ***********************
FUNCTION EpotVal,glat,gmlt
;
; Return the value of the electric potential in kV at
; corrected geomagnetic coordinates gLAT (degrees) and gMLT (hours).
;
; Must first call ReadCoef and SetModel to set up the model coeficients for
; the desired values of Bt, IMF clock angle, Dipole tilt angle, and SW Vel.
;
COMMON SetCoef,ML,MM,Coef
r=90.-glat
theta=r*!PI/45.
phi=gmlt*!PI/12.
n=N_ELEMENTS(theta)
DC=Coef(0,0,0)
Z=REPLICATE(DC,n)
ct=COS(theta)
FOR l=1,ML DO BEGIN
   Plm=Plgndr(l,0,ct)
   Z=Z + Coef(0,l,0)*Plm
   limit=MIN([l,MM])
   FOR m=1,limit DO BEGIN
     phim=phi*m
     Plm=Plgndr(l,m,ct)
     Z=Z + Coef(0,l,m)*Plm*COS(phim) + Coef(1,l,m)*Plm*SIN(phim)
   ENDFOR
ENDFOR
RETURN,Z
END
;*********************** Copyright 1996, Dan Weimer/MRC ***********************
FUNCTION FSVal,omega,MaxN,fsc
Y=FLTARR(N_ELEMENTS(omega))
FOR n=0,MaxN DO BEGIN
  theta=omega*n
  Y=Y + fsc(0,n)*COS(theta) + fsc(1,n)*SIN(theta)
ENDFOR
RETURN,Y
END
;*********************** Copyright 1996, Dan Weimer/MRC ***********************
PRO ReadCoef

COMMON AllCoefs,MaxL,MaxM,MaxN,Cn

file='C:\Cal\IDLSource\Code\potentials\w96.dat'
OPENR,udat,file,/GET_LUN
skip=''
READF,udat,skip
MaxL=0
MaxM=0
MaxN=0
READF,udat,MaxL,MaxM,MaxN
Cn=FLTARR(4,2,MaxN+1,2,MaxL+1,MaxM+1)
C=FLTARR(4)
FOR l=0,MaxL DO BEGIN
  mlimit=MIN([l,MaxM])
  FOR m=0,mlimit DO BEGIN
    klimit=MIN([m,1])
    FOR k=0,klimit DO BEGIN
      READF,udat,ll,mm,kk,FORMAT='(3I2)'
      IF ll NE l OR mm NE m OR kk NE k THEN MESSAGE,'Data File Format Error'
      FOR n=0,MaxN DO BEGIN
        ilimit=MIN([n,1])
    FOR i=0,ilimit DO BEGIN
      READF,udat,nn,ii,C,FORMAT='(2I2,4E15.6)'
          IF nn NE n OR ii NE i THEN MESSAGE,'Data File Format Error'
      Cn(*,i,n,k,l,m)=C
        ENDFOR
      ENDFOR
    ENDFOR
  ENDFOR
ENDFOR
Free_Lun,udat

RETURN
END
;*********************** Copyright 1996, Dan Weimer/MRC ***********************
PRO SetModel,angle,Bt,Tilt,SWVel
;
; Calculate the complete set of spherical harmonic coeficients,
; given an aribitrary IMF angle (degrees from northward toward +Y),
; magnitude Bt (nT), dipole tilt angle (degrees),
; and solar wind velocity (km/sec).
; Returns the Coef in the common block SetCoef.
;
COMMON AllCoefs,MaxL,MaxM,MaxN,Cn
COMMON SetCoef,ML,MM,Coef

X=FLTARR(4)
X(0)=1.
X(1)=Bt
X(2)=SIN(Tilt*!DTOR)
X(3)=SWVel

Coef=FLTARR(2,MaxL+1,MaxM+1)
omega=angle*!PI/180.
FOR l=0,MaxL DO BEGIN
  mlimit=MIN([l,MaxM])
  FOR m=0,mlimit DO BEGIN
    klimit=MIN([m,1])
    FOR k=0,klimit DO BEGIN
; Retrieve the regression coeficients and evaluate the function
; as a function of Bt,Tilt,and SWVel to get each Fourier coeficient.
      fsc=FLTARR(2,MaxN+1)
      FOR n=0,MaxN DO BEGIN
        ilimit=MIN([n,1])
    FOR i=0,ilimit DO BEGIN
      C=Cn(*,i,n,k,l,m)
      fsc(i,n)=TOTAL(C*X)
    ENDFOR
      ENDFOR
;Next evaluate the Fourier series as a function of angle.
      Coef(k,l,m)=FSVal(omega,MaxN,fsc)
    ENDFOR
  ENDFOR
ENDFOR
ML=MaxL
MM=MaxM
RETURN
END
