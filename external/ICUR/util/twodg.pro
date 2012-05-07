;*******************************************************************
pro twodg,arr_orig,ax,ay,yfitx,yfity,header=header,interact=interact, $
    helpme=helpme,noiter=noiter,x0=x0,y0=y0,rad=rad,bsub=bsub,pixels=pixels, $
    tvcoords=tvcoords,stp=stp,plt=plt,debug=debug,ndigits=ndigits,col=col, $
    quiet=quiet,scan=scan,width=width,exwid=exwid,nocent=nocent,contin=contin, $
    ncomb=ncomb,noise=noise,clim=clim,nit=nit,fitwidth=fitwidth,wfpc2=wfpc2, $
    numout=numout,prt=prt,auto=auto,id0=id0
common tvcom,pixf,zerr,tvscale,imin,imax,ids,implot,ism,ilog,autos
common grid,sc,atn,dtn,ddec,dr,equinox,acen,dcen,atnp,dtnp,xoffset,yoffset,dss
common dss,xc0,yc0,px,py,xc1,yc1,ap,bp,ac,dc,dssh,astr,dxfudge,dyfudge
COMMON VARS,var1,var2,VAR3,VAR4,var5,psdel,prffit,vrot2
common icurunits,xunits,yunits,title,c1,c2,c3,ch,c4,c5,c6,c7,c8,c9
COMMON COMXY,XCUR,YCUR,ZERR0,RESETSCALE,lu3,ieb
COMMON COM1,H,IK,IFT,NSM,C,NDAT,IFSM,KBLO,H1,ipdv,ihcdev
COMMON COM2,icA,icB,icFH,icFIXT,icISHAPE
common tvcoltab,r,g,b,opcol,ctnum
common wcs,wcs_flag
;
if n_elements(ctnum) eq 0 then ctnum=1
if not keyword_set(wfpc2) then wfpc2=0
wfpc2flag=wfpc2
if n_elements(arr_orig) eq 0 then arr_orig=implot
s0=size(arr_orig)
if s0(0) ne 2 then helpme=1
if keyword_set(helpme) then begin
   print,' '
   print,'* TWODG - 2 dimensional gaussian fit' 
   print,'*  calling sequence: TWODC,arr,ax,ay'
   print,'*     ARR: input 2-D array'
   print,'*     AX,AY: output arrays from Gaussfit'
   print,'* '
   print,'* KEYWORDS:'
   print,'*    AUTO:    if set, use AX,AY instead of interactive input'
   print,'*    CLIM:    delta chi-2, def=2.3'
   print,'*    COL:     color of overplot, def=!p.color'
   print,'*    CONT:    set to loop until right mouse button hit'
   print,'*    EXWID:   extraction slit half width, def=10 pix'
   print,'*    FITWIDTH: set to fit width in stat pass for errors'
   Print,'*    HEADER:  FITS header'
   print,'*    INTERACT: set to fit peaks interactively (3 times)'
   print,'*    NCOMB:   number of combined images, for statistics, def=1'
   print,'*    NDIGITS: controls number of decimal places in output.'
   print,'*    NOCENT:  if set, uses TV position as passed'
   print,'*    NOITER:  do not iterate on image'
   print,'*    NUMOUT:  set to output unannotated position (sets /HMS'
   print,'*    PLT:     1 to plot slices, 2 to oplot profiles, 3 for both'
   print,'*    TVCOORDS: set to mark position on TV display'
   print,'*    X0,Y0,RAD: coordinates of center and radius of source; def RAD=30'
   print,'*              if passed, array is truncated to 2*rad+1'
   print,'*    WFPC2:   set to correct for 34th row error in HST images'
   print,'*    WIDTH:   initial guess at Gaussian width, def=2 bins'
   print,' '
   return
   endif
;
var1=0
if n_elements(stp) eq 0 then stp=0
if keyword_set(interact) then plt=0
xunits='pixels' & yunits='counts'
if keyword_set(numout) then hms=1
if n_elements(header) gt 1 then begin    ;header passed
  if strtrim(strupcase(sxpar(header,'instrume')),2) eq 'WFPC2' then begin
     wfpc2=1
     if n_elements(ncomb) eq 0 then ncomb=fix(sxpar(header,'ncombine'))
     gain=sxpar(header,'atodgain')
     if n_elements(noise) eq 0 then noise=5./gain
     endif
   endif
