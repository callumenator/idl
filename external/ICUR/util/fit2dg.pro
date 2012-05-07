;*******************************************************************
pro fit2dg,arr_orig,afit0,afite0,yfitx,yfity,header=header,interact=interact, $
    helpme=helpme,noiter=noiter,x0=x0,y0=y0,rad=rad,bsub=bsub,pixels=pixels, $
    tvcoords=tvcoords,stp=stp,plt=plt,debug=debug,ndigits=ndigits,col=col, $
    quiet=quiet,scan=scan,width=width,exwid=exwid,nocent=nocent,contin=contin, $
    ncomb=ncomb,noise=noise,clim=clim,nit=nit,fitwidth=fitwidth,wfpc2=wfpc2, $
    numout=numout,prt=prt,auto=auto,id0=id0,lorent=lorent,gauss=gauss, $
    tilt=tilt,noprt=noprt,zout=zout, $
    override_34=override_34,test=test,nodistort=nodistort
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
common twodfitcom,z,fit,zdiff,sigim,afit,afite
;
if n_elements(ctnum) eq 0 then ctnum=1
if not keyword_set(wfpc2) then wfpc2=0
if n_elements(gauss) eq 0 then lorent=1
if not keyword_set(quiet) then tprt=1 else tprt=0
wfpc2flag=wfpc2
if (n_elements(arr_orig) eq 0) and (n_elements(implot) gt 0) $
   then arr_orig=implot
s0=size(arr_orig)
ztest=''
;
;if (s0(0) ne 2) and not keyword_set(auto) then helpme=1
if keyword_set(helpme) then begin
   print,' '
   print,'* FIT2DG - 2 dimensional gaussian fit using MPFIT2DGAUSS' 
   print,'*  calling sequence: FIT2DG,arr,afit,afite'
   print,'*     ARR: input 2-D array'
   print,'*     AFIT,AFITE: fit parameters and errors from MPFIT2D'
   print,'* '
   print,'* KEYWORDS:'
   print,'*    AUTO:    if set, use AX,AY instead of interactive input'
   print,'*    CLIM:    delta chi-2, def=2.3'
   print,'*    COL:     color of overplot, def=!p.color'
   print,'*    CONT:    set to loop until right mouse button hit'
   print,'*    EXWID:   extraction slit half width, def=10 pix'
   print,'*    FITWIDTH: set to fit width in stat pass for errors'
   print,'*    GAUSS:   set to use Gaussian in fit, def=Lorentzian profile'
   Print,'*    HEADER:  FITS header'
   print,'*    NCOMB:   number of combined images, for statistics, def=1'
   print,'*    NDIGITS: controls number of decimal places in output.'
   print,'*    NOCENT:  if set, uses TV position as passed'
   print,'*    NOITER:  do not iterate on image'
   print,'*    NUMOUT:  set to output unannotated position'
   print,'*    TVCOORDS: set to mark position on TV display'
   print,'*    X0,Y0,RAD: coordinates of center and radius of source; def RAD=20'
   print,'*              if passed, array is truncated to 2*rad+1'
   print,'*    WFPC2:   set to correct for 34th row error in HST images'
   print,'*    WIDTH:   initial guess at Gaussian width, def=2 bins'
   print,' '
   return
   endif
;
var1=0
if n_elements(stp) eq 0 then stp=0
xunits='pixels' & yunits='counts'
if n_elements(header) gt 1 then begin    ;header passed
  if strtrim(strupcase(sxpar(header,'instrume')),2) eq 'WFPC2' then begin
     wfpc2=1
;wcs_flag=1    ;???
     if n_elements(ncomb) eq 0 then ncomb=fix(sxpar(header,'ncombine'))
     gain=sxpar(header,'atodgain')
     if n_elements(noise) eq 0 then noise=5./gain
     endif
   endif
