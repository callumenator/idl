;**********************************************************************
pro apphot,d,x,y,net,enet,nbins,helpme=helpme,radius=radius,annulus=annulus, $
    off=off,stp=stp,cont=cont,gap=gap,out=out,noplt=noplt,hcpy=hcpy,prt=prt, $
    title=title,scan=scan,filter=filter,nocentrd=nocentrd,nofilter=nofilter, $
    medfilt=medfilt,auto=auto,rcent=rcent,mark=mark,nodisplay=nodisplay, $
    numout=numout,header=header,wfpc2=wfpc2,quiet=quiet,maxbiter=maxbiter, $
    skyoffset=skyoffset,zout=zout,apcorf=apcorf,ofmt=ofmt,pixels=pixels
common ins,v0,v1,v2,u0,hv,hv1,hv2,hu,c1r,c1d,cr,cd,roll,snfact
common tvcom,pixf,zerr,tvscale,imin,imax,idl,implot,ism,ilog,autos
common grid,sc,atn,dtn,ddec,dr,equinox,acen,dcen,atnp,dtnp,xoffset,yoffset,dss
common dss,xc,yc,px,py,xc1,yc1,ap,bp,ac,dc,dssh,astr,dxf,dyf
common fullimage,imsave,ximage
common wcs,wcs_flag
common rosattimes,tstart,tstop,ontime,setdelay,t0,obt1,obt2,gmt1,gmt2,jdref, $
       sczero,bcappl
common apphot,aprad,nc,enc,bc,ebc
;
if n_elements(maxbiter) eq 0 then maxbiter=16
if n_elements(skyoffset) eq 0 then skyoffset=0
if n_elements(ofmt) eq 0 then ofmt=0
if ofmt eq 1 then quiet=1
irad=1
;
if keyword_set(helpme) then begin
   print,' '
   print,'* apphot  --  extract counts in circular aperture
   print,'* calling sequence:   APPHOT,image,x,y,cts,ects'
   print,'*     CTS,ECTS: output counts and error'
;   print,'*   NBINS: number of pixels measured'
   print,'*     X,Y: center for remote call'
   print,'* '
   print,'* KEYWORDS:'
   print,'*    ANNULUS: width of background annulus; def=20'
   print,'*    FILTER: value in sigma of background filter, def=3'
   print,'*    GAP:     gap between source and background regions, def=5'
   print,'*    HEADER:  header containing photometric calibration'
   print,'*    RADIUS: radius of extraction box (pixels); def=5'
   print,'*    RCENT:   radius of centroiding box, def=7<(radius+2)'
   print,'*    SCAN:   equivalent RAD=2+indgen(scan), /scan ->15 '
   print,'*    MAXBITER:  maximum number of background iterations, def=',maxbiter
   print,'*    MEDFILT:  use median-filtered background '
   print,'*    NOCENTRD: set to use marked position, otherwise centroid on peak' 
   print,'*    NOFILTER: set to turn off background filtering'
   print,'*    SKYOFFSET: mean sky offset, def=0'
   print,'*    OUT:     send output to file, def=apphot.lst'
   print,' '
   return
   endif
;
if not keyword_set(stp) then stp=0
if not keyword_set(quiet) then quiet=0
if n_elements(pixf) eq 0 then tvinitpixf
if n_elements(sc) eq 0 then sc=-1
if n_elements(dss) eq 0 then dss=0
if n_elements(wcs_flag) eq 0 then wcs_flag=0
if sc eq -1 and (n_elements(dssh) gt 0) then dss=1
if sc le 0. then itp=0 else itp=1            ;use tangent plane projection?
if keyword_set(dss) then itp=1
if keyword_set(pixels) then itp=0              ;override T-P
if n_elements(snfact) eq 0 then snfact=1.
if snfact le 0. then snfact=1.
if n_elements(scan) eq 1 then begin
   if scan le 1 then scan=15
   scan=(scan>2)<50
   if n_elements(radius) eq 1 then r0=radius else r0=2
   radius=r0+indgen(scan)
   endif
