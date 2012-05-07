;******************************************************************
PRO LSQRE,X,Y,SLOPE,B,DS,DB,R,helpme=helpme,prt=prt,plt=plt,weights=weights, $
    stp=stp
if keyword_set(helpme) then begin
   print,' '
   print,'* LSQRE : least squares solution for y|x'
   print,'* calling sequence: LSQRE,X,Y ,[SLOPE,B,DS,DB,R] '
   print,'*    X,Y: independent and dependent variables'
   print,'*    SLOPE,B: slope and Y-intercept'
   print,'*    DS,DB: errors on the slope and Y-intercept '
   print,'*    R: linear correlation coefficient'
   print,'*'
   print,'*    note: output is sent to the screen if only 2 parameters are specified'
   print,' '
   return
   endif
np=n_params(0)
if np lt 2 then return                 ;insufficient parameters
N=FLOAT(N_ELEMENTS(X))
if n lt 2 then return                  ; need at least 3 points
;
ny=n_elements(y)
noweights=0
if n_elements(weights) lt ny then begin
   w=replicate(1.,ny) & noweights=1
   endif else begin
   w=weights
   w=abs(w)
   if min(w) eq 0 then begin
      k=where(w gt 0,nk)
      if nk eq 0 then begin
         w=replicate(1.,ny) & noweights=1
         endif else w=w>min(w(k))
      endif
   endelse
;
if np lt 3 then ipr=1 else ipr=0
if keyword_set(prt) then ipr=1
SLOPE=0.0 & DS=0.0
B=0.0 & DB=0.0
R=0.0
sx=total(x/w/w)
sy=total(y/w/w)
SX2=TOTAL(X*X/w/w)
Sy2=TOTAL(y*y/w/w)
sxy=TOTAL(X*Y/w/w)
sw2=total(1./w/w)
D=sw2*SX2-SX*SX
IF D EQ 0.0 THEN RETURN
B=(SX2*SY-SX*SXY)/D
SLOPE=(sw2*SXY-SX*SY)/D
if keyword_set(plt) then begin
;   if !x.crange(1) gt !x.crange(0) then begin
      yp=slope*x+b
      oplot,x,yp
;      endif
   endif
if (np lt 5) and (ipr eq 0) then return
;
; errors
;
D2=N*total(x*x)-total(x)*total(x)
if noweights eq 0 then v=1. else V=(total(y*y)+B*B*N+SLOPE*SLOPE*total(x*x) $
   -2.*(B*total(y)+SLOPE*total(x*y)-SLOPE*B*total(x)))/(N-2.)
;if v lt 0 then begin
;   v=abs(v)
;   print,' LSQRE: WARNING: sigma^2 < 0; set positive'
;   endif
;DB=SQRT(V*total(x*x)/D2)
db=sqrt(abs(v*sx2/d))
;DS=SQRT(V*N/D2)
ds=sqrt(abs(V*sw2/d))
;
if ipr eq 1 then begin
   print,'  Slope =     ',slope,' +/-',ds
   print,'  Yintercept =',b,' +/-',db
   endif
if (np lt 7) and (ipr eq 0) then return
;
; correlation coefficient
;
D=N*total(x*x)-total(x)*total(x)
R=(N*total(x*y)-total(x)*total(y))/SQRT(D*(total(y*y)*N-total(y)*total(Y)))
;R=(sw2*SXY-SX*SY)/SQRT(D*(SY2*sw2-SY*SY))
if ipr eq 1 then print,'  Correlation coefficient =',r
if keyword_set(stp) then stop,'LSQRE>>>'
RETURN
END