;
nscan=1
;
if n_elements(exwid) eq 0 then exwid=10
if (n_elements(ndigits) eq 0) and keyword_set(wfpc2) then ndigits=4
if n_elements(ndigits) eq 0 then ndigits=3
ndigits=ndigits>2
if n_elements(rad) eq 0 then rad=20
if n_elements(width) eq 0 then width=2
width=width>1
if keyword_not_zero(rad) then width=width<(rad/2)
if n_elements(ncomb) eq 0 then ncomb=1
ncomb=ncomb>1
if n_elements(noise) eq 0 then noise=0.
noise=noise>0.
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
f95='(F10.5)'
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
    2: begin
         form2= "(F6.2,F7.2,i3,i3,F6.2,F5.2,i4,i3,F5.1,F4.1,I3,2F7.2)"
         form3= "(F6.2,F5.2,F7.2,F5.2,F6.2,F5.2,F5.1,F4.1,I3)"
         form4= "(F8.4,F7.4,F9.4,F7.4,F6.2,F5.2,F5.1,F4.1,I3,F8.4,F7.4)"
         end
    4: begin
         form2= "(F6.2,F7.2,i3,i3,F8.4,F7.4,i4,i3,F7.3,F6.3,I3,2F7.2)"
         form3= "(F6.2,F5.2,F7.2,F5.2,F8.4,F7.4,F7.3,F6.3,I3)"
         form4= "(F9.4,F7.4,F9.4,F7.4,F8.4,F7.4,F7.3,F6.3,I3,F9.4,F7.4)"
         end
    5: begin
         form2= "(F6.2,F7.2,i3,i3,F9.5,F9.5,i4,i3,F8.4,F8.4,I3,2f7.2)"
         form3= "(F6.2,F5.2,F7.2,F5.2,F9.5,F9.5,F8.4,F8.4,I3)"
         form4= "(F9.4,F7.4,F9.4,F7.4,F9.5,F9.5,F8.4,F8.4,I3,F9.4,F7.4)"
         end
    else: begin
         form2= "(F6.2,F7.2,i3,i3,F7.3,F6.3,i4,i3,F6.2,F5.2,I3,2f7.2)"
         form3= "(F6.2,F5.2,F7.2,F5.2,F7.3,F6.3,F6.2,F5.2,I3)"
         form4= "(F8.4,F7.4,F9.4,F7.4,F7.3,F6.3,F6.2,F5.2,I3,F8.8,F7.4)"
         end
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
if keyword_set(fitwidth) and (n_elements(clim) eq 0) then clim=2.3  ;2 params
if n_elements(clim) eq 0 then clim=1.0    ;1 parameters
;
if keyword_set(auto) then begin
   if n_elements(afit0) ne 1 then begin
      if n_elements(x0) eq 0 then auto=0 else afit0=x0
      endif
   if n_elements(afite0) ne 1 then begin
      if n_elements(y0) eq 0 then auto=0 else afite0=y0
      endif
   endif
;
if n_params() lt 3 then tvcoords=1
if (n_elements(afit0) ne 1) then tvcoords=1
if (n_elements(afite0) ne 1) then tvcoords=1
;
echo=0
if n_elements(id0) eq 0 then id0=''
if keyword_set(auto) then begin
   ax=afit0 & ay=afite0
   tvcoords=0
   npts=n_elements(ax)
   ax0=ax & ay0=ay
   if n_elements(prt) eq 0 then prt=1
   contin=1
   endif
if keyword_set(noprt) then prt=0
if keyword_set(prt) then begin
   if ifstring(prt) then begin
      outfile=prt 
      prt=1
      endif else outfile='fit2dg'
   if prt gt 1 then lun=lu
   if strlen(get_ext(outfile)) eq 0 then outfile=outfile+'.lst'
   openw,lu,outfile,/get_lun
   printf,lu,' FIT2DG output   run at ',systime(0)
   printf,lu,' '
   echo=1
   endif else lu=-1
;
iwfpc2loop=1
if wfpc2 eq 2 then wfpc2=0               ; first pass only
;
wfpc2loop:            ;*****************
;
arr0=arr_orig
nx=s0(1) & ny=s0(2)
;
if keyword_set(test) then begin
;   print,'WFPCloop: ',wfpc2
;   echo=1
   dprt=1
;   stp=2
   endif
;
if keyword_set(wfpc2) and not keyword_set(override_34) then begin ;PASP 111, 1095
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
   if keyword_set(wfpc2) and not keyword_set(override_34) then $
      printf,lu,'****    Corrected for row 34 error    ****'
   if echo then begin
      print,' Fit Parameters:
      print,'    SLICE WIDTH:     ',rad,  '    READ NOISE:      ',noise
      print,'    IMAGES COMBINED: ',ncomb,'    Delta CHI-2:     ',clim
      if not keyword_set(fitwidth) then print,'    Profile width fixed'
   if keyword_set(wfpc2) and not keyword_set(override_34) then $
      printf,lu,'****    Corrected for row 34 error    ****'
      endif
   endif
