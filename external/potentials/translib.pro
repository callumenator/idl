; COORDINATE TRANSFORMATION UTILITIES
; IDL version translated from FORTRAN
;****************************************************************************
FUNCTION ADJUST,ANGLE
;	ADJUST AN ANGLE IN DEGREES TO BE IN RANGE OF 0 TO 360.
	result=angle MOD 360.
	less=WHERE(result LT 0.,count)
	IF count GT 0 THEN result(less)=result(less)+360.
	RETURN,result
END
;******************************************************************************
FUNCTION JULDAY,MM,ID,IYYY
      IGREG=15L+31L*(10L+12L*1582L)
      IF IYYY EQ 0 THEN MESSAGE, 'There is no Year Zero.'
      IF IYYY LT 0 THEN IYYY=IYYY+1
      IF MM GT 2 THEN BEGIN
        JY=IYYY
        JM=MM+1
      ENDIF ELSE BEGIN
        JY=IYYY-1
        JM=MM+13
      ENDELSE
      JDAY=LONG(365.25*JY)+LONG(30.6001*JM)+ID+1720995L
      IF ID+31L*(MM+12L*LONG(IYYY)) GE IGREG THEN BEGIN
        JA=LONG(0.01*JY)
        JDAY=JDAY+2-JA+LONG(0.25*JA)
      ENDIF
      RETURN,JDAY
END
;*****************************************************************************
FUNCTION SIND,angle
RETURN,SIN(angle*!DTOR)
END
;*****************************************************************************
FUNCTION COSD,angle
RETURN,COS(angle*!DTOR)
END
;*****************************************************************************
PRO TRANS,YEAR,MONTH,DAY,HOUR,IDBUG=idbug
;
;      THIS PROCEDURE DERIVES THE ROTATION MATRICES AM(I,J,K) FOR 11
;      TRANSFORMATIONS, IDENTIFIED BY K.
;          K=1 TRANSFORMS GSE to GEO
;          K=2     "      GEO to MAG
;          K=3     "      GSE to MAG
;          K=4     "      GSE to GSM
;          K=5     "      GEO to GSM
;          K=6     "      GSM to MAG
;          K=7     "      GSE to GEI
;          K=8     "      GEI to GEO
;          K=9     "      GSM to SM
;	   K=10    "      GEO to SM
;	   K=11    "      MAG to SM
;
;      IF IDBUG IS NOT 0, THEN OUTPUTS DIAGNOSTIC INFORMATION TO
;      FILE debug.dat
;
GSEGEO= 1 & GEOGSE=-1 & GEOMAG= 2 & MAGGEO=-2
GSEMAG= 3 & MAGGSE=-3 & GSEGSM= 4 & GSMGSE=-4
GEOGSM= 5 & GSMGEO=-5 & GSMMAG= 6 & MAGGSM=-6
GSEGEI= 7 & GEIGSE=-7 & GEIGEO= 8 & GEOGEI=-8
GSMSM = 9 & SMGSM =-9 & GEOSM =10 & SMGEO=-10
MAGSM =11 & SMMAG =-11
;
;      The formal names of the coordinate systems are:
;	GSE - Geocentric Solar Ecliptic
;	GEO - Geographic
;	MAG - Geomagnetic
;	GSM - Geocentric Solar Magnetospheric
;	SM  - Solar Magnetic
;
;      THE ARRAY CX(I) ENCODES VARIOUS ANGLES, STORED IN DEGREES
;       ST(I) AND CT(I) ARE SINES & COSINES.
;
;       Program author:  D. R. Weimer
;
;       Some of this code has been copied from subroutines which had been
;       obtained from D. Stern, NASA/GSFC.  Other formulas are from "Space
;       Physics Coordinate Transformations: A User Guide" by M. Hapgood (1991).
;
;       The formulas for the calculation of Greenwich mean sidereal time (GMST)
;       and the sun's location are from "Almanac for Computers 1990",
;       U.S. Naval Observatory.
;
	COMMON TRANSDAT,CX,ST,CT,AM
	CX=FLTARR(9)
	AM=FLTARR(3,3,12)