;
if n_elements(scan) eq 1 then begin
   if scan eq 1 then nscan=5 else nscan=scan
   scan=1
   if n_elements(rad) eq 0 then rad=10
   plt=0
   endif else nscan=1
;
if n_elements(exwid) eq 0 then exwid=10
if (n_elements(ndigits) eq 0) and keyword_set(wfpc2) then ndigits=4
if n_elements(ndigits) eq 0 then ndigits=3
ndigits=ndigits>2
if n_elements(rad) eq 0 then rad=30
if n_elements(width) eq 0 then width=2
width=width>1
if keyword_not_zero(rad) then width=width<(rad/2)
if n_elements(ncomb) eq 0 then ncomb=1
ncomb=ncomb>1
if n_elements(noise) eq 0 then noise=0.
noise=noise>0.
if n_elements(plt) eq 0 then plt=0
;
cwind=!d.window
;
; set up output format
;
if n_elements(sc) eq 0 then sc=-1
if n_elements(dss) eq 0 then dss=0
if n_elements(wcs_flag) eq 0 then wcs_flag=0
if sc eq -1 and (n_elements(dssh) gt 0) then dss=1
if sc le 0. then itp=0 else itp=1            ;use tangent plane projection?
if keyword_set(dss) then itp=1
if keyword_set(notp) then itp=0              ;override T-P
hms=1
case 1 of
   keyword_set(pixels):
   dss: pixels=0 
   itp: pixels=0
   else: pixels=1
   endcase
if pixels then hms=0
pm=' +/-'
case 1 of    ;format FORM1
   keyword_set(hms): case ndigits of
      2: form1= $
"('rad=',i3,'  RA=',i3,i3,F6.2,' +/-',F5.2,'s  DEC=',i3,i3,F5.1,' +/-',F4.1,'""')"
      4: form1= $
"('rad=',i3,'  RA=',i3,i3,F8.4,' +/-',F7.4,'s  DEC=',i3,i3,F7.3,' +/-',F6.3,'""')"
      5: form1= $
"('rad=',i3,'  RA=',i3,i3,F9.5,' +/-',F9.5,'s  DEC=',i3,i3,F8.4,' +/-',F8.4,'""')"
      else: form1= $
"('rad=',i3,'  RA=',i3,i3,F7.3,' +/-',F6.3,'s  DEC=',i3,i3,F6.2,' +/-',F5.2,'""')"
          endcase
   keyword_set(dss) and not itp: form1="('rad=',i3,'  x=',F7.3,', y=',F7.3)"
   itp eq 0: form1="('rad=',i3,'  x=',i4,', y=',i4)"
   itp eq 1: form1="('rad=',i3,'  x=',F7.3,', y=',F7.3)"
   else: form1="('rad=',i3,'  x=',i4,', y=',i4)"
   endcase
case 1 of    ;format FORM2
   keyword_set(hms): case ndigits of
    2: form2= "(F7.2,F8.2,i4,i3,F6.2,' ',F5.2,' ',i3,i3,F5.1,' ',F4.1,I3,2F7.2)"
    4: form2= "(F7.2,F8.2,i4,i3,F8.4,' ',F7.4,' ',i3,i3,F7.3,' ',F6.3,I3,2f7.2)"
    5: form2= "(F7.2,F8.2,i4,i3,F9.5,' ',F9.5,' ',i3,i3,F8.4,' ',F8.4,I3,2f7.2)"
  else: form2= "(F7.2,F8.2,i3,i3,F7.3,' ',F6.3,' ',i3,i3,F6.2,' ',F5.2,I3,2f7.2)"
          endcase
   keyword_set(dss) and not itp: form2="(i3,' ',F7.3,' ',F7.3)"
   itp eq 0: form2="(i3,' ',i4,' ',i4)"
   itp eq 1: form2="(i3,' ',F7.3,' ',F7.3)"
   else: form2="(i3,' ',i4,' ',i4)"
   endcase
