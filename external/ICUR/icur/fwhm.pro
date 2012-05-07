;*************************************************************
pro FWHM,WAVE,FLUX,fw                ; return full width at half max
common comxy,xcur,ycur,zerr
common com1,h,ik
if n_params(0) lt 2 then begin
   print,' '
   print,'* FWHM   -estimate FWHM of feature'
   print,'*    calling sequence: FWHM,W,F,FW'
   print,'*       W,F: wavelength and flux vectors'
   print,'*        FW: output FWHM
   print,'*    operational notes: X and Y of first point must be in COMXY'
   print,'*    method: find all points above (below) half peak. Linearly'
   print,'*            interpolate outside that range.'
   print,' '
   return
   endif
np=n_elements(wave)-1
i1w=xcur
y1=ycur
z=' place cursor on other continuum point'
print,z 
blowup,-1
i2w=xcur
y2=ycur
i1=fix(xindex(wave,i1w)) & i2=fix(xindex(wave,i2w)+0.5)
                               ;tabinv,wave,i1w,i1 & tabinv,wave,i2w,i2
IF I2 LT I1 THEN BEGIN
     T=I2
     I2=I1
     I1=T
     ENDIF
i1=(i1>0)                   ;force I1 > 0
i2=i2<np  ;force i2 < greatest element
IF (I2-I1) LE 1 THEN RETURN
yd=(y1+y2)/2.                      ;mean continuum
FD=FLUX(i1:i2-1)-YD
iem=1
IF TOTAL(fd) LT 0 THEN begin
   FD=-FD    ;make positive
   iem=-1
   endif
height=abs(max(fd))/2.
k=where(fd gt height)     ;points above FWHM
k0=k(0)>1
km=max(k)<(n_elements(fd)-1)
f1=i1+k0-1+(height-fd(k0-1))/(fd(k0)-fd(k0-1))          ;bin number
f2=i1+km+(height-fd(km))/(fd(km+1)-fd(km))
p1=f1 & fp1=fix(p1)
dw=wave(p1+1)-wave(p1)
w1=wave(fp1)+(p1-fp1)*dw
p2=f2 & fp2=fix(p2)
w2=wave(fp2)+(p2-fp2)*dw
fw=w2-w1
ik=ik+1
z=' FWHM:'+string(fw,'(F9.3)')
yp=!d.y_size*!y.window(1)-(!d.y_ch_size+1)*float(ik)
xp=!d.x_size*!x.window(1)-!d.x_ch_size*16.
xyouts,xp,yp,z,/device
print,z
!c=-1
x=[w1,w2]
if !psym eq 10 then x=x-0.5*dw
oplot,x,[yd+iem*height,yd+iem*height],color=55,linestyle=0
RETURN
END