temp=[ $
[ 1945. ,  -68.531 ,   11.534 ] , $
[ 1950. ,  -68.847 ,   11.534 ] , $
[ 1955. ,  -69.164 ,   11.540 ] , $
[ 1960. ,  -69.467 ,   11.490 ] , $
[ 1965. ,  -69.854 ,   11.465 ] , $
[ 1970. ,  -70.177 ,   11.409 ] , $
[ 1975. ,  -70.470 ,   11.313 ] , $
[ 1980. ,  -70.759 ,   11.194 ] , $
[ 1985. ,  -70.896 ,   11.026 ] , $
[ 1990. ,  -71.127 ,   10.862 ] , $
[ 1995. ,  -71.407 ,   10.704 ] , $
[ 2000. ,  -71.744 ,   10.535 ] ]
times=REFORM(temp(0,*))
ph0s=REFORM(temp(1,*))
th0s=REFORM(temp(2,*))

	IF YEAR LT 1900 THEN IYR=1900+YEAR ELSE IYR=YEAR
	epoch=[ FLOAT(IYR)+ (month-1)/12.+(day-1)/365. ]
	TH0=INTERPOL(th0s,times,epoch)
	PH0=INTERPOL(ph0s,times,epoch)

	UT=HOUR
	JD=JULDAY(MONTH,DAY,IYR)
	MJD=JD-2400001L
	T0=(DOUBLE(MJD)-51544.5D0)/36525.0D0
	GMSTD=100.4606184D0 + 36000.770*T0 + 3.87933D-4*T0*T0 + 15.0410686D0*UT
	GMSTD=ADJUST(GMSTD)
	GMSTH=GMSTD*24./360.
	ECLIP=23.439D0 - 0.013*T0
	MA=357.528D0 + 35999.050*T0 + 0.041066678D0*UT
	MA=ADJUST(MA)
	LAMD=280.460D0 + 36000.772*T0 + 0.041068642D0*UT
	LAMD=ADJUST(LAMD)
	SUNLON=LAMD + (1.915-0.0048*T0)*SIND(MA) + 0.020*SIND(2.*MA)
	SUNLON=ADJUST(SUNLON)
	IF KEYWORD_SET(idbug) THEN BEGIN
	  PRINT, YEAR,MONTH,DAY,HOUR
	  PRINT, 'MJD=',MJD
	  PRINT, 'T0=',T0
	  PRINT, 'GMSTH=',GMSTH
	  PRINT, 'ECLIPTIC OBLIQUITY=',ECLIP
	  PRINT, 'MEAN ANOMALY=',MA
	  PRINT, 'MEAN LONGITUDE=',LAMD
	  PRINT, 'TRUE LONGITUDE=',SUNLON
	  PRINT, 'EPOCH=',EPOCH
	  PRINT, 'PH0=',PH0
	  PRINT, 'TH0=',TH0
	ENDIF

	CX(0)= GMSTD
	CX(1) = ECLIP
	CX(2) = SUNLON
	CX(3) = TH0
	CX(4) = PH0
