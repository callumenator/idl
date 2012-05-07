;*********************************************************************
pro set_coords,file,d,helpme=helpme,stp=stp,debug=debug, $
    tvdisplay=tvdisplay,coords=coords,cirim=cirim,quiet=quiet,verbose=verbose, $
    logscale=logscale,swap=swap,bscale=bscale,wcsf=wcsf,f75=f75
common grid,sc,atn,dtn,ddec,dr,equinox,acen,dcen,atnp,dtnp,xfudge,yfudge,dss
common dss,xc,yc,px,py,xc1,yc1,a,b,ac,dc,dssh,astr,dxfudge,dyfudge
common wcs,wcs_flag
;
if (n_params(0) eq 0) and (n_elements(h) eq 0) then helpme=1
if (n_elements(file) eq 0) and (n_elements(h) eq 0) then helpme=1
if keyword_set(helpme) then begin
   print,' '
   print,'* SET_COORDS '
   print,'*    calling sequence: SET_COORDS,h,d or SET_COORDS,file,d'
   print,'*       file: name of FITS file containing image'
   print,'*       h   : header from FITS file'
   print,'*       d   : image array (optional output)'
   print,'*'
   print,'*   KEYWORDS:'
   print,'*      BSCALE: rebinning factor for rebinned image (- if already rebinned)'
   print,'*      CIRIM:  read header from CTIO/CIRIM'
   print,' '
   return
   endif
;
if keyword_set(verbose) then quiet=0
if keyword_set(quiet) then verbose=0
if keyword_set(wcsf) then wcs_flag=1
if not keyword_set(cirim) then cirim=0
maxscreen=1024
if n_elements(bscale) eq 0 then bscale=1
bsc=abs(bscale)
;
if n_elements(file) gt 1 then begin    ;header passed
   dssh=file 
   tvdisplay=0 & swap=0
   endif else begin                    ;read file
   ff=file+'.fits'
   if not ffile(ff) then begin
      print,' File ',ff,' not found - returning'
      return
      endif
   dssh=0
   d=readfits(file,dssh,/shorth)
   endelse
;
tel=strupcase(strtrim(sxpar(dssh,'TELESCOP'),2))
if (tel eq 'CT15M') or (tel eq 'NASA IRTF') then cirim=1
case 1 of
   cirim: begin
      dss=0 & wcs_flag=0
      end
   else: begin
      t=getval('PPO1',dssh,/nomess,nval=nval)
      if nval eq 0 then begin
         dss=0 & wcs_flag=1
         endif else begin
         dss=1 & wcs_flag=0
;         dss=0 & wcs_flag=1   ;***
         endelse
      end
   endcase
;
;if keyword_set(wfpc2) then begin
;   if not keyword_set(off) then off=400
;   cp1=sxpar(dssh,'crpix1')
;   sxdelpar,dssh,'crpix1'
;   sxaddpar,dssh,'crpix1',cp1+off
;   cp2=sxpar(dssh,'crpix2')
;   sxdelpar,dssh,'crpix2'
;   sxaddpar,dssh,'crpix2',cp2+off
;   endif
;
if n_elements(d) gt 4 then begin      ;data array present
   s=size(d)
   if (bsc le 1) and keyword_set(tvdisplay) and $
         (s(1)>s(2) gt maxscreen) then begin
      msize=s(1)>s(2)
      bscale=msize/maxscreen
      if float(msize)/maxscreen gt bscale then bscale=bscale+1
      bsc=bscale
      print,' Image too big to be displayed - binning down.'
      endif
   if bscale gt 1 then begin
      xs=s(1)/bsc
      ys=s(2)/bsc
      case 1 of
         (xs*bsc lt s(1)) and (ys*bsc lt s(2)): d=d(0:xs*bsc-1,0:ys*bsc-1)
         xs*bsc lt s(1): d=d(0:xs*bsc-1,*)
         ys*bsc lt s(2): d=d(*,0:ys*bsc-1)
         else:
         endcase
      d=rebin(temporary(d),xs,ys)
      endif       
   if bsc lt 0 then bsc=abs(bsc)
   s=size(d)
   if (s(1) gt maxscreen) or (s(2) gt maxscreen) then tvdisplay=0
   endif   ;file present