;
iloop=-1
loop:    ;*******************************************************************
;
iloop=iloop+1
zerr=0
if n_elements(id0) eq 1 then id=string(id0(0))+' ' else id=''
if keyword_set(auto) then begin
   ;print,'AUTO:',iloop,npts
   if iloop ge (npts-1) then zerr=4      ;exit loop if zerr>1
   if n_elements(id0) gt iloop then id=strtrim(id0(iloop),2)+' ' else id=''
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
      endif
   endif   ;tvcoords
if keyword_set(auto) then begin
   x0=ax0(iloop) & y0=ay0(iloop)
;print,x0,y0
   endif
;
s=size(arr)
nx=s(1) & ny=s(2)
xstart=0 & ystart=0
;
s=size(arr)
nx=s(1) & ny=s(2)
;
twodfit,arr,x0,y0,afit,aefit,chisqr,rad=rad,ycorr=ycorr,lorent=lorent, $
   wfpc2=wfpc2,prt=tprt,lun=lun,tilt=tilt
afit0=afit & afite0=afite
xc=afit(4) & yc=afit(5)>3                       ;+0.5    ;do not add 1/2 pixel
xce=aefit(4) & yce=aefit(5)
zcts=long(total(arr(xc-3:xc+3,yc-3:yc+3)-afit(0)))   ;approx # of counts
;
if not keyword_set(quiet) then begin
   if echo then begin
      print,' Centroids: x,y=',xc,yc
      print,' '
      endif
   endif
;
if stp eq 2 then stop
;
zxx=xc & zyy=yc       ;observed position
if keyword_set(wfpc2) then begin
   if keyword_set(nodistort) then begin
      wfpc2_distort,400,400,xin,yin
      xc=xc-400+xin & yc=yc-400+yin    ;undistorted but shifted
      endif else begin
      wfpc2_distort,xc,yc,xin,yin,prt=dprt
      x000=xin & y000=yin
      xc=xin & yc=yin       ;true (corrected) position
      endelse
   endif
ztest=ztest+' '+string(zxx,F95)+string(zyy,F95)+string(xc,F95)+string(yc,F95)
;if keyword_set(test) then print,' ITP, WCS_FLAG:',itp,wcs_flag
case 1 of
   itp and wcs_flag: xy2ad,xc,yc,astr,xx,yy
   keyword_set(dss) and itp: gsssxyad,astr,xc,yc,xx,yy
   itp: begin
      xytad,xx,yy,xc-s0(2)/2.,yc-s0(2)/2.       
      xx=xx*!radeg & yy=yy*!radeg
      end
   else: begin     ;pixels
      xx=xc & yy=yc
      end
   endcase
;
if keyword_set(hms) then begin
   degtohms,xx,rah,ram,ras
   degtodms,yy,dd,dm,ds
   scale=sc*3600.*!radeg     ;arcsec/pixel
   me=(aefit(4)+aefit(5))/2.*scale     ;mean error in arcsec
   mes=me/cos(yy/!radeg)/15.
   if not keyword_set(numout) then numout=0
   case numout of
      1: zp=strmid(id+'   ',0,3)+ $
         string(form=form2,zxx,zyy,rah,ram,ras,mes,dd,dm,ds,me,rad,x000,y000) $
         +' '+string(zcts<9999,'(I4)')
      2: zp=strmid(id+'   ',0,3)+ $
         string(form=form3,zxx,xce,zyy,yce,ras,mes,ds,me,rad) $
         +'  '+string(zcts<99999L,'(I5)')
      3: zp=strmid(id+'   ',0,3)+' '+ $
         string(form=form4,zxx,xce,zyy,yce,ras,mes,ds,me,rad) $
         +'  '+string(zcts<99999L,'(I5)')
      else: zp=strmid(id+'   ',0,3)+ $
         string(form=form1,rad,rah,ram,ras,mes,dd,dm,ds,me)
      endcase
   printf,lu,zp
   zout=zp
   if echo then begin
      print,zp
      print,' '
      endif
   endif 
;
if keyword_set(stp) then stop,'FIT2DG>>>'
goto,retn
;
;***********************************************************
;
   retn:
;
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
if keyword_set(test) then test=ztest
return
end
