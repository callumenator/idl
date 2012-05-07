;******************************************************************
PRO LSQRD,X1,Y1,dx1,dy1,type,hcpy=hcpy
NP=FLOAT(N_ELEMENTS(X1))
if n_params(0) lt 5 then type=-2
x=x1 & dxa=dx1
y=y1 & dya=dy1
type=abs(type)
if not keyword_set(hcpy) then hcpy=0 else hcpy=1
if type eq 0 then type=1
case 1 of
   type eq 1: begin   ;linear scaling
      my=max(y1)
      y=y1/my
      dya=dy1/my
      dyb=dya
      dxb=dxa
      end
   type eq 2: begin   ;exponential scaling (ln y)
      y=alog(y1)
      y2=alog(y1-dy1)
      y3=alog(y1+dy1)
      dya=y-y2
      dyb=y3-y
      x=x1
      dxa=dx1
      dxb=dxa
      end
   type eq 3: begin   ;log scaling
      x=alog10(x1)
      x2=alog10(x1-dx1)
      x3=alog10(x1+dx1)
      dxb=x3-x
      dxa=x-x2
      y=alog10(y1)
      y2=alog10(y1-dy1)
      y3=alog10(y1+dy1)
      dya=y-y2
      dyb=y3-y
      end
   endcase
;
lsqre,x,y
lsqre,x,y,slope,b,ds,db,r
;
;determine perp distances
;
sperp=-1./slope
bperp=y-sperp*x
if abs(slope) eq 1. then xperp=(b-bperp)/2. else xperp=(bperp-b)/(slope-sperp)
yperp=slope*xperp+b
yperpt=sperp*xperp+bperp
dif=yperp-yperpt
if abs(mean(dif/yperp)) gt .001 then stop,' LSQRED: yperp ne yperpt'
dist=sqrt((x-xperp)*(x-xperp)+(y-yperp)*(y-yperp))
theta=atan(y-yperp,x-xperp)
k=where(theta lt 0.)
theta(k)=theta(k)+!pi*2
k=where(x gt xperp)
dx=dxa
dy=dya
dx(k)=dxb(k)
dy(k)=dyb(k)
dxy=sqrt(dx*sin(theta)*dx*sin(theta)+dy*cos(theta)*dy*cos(theta))
sig=dist/dxy
chsq=total(sig*sig)
print,'chi-square=',chsq,' Prob=',pchisq(chsq,np-2)
if hcpy eq 1 then begin
   setxy,0.,0.,min(y),max(y)
   plot,x,y,linestyle=0,psym=8
   xx=!x.crange(0)+findgen(100)*.01*(!x.crange(1)-!x.crange(0))
   oplot,xx,xx*slope+b,psym=0
   for i=0,np-1 do oplot,xx,xx*sperp+bperp(i),linestyle=2,psym=0
   for i=0,np-1 do begin
      aa=[x(i)-dxa(i),x(i),x(i)+dxb(i)]
      bb=[y(i)-dya(i),y(i),y(i)+dyb(i)]
      oplot,fltarr(3)+x(i),bb & oplot,aa,fltarr(3)+y(i),linestyle=0
      endfor
   endif
RETURN
END