if keyword_set(nofilter) then filter=-1 else begin
   if n_elements(filter) eq 0 then filter=3. 
   if n_elements(filter) eq 1 then filter=filter>3. 
   endelse
;
if (n_elements(wfpc2) eq 1) and (n_elements(header) eq 0) then wfpc2=0
if (n_elements(wfpc2) eq 0) and (n_elements(header) gt 0) then begin
   if strtrim(strupcase(sxpar(header,'instrume')),2) eq 'WFPC2' then wfpc2=1
   if n_elements(rcent) eq 0 then rcent=3
   endif
;
if n_elements(radius) eq 0 then radius=5
if n_elements(rcent) eq 0 then rcent=7<(radius(0)+2)
k=where(radius le 0,nk)
if nk gt 0 then radius(k)=5
if n_elements(gap) eq 0 then gap=5
; 
if ifstring(apcorf) then apcorf=rd_apcor(-1,file=apcorf)
;
form2="(F9.2,F8.2,' ',F6.2,' ',F7.2,F6.2,' ',2F7.2)"
form2w="(F9.2,F8.2,' ',F6.2,' ',F6.2,' ',F7.2,F6.2,' ',2F7.2)"
;
if keyword_set(wfpc2) then begin
   pcal=sxpar(header,'photflam')
   pzero=sxpar(header,'photzpt')
   nc=sxpar(header,'ncombine')>1
   expt=nc*sxpar(header,'UEXPODUR')
   if (expt le 0.) then wfpc2=0.
   endif
;
case 1 of
   ifstring(title): !p.title=title 
   ifstring(out): !p.title=out
   else: !p.title='APPHOT'
   endcase
zt=!p.title
ztb=byte(zt)
k=where(ztb eq 42b,nk)      ;*
if nk gt 0 then ztb(k)=32b
k=where(ztb eq 44b,nk)      ;commas
if nk gt 0 then ztb(k)=32b
k=where(ztb eq 46b,nk)      ;periods
if nk gt 0 then ztb(k)=32b
k=where(ztb eq 58b,nk)      ;colon
if nk gt 0 then ztb(k)=32b
k=where(ztb eq 59b,nk)      ;semicolon
if nk gt 0 then ztb(k)=32b
ztb=byte(strcompress(string(ztb)))
k=where(ztb eq 32b,nk)
if nk gt 0 then ztb(k)=95b
ztb=string(ztb)
!p.title='!6'+!p.title
;
noim=0
case 1 of
   n_elements(d) gt 4: im0=d
   n_elements(imsave) gt 0: im0=imsave
   n_elements(implot) gt 0: im0=implot
   else: noim=1
   endcase
;
if noim eq 1 then return            ;no image passed
;
if n_elements(cont) eq 0 then cont=0
case 1 of
   (n_elements(x) eq 0) or (n_elements(y) eq 0): interact=1
   keyword_set(auto): interact=0
   cont eq 1: interact=1 
   n_params() lt 3: interact=1
   else: interact=0
   endcase
;
if n_elements(mark) gt 0 then begin
   if ifstring(mark) then marks,cat=mark,ps=1 else marks,ps=1
   endif
npass=-1
if keyword_set(prt) and n_elements(out) eq 0 then out=1
if n_elements(out) eq 1 then begin
   quiet=0
   case 1 of
      ifstring(out): ofile='ap_'+out
      strlen(ztb) gt 0: ofile='ap_'+ztb
      else: ofile='apphot'
      endcase
   if strlen(get_ext(ofile)) eq 0 then ofile=ofile+'.lst'
   openw,lu,ofile,/get_lun
   printf,lu,' Aperture Photometry.  Run at ',systime(0)
   printf,lu,zt
   endif else lu=-1
