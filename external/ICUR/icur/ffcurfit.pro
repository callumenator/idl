;**********************************************************************
pro FFCURFIT,Nfree,weight,FLAMDA,CHISQ1,IFLAG,cii=cii
; called by ffcfit in ffit2
;C**   CURFIT FROM BEVINGTON VIA FWCFIT
;C**   TYPED IN 6/25/82
;C**   modified 7/2/84 to permit freezing of parameters, following
;C**        M. Lampton's WHIZ algorithm
COMMON CFT,X,Y,SIGMAY,eeeeee
COMMON PLCR,YFIT
COMMON CURVE,A,EA,IFIXT
common custompars,dw,lp,x2,x3,x4,x5
common ffits,lu4
if n_elements(lu4) eq 0 then lu4=-1
ea=a*0.
iflag=-1
TW=TOTAL(WEIGHT)
;
n=where(ifixt gt 0,NVAR)
INDX=FIX(N)
;
BETA=dblarr(nvar,/nozero)
ALPHA=dblarr(nvar,nvar,/nozero)
array=dblarr(nvar,nvar,/nozero)
FUN=FUNGUS(x,A,cii=cii)
deriv=GDERIV(x,a)
k=where(deriv eq 0,nk)
mm=min(abs(deriv)>1.e-20)
isign=deriv/(abs(deriv)>mm)
if nk gt 0 then isign(nk)=0
logd=alog10(abs(deriv)>mm)
logw=alog10(weight+1.E-9)
z=weight*(y-fun)
for j=0,nvar-1 do beta(j)=total(z*deriv(*,indx(j)))
;
for j=0,nvar-1 do begin            
   JI=INDX(J)
   for k=0,j DO begin 
      KI=INDX(K)
      z=(logW+logD(*,JI)+logD(*,KI))>(-37.)
      ALPHA(J,K)=TOTAL(isign(*,ji)*isign(*,KI)*10^(z)) 
      endfor
   endfor
;
yfit=fungus(x,a,cii=cii)
IFLAG=-1
for J=0,NVAR-1 do begin
   for K=0,J do ALPHA(K,J)=ALPHA(J,K)
   IF ALPHA(J,J) EQ 0. then goto,curerr
   endfor
IFLAG=0
CHISQ1=FCHISQ(NFREE,y,yfit,weight)
lab71:
sqralpha=sqrt(ABS(alpha))
for J=0,NVAR-1 do begin
   dj=sqrt(alpha(j,j))
   for K=0,NVAR-1 do ARRAY(J,K)=ALPHA(J,K)/dj/sqrALPHA(K,K)
   ARRAY(J,J)=1.D0+FLAMDA
   endfor
;
iflag=-99
arr=array
array=invert(arr)
;
b=a
dal=dblarr(nvar,/nozero)
for j=0,nvar-1 do dal(j)=alpha(j,j)
dal=sqrt(dal)
for J=0,NVAR-1 do begin
   JI=INDX(J)
   b(ji)=b(ji)+total(beta*array(j,*)/dal(j)/dal)
;for K=0,NVAR-1 do B(JI)=b(ji)+BETA(K)*ARRAY(J,K)/SQRT(ALPHA(J,J))/sqrt(ALPHA(K,K))
   endfor
YFIT=FUNGUS(x,B,cii=cii)
CHISQR=FCHISQ(NFREE,y,yfit,weight)
case 1 of
   chisq1 lt chisqr: begin
      FLAMDA=10.D0*FLAMDA
      IF FLAMDA LT 101.D0 then GOTO,lab71
      IFLAG=-92
      RETURN
      end
   chisq1 ge chisqr: begin
      a=b
      saa=SQRT(ABS(ARRAY/ALPHA))
      for J=0,NVAR-1 do begin
         JI=INDX(J)
         EA(JI)=SAA(J,J)
         endfor
      end
   else: begin
      print,'*** FFCURFIT: You''ve got a problem here! ***'
      a=b
      saa=SQRT(ABS(ARRAY/ALPHA))
      for J=0,NVAR-1 do begin
         JI=INDX(J)
         EA(JI)=SAA(J,J)
         endfor
      end
   endcase
FLAMDA=FLAMDA/10.D0
CHISQ1=CHISQR
iflag=0
RETURN
;
curerr: 
bell
print,' *** CURFIT failed to converge'
if lu4 le 0 then return
printf,lu4,'*  CURFIT ERRORS: IFLAG,J,Nvar=',IFLAG,J,Nvar
printf,lu4,'*  I,A(I),DERIV(I),BETA(I),ALPHA(I,J=(1,N))'
for I=0,Nvar-1 do begin
   ji=indx(i)
   printf,lu4,'* ',I,A(jI),DERIV(jI),BETA(I),(ALPHA(I,0:nvar-1))
   endfor
RETURN
END
