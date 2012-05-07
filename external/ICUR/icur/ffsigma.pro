;***************************************************************************
pro FFSIGMA,im1,IB
; called by FFIT2
;C**   ROUTINE TO ESTIMATE ERRORS IN DATA and return variance
;C**   MODE 1: 1 SIGMA = 1 STANDARD DEVIATION OF DATA
;C**   MODE 2: ERROR PROPORTIONAL TO ROOT N
;C**   MODE 3: ERROR CONSTANT AT LEVEL INPUT
;C**   MODE 4: use E vector to estimate 1 sigma errors
;C**   NEGATIVE MODE IGNORES ERROR FLAGS
;C**   ERROR FLAGS TO BE DEALT WITH DEPENDING ON SEVERITY IN FUTURE
;C**   MODIFIED 7/26 TO TAKE OUT LINEAR TREND IN DATA FOR VARIANCES
;C**   INTERACTIVE INPUT UPDATED 11/7/85
COMMON CFT,X,Y,SIG,E
common ffits,lu4
; test for valid input
immax=4
imdesc=['','Observed Variance','Variance scaled by root(n)','Fixed value','S/N']
if n_params(0) eq 0 then im1=3
if n_params(0) lt 2 then ib=intarr(4)
if (im1 ne 4) and (ib(3) le ib(2)) then im1=3
if n_elements(lu4) eq 0 then lu4=-1
if im1 lt 0 then ie=1 else ie=0        ;1 to ignore bad data flags
im=abs(im1)
;
if im1 eq 4 then begin            ;use S/N vector
   sig=abs(e)                          ;E is S/N vector
   k=where(sig eq 0,nz)
   if nz gt 0 then for i=0,nz-1 do  $
      sig(k(i))=(sig((k(i)-1)>0)+sig((k(i)+1)<(n_elements(sig)-1)))/2.
;   sig=1./sig                 ;  INVERSE OF S/N VECTOR
   goto,bdata
   endif
;
reenter:
IF (IM lt 0) OR (IM GT immax) then IM=3
if im eq 3 then begin                  ;constant EB
   if ib(3) eq -9 then sd=mean(abs(y))/100. else read,' Enter size of error bar: ',sd
   sig=x*0.+SD/mean(y)
   if lu4 ne -1 then print,' Error magnitude from mode',im,' is ',sd
   goto,bdata
   return
   endif
;
np=ib(3)-ib(2)+1
short:
IF (np lt 3) or (IB(3) Lt 0) OR (IB(2) lt 0) then begin
   print,' BAD ERROR REGION: LIMITS=',ib(2),ib(3)
   print,' SUBROUTINE SIGMA : Re-enter error determination mode'
   print,' 1 FOR VARIANCE, 2 FOR ~ROOT N, 3 TO ENTER CONSTANT'
   print,' NEGATIVE TO IGNORE BAD DATA FLAGS'
   read,' Reenter mode: ',im1
   if abs(im1) lt 3 then begin
      read,'Please reenter the 2 bin limits',ib1,ib2
      ib(2)=ib1 & ib(3)=ib2
      endif
   IM=ABS(IM1)
   goto,reenter
   endif
;
xx=x(ib(2):ib(3))
yy=y(ib(2):ib(3))
ee=e(ib(2):ib(3))
ke=where(ee ge 0)
np=n_elements(ke)
if np lt 3 then begin
   print,' too few good data points here'
   goto,short
   endif
;
ym=mean(yy(ke))
if np gt 2 then begin   ; take out linear trend in data
   LSQRE,xx(ke),yy(ke),SLOPE,B
   yf=b+slope*xx        ;linear fit
   yres=yy-yf           ;residuals
   sd=stddev(yres)      ;standard deviation
   endif
if lu4 gt 0 then begin
   printf,lu4,'*    Error bar determination mode: ',string(im,'(I2)'), $
              ' (',imdesc(abs(im)),')'
   printf,lu4,'*    Magnitude of error bar: ',sd
   endif
print,' Error magnitude from mode',im,' is ',sd,' (',imdesc(abs(im)),')'
SIG=SD/MEAN(Y)+x*0.                   ;NOISE/SIGNAL
IF IM EQ 2 then sig=sig/sqrt(y/ym)    ;ESTIMATE ERROR PROPORTIONAL TO ROOT N
SIG=ABS(SIG)
;
;
bdata:                     ;   IF ERROR FLAG NEGATIVE, MAKE SIG LARGE   
if ie eq 0 then begin      
   kbad=where(e lt -201,nbad)      ;-201 in IUE data (extrapolated ITF) OK
   if nbad gt 0 then begin
      sig(kbad)=-9999
      if lu4 gt 0 then printf,lu4,'*    The ',string(nbad,'(I3)'), $
          ' points flagged as bad will not be fit.'
      print,'*    The ',string(nbad,'(I3)'),' points flagged as bad will not be fit.'
      endif
   endif else if lu4 gt 0 then printf,lu4,'*    *** Bad data flags ignored in fit ***'
RETURN
end   