;
loop:
npass=npass+1
case 1 of
   interact eq 0: im=im0
   keyword_set(nocentrd) and (n_elements(x) eq 1) and (n_elements(y) eq 1): begin
      cont=0 
      im=implot
      end
   (n_elements(x) eq 1) and (n_elements(y) eq 1) and (interact eq 0): begin
      cont=0 
      im=implot
      end
   else: begin
      nodisplay=0
      print, 'Mark position using cursor'
      tvp,im,x,y,v,/pix,/noprompt
      if !err gt 1 then cont=0
      end
   endcase
;
if keyword_set(nodisplay) then noplt=1
if keyword_set(nocentrd) then toff=0.0 else begin
   xss=x & yss=y
   tvcent,im0,x,y,box=rcent,/auto,/pixels,/nomark,nodisplay=nodisplay
   if sqrt((xss-x)*(xss-x)+(yss-y)*(yss-y)) gt 2 then begin
      print,'*** APPHOT WARNING: centroid moved by more than 2 pixels.'
      if keyword_set(stp) then stop,'APPHOT(2)>>>'
      endif
   if (x lt -9998) and (y lt -9998) then begin
      printf,lu,' Coordinates off image'
      printf,lu,' '
      zout='0. 0. 0. 0. 0. 0. 0. 0. 0.'
      goto, offimage
      endif
   toff=0.0
   x=x+toff & y=y+toff
   endelse
xcn=x & ycn=y
s=size(im)
s0=size(im0)
if !d.y_size lt s0(2) then begin
   bell
   print,'**************************************************************' 
   print,'*APPHOT WARNING: Y image truncated.
   print,'**************************************************************' 
   bell
   deltay=(s0(2)-!d.y_size)/2.
   endif else deltay=0
xdif=(s0(1)-s(1))/2. > 0.
ydif=(s0(2)-s(2))/2. > 0.
if s(4) lt s0(4) then im0=im0(0:(s(1)-1)<(s0(1)-1),0:(s(2)-1)<(s(2)-1))
s=size(im0)
if keyword_set(medfilt) then bim0=median(im0,3)    ;smoothed background
sxtp=s(1)/2 & sytp=s(2)/2
;
xcz=x-toff & ycz=y-toff
if not quiet then begin
   case 1 of
      keyword_set(pixels):
      wcs_flag: xy2ad,xcz,ycz,astr,xx,yy
      keyword_set(dss): gsssxyad,astr,xcz,ycz,xx,yy
      else: begin
         xytad,xx,yy,xcz-sxtp,ycz-sytp
         xx=xx*!radeg & yy=yy*!radeg
         end
      endcase
   if keyword_set(pixels) then zp='' else begin
      degtohms,xx,hh,/strings
      degtodms,yy,dd,/strings
      zp=hh+' '+dd
      endelse
   printf,lu,' Aperture is at X,Y =',xcz,ycz,' ',zp
   if keyword_set(medfilt) then printf,lu,' Using median-smoothed background'
   if not keyword_set(nofilter) then $
      printf,lu,' background filtered at ',filter,' sigma from mean' else $
      printf,lu,' No background filtering performed.'
      if n_elements(apcorf) gt 1 then $
         printf,lu,' Aperture correction is ',apcorf(radius-1)
      printf,lu,' '
   endif
