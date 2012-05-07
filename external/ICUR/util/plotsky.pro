;***************************************************************************
pro plotsky,h,m,sec,d,dm,ds,ep=ep,scale=scale,sf=sf,helpme=helpme,stp=stp, $
    size_leg=size_leg,oplot_grid=oplot_grid,tpcen=tpcen,radius=radius
common grid,sc,at,dt,ddec,dr,epoch,acen,dcen,atnp,dtnp,xfudge,yfudge,dssastr
common tvcom,pixf,zerr,tvscale,imin,imax,idl,implot,ism,ilog,autos
sendhelp:
if keyword_set(helpme) then begin
   print,' '
   print,'* PLOTSKY - plot sky grid  '
   print,'*    calling sequence: PLOTSKY,acen,dcen'
   print,'*             -or-     PLOTSKY,h,m,s,d,dm,ds'
   print,'*       acen,dcen: plot center in decimal degrees '
   print,'*       h,m,s,d,dm,ds: center coordinates'
   print,'*  KEYWORDS:'
   print,'*     EP: epoch of plot, def=common epoch, then 1950.0 '
   print,'*     OPLOT_GRID: set to overplot grid on image; pass image'
   print,'*     scale: scale factor in arcsec/mm'
   print,'*     sf: scale factor in multiples of POSS scale'
   print,'*     size_leg: size of characters in labels, def=1.4'
   print,'*     TPCEN: 2 element vector containing tangent plane center, def= center (deg)'
   print,'* *** - right ascension scaling off on postscript plots ***'
   print,'* *** - marks does not work following plotsky,/op ***'
   print,' '
   return
   endif
;s=sc
dr=0.0174532925D0
if n_elements(tpcen) eq 2 then begin            ;tangent plane supplied
   at=tpcen(0)*dr & dt=tpcen(2)*dr
   endif
case 1 of                                       ;center of plot
   n_params(0) lt 2: begin
      if n_elements(at) eq 0 then begin
         print,' you must supply coordinates. '
         helpme=1
         goto,sendhelp
         endif
      acen=at/dr & dcen=dt/dr
      end
   n_params(0) eq 6: begin
      acen=hmstodeg(h,m,sec) & dcen=dmstodeg(d,dm,ds)
      end
   else: begin
      acen=h & dcen=m
      end
   endcase
;
oldcolor=!p.color
if n_elements(at) eq 0 then begin
   at=acen*dr & dt=dcen*dr
   endif   
;
at=at(0) & dt=dt(0)
at0=at & dt0=dt
poss=66.7             ;POSS scale in arcsec/mm
if n_elements(ddec) eq 0 then ddec=0.
if n_elements(sc) eq 1 then sold=sc else sold=-1
plotlen=!d.y_vsize*float(!p.position(3)-!p.position(1))
xs=1. & ys=1.
;print,'plotsky: sf,sc:',sf,sc
case 1 of                 ;get plate scale (arcsec/mm)
   keyword_set(oplot_grid): begin
      if !d.window eq -1 then begin
         print,' No window defined - you cannot use the OPLOT_GRID keyword'
         return
         endif
      sz=size(oplot_grid)
      if sz(0) eq 2 then begin
         xs=float(sz(1)) & ys=float(sz(2))             ;image size
         endif else begin
         ys=float(!d.y_vsize) & xs=float(!d.x_vsize)   ;window size
         endelse
      if n_elements(pixf) ne 0 then begin
         zoom=pixf(!d.window,2)
         xytad,xs/2/zoom+pixf(!d.window,3),ys/2/zoom+pixf(!d.window,4),at,dt
         endif else begin
         zoom=1
         endelse
      case 1 of
         !d.name eq 'PS': begin
            if ys gt 2 then ddec=ys*sc*!radeg
         sc=ddec*3600.*!d.y_px_cm/!d.y_vsize/10./(!p.position(3)-!p.position(1))
            end
         else: sc=sc*!d.y_px_cm/10.*!radeg*3600. 
         endcase
      sc=sc/zoom