; Derived later:
;       CX(5) = Dipole tilt angle
;       CX(6) = Angle between sun and magnetic pole
;       CX(7) = Subsolar point latitude
;       CX(8) = Subsolar point longitude

	ST=SIND(CX)
	CT=COSD(CX)

      AM(0,0,GSEGEI) = CT(2)
      AM(0,1,GSEGEI) = -ST(2)
      AM(0,2,GSEGEI) = 0.
      AM(1,0,GSEGEI) = ST(2)*CT(1)
      AM(1,1,GSEGEI) = CT(2)*CT(1)
      AM(1,2,GSEGEI) = -ST(1)
      AM(2,0,GSEGEI) = ST(2)*ST(1)
      AM(2,1,GSEGEI) = CT(2)*ST(1)
      AM(2,2,GSEGEI) = CT(1)

      AM(0,0,GEIGEO) = CT(0)
      AM(0,1,GEIGEO) = ST(0)
      AM(0,2,GEIGEO) = 0.
      AM(1,0,GEIGEO) = -ST(0)
      AM(1,1,GEIGEO) = CT(0)
      AM(1,2,GEIGEO) = 0.
      AM(2,0,GEIGEO) = 0.
      AM(2,1,GEIGEO) = 0.
      AM(2,2,GEIGEO) = 1.

      AM(0,0,GSEGEO)= AM(*,*,GEIGEO) # AM(*,*,GSEGEI)

      AM(0,0,GEOMAG) = CT(3)*CT(4)
      AM(0,1,GEOMAG) = CT(3)*ST(4)
      AM(0,2,GEOMAG) =-ST(3)
      AM(1,0,GEOMAG) =-ST(4)
      AM(1,1,GEOMAG) = CT(4)
      AM(1,2,GEOMAG) = 0.
      AM(2,0,GEOMAG) = ST(3)*CT(4)
      AM(2,1,GEOMAG) = ST(3)*ST(4)
      AM(2,2,GEOMAG) = CT(3)

      AM(0,0,GSEMAG)= AM(*,*,GEOMAG) # AM(*,*,GSEGEO)

      B21 = AM(2,1,GSEMAG)
      B22 = AM(2,2,GSEMAG)
      B2  = SQRT(B21*B21+B22*B22)
      IF B22 LE 0. THEN B2 = -B2

      AM(1,1,GSEGSM) = B22/B2
      AM(2,2,GSEGSM) = AM(1,1,GSEGSM)
      AM(2,1,GSEGSM) = B21/B2
      AM(1,2,GSEGSM) =-AM(2,1,GSEGSM)
      AM(0,0,GSEGSM) = 1.
      AM(0,1,GSEGSM) = 0.
      AM(0,2,GSEGSM) = 0.
      AM(1,0,GSEGSM) = 0.
      AM(2,0,GSEGSM) = 0.

      AM(0,0,GEOGSM)= AM(*,*,GSEGSM) # TRANSPOSE(AM(*,*,GSEGEO))

      AM(0,0,GSMMAG)= AM(*,*,GEOMAG) # TRANSPOSE(AM(*,*,GEOGSM))

	ST(5) = AM(2,0,GSEMAG)
	CT(5) = SQRT(1.-ST(5)*ST(5))
	CX(5) = ASIN(ST(5))*!RADEG

        AM(0,0,GSMSM) = CT(5)
        AM(0,1,GSMSM) = 0.
        AM(0,2,GSMSM) = -ST(5)
        AM(1,0,GSMSM) = 0.
        AM(1,1,GSMSM) = 1.
        AM(1,2,GSMSM) = 0.
        AM(2,0,GSMSM) = ST(5)
        AM(2,1,GSMSM) = 0.
        AM(2,2,GSMSM) = CT(5)

      AM(0,0,GEOSM)= AM(*,*,GSMSM) # AM(*,*,GEOGSM)

      AM(0,0,MAGSM)= AM(*,*,GSMSM) # TRANSPOSE(AM(*,*,GSMMAG))

      CX(6)=ATAN( AM(1,0,11) , AM(0,0,11) ) *!RADEG
      CX(7)=ASIN( AM(2,0,1) ) *!RADEG
      CX(8)=ATAN( AM(1,0,1) , AM(0,0,1) ) *!RADEG
      ST(6)=SIND(CX(6:8))
      CT(6)=COSD(CX(6:8))

      IF KEYWORD_SET(idbug) THEN BEGIN
	  PRINT,'Dipole tilt angle=', CX(5)
	  PRINT,'Angle between sun and magnetic pole=',CX(6)
	  PRINT,'Subsolar point latitude=',CX(7)
	  PRINT,'Subsolar point longitude=',CX(8)
        form1001='( " ROTATION MATRIX ",I2)'
        form1002='(3F9.5)'
        FOR K=1,11 DO BEGIN
         PRINT,K,FORMAT=form1001
         FOR I=0,2 DO $
           PRINT,REFORM( AM(I,*,K) ),FORMAT=form1002
        ENDFOR
      ENDIF

      RETURN
