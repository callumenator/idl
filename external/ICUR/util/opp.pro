;*************************************************************
pro opp,x,y,ps,psize=psize,color=color,helpme=helpme,pixels=pixels,stp=stp
common grid,sc,atn,dtn,ddec,dr,equinox,acen,dcen,atnp,dtnp,xoffset,yoffset,dss
common dss,xc,yc,px,py,xc1,yc1,ap,bp,ac,dc,dssh,astr,dxf,dyf
common fullimage,imsave,im0
common wcs,wcs_flag
if n_params(0) lt 2 then helpme=1
if keyword_set(helpme) then begin
   print,' '
   print,'* OPP - overplot single point'
   print,'* calling sequence: OPP,x,y,ps'
   print,'*    x,y: coordinates of point'
   print,'*     ps: !P.PSYM value for point, defaults to current value'
   print,'* '
   print,'*  KEYWORDS:'
   print,'*     pixels: set if input is in pixels on screen'
   print,'*     psize:  symbol size, default=1.'
   print,'*     color:  symbol color, default=!p.color'
   print,' '
   return
   endif
if n_elements(x) gt 1 then x1=x(0) else x1=x
if n_elements(y) gt 1 then y1=y(0) else y1=y
if n_params(0) lt 3 then ps=!p.psym
if not keyword_set(psize) then psize=1.
if not keyword_set(color) then color=!p.color
if keyword_set(pixels) then begin
   s=size(imsave)
   sxtp=s(1)/2 & sytp=s(2)/2
   x1=x1-sxtp & y1=y1-sytp
   endif
oplot,[x1,x1],[y1,y1],psym=ps,symsize=psize,color=color
if keyword_set(stp) then stop,'OPP>>>'
return
end
