;*****************************************************************
PRO XYTAD,A,D,X0,Y0,deg=deg,rad=rad, $
      helpme=helpme,prt=prt,dss=dss,wcs=wcs,stp=stp
common grid,s,atn,dtn,ddec,dr,equinox,acen,dcen,atnp,dtnp,xfudge,yfudge,dssastr
common dss,xc,yc,px,py,xc1,yc1,ax,bx,ac,dc,dssh,astr,dxf,dyf
common wcs,wcs_flag
if n_params(0) lt 2 then helpme=1
if n_params() eq 2 then begin
   x0=a & y0=d
   if not keyword_set(prt) then prt=1
   endif
if not keyword_set(dss) then begin
   if (n_elements(dssastr) eq 0) then dss=0 else dss=dssastr
   endif
if not keyword_set(prt) then prt=0
if prt eq -1 then deg=1
if keyword_set(wcs) then wcs_flag=1
if n_elements(astr) eq 0 then dss=0
if (n_elements(s) eq 0) and not keyword_set(dss) and not keyword_set(wcs_flag) $
   then helpme=1
if (n_elements(x0) eq 0) or (n_elements(y0) eq 0) then helpme=1
if keyword_set(helpme) then begin
   print,' '
   print,'* XYTAD - convert from X,Y in tangent plane to RA,DEC' 
   print,'*    calling sequence: XYTAD,RA,DEC,X,Y'
   print,'*        RA,DEC: output coordinates'
   print,'*        X,Y:    input positions'
   print,'*'
   print,'*    KEYWORDS:'
   print,'*       RAD: return results in radians, (default)'
   print,'*       DEG: return results in degrees, default is radians'
   print,'*       DSS: use DSS astrometry structure'
   print,'*       PRT: print results to screen, -1 for HMS,DMS'
   if (n_elements(s) eq 0) and not keyword_set(dss) then begin
      print,'*'
      print,'*  ****** You must define the tangent point center (atn,dtn) '
      print,'*         and scale (s; rad/mm) first'
      print,'*         These are in COMMON GRID,s,atn,dtn,ddec,dr'
      endif
   print,' '
   if keyword_set(stp) then stop,'XYTAD>>>'
   return
   endif
;
x=x0 & y=y0
if keyword_set(wcs_flag) then begin
;   x=x-dxf & y=y-dyf 
   xy2ad,x,y,astr,a,d   ;,print=prt      ;output is in degrees
   if not keyword_set(deg) then begin
      a=a/!radeg & d=d/!radeg
      endif
   endif
;
if keyword_set(dss) then begin
   x=x-dxf & y=y-dyf 
   gsssxyad,astr,x,y,a,d,print=prt
   if not keyword_set(deg) then begin
      a=a/!radeg & d=d/!radeg
      endif
   endif
;
if keyword_set(wcs_flag) or keyword_set(dss) then begin
   if keyword_set(prt) then begin
      if prt eq -1 then begin
         degtohms,a,h,m,as & degtodms,d,ddx,dm,ds
         z=string(h,'(i2)')+string(m,'(I3)')+string(as,'(F7.3)')
         z=z+string(ddx,'(I6)')+string(dm,'(I4)')+string(ds,'(F8.3)')
         endif else z=string(a,'(F8.3)')+' '+string(d,'(F8.3)')
      print,' Coordinates: ',z
      endif
   if keyword_set(stp) then stop,'XYTAD>>>'
   return
   endif
;
NAR=1
if n_elements(dr) eq 0 then dr=0.0174532925D0
if n_elements(x) eq 1 then begin
   nar=0
   x=x(0) & y=y(0)
   endif
SX=SIZE(X) & SY=SIZE(Y)
TP=2.0*3.1415926D0
a=atn & d=dtn            ;tangent point
IF (NAR EQ 0) THEN BEGIN
   IF ((X(0) EQ 0.) AND (Y(0) EQ 0.)) THEN goto,done    ;at the tangent point
   ENDIF
ETA=-X*S & XSI=Y*S
K=WHERE ((XSI EQ 0.) AND (ETA EQ 0.),nk)
if nk gt 0 then ETA(K)=1.
THETA=ATAN(ETA,XSI)
PHI=ATAN(SQRT(ETA*ETA+XSI*XSI))
ARG=SIN(DTN)*COS(PHI)+COS(DTN)*SIN(PHI)*COS(THETA)
D=ASIN(ARG)
A=0.0
IF (NAR EQ 0) and (COS(D(0)) EQ 0.) THEN begin
   if keyword_set(deg) then begin
      a=a/dr & d=d/dr
      endif
   RETURN
   ENDIF
XARG=COS(DTN)*COS(PHI)-SIN(DTN)*SIN(PHI)*COS(THETA)
YARG=SIN(PHI)*SIN(THETA)
IF (NAR EQ 0) THEN BEGIN
   IF ((XARG(0) EQ 0.) AND (YARG(0) EQ 0.)) THEN begin
      if keyword_set(deg) then begin
         a=a/dr & d=d/dr
         endif
      RETURN
      endif
   ENDIF
K=WHERE ((YARG EQ 0.) AND (XARG EQ 0.),nk)
if nk gt 0 then YARG(K)=1.
A=ATAN(YARG,XARG)+ATN
IF NAR EQ 1 THEN BEGIN
   TPA=TP+FLTARR(N_ELEMENTS(A))
   F=FLTARR(N_ELEMENTS(A))+1.
   K=WHERE (A GT 0.) & if k(0) ne -1 then F(K)=0.
   A=A+TPA*F
   F=F*0.
   K=WHERE (A GT TP) & if k(0) ne -1 then F(K)=1.
   A=A-TPA*F
   ENDIF ELSE BEGIN
   IF A LT 0. THEN A=A+TP
   IF A GT TP THEN A=A-TP
   ENDELSE
theta=0 & arg=0 & phi=0
done:
ad=a/dr & dd=d/dr            ;degrees
if keyword_set(deg) then begin
   a=ad & d=dd
   endif
if keyword_set(prt) then begin
   if prt eq -1 then begin
      degtohms,ad,h,m,as & degtodms,dd,ddx,dm,ds
      z=string(h,'(i2)')+string(m,'(I3)')+string(as,'(F7.3)')
      z=z+string(ddx,'(I6)')+string(dm,'(I4)')+string(ds,'(F8.3)')
      endif else z=string(ad,'(F8.3)')+' '+string(dd,'(F8.3)')
   print,' Coordinates: ',z
   endif
if keyword_set(stp) then stop,'XYTAD>>>'
RETURN
END