;
; statistics setups
if n_elements(nit) eq 0 then nit=10
nit=nit>3
chisq=fltarr(nit*2+1)
if keyword_set(fitwidth) and (n_elements(clim) eq 0) then clim=2.3  ;2 params
if n_elements(clim) eq 0 then clim=1.0    ;1 parameters
;
if n_params() lt 3 then tvcoords=1
if (n_elements(ax) ne 1) then tvcoords=1
if (n_elements(ay) ne 1) then tvcoords=1
;
echo=0
if n_elements(id0) eq 0 then id0=''
if keyword_set(auto) then begin
   tvcoords=0
   npts=n_elements(ax)
print,npts
   ax0=ax & ay0=ay
   if n_elements(prt) eq 0 then prt=1
   contin=1
   endif
if keyword_set(prt) then begin
   if ifstring(prt) then outfile=prt else outfile='twodg'
   if strlen(get_ext(outfile)) eq 0 then outfile=outfile+'.lst'
   openw,lu,outfile,/get_lun
   printf,lu,' TWODG output   run at ',systime(0)
   printf,lu,' '
   echo=1
   endif else lu=-1
;
iwfpc2loop=1
if wfpc2 eq 2 then wfpc2=0               ; first pass only
wfpc2loop:            ;*****************
;
arr0=arr_orig
nx=s0(1) & ny=s0(2)
;
if keyword_set(wfpc2) then begin    ;PASP 111, 1095
   wfpc2_photcor,arr0
   if ny ne 800 then print,' WARNING: HST image size should be 800'
   j=dindgen(ny+1)+1.
   p=(j+3.70) mod 34.1333
   ycorr=j
   k=where(p le 0.5,nk)
   if nk gt 0 then ycorr(k)=j(k)+0.06*(0.25-p(k))
   k=where(p gt 0.5,nk)
   if nk gt 0 then ycorr(k)=j(k)+0.0008920D0*(p(k)-17.3167)
   ycorr=float(ycorr-1.)    ;true detector Y values
   endif
;
if not keyword_set(quiet) and (iwfpc2loop eq 1) then begin
   printf,lu,' Fit Parameters:
   printf,lu,'    SLICE WIDTH:     ',rad,  '    READ NOISE:      ',noise
   printf,lu,'    IMAGES COMBINED: ',ncomb,'    Delta CHI-2:     ',clim
   if not keyword_set(fitwidth) then printf,lu,'    Profile width fixed'
   if echo then begin
      print,' Fit Parameters:
      print,'    SLICE WIDTH:     ',rad,  '    READ NOISE:      ',noise
      print,'    IMAGES COMBINED: ',ncomb,'    Delta CHI-2:     ',clim
      if not keyword_set(fitwidth) then print,'    Profile width fixed'
      endif
   endif
;
iloop=-1
loop:    ;*******************************************************************
;
iloop=iloop+1
zerr=0
if n_elements(id0) eq 1 then id=id0(0) else id=''
if keyword_set(auto) then begin
   print,'AUTO:',iloop,npts
   if iloop ge (npts-1) then zerr=4      ;exit loop if zerr>1
   if n_elements(id0) ge iloop then id=strtrim(id0(iloop),2)+' ' else id=''
   endif
arr=arr0
nx=s0(1) & ny=s0(2)
if keyword_set(contin) then zc=' -  middle or right to end' else zc=' '
;
if n_elements(x0) eq 0 then x0=nx/2
if n_elements(y0) eq 0 then y0=ny/2
xi=-x0 & yi=-y0
;
if keyword_set(tvcoords) then begin
   if iwfpc2loop ne 2 then begin
      zoom=pixf(!d.window,2)
      xi=pixf(!d.window,3) 
      yi=pixf(!d.window,4) 
      print, 'Mark position using cursor'
      tvp,arr,x0,y0,v,/pix,/noprompt
      zerr=!err
      if zerr gt 1 then goto,retn
      if not keyword_set(quiet) then print,x0,y0
      nx=nx/zoom & ny=ny/zoom
      arr=arr(xi:xi+nx-1,yi:yi+ny-1)
      x0=x0-xi & y0=y0-yi
      endif
   endif   ;tvcoords
if keyword_set(auto) then begin
   x0=ax0(iloop) & y0=ay0(iloop)
print,x0,y0
   endif