END
;*****************************************************************************
FUNCTION ROTATEV,A,I
;
;     THIS FUNCTION APPLIES TO THE VECTOR A(3) THE ITH ROTATION
;     MATRIX AM(N,M,I) GENERATED BY SUBROUTINE TRANS
;     AND OUTPUTS THE CONVERTED VECTOR B(3), WITH NO CHANGE TO A.
;     IF I IS NEGATIVE, THEN THE INVERSE ROTATION IS APPLIED
;
      COMMON TRANSDAT,CX,ST,CT,AM

      IF I EQ 0 THEN BEGIN
        B=A
        RETURN,B
      ENDIF

      IF ABS(I) GT 11 THEN BEGIN
        PRINT,'ROTATEV CALLED WITH UNDEFINED TRANSFORMATION'
        B=FLTARR(3)
        RETURN,B
      ENDIF

      IF I GT 0 THEN M=AM(*,*,I) ELSE M=TRANSPOSE(AM(*,*,-I))
      B=M#A
      RETURN,B
END
;**********************************************************************
PRO ROTATE,X,Y,Z,I
;
;     THIS SUBROUTINE APPLIES TO THE VECTOR (X,Y,Z) THE ITH ROTATION
;     MATRIX AM(N,M,I) GENERATED BY SUBROUTINE TRANS
;     IF I IS NEGATIVE, THEN THE INVERSE ROTATION IS APPLIED
;
      A=ROTATEV( [X,Y,Z] ,I)
      X=A(0)
      Y=A(1)
      Z=A(2)

      RETURN
END
;*****************************************************************************
PRO FROMCART,R,LAT,LONG,POS
; CONVERT CARTESIAN COORDINATES POS(3)
; TO SPHERICAL COORDINATES R, LATITUDE, AND LONGITUDE (DEGREES)
	P2=POS^2
	R=SQRT(TOTAL(P2))
	IF R EQ 0. THEN BEGIN
	  LAT=0.
	  LONG=0.
	ENDIF ELSE BEGIN
	  LAT=!RADEG*ASIN(POS(2)/R)
	  LONG=!RADEG*ATAN(POS(1),POS(0))
	ENDELSE
	RETURN
END
;******************************************************************************
FUNCTION TOCART,R,LAT,LONG
; CONVERT SPHERICAL COORDINATES R, LATITUDE, AND LONGITUDE (DEGREES)
; TO CARTESIAN COORDINATES, RETURNED AS A VECTOR OF SIZE 3
        STC = SIND(LAT)
        CTC = COSD(LAT)
        SF = SIND(LONG)
        CF = COSD(LONG)
        POS = [ R*CTC*CF ,  R*CTC*SF , R*STC ]
 	RETURN,POS
END
;*****************************************************************************
FUNCTION MLT,MagLong
;given magnetic longitude in degrees, return Magnetic Local Time
;assuming that TRANS has been called with the date & time to calculate
;the rotation matrices.
COMMON TRANSDAT,CX,ST,CT,AM
RotAngle=CX(6)
hour=ADJUST(Maglong+RotAngle+180.)/15.
RETURN,hour
END
;*****************************************************************************
FUNCTION MagLong,MLT
;return magnetic longitude in degrees, given Magnetic Local Time
;assuming that TRANS has been called with the date & time to calculate
;the rotation matrices.
COMMON TRANSDAT,CX,ST,CT,AM
RotAngle=CX(6)
angle=MLT*15.-RotAngle-180.
angle=ADJUST(angle)
RETURN,angle
END
;*****************************************************************************
PRO SunLoc,SunLat,SunLong
; Return latitude and longitude of sub-solar point.
; Assumes that TRANS has previously been called with the
; date & time to calculate the rotation matrices.
COMMON TRANSDAT,CX,ST,CT,AM
SunLong=CX(8)
SunLat=CX(7)
RETURN
END
;*****************************************************************************
;COMMON TRANSDAT,CX,ST,CT,AM
;GSEGEO= 1 & GEOGSE=-1 & GEOMAG= 2 & MAGGEO=-2
;GSEMAG= 3 & MAGGSE=-3 & GSEGSM= 4 & GSMGSE=-4
;GEOGSM= 5 & GSMGEO=-5 & GSMMAG= 6 & MAGGSM=-6
;GSEGEI= 7 & GEIGSE=-7 & GEIGEO= 8 & GEOGEI=-8
;GSMSM = 9 & SMGSM =-9 & GEOSM =10 & SMGEO=-10
;MAGSM =11 & SMMAG =-11
;END
