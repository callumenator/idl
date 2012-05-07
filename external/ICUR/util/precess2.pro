PRO PRECESS2,RA,DEC,EPOCH1,EPOCH2
;+
; NAME:
;    PRECESS
; PURPOSE:
;    Precess coordinates from EPOCH1 to EPOCH2.  For interactive
;    display, one should use ASTRO which calls PRECESS.
; CALLING SEQUENCE:
;    PRECESS,RA,DEC	;Prompt for initial and final epoch
;    PRECESS,RA,DEC,EPOCH1,EPOCH2
; INPUTS:
;    RA - Input right ascension in DEGREES (scalar or vector)
;    DEC - Input declination in DEGREES (scalar or vector)
; OPTIONAL INPUTS:
;    EPOCH1 - Original epoch of coordinates.  If omitted, the program
;	      will query for EPOCH1 and EPOCH2.
;    EPOCH2 - Epoch of precessed coordinates.
; OUTPUTS:
;    RA - Right ascension after precession in DEGREES
;    DEC - Declination after precession in DEGREES
; SIDE EFFECTS:
;    The input RA and DEC are modified to give the values after precession.
;    The result is always double precision, with the same number of dimensions.
; RESTRICTIONS:
;    Accuracy of precession decreases for declination values near 90 
;    degrees.  PRECESS should not be used more than 2.5 centures from
;    1900.    
; EXAMPLE:
;    Precess the 1950 coordinates of Eps Ind (RA = 21h 59m,33.053s,
;    DEC = (-56d, 59', 33.053") to equinox 1950.
;    RA = TEN(21,59,33.053)*15.            ;Convert to decimal degrees
;    DEC= TEN(-56,59,33.053)
;    PRECESS,RA,DEC,1950.,1975.            ;Perform precession
;    PRINT,ADSTRING(RA,DEC)                ;Print in pretty format
; PROCEDURE:
;    Algorithm from Computational Spherical Astronomy by Taff (1983), 
;    p. 24. 
; REVISION HISTORY
;    Written, Wayne Landsman, STI Corporation  August 1986
;    Accept single element input vectors December 1988
;    Correct negative output RA values   February 1989
;-    
NPAR = N_PARAMS(0)
IF (NPAR LT 2) THEN BEGIN
   PRINT,STRING(7B),'CALLING SEQUENCE: precess,ra,dec,[epoch1,epoch2]
   PRINT,'NOTE: RA and DEC must be supplied in DEGREES'
   RETURN
ENDIF ELSE IF (NPAR LT 4) THEN $
   READ,'Enter original and new equinox of coordinates',EPOCH1,EPOCH2
CDR = 0.17453292519943D-1
RA_RAD = RA*CDR		;Convert to double precision if not already
DEC_RAD = DEC*CDR
;
A = COS(DEC_RAD)
NPTS = MIN([N_ELEMENTS(RA),N_ELEMENTS(DEC)])
CASE NPTS OF	         ;Is RA a vector or scalar?
0:    BEGIN
      PRINT,STRING(7B),'PRECESS: ERROR - RA and DEC must be vectors or scalars'
      RETURN
      END
1:    X = [A*COS(RA_RAD), A*SIN(RA_RAD), SIN(DEC_RAD)] ;input direction cosines
ELSE: BEGIN	
      X = DBLARR(NPTS,3)
      X(0,0) = A*COS(RA_RAD)
      X(0,1) = A*SIN(RA_RAD)
      X(0,2) = SIN(DEC_RAD)
      X = TRANSPOSE(X)
      END
ENDCASE
;
CSR = CDR/3600.D0
T = 0.001D0*(EPOCH2-EPOCH1)
ST = 0.001D0*(EPOCH1-1900.D0)
;                                Compute 3 rotation angles
A = CSR*T*(23042.53D0 + ST*(139.75D0 +0.06D0*ST) $
    +T*(30.23D0 - 0.27D0*ST+18.0D0*T))
B = CSR*T*T*(79.27D0 + 0.66D0*ST + 0.32D0*T) + A
C = CSR*T*(20046.85D0 - ST*(85.33D0 + 0.37D0*ST) $
    +T*(-42.67D0 - 0.37D0*ST -41.8D0*T))
;
SINA = SIN(A) &  SINB = SIN(B)  & SINC = SIN(C)
COSA = COS(A) &  COSB = COS(B)  & COSC = COS(C)
R = DBLARR(3,3)
R(0,0) = [ COSA*COSB*COSC-SINA*SINB, SINA*COSB+COSA*SINB*COSC,  COSA*SINC]
R(0,1) = [-COSA*SINB-SINA*COSB*COSC, COSA*COSB-SINA*SINB*COSC, -SINA*SINC]
R(0,2) = [-COSB*SINC, -SINB*SINC, COSC]
;
X2 = R#X	;rotate to get output direction cosines
IF NPTS EQ 1 THEN BEGIN	         ;scalar
	RA_RAD = ATAN(X2(1),X2(0))
	DEC_RAD = ASIN(X2(2))
ENDIF ELSE BEGIN	         ;vector
	RA_RAD = DBLARR(NPTS) + ATAN(X2(1,*),X2(0,*))
	DEC_RAD = DBLARR(NPTS) + ASIN(X2(2,*))
ENDELSE
RA = RA*0.D + RA_RAD/CDR
RA = RA + (RA LT 0.)*360.            ;RA between 0 and 360 degrees
DEC = DEC*0.D +DEC_RAD/CDR
RETURN
END
                       