;
arr1=arr
for iscan=0,nscan-1 do begin
   s=size(arr1)
   nx=s(1) & ny=s(2)
   xstart=0 & ystart=0
   if iscan gt 0 then rad=rad+3
   if keyword_not_zero(rad) then begin
      dia=fix(2*rad)
      xi=fix(x0-rad)>0
      yi=fix(y0-rad)>0
      arr=arr1(xi:(xi+dia)<(nx-1),yi:(yi+dia)<(ny-1))
      xstart=xi
      ystart=yi
      endif
;
s=size(arr)
nx=s(1) & ny=s(2)
marr=median(arr)
if keyword_set(bsub) then arr=arr-marr
x=indgen(nx) & y=indgen(ny)
if keyword_set(wfpc2) then y=ycorr(yi:yi+ny-1)-yi
cx=total(arr,2) & cy=total(arr,1)
if not keyword_set(nocent) then begin
   xc=total(x*cx)/total(cx)
   yc=total(y*cy)/total(cy)
   endif else begin
   xc=nx/2. & yc=ny/2.
   noiter=1
   endelse
if keyword_set(noiter) then goto,ret1
;
; truncate array in X
dx=nx/4
dy=ny/4
x1=fix(xc+.5)-dx
z1=arr(x1>0:(x1+2*dx)<(nx-1),*)
cy=total(z1,1)
yc=total(y*cy)/total(cy)
y1=fix(yc+.5)-dy
z1=arr(*,y1>0:(y1+2*dy<ny-1))
cx=total(z1,2)
xc=total(x*cx)/total(cx)
;
ret1:
xc=xc+xi
yc=yc+yi
;
if not keyword_set(quiet) and (iscan eq 0) then begin
   if keyword_set(wfpc2) then printf,lu,'****    Corrected for row 34 error    ****'
   printf,lu,' Centroids: x,y=',xc+0.5,yc+0.5
   printf,lu,' '
   if echo then begin
      if keyword_set(wfpc2) then print,'****    Corrected for row 34 error    
      print,' Centroids: x,y=',xc+0.5,yc+0.5
      print,' '
      endif
   endif
;
wold=!d.window
if plt gt 0 then begin
   newwindow,title='TwoDG'
   setxy & svp
;   gc,13
   endif
;
; sum in X to find Y position    (First fit)
;
yslice=float(total(arr((xc-xi-exwid)>0:(xc-xi+exwid)<(nx-1),*),1))
xx0=fix(xc-xi)>3
amp=yslice(xx0-3:xx0+3)
xx0=(where(yslice eq max(amp)))(0)
amp=yslice(xx0)-median(yslice)
a=[amp>0,xx0,width,median(yslice),0,0]
if keyword_set(interact) then begin
   win=!d.window
   window,4 & gc,ctnum
   setxy & svp
   plot,float(x),yslice,ps=10
   icfit2,float(x),yslice,0,yfit=yfit,/notitle
   par=ica
   a(1)=par(4) & a(2)=par(5)
   reset_screen
   wset,win
   endif else yfit=gaussfit(float(x),yslice,a,order=2)   ;;;;;;;;;;;;;;FIT
;
ibomb=0
if (a(1) lt 1) or (a(1) gt (ny-2)) then goto,bomb
a(2)=(abs(a(2))>0.5)
if a(2) gt ny/2 then goto,bomb
;
; sum in Y to get X               (second fit)
;
xslice=total(arr(*,(floor(a(1)-a(2))>0):ceil(a(1)+a(2))<(ny-1)),2)
xx0=fix(xc-xi)>3
amp=xslice(xx0-3:xx0+3)
xx0=(where(xslice eq max(amp)))(0)
amp=xslice(xx0)-median(xslice)
ax=[amp>0,xx0,a(2)*2.,median(xslice),0,0]
xs=xslice
if keyword_set(interact) then begin
   win=!d.window
   wset,4  & gc,ctnum
   setxy & svp
   plot,y,xs,ps=10
   icfit2,y,xs,0,yfit=yfitx,/notitle
   p1=icb(0)
   par=ica
   wset,win
   reset_screen
   endif else begin
