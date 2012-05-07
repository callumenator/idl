;*****************************************************************
pro stkplt,ilog,xx,yy,sy,legend,offset
;ilog=0,1,2,3 for plot,_io,_oi,_oo
ihlp=0
if n_params(0) lt 3 then ihlp=1
if n_elements(yy) eq 0 then ihlp=1
if ihlp eq 1 then begin
   print,' '
   print,' * STKPLT - stack plots on page'
   print,' *    calling sequence: STKPLT,ILOG,X,Y,SY,LEGEND,OFFSET'
   print,' *       ILOG : 0: linear, 1: linear-log, 2: log-linear, 3: log-log'
   print,' *       X    : array(x,*) of independent variable'
   print,' *       Y    : array(x,*) of dependent variables'
   print,' *       SY   : optional error bars on Y. Scalar to skip'
   print,' *      LEGEND: optional identifier for each plot' 
   print,' *      OFFSET: offset between plots, def=range, - to switch psym'
   print,' '
   return
   endif
;
x=xx
y=yy
;
s=size(y)              ;Y vector
if s(0) ne 2 then begin     ;make 2 dimensional
   y=transpose(y)
   s=size(y)
   endif
ylen=s(2)
nplots=s(1)                            ;number of plots
;
if n_elements(x) lt 2 then begin           ;X vector
   if n_elements(x) eq 0 then x=indgen(ylen)   ;make array
   if n_elements(x) eq 1 then begin
      x=intarr(1)+x
      if x(0) le 1 then x=indgen(ylen) else x=indgen(x(0)>1)
      endif
   endif
sx=size(x)
if sx(0) ne 2 then begin     ;make 2 dimensional
   x=transpose(x)
   sx=size(x)
   endif
if sx(1) lt nplots then begin     ;X array smaller than Y array
   x=transpose(x)          ;transpose back
   xt=fltarr(ylen,nplots)
   if sx(1) eq 1 then for i=0L,nplots-1L do xt(ylen*i)=x else $
      for i=0L,nplots-1L do xt(ylen*i)=x(*,sx(1)-1)
   x=transpose(xt)
   endif
;
midplot=fix(nplots/2)>0
if (midplot mod 2) eq 1 then midplot=midplot-1
if n_params(0) lt 4 then ieb=0 else ieb=1
if n_elements(sy) lt 2 then ieb=0
if ieb eq 0 then sy=y*0.
if n_params(0) ge 5 then ileg=1 else ileg=0
;
dev=!d.name
sp,dev
ps=!psym
if n_elements(offset) eq 0 then offset=max(y)-min(y)
off=abs(offset)
if offset lt 0 then !psym=-8 else !psym=8
xmin=!x.range(0) & xmax=!x.range(1) & ymin=!y.range(0) & ymax=!y.range(1)
svp
setxy,min(x),max(x),min(y),max(y)+(nplots-1)*off
;
figsym,2,1
w=x(0,*)
v=y(0,*)
e=sy(0,*)
k=sort(w)
case 1 of
   ilog eq 0: plot,w(k),v(k)
   ilog eq 1: plot_io,w(k),v(k)
   ilog eq 2: plot_oi,w(k),v(k)
   ilog eq 3: plot_oo,w(k),v
   endcase
if ieb eq 1 then erbar,2,v(k),v(k)+e(k),v(k)-e(k),w(k)
for iloop=0,nplots-1 do begin
   w=x(iloop,*)
   v=y(iloop,*)+off*iloop
   e=sy(iloop,*)
   eo=iloop mod 2
   if eo then figsym,2 else figsym,2,1
;
   !c=-1
   case 1 of
      ilog eq 0: oplot,w(k),v(k)
      ilog eq 1: oplot_io,w(k),v(k)
      ilog eq 2: oplot_oi,w(k),v(k)
      ilog eq 3: oplot_oo,w(k),v(k)
      endcase
   if ieb eq 1 then erbar,2,v(k),v(k)+e(k),v(k)-e(k),w(k)
   if ileg eq 1 then begin
      xyouts,!x.crange(0)-.2*(!x.crange(1)-!x.crange(0)),min(v),legend(iloop)
      endif
   endfor
lplt,dev
!psym=ps
setxy,xmin,xmax,ymin,ymax
return
end