;
dxfudge=-fix(getval('naxis1',dssh))/2./bsc
dyfudge=-fix(getval('naxis2',dssh))/2./bsc
dr=1./!radeg
;
if strupcase(strtrim(sxpar(dssh,'INSTRUME'),2)) eq 'CIRIM' then cirim=1
if strupcase(strtrim(sxpar(dssh,'INSTRUME'),2)) eq 'IRIM' then cirim=1
case 1 of
   keyword_set(cirim):
   wcs_flag: extast,dssh,astr ,rebin=bsc
   else: gsssextast,dssh,astr,rebin=bsc,stp=stp
   endcase
;
xc=float(getval('naxis1',dssh))/2.
yc=float(getval('naxis2',dssh))/2.
;
case 1 of
   cirim: begin
      zeq=strtrim(sxpar(dssh,'epoch'),2)
      if strupcase(strmid(zeq,0,1)) eq 'J' then zeq=strpos(zeq,1)
      if strupcase(strmid(zeq,0,1)) eq 'B' then zeq=strpos(zeq,1)
      equinox=float(zeq)
;      equinox=float(getval('EPOCH',dssh))
      ac=getval('RA',dssh,/noap)
      k=strpos(ac,':')
      rah=fix(strmid(ac,0,k))
      ac=strmid(ac,k+1,20)
      k=strpos(ac,':')
      ram=fix(strmid(ac,0,k))
      ac=strmid(ac,k+1,20)
      ras=double(ac)
      ac=hmstodeg(rah,ram,ras)
;
      dc=getval('DEC',dssh,/noap)
      k=strpos(dc,':')
      dd=fix(strmid(dc,0,k))
      if (dd eq 0) and strmid(dc,0,1) eq '-' then dsign=-1. else dsign=1.
      dc=strmid(dc,k+1,20)
      k=strpos(dc,':')
      dm=fix(strmid(dc,0,k))
      dc=strmid(dc,k+1,20)
      ds=double(dc)
      dc=dmstodeg(dd,dm,ds)*dsign
      end
   wcs_flag: begin
      xc=xc/bsc
      yc=yc/bsc
      zeq=strtrim(sxpar(dssh,'equinox'),2)
      if strupcase(strmid(zeq,0,1)) eq 'J' then zeq=strpos(zeq,1)
      if strupcase(strmid(zeq,0,1)) eq 'B' then zeq=strpos(zeq,1)
      equinox=float(zeq)
;      equinox=float(getval('EQUINOX',dssh))
      xy2ad,xc,yc,astr,acen,dcen
      ac=getval('CRVAL1',dssh)
      dc=getval('CRVAL2',dssh)
      end
   else: begin
      zeq=strtrim(sxpar(dssh,'equinox'),2)
      if strupcase(strmid(zeq,0,1)) eq 'J' then zeq=strpos(zeq,1)
      if strupcase(strmid(zeq,0,1)) eq 'B' then zeq=strpos(zeq,1)
      equinox=float(zeq)
;      equinox=float(getval('EQUINOX',dssh))
      gsssxyad,astr,xc,yc,acen,dcen
      ac=hmstodeg(fix(getval('PLTRAH',dssh)),fix(getval('PLTRAM',dssh)), $
         double(getval('PLTRAS',dssh)))
      dc=dmstodeg(fix(getval('PLTDECD',dssh)),fix(getval('PLTDECM',dssh)), $
         double(getval('PLTDECS',dssh)))
      ds=strtrim(getval('PLTDECSN',dssh,/noap),2)
      if ds eq '-' then dc=-dc
      end
   endcase
