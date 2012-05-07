;******************************************************************************
pro tdradvel,ws,fs,wt,ft
;
; written by Y. Gao Summer 1991
;
;rdascsp,'oph13',ws,fs,h,s         ; get the rotating star's spectrum
;rdascsp,'sky13',wt,ft,h,s         ; get the non-rot template's spectrum
tdxcor,wt,ft,ws,fs,wta,c           ; call the procedure 'crosscor' to 
;
dv=mean(wta(1:*)-wta)              ;bin size
;
kmax=where(c eq max(c)) & kmax=kmax(0)
no=n_elements(c)
nc=100                            ; show the details around the peak 
xp=wta((kmax-nc)>0:(kmax+nc)<(no-1)) & cp=c((kmax-nc)>0:(kmax+nc)<(no-1))
setxy
plot,xp,cp,psym=10
acl=fltarr(6)
acl=[c(kmax),wta(kmax),20.,0.,0.,0.]
pea=gaussfit(xp,cp,acl)           ; use Gaussian fit to estimate the 
;                                   width of the cross-correlation peak
oplot,xp,pea,color=85
wcro=acl(2)*2.*sqrt(2.)
xcen=acl(1)
print,'acl=',acl(0:2)
print,'kmax=',kmax
;
stop,'TDRADVEL'
tdxcor,wt,ft,wt,ft,wta,ac       ; evaluate the auto-correlation peak
na=100
xpp=wta(no/2-na:no/2+na)
cpp=ac(no/2-na:no/2+na)
plot,xpp,cpp
peap=gaussfit(xpp,cpp,aal)
oplot,xpp,peap
waut=aal(2)*2.*sqrt(2.)
vsin=3.e5*sqrt(wcro^2-2.*waut^2)  ; calculate the rotating star's vsini
print,'vsini=',vsin,' km/s'
stop
return
END
