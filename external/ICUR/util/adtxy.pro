;*****************************************************************
PRO ADTXY,A0,D0,X,Y,helpme=helpme,deg=deg,prt=prt,dss=dss,wcs=wcs
common grid,s,atn,dtn,ddec,dr,equinox,acen,dcen,atnp,dtnp,xfudge,yfudge,dssastr
common dss,xc,yc,px,py,xc1,yc1,a,b,ac,dc,dssh,astr,dxf,dyf
;
if n_params(0) lt 2 then helpme=1
if n_params(0) lt 4 then prt=1
if n_elements(s) eq 0 then ns=1 else ns=0
if n_elements(atn) eq 0 then nt=1 else nt=0
if n_elements(dtn) eq 0 then nt=1 
if not keyword_set(dss) then begin
   if n_elements(dssastr) eq 0 then dss=0 else dss=dssastr
   endif
if dss eq -1 then dss=0
if not keyword_set(wcs) then wcs=0
if n_elements(astr) eq 0 then dss=0    ;astrometry structure undefined
if n_elements(astr) eq 0 then wcs=0    ;astrometry structure undefined
if ((ns eq 1) or (nt eq 1)) and not keyword_set(dss) then helpme=1
;
if keyword_set(helpme) then begin
   print,' '
   print,'* ADTXY - convert alpha, delta on sky to X,Y'
   print,'*    calling sequence: ADTXY,A,D,X,Y'
   print,'*       A,D: input RA,dec (radians unless /DEG)'
   print,'*       X,Y: output X,Y'
   print,'*'
   print,'*    KEYWORDS:'
   print,'*       DEG: inputs are in degrees'
   print,'*       DSS: use DSS astrometry (GSSSEXTAST must have been run)'
   print,'*'
   if ((ns eq 1) or (nt eq 1)) and not keyword_set(dss) then begin
      print,'*       '
      print,'*   You must have defined the common GRID,s,atn,dtn
      if ns eq 1 then    print,'*       S: plate scale in rad/mm'
      if nt eq 1 then    print,'*       ATN,DTN: plate center in radians'
      endif
   print,'* '
   print,' '
   return
   endif
;
if keyword_set(deg) then begin   ; UNITS ARE RADIANS
   a=a0/!radeg & d=d0/!radeg
   endif else begin
   a=a0 & d=d0
   endelse
if keyword_set(wcs) then begin
   ad2xy,a*!radeg,d*!radeg,astr,x,y   ;,print=prt
   x=x+dxf & y=y+dyf
   if keyword_set(prt) then print,' X,Y=',x,y
   return
   endif
if keyword_set(dss) then begin
   gsssadxy,astr,a*!radeg,d*!radeg,x,y,print=prt
   x=x+dxf & y=y+dyf
   return
   endif
;
NAR=1
SA=SIZE(A) & SD=SIZE(D)
IF (SA(0) EQ 0) AND (SD(0) EQ 0) THEN NAR=0
SPST=COS(D)*SIN(A-ATN)
CPHI=SIN(D)*SIN(DTN)+COS(D)*COS(DTN)*COS(A-ATN)
SPCT=SIN(D)*COS(DTN)-COS(D)*SIN(DTN)*COS(A-ATN)
IF NAR EQ 1 THEN BEGIN  ;ARRAYS
   K=WHERE (CPHI EQ 0.) & if k(0) ne -1 then CPHI(K)=1.
   Y=SPCT/CPHI/S 
   X=SPST/CPHI/S 
   if k(0) ne -1 then begin
      Y(K)=0.
      x(k)=0.
      endif
   ENDIF ELSE BEGIN  ;SCALARS
   X=0. & Y=0.
   IF CPHI EQ 0. THEN goto,ret
   Y=SPCT/CPHI/S 
   X=SPST/CPHI/S
   ENDELSE
X=-X
SPST=0 & CPHI=0 & SPCT=0 
ret:
if keyword_set(prt) then begin
   print,' X,Y=',x,y
   endif
RETURN
END