;
nrad=n_elements(radius)
nc=fltarr(nrad) & enc=nc & bc=nc & ebc=bc
if nrad le 2 then noplt=1
if (n_elements(gap) eq 1) and (nrad gt 1) then gap=gap+radius*0
if n_elements(annulus) eq 0 then annulus=radius>20    ;(4.*radius)>(gap+radius+5)
if annulus(0) lt 1 then annulus=radius>20
if (n_elements(annulus) eq 1) and (nrad gt 1) then annulus=annulus+radius*0
;
if sc ne -1 then rf=abs(sc)*!radeg*3600. else rf=1.   ;(arcsec/pix)
;aprad=radius*rf                                  ;aperture radius in arcsec
;
cr = string("15b)
if lu ne -1 then begin
   print,form="($,a)",string("12b)   ;print new line
   print,form="($,'Number to go: ',i3,a)",nrad,cr
   endif
for irad=0,nrad-1 do begin
   if n_elements(gap) eq 0 then gap=radius(irad)>5
   rg=radius(irad)+gap(irad)
   smask=make_mask(s(1),s(2),xcn,ycn,rad=radius(irad))   ;source
   amask1=make_mask(s(1),s(2),xcn,ycn,rad=rg)            ;source+gap
   amask=make_mask(s(1),s(2),xcn,ycn,rad=rg+annulus(irad))  ;inside annulus
   amask=amask xor amask1
   if n_elements(off) eq 0 then off=0.0
   if not keyword_set(nodisplay) then begin
      opcirc,xcn-xdif+off,ycn+off+ydif-deltay,radius(irad),/pix
      opcirc,xcn-xdif+off,ycn+off+ydif-deltay,rg,/pix
      opcirc,xcn-xdif+off,ycn+off+ydif-deltay,rg+annulus(irad),/pix
      endif
   sa=total(smask)                   ;source area
   aa=total(amask)                   ;background area
   gc=total(smask*im0)
;
   if filter gt 0 then begin
      if keyword_set(medfilt) then gbb=amask*bim0 else gbb=amask*im0
      gbb=gbb(where(amask gt 0))
      np=n_elements(gbb)
      filter_back,gbb,2.*filter
      np0=n_elements(gbb)
      niter=0
      while np0 lt np do begin
         np=np0
         filter_back,gbb,filter
         np0=n_elements(gbb)
         niter=niter+1
         if niter ge maxbiter then begin
            print,' Not yet converged after ',strtrim(maxbiter,2), $
                  ' iterations - moving on.'
            print,np,np0,mean(gbb),stddev(gbb)
            np0=np
            endif
         endwhile
      nk=n_elements(gbb)
      if (aa-nk gt 0) and not quiet then $
          printf,lu,' Deleted ',fix(aa-nk),' points discrepant by >',filter,' sigma'
      gb=total(gbb)             ;total counts
      aa=nk                     ;background area
      if stp gt 1 then stop,'APPHOT - filter loop>>>'
      endif else begin      ;no filtering
      if keyword_set(medfilt) then gb=(amask*bim0) else gb=(amask*im0)
      gbb=gb(where(amask gt 0))
      gb=total(gb)               ;counts
      endelse
   sgb=stddev(gbb)               ;standard deviation of background
;
   ar=sa/aa     ;ratio of areas
;
   net=gc-(gb)*ar
   esky=sqrt(abs(gb+skyoffset))/aa
   if (sqrt(sgb) gt 10.) then esky=esky > sqrt(sgb)    ;???  tune for IR
   esky=esky/snfact         ;background error in counts per pixel
   enet=sqrt(abs(gc)+esky*esky*sa*sa)/snfact
   if n_elements(apcorf) gt radius(irad) then begin
      apc=apcorf(radius(irad)-1)
      net=net*apc & enet=enet*apc
      endif

   if n_elements(ontime) eq 1 then begin
      if ontime le 0. then zt='' else begin
         nr=net/ontime & er=enet/ontime
         fmt='(f7.2)'
         if nr lt 1. then fmt='(f6.4)'
         zt='Net rate: '+string(nr,fmt)+' +/- '+string(er,fmt)
         endelse
      endif else zt=''
      fmt1='(F9.2)'
      case 1 of
           enet ge 100000.: fmt2='(F9.2)' 
           enet ge 10000.: fmt2='(F8.2)' 
           enet ge 1000.: fmt2='(F7.2)' 
           enet ge 100.: fmt2='(F6.2)' 
           else: fmt2='(F5.2)'
           end
      if (gb>gc) gt 1.e6 then fmti='(I7)' else fmti='(I6)'
      if net gt 99999. then fmt1='(F9.2)'
      if net gt 1.e6 then fmt1='(F11.2)'
      if sc ne -1 then $
           zrad=' ('+string(radius(irad)*rf,'(F5.2)')+'")' else zrad=''
      if not quiet then begin
        printf,lu,' Rad =',string(radius(irad),'(I2)'),zrad,string(rg,'(I3)'), $
           string(rg+annulus(irad),'(I3)'),'   ', $
           ' gross cts (src, b)=',string(gc,fmti),' ', $
            string(gb,fmti),'  Area ratio=',string(ar,'(F4.2)')
        printf,lu,' Net counts:',string(net,fmt1),' +/- ',string(enet,fmt2), $
           '  ',zt,' SNR=',string(net/enet,'(F6.1)'), $
           ' Back/pix = ',string(gb/aa,'(F7.2)'),' +/- ',string(esky,'(F6.2)')
         endif
      if keyword_set(wfpc2) then begin
         dn=net/expt     ;dn/sec
         fhst=dn*pcal
         mag=pzero-2.5*alog10(fhst)
         if not keyword_set(quiet) then printf,lu,' Flux on HST system: ', $
                   string(fhst,'(E9.2)'), $
                   '  Magnitude on HST system: ',string(mag,'(F6.2)')
         endif
   if ofmt eq 1 then printf,lu,string(radius(irad),'(I2)'),' ', $
      string(fhst,'(E9.2)'),' ',string(mag,'(F6.2)'),' ', $
      string(net/enet,'(F6.1)')
   if keyword_set(wfpc2) then zout=string(net,enet,net/enet,gb/aa,esky, $
                          mag,xcz,ycz,format=form2w)
   if keyword_set(numout) then case 1 of
      keyword_set(wfpc2): printf,lu,form=form2w,net,enet,net/enet,gb/aa,esky, $
                          mag,xcz,ycz
      else: printf,lu,form=form2,net,enet,net/enet,gb/aa,esky,xcz,ycz
      endcase
   if (lu ne -1) and (ofmt eq 0) then printf,lu,' '
   if lu ne -1 then print,form="($,'Number to go: ',i3,a)",nrad-irad-1,cr
   nc(irad)=net & enc(irad)=enet & bc(irad)=gb/aa*sa & ebc(irad)=esky*sa
      if (nrad gt 1) and (ofmt eq 0) then printf,lu,' '
      endfor    ;irad
offimage:
if cont then goto,loop
if lu ne -1 then print,form="($,a)",string("12b)   ;print new line
;
if lu ne -1 then begin
   close,lu & free_lun,lu
   if keyword_set(prt) then spawn,'lpr '+ofile else $
      print,' Measurements are in ',ofile
   endif
;
if n_elements(nrad) lt 2 then noplt=1
if not keyword_set(noplt) then begin
   scb=(mean(nc)/mean(bc))(0)
   lscb=floor(alog10(scb))
   if lscb lt 0 then lscb=lscb
   scb=10.^lscb
   if keyword_set(hcpy) then sp,'ps' else newwindow
   svp & setxy    ;,0.,0.,1.,max(nc)
   !x.title='!6 Radius (pix)'
   if sc gt 0. then !x.title='!6 Radius (arcsec)'
   !y.title='!6 counts'
   !p.title=!p.title+'  B scaled by 10^'+strtrim(lscb,2)
   plot,radius*rf,nc
   erbar,2,nc,enc,radius*rf
   oplot,radius*rf,bc*scb,linestyle=1
   erbar,2,bc*scb,ebc*scb,radius*rf
   oplot,radius*rf,bc,linestyle=1
   erbar,2,bc,ebc,radius*rf
   snr=nc/enc
   if !d.name eq 'X' then begin
      wshow 
      oldwindow
      endif
   make_hcpy,hcpy
   endif
;
irad=irad-1
if keyword_set(stp) then stop,'APPHOT>>>' else begin
   if keyword_set(hc) or keyword_set(prt) then bell,3
   endelse
return
end
