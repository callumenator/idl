;*****************************************************************
pro pltx2,ilog,xx,yy,sy,legend,zero
;ilog=0,1,2,3 for plot,_io,_oi,_oo
ihlp=0
if n_params(0) lt 3 then ihlp=1
if n_elements(yy) eq 0 then ihlp=1
if ihlp eq 1 then begin
   print,' '
   print,' * PLTx2 - x plots per page'
   print,' *    calling sequence: PLTx,ILOG,X,Y,SY,LEGEND,ZERO'
   print,' *       ILOG : 0: linear, 1: linear-log, 2: log-linear, 3: log-log'
   print,' *       X    : array(x,*) of independent variable'
   print,' *       Y    : array(x,*) of dependent variables'
   print,' *       SY   : optional error bars on Y. Scalar to skip'
   print,' *      LEGEND: optional identifier for each plot' 
   print,' *       ZERO : plot optional horizontal line at level ZERO'
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
;l
dev=!d.name
xt=!x.title
yt=!y.title
mt=!p.title
fn=!fancy
sp,dev
ps=!psym
xmin=!x.range(0) & xmax=!x.range(1) & ymin=!y.range(0) & ymax=!y.range(1)
;
yrange=0.8/nplots
for iloop=0,nplots-1 do begin
   ylo=.1+iloop*yrange
   !p.position=[.2,ylo,.9,ylo+yrange]
   w=x(iloop,*)
   v=y(iloop,*)
   setxy,min(x),max(x),min(v),max(v)
   e=sy(iloop,*)
   eo=iloop mod 2
   !p.title=''
   !y.title=''
   !x.title=''
   !x.ticks=-1
   if eo eq 0 then !y.ticks=0 else !y.ticks=-1
   !p.noerase=1
   if iloop eq 0 then begin
      !xticks=0
      !p.noerase=0
      !x.title=xt
      endif
;
   if iloop eq midplot then !y.title=yt              ;do ytitle here
;
   if iloop eq nplots-1 then !p.title=mt      ;top plot
;
   !c=-1
   case 1 of
      ilog eq 0: plot,w,v
      ilog eq 1: plot_io,w,v
      ilog eq 2: plot_oi,w,v
      ilog eq 3: plot_oo,w,v
      endcase
   if n_params(0) ge 6 then begin drlin,zero,ls=1
   if eo eq 1 then begin              ;label Y axis
      !y.ticks=0
      axis,/yaxis=1,/ytype=(ilog mod 2)
      endif
   if ieb eq 1 then erbar,2,v,v+e,v-e,w
   if ileg eq 1 then begin
      xyouts,!x.crange(0)+.02*(!x.crange(1)-!x.crange(0)), $
             !y.crange(0)+.90*(!y.crange(1)-!y.crange(0)),legend(iloop)
      endif
   endfor
lplt,'X'
!p.noerase=0
!x.ticks=0
!y.ticks=0
!p.title=mt
!x.title=xt
!y.title=yt
!psym=ps
setxy,xmin,xmax,ymin,ymax
return
end