;
   yfitx=gaussfit(float(y),xslice,ax,order=2)      ;***********************XFIT
   ibomb=1
   if (ax(1) lt 1) or (ax(1) gt (nx-2)) then goto,bomb
   ax(2)=abs(ax(2))
   if ax(2) gt nx/2 then goto,bomb
   ax(1)=ax(1)+0.5
   par=[ax(3:4),0,ax(0:2)]
   par(4)=par(4)-0.5
   ifx=2
   icfit4,0,y,xs,ab,par,ifx,/quiet
   p1=0
   endelse
parc=par     ;best fit
;
; statistics
;
eb=sqrt(abs(xslice)+noise*noise)/sqrt(ncomb)     ;root-N statistics
;knf=where(finite(eb) eq 0,nkbf)
;if nkbf gt 0 then eb(knf)=10.*max(eb)
sig=(xslice-yfitx)/eb
chi2=total(sig*sig)
dof=n_elements(sig)-4
chi2r=chi2/float(dof)
;print,' Prob=',chisqr_pdf(chi2,dof)
if keyword_set(fitwidth) then ifx=[2,4] else ifx=[2,4,5]
par0=par
for j=0,2*nit do begin
   par=par0
   par(4)=par0(4)+(j-nit)/float(nit)
   xs=xslice
   icfit4,0,y,xs,ab,par,ifx,/quiet
   sig=(xslice-xs)/eb
   chisq(j)=total(sig*sig)
   endfor
c=chisq-min(chisq)
k=where(c le 1.,nk)
kmin=(where(c le 1.e-5))(0)
k1=(1.-xindex(reverse(c((k(0)-1)>0:kmin)),clim))+k(0)-1
k2=kmin+xindex(c(kmin:(k(nk-1)+1)<(n_elements(c)-1)),clim)
dxe=(k2-k1)/2.
;
ax1=parc(4)+0.5
ax(0)=parc(3) & ax(2)=parc(5)
if keyword_set(rad) then ax1=ax1+pixf(cwind,3)
case 1 of
   ax(0) ge 1.e6: fmth='(F12.0)'
   ax(0) ge 1.e5: fmth='(F7.0)'
   ax(0) ge 1.e4: fmth='(F7.1)'
   ax(0) ge 1.e3: fmth='(F7.2)'
   ax(0) ge 1.e2: fmth='(F6.2)'
   else: fmth='(F5.2)'
   endcase
zxx=ax1+xi
if not keyword_set(quiet) then begin
   printf,lu,' X: ',string(zxx,'(F8.3)'),' +/- ',string(dxe,'(F6.3)'), $
   ' Width= ',string(ax(2),'(F5.2)'),' Height= ',string(ax(0),fmth), $
   ' Red. Chi^2 = ',string(chi2r,'(F6.2)')
   if echo then print,' X: ',string(zxx,'(F8.3)'),' +/- ', $
      string(dxe,'(F6.3)'), $
      ' Width= ',string(ax(2),'(F5.2)'),' Height= ',string(ax(0),fmth), $
      ' Red. Chi^2 = ',string(chi2r,'(F6.2)')
   endif
ax1=ax1+xi
;
if (plt eq 1) or (plt eq 3) then begin
   !p.position=[.15,.15,.9,.5]
   plot,y,xslice,ps=10
   oplot,y(p1:*),yfitx,linestyle=1
   xyouts,.62,.47,'!6 X fit  !7 v!Dm!U2!N='+string(chi2r,'(F5.2)'),charsize=1.4,/norm
   xyouts,.6,.43,'!6 '+string(ax1,'(F8.3)')+' +/- '+string(dxe,'(F6.3)'),/norm
   endif
if stp eq 2 then stop
;
; sum in X to get Y                        Third fit
;
yslice=total(arr((fix(ax(1)-ax(2)+0.5)>0)<(nx-1):(ax(1)+ax(2))<(nx-1),*),1)
xx0=fix(xc-xi)>3
amp=yslice(xx0-3:xx0+3)
xx0=(where(yslice eq max(amp)))(0)
amp=yslice(xx0)-median(yslice)
ay=[amp>0,xx0,a(2)*2.,median(yslice),0,0]
xs=yslice
if keyword_set(interact) then begin
   win=!d.window
   wset,4 & gc,ctnum
   setxy & svp
   plot,x,xs,ps=10
   icfit2,x,xs,0,yfit=yfity,/notitle
   p1=icb(0)
   par=ica
   wset,win
   reset_screen
   endif else begin
