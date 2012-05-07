;*************************************************************************
pro opcirc,rar0,rdec0,radius,pperd,thick=thick,color=color,epoch=epoch, $
    helpme=helpme,stp=stp,pixels=pixels,inpix=inpix,hmsdeg=hmsdeg,notp=notp, $
    radec=radec,pa=pa,ar=ar,tvcoords=tvcoords,cont=cont
common tvcom,pixf,zerr,tvscale,imin,imax,ids,implot,ism,ilog,autos
common grid,sc,at,dt,ddec,dr,ep0,acen,dcen,atnp,dtnp,xfudge,yfudge,dssastr
common dss,xc,yc,px,py,xc1,yc1,ap,bp,ac,dc,dssh,astr,dxf,dyf
common wcs,wcs_flag
if n_params(0) lt 2 then helpme=1
if keyword_set(helpme) then begin
   print,' '
   print,'* OPCIRC - overplot circle or ellipse on sky plot'
   print,'*    calling sequence: OPCIRC,ra,dec,radius,pperd'
   print,'*       RA,DEC: position(s) of centers of circles (decimal degrees)'
   print,'*       RADIUS: radius of circle (arcmin), default=1 arcmin'
   print,'*       PPERD:  number of points per degree in circle, default=2'
   print,'*    KEYWORDS:'
   print,'*       COLOR: color of circle, default=1 '
   print,'*       EPOCH: epoch of coordinates, default=epoch of plot'
   print,'*       HMSDEG: coordinates entered in HMS,DMS format'
   print,'*       PIXELS: ra,dec are pixel numbers'
   print,'*       INPIX: ignore GRID common and plot in pixels
   print,'*       THICK: line thickness, default=1'
   print,'*       TVCOORDS: mark position with cursor'
   print,'*       AR:    ratio of major to minor axis (given by RADIUS), def=1'
   print,'*       PA:    position angle of ellipse, in degrees E of N, def=90'
   print,' '
   return
   endif
;
if !d.name ne 'X' then tvcoords=0
zerr=0
if keyword_set(cont) then print,'Right click to exit loop'
while zerr lt 2 do begin
if keyword_set(tvcoords) then begin
   wshow
   print,' Mark position with cursor'
   cursor,rar0,rdec0
   if keyword_set(cont) then wait,0.1
   zerr=!err
   if zerr ge 2 then goto,retn
   print,' Position = ',rar0,rdec0
   endif
rar=rar0 & rdec=rdec0
if not keyword_set(notp) then notp=0
if n_elements(sc) eq 0 then begin
   notp=1
   sc=1 & ep0=0.
   endif
dpix=sc*!radeg
if keyword_set(inpix) then begin
   dpix=60.
   endif
if n_elements(wcs_flag) eq 0 then wcs_flag=0
;
if n_params(0) lt 3 then radius=1.     ;default=1 arcmin
if ((n_params(0) lt 3) and (keyword_set(pixels))) then radius=dpix/60.  ;default=1 arcmin
if n_params(0) lt 4 then pperd=2           ;points per degree
if not keyword_set(thick) then thick=1.
if not keyword_set(color) then color=!d.n_colors<255
if strupcase(!d.name) eq 'PS' then color=0
if strupcase(!d.name) ne 'PS' then cwind=!d.window else cwind=0
if (n_elements(pixf) eq 0) or (strupcase(!d.name) eq 'PS') or $
   (strupcase(!d.name) eq 'Z') or (cwind lt 0) then begin
   x0=0 & y0=0 & zoom=1 & scx=1 & scy=1
   endif else begin
   x0=pixf(cwind,3) & y0=pixf(cwind,4) & zoom=pixf(cwind,2)
   scx=pixf(cwind,0) & scy=pixf(cwind,1)
   endelse
;
if keyword_set(hmsdeg) then begin
   rar=hmstodeg(rar) & rdec=dmstodeg(rdec)
   endif
nrbx=n_elements(rar)                       ;number of boxes
nr=n_elements(radius)
if nr eq 1 then rad=fltarr(nrbx)+radius else rad=radius
k=where(rad le 0.,ck) & if ck gt 0 then rad(k)=1.
if not keyword_set(pixels) and not keyword_set(inpix) then rad=rad/60. ;convert to degrees
;rad=rad*2.         ;radius to diameter
DR=0.0174532925D0
np=361*pperd   
j=findgen(np)/pperd*dr
if nrbx eq 1 then begin
      rar=fltarr(1)+rar
      rdec=fltarr(1)+rdec
      endif
;
de=0.
case 1 of
   n_elements(ep0) eq 0: de=0.
   not keyword_set(epoch) and n_elements(ep0) eq 1: de=0.
   else: de=epoch-ep0
   endcase
if abs(de) gt 0.1 then precess,rar,rdec,epoch,ep0
if keyword_set(pixels) or keyword_set(inpix) then sf=1. else sf=dr/sc
FOR I=0,Nrbx-1 DO BEGIN                ;rosat boxes
   case 1 of
      notp: begin
         sf=1.
         rc=rar(i) & dc=rdec(i)
         end
      keyword_set(pixels): begin
         imxsiz=(!x.crange(1)-!x.crange(0))*zoom/2
         imysiz=(!y.crange(1)-!y.crange(0))*zoom/2
         if imysiz lt !x.crange(1) then ddy=!x.crange(1)-imysiz else ddy=0.
ddy=0.
         rc=scx*(rar(i)-imxsiz/scx) & dc=scy*(rdec(i)-imysiz/scy)+ddy  ;pixels
         end
      wcs_flag: begin
         ad2xy,rar(i),rdec(i),astr,rc,dc     ;,/zeroc
         rc=rc-xc & dc=dc-yc
         end
      keyword_set(radec): begin
         sf=1.
         rc=rar0(i) & dc=rdec0(i)
         scx=1./cos(dc/!radeg) & scy=1.
         end
      else: if (n_elements(sc) eq 0) or (n_elements(at) eq 0) then begin
            rc=rar0(i) & dc=rdec0(i)
            sf=1.
            endif else adtxy,rar(i)*dr,rdec(i)*dr,rc,dc      ;central position
      endcase
   if n_elements(ar) eq 0 then ar=1.
   xbox=rc+sin(j)*rad(i)*sf*scx*ar
   ybox=dc+cos(j)*rad(i)*sf*scy
;
   if n_elements(pa) gt 0 then begin     ;position angle
      pa=(90.-pa)*dr
      mx=mean(xbox) & my=mean(ybox)
      xb=xbox-mx & yb=ybox-my
      xbox=xb*cos(pa)-yb*sin(pa)+mx
      ybox=xb*sin(pa)+yb*cos(pa)+my
      endif
;
   !c=-9
   xb1=!x.crange(0)<!x.crange(1) & xb2=!x.crange(0)>!x.crange(1)
   yb1=!y.crange(0)<!y.crange(1) & yb2=!y.crange(0)>!y.crange(1)
   k=where((xbox ge xb1) and (xbox le xb2) and $
           (ybox ge yb1) and (ybox le yb2),nk)
   if nk gt 0 then begin
;      oplot,xbox(k),ybox(k),psym=0,linestyle=0,thick=thick,color=color
      oplot,xbox,ybox,psym=0,linestyle=0,thick=thick,color=color
      endif
   ENDFOR
if nrbx eq 1 then begin
      rar=rar(0)
      rdec=rdec(0)
      endif
   if not keyword_set(cont) then zerr=4
   endwhile            ;zerr
retn:
if keyword_set(stp) then stop
return
end