;
if keyword_set(coords) then begin
   degtohms,acen,hh,mm,ss & degtodms,dcen,dd,dm,ds
   zra=string(hh,'(I2)')+string(mm,'(I3)')+string(ss,'(F6.2)')
   zdec=string(dd,'(I4)')+string(dm,'(I4)')+string(ds,'(F7.2)')
   print,' Image center: ',zra,' ',zdec,' (',string(equinox,'(F6.1)'),')'
   endif
ac=ac/!radeg & dc=dc/!radeg
atn=ac & dtn=dc
if keyword_set(verbose) then print,'SET_COORDS: astr defined'
if wcs_flag eq 0 then dss=1 else dss=0
if cirim then begin
   dss=0 & wcs_flag=0
   endif
if keyword_set(swap) then d=max(d)-d
if keyword_set(tvdisplay) then begin
   tvinitpixf & tvs,d,/reset,log=logscale,id=file
   end
;
h=dssh
case 1 of
   cirim: begin
      sc=sxpar(h,'cdelt1')
      if sc le 0 then begin
         sc=0.65
         if keyword_set(f75) then sc=sc*2.
         endif
      sc=sc*dr         ;rad/pix
      atn=ac & dtn=dc
      acen=ac*!radeg & dcen=dc*!radeg
      atnp=xc & dtnp=yc
      ddec=sc*yc*2/dr              ;degrees
      end
   wcs_flag: begin
      sc=sqrt(astr.cd(1,1)*astr.cd(1,1)+astr.cd(1,0)*astr.cd(1,0))/!radeg
      px=sqrt(astr.cd(0,1)*astr.cd(0,1)+astr.cd(0,0)*astr.cd(0,0))/!radeg
      py=sc   
      xc1=0 & xc2=0
xx=abs(sxpar(h,'cdelt1'))
if xx gt 0 then sc=xx*dr
      end
   else: begin
      xc=double(getval('PPO3',h)) & yc=double(getval('PPO6',h))     ;plate center
      px=double(getval('XPIXELSZ',h))*bsc   ;microns
      py=double(getval('YPIXELSZ',h))*bsc   ;plate scale
      xc1=long(getval('cnpix1',h))/bsc & yc1=long(getval('cnpix2',h))/bsc  ;x,y corners
      sc=float(getval('PLTSCALE',dssh))*px/3.6e6/!radeg
      end
   endcase
sc=sc*bscale
if keyword_set(stp) then stop,'SET_COORDS>>>'
;
if keyword_set(debug) then begin
   print,' Plate center xc,yc  :',xc,yc
   print,' Plate center (deg)  :',a*!radeg,d*!radeg
   degtohms,a & degtodms,d
   print,' plate scale         :',px,py
   print,' subplate corners    :',x1,y1
   print,' mm from plate center:',x,y
   endif
;
if wcs_flag or cirim then return
;
a=dblarr(13)
a(0)=double(getval('AMDX1',h))
a(1)=double(getval('AMDX2',h))
a(2)=double(getval('AMDX3',h))
a(3)=double(getval('AMDX4',h))
a(4)=double(getval('AMDX5',h))
a(5)=double(getval('AMDX6',h))
a(6)=double(getval('AMDX7',h))
a(7)=double(getval('AMDX8',h))
a(8)=double(getval('AMDX9',h))
a(9)=double(getval('AMDX10',h))
a(10)=double(getval('AMDX11',h))
a(11)=double(getval('AMDX12',h))
a(12)=double(getval('AMDX13',h))
;
b=dblarr(13)
b(0)=double(getval('AMDY1',h))
b(1)=double(getval('AMDY2',h))
b(2)=double(getval('AMDY3',h))
b(3)=double(getval('AMDY4',h))
b(4)=double(getval('AMDY5',h))
b(5)=double(getval('AMDY6',h))
b(6)=double(getval('AMDY7',h))
b(7)=double(getval('AMDY8',h))
b(8)=double(getval('AMDY9',h))
b(9)=double(getval('AMDY10',h))
b(10)=double(getval('AMDY11',h))
b(11)=double(getval('AMDY12',h))
b(12)=double(getval('AMDY13',h))
;
return
end