;
   yfity=gaussfit(float(x),yslice,ay,order=2)               ;****YFIT
   ibomb=2
   if (ay(1) lt 1) or (ay(1) gt (ny-2)) then goto,bomb
   ay(2)=abs(ay(2))
   if ay(2) gt ny/2 then goto,bomb
   ay(1)=ay(1)+0.5
   par=[ay(3:4),0,ay(0:2)]
   par(4)=par(4)-0.5
   ifx=2
   icfit4,0,y,xs,ab,par,ifx,/quiet
   p1=0
   endelse
parc=par     ;best fit
;
; statistics
   eb=sqrt(abs(xslice)+noise*noise)/sqrt(ncomb)     ;root-N statistics
   sig=(yslice-yfity)/eb
   chi2=total(sig*sig)
   dof=n_elements(sig)-4
   chi2r=chi2/float(dof)
;print,' Prob=',chisqr_pdf(chi2,dof)
if keyword_set(fitwidth) then ifx=[2,4] else ifx=[2,4,5]
par0=par
for j=0,2*nit do begin
   par=par0
   par(4)=par0(4)+(j-nit)/float(nit)
   xs=yslice
   icfit4,0,x,xs,ab,par,ifx,/quiet
   sig=(yslice-xs)/eb
   chisq(j)=total(sig*sig)
   endfor
c=chisq-min(chisq)
k=where(c le 1.,nk)
kmin=(where(c le 1.e-5))(0)
k1=(1.-xindex(reverse(c((k(0)-1)>0:kmin)),clim))+k(0)-1
k2=kmin+xindex(c(kmin:(k(nk-1)+1)<(n_elements(c)-1)),clim)
dye=(k2-k1)/2.
;
ay(1)=parc(4)+0.5
ay(0)=parc(3) & ay(2)=parc(5)
if keyword_set(rad) then ay(1)=ay(1)+pixf(cwind,4)
case 1 of
   ay(0) ge 1.e6: fmth='(F12.0)'
   ay(0) ge 1.e5: fmth='(F7.0)'
   ay(0) ge 1.e4: fmth='(F7.1)'
   ay(0) ge 1.e3: fmth='(F7.2)'
   ay(0) ge 1.e2: fmth='(F6.2)'
   else: fmth='(F5.2)'
   endcase
zyy=ay(1)+yi
if not keyword_set(quiet) then begin
   printf,lu,' Y: ',string(zyy,'(F8.3)'),' +/- ',string(dye,'(F6.3)'), $
   ' Width= ',string(ay(2),'(F5.2)'),' Height= ',string(ay(0),fmth), $
   ' Red. Chi^2 = ',string(chi2r,'(F6.2)')
   if echo then print,' Y: ',string(zyy,'(F8.3)'),' +/- ', $
      string(dye,'(F6.3)'), $
      ' Width= ',string(ay(2),'(F5.2)'),' Height= ',string(ay(0),fmth), $
      ' Red. Chi^2 = ',string(chi2r,'(F6.2)')
   endif
ax(1)=ax1
ay(1)=ay(1)+yi
;
if (plt eq 1) or (plt eq 3) then begin
   !p.position=[.15,.6,.9,.95]
   plot,x,yslice,ps=10,/noerase,xtitle=''   ;,xtickname=strarr(30)+''
   oplot,x(p1:*),yfity,linestyle=1
   xyouts,.62,.92,'!6 Y fit  !7 v!Dm!U2!N='+string(chi2r,'(F5.2)'),charsize=1.4,/norm
   xyouts,.6,.88,'!6 '+string(ay(1),'(F8.3)')+' +/- '+string(dye,'(F6.3)'),/norm
   ;
   reset_screen
   wset,wold
   endif
if stp eq 2 then stop
;
x000=ax(1) & y000=ay(1)       ;observed position
if keyword_set(wfpc2) then begin
   wfpc2_distort,ax(1),ay(1),xin,yin
   x000=xin & y000=yin
   ax(1)=xin & ay(1)=yin       ;true (corrected) position
   endif