print,' PLOTSKY: sc,at,dt,sold,at,dt:',sc,at,dt,sold,at,dt
      end
   keyword_set(sf): sc=poss/(sf>.01)   ;sf is scale factor relative to POSS
   keyword_set(scale): sc=(scale>0)    ;arcsec/mm passed
   n_elements(radius) eq 1: begin      ;radius in degrees
      ddec=2.*radius
      sc=360.*DDEC/plotlen*!d.y_px_cm
      if sc le 0. then sc=poss
      end
   else: begin
      sc=360.*DDEC/plotlen*!d.y_px_cm
      if sc le 0. then sc=poss
      end
   endcase
ddec=Sc/360.*plotlen/!d.y_px_cm
if !d.y_vsize eq 988 then begin            ;fudge for 1024 square images
   ddec2=ddec*1024./988./2.
   endif else ddec2=ddec/2.
;
if sc le 0. then begin
   print,' Scale is le 0. :', sc
   return
   endif
;
if n_elements(at) eq 0 then at=acen*dr
if n_elements(dt) eq 0 then dt=dcen*dr
if keyword_set(ep) then epoch=ep
if n_elements(epoch) eq 0 then epoch=1950.0
;
xscale=1.
xscale=float(!d.y_vsize)/float(!d.x_vsize)
if keyword_set(oplot_grid) then !p.position=[0.,0.,1.*xscale,1.] else $
     !p.position=[.2,.2,.2+.7*xscale,.9]
AC=ACEN*DR & DC=DCEN*DR    ; DETERMINE COORDINATES OF PLOT CORNERS
ADTXY,AC,DC,X0,Y0   ;CENTER OF PLOT
DDN=(DCEN-DDEC2)*DR
DUP=DDN+DDEC*DR
dra=ddec/2.*float(xs)/float(ys)
A=[-DRA/COS(DUP),-DRA/COS(DDN),DRA/COS(DDN),DRA/COS(DUP)]
A=A*DR+AC
AMIN=MIN(A)/DR & AMAX=MAX(A)/DR
IF (ACEN LT AMIN) OR (ACEN GT AMAX) THEN ISW=1 ELSE ISW=0
D=[DUP,DDN,DDN,DUP]
ADTXY,A,D,X1,Y1
XCOR=[!X.range,!x.range(1),!x.range(0)]
YCOR=[!Y.range(0),!Y.range,!Y.range(1)]
XYTAD,ACOR,DCOR,XCOR,YCOR
;
!x.range=[MIN(X1),MAX(X1)] & !y.range=[MIN(Y1),MAX(Y1)]
!p.noclip=-1
!p.charsize=8./5.
sep=string(epoch,'(F6.1)')
xtitle='!7a ('+sep+')'
ytitle='!7d'
!c=-9
if not keyword_set(oplot_grid) then $
       PLOT,[X0,X0],[Y0,Y0],/nodata,xstyle=4,ystyle=4 else $   ;POINT AT CENTER
       PLOT,[X0,X0],[Y0,Y0],/nodata,xstyle=5,ystyle=5,/noerase 
!p.charsize=7./5.
if (!d.name eq 'PS') and (keyword_set(size_leg)) then size_leg=size_leg/2.
;
case 1 of
   keyword_set(oplot_grid): begin
      grid2,acen,dcen,ddec,dup/dr,ddn/dr,amin,amax,isw,size_leg=size_leg,/image
      end
   else: begin
      xyouts,.1,.5,ytitle,/normal,size=8./5.,orient=0.   ;was 90.
      xyouts,.4,.1,xtitle,/normal,size=8./5.,orient=0.   ;was 90.
      grid2,acen,dcen,ddec,dup/dr,ddn/dr,amin,amax,isw,size_leg=size_leg
      end
   endcase
!p.noclip=0     ;WAS -1
if keyword_set(stp) then stop,'PLOTSKY>>>'
;if sold gt 0. then sc=sold
ddec=ddec2*2.
if keyword_set(oplot_grid) then begin
   sc=sold & at=at0 & dt=dt0
   endif
!p.color=oldcolor
return
end
