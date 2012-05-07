;*****************************************************************
pro pltx,ilog,x,y,sy,legend,zero
;ilog=0,1,2,3 for plot,_io,_oi,_oo
ihlp=0
if n_params(0) lt 3 then ihlp=1
if n_elements(y) eq 0 then ihlp=1
if ihlp eq 1 then begin
   print,' '
   print,' * PLTx - x plots per page'
   print,' *    calling sequence: PLTx,ILOG,X,Y,SY,LEGEND,ZERO'
   print,' *       ILOG : 0: linear, 1: linear-log, 2: log-linear, 3: log-log'
   print,' *       X    : X variable, must be same for all plots.'
   print,' *       Y    : array(x,*) of dependent variables'
   print,' *       S    : optional error bars on Y. Scalar to skip'
   print,' *      LEGEND: optional identifier for each plot' 
   print,' *       ZERO : plot optional horizontal line at level ZERO'
   print,' '
   return
   endif
;
s=size(y)
if s(0) ne 2 then begin     ;make 2 dimensional
   y=transpose(y)
   s=size(y)
   endif
nplots=s(1)
midplot=fix(nplots/2)>0
if (midplot mod 2) eq 1 then midplot=midplot-1
ylen=s(2)
if n_params(0) lt 4 then ieb=0 else ieb=1
if n_elements(sy) lt 2 then ieb=0
if ieb eq 0 then sy=y*0.
if n_elements(x) lt 2 then begin
   if n_elements(x) eq 0 then x=indgen(ylen)
   if n_elements(x) eq 1 then begin
      x=intarr(1)+x
      if x(0) le 1 then x=indgen(ylen) else x=indgen(x(0))
      endif
   endif
if n_params(0) ge 5 then ileg=1 else ileg=0
;l
dev=!d.name
xt=!x.title
yt=!y.title
mt=!p.title
opf=!p.fonts & opchar=!p.charsize   ;fn=!fancy
sp,dev
ps=!p.psym
;
yrange=0.7/nplots
for iloop=0,nplots-1 do begin
   ylo=.2+iloop*yrange
   !p.position=[.2,ylo,.9,ylo+yrange]
   v=y(iloop,*)
   e=sy(iloop,*)
   eo=iloop mod 2
   !p.title=''
   !y.title=''
   !x.title=''
   !x.ticks=-1
   if eo eq 0 then !y.ticks=0 else !y.ticks=-1
   !p.noeras=1
   if iloop eq 0 then begin
      !x.ticks=0
      !p.noeras=0
      !x.title=xt
      endif
;
   if iloop eq midplot then !y.title=yt              ;do ytitle here
;
   if iloop eq nplots-1 then !p.title=mt      ;top plot
;
   !c=-1
   case 1 of
      ilog eq 0: plot,x,v
      ilog eq 1: plot_io,x,v
      ilog eq 2: plot_oi,x,v
      ilog eq 3: plot_oo,x,v
      endcase
   if n_params(0) ge 6 then drlin,zero,ls=1
   if eo eq 1 then begin              ;label Y axis
      !y.ticks=0
      axis,/yaxis=1,/ytype=(ilog mod 2)     ;axis,!cymin,!cymax,2+(ilog mod 2)
      endif
   if ieb eq 1 then erbar,2,v,v+e,v-e,x
   if ileg eq 1 then begin
      !p.charsize=1. & p.fonts=-1
      xyouts,!x.crange(0)+.02*(!x.crange(1)-!x.crange(0)), $
           !y.crange(0)+.9*(!y.crange(1)-!y.crange(0)),legend(iloop)
      !p.fonts=opf & !p.charsize=opchar     ;!fancy=fn
      endif
   endfor
lplt,'X'
!p.noeras=0
!x.ticks=0
!y.ticks=0
!p.title=mt
!x.title=xt
!y.title=yt
!p.psym=ps
return
end