case 1 of
   itp and wcs_flag: xy2ad,ax(1),ay(1),astr,xx,yy
   keyword_set(dss) and itp: gsssxyad,astr,ax(1),ay(1),xx,yy
   itp: begin
      xytad,xx,yy,ax(1)-s0(1)/2.,ay(1)-s0(2)/2.       
      xx=xx*!radeg & yy=yy*!radeg
      end
   else: begin     ;pixels
      xx=ax(1) & yy=ay(1)
      end
   endcase
if keyword_set(hms) then begin
   degtohms,xx,rah,ram,ras
   degtodms,yy,dd,dm,ds
   scale=sc*3600.*!radeg     ;arcsec/pixel
   me=(dxe+dye)/2.*scale     ;mean error in arcsec
   mes=me/cos(yy/!radeg)/15.
   zp=id+string(form=form1,rad,rah,ram,ras,mes,dd,dm,ds,me)
   if keyword_set(numout) then $
      zp=id+string(form=form2,zxx,zyy,rah,ram,ras,mes,dd,dm,ds,me,rad,x000,y000)
   printf,lu,zp
   printf,lu,' '
   if echo then begin
      zp=id+string(form=form1,rad,rah,ram,ras,mes,dd,dm,ds,me)
      if keyword_set(numout) then $
      zp=id+string(form=form2,zxx,zyy,rah,ram,ras,mes,dd,dm,ds,me,rad,x000,y000)
      print,zp
      print,' '
      endif
   endif 
;
if (plt eq 2) or (plt eq 3) then begin
   oldwindow
   if keyword_set(tvcoords) then begin
      !p.position=[0.,0.,1.,1.]
      setxy,0,!d.x_size-1,0,!d.y_size-1
      plot,[0,!d.x_size-1],[0,!d.y_size-1],/nodata,/noerase,xstyle=5,ystyle=5
      npx=n_elements(yfitx) & npy=n_elements(yfity)
      xv1=yfitx/2./(ax(0)+ax(3))*!d.x_size
      yv1=yfity/2./(ay(0)+ay(3))*!d.y_size
      xv2=rebin(xv1,npx*zoom,/sample) & yv2=rebin(yv1,npy*zoom,/sample)
      xoff=(xstart)>0 & if xoff gt 0 then xv2=[intarr(xoff*zoom),xv2]
      yoff=(ystart)>0 & if yoff gt 0 then yv2=[intarr(yoff*zoom),yv2]
      oplot,indgen(!d.x_size),xv2,psym=10,color=col
      oplot,yv2,findgen(!d.y_size),psym=10,color=col
      reset_screen
      endif else begin
      gc,13
      setxy
      !p.position=[.1,.2,.5,.9]
      plot,x+xi,xslice & oplot,x+xi,yfitx,color=1
      !p.position=[.55,.2,.95,.9]
      plot,y+yi,yslice,/noerase & oplot,y+yi,yfity,color=1
      if !d.name eq 'X' then wshow
      svp
      endelse
   endif
;
ax=[ax,xc] & ay=[ay,yc]
ax(5)=xc & ay(5)=yc   ; put centroids in array
;
if keyword_set(stp) then stop,'TWODG>>>'
if keyword_set(interact) then wdelete,4
goto,retn
;
;***********************************************************
;
bomb:
print,'*** centroid out of bounds - returning'
if n_elements(ay) eq 0 then ay=intarr(6)-99
if n_elements(ax) eq 0 then ax=intarr(6)-99
case ibomb of
   0: print,a(1:2)
   1: print,ax(1:2)
   else: print,ay(1:2)
   endcase
if keyword_set(stp) then stop,'TWODG>>>'
if plt gt 0 then oldwindow
;
   retn:
   endfor    ;iscan
if (wfpc2flag eq 2) and (iwfpc2loop eq 1) and (zerr eq 1) then begin
   wfpc2=1
   iwfpc2loop=2
   goto,wfpc2loop     ;loop to do with row 34 correction
   endif else iwfpc2loop=1
if keyword_set(contin) and (zerr le 1) then begin
   wait,0.2
   goto,loop
   endif
if lu ne -1 then begin
   free_lun,lu
   print,' Output in ',outfile
   endif
return
end
