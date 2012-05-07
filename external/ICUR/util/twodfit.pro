;*************************************************************************
pro twodfit,arr,x0,y0,a,perr,rchsq,rad=rad,head=head,ycorr=ycorr, $
    prt=prt,stp=stp,wfpc2=wfpc2,rn=rn,gain=gain,gauss=gauss,lun=lun, $
    lorentzian=lorentzian,moffat=moffat,tilt=tilt,all=all,helpme=helpme
common grid,sc,atn,dtn,ddec,dr,equinox,acen,dcen,atnp,dtnp,xoffset,yoffset,dss
common dss,xc0,yc0,px,py,xc1,yc1,ap,bp,ac,dc,dssh,astr,dxfudge,dyfudge
common wcs,wcs_flag
common twodfitcom,z,fit,zdiff,sigim,a1,perr1
;
if keyword_set(helpme) then begin
   print,' '
   print,'* TWODFIT: wrapper for MPFIT2DPEAK'
   print,'* calling sequence: TWODFIT,arr,x0,y0 (,a,perr,rchsq)'
   print,'*    ARR:    input 2-D array'
   print,'*    X0,Y0:  center of peak to fit'
   print,'*    A,PERR: output fit parameters and errors'
   print,'*    RCHSQ:  reduced chi-square of fit'
   print,'* '
   print,'* KEYWORDS'
   print,'*    ALL:    fit entire input array'
   print,'*    GAIN:   ADU to electron gain, def=1.'
   print,'*    HEAD:   named variable containing FITS header'
   print,'*    LORENTZIAN: do Lorentzian fit'
   print,'*    LU:     logical unit for printing, def=-1
   print,'*    MOFFAT: fit with Moffat function'
   print,'*    PRT:    controls printed output, def=0 (no output), 1 is verbose'
   print,'*    RAD:    radius of extracted region, def=20, size of Z is 2*RAD+1'
   print,'*    RN:     read noise (electrons), def=0.'
   print,'*    TILT:   set to fit tilt of asymmetric PSF'
   print,'*    WFPC2:  set for default WFPC gain and read noise'
   print,'*    YCORR:  True Y coordinates (input) for WFPC2 for 34th row error'
   print,'* '
   print,'* COMMON  TWODFITCOM'
   print,'*    Z: image subarray'
   print,'*    FIT: fit array'
   print,'*    ZDIFF: Z-FIT difference array'
   print,'*    SIGIM: sigma image (zdiff/sqrt(*z))'
   print,'*    A, PERR: fit parameters and errors
   print,' '
   return
   end
;
if n_elements(lu) eq 0 then lu=-1
if n_elements(sc) eq 0 then sc=-1.
if sc le 0. then itp=0 else itp=1            ;use tangent plane projection?
if n_elements(rad) eq 0 then rad=20
s=size(arr)
sx=s(1)-1 & sy=s(2)-1
if (n_elements(x0) eq 0) or (n_elements(y0) eq 0) then begin
   all=1
   x0=sx/2. & y0=sy/2.
   endif
;
ix0=fix(x0) & iy0=fix(y0)
case 1 of
   keyword_set(all): begin
      z=arr
      rad=sx/2
      end
   else: z=arr((ix0-rad)>0:(ix0+rad)<sx,(iy0-rad>0):(iy0+rad)<sy)   ;subarray
   endcase
if n_elements(head) gt 1 then begin
   if strtrim(strupcase(sxpar(head,'instrume')),2) eq 'WFPC2' then wfpc2=1
   endif
if keyword_set(wfpc2) then begin
   gain=7. 
   rn=1.4
   endif
if n_elements(rn) eq 0 then rn=0.
if n_elements(gain) eq 0 then gain=1.
;
ze=sqrt((z>1)+rn*rn)/sqrt(gain)
mx=max(z)
np=n_elements(z)
mz=median(z)
rad2=2*rad
x=ix0-rad+findgen(rad2+1)          ;indices...
y=iy0-rad+findgen(rad2+1)
if n_elements(ycorr) ge 2*rad then y=ycorr((iy0-rad)>0:iy0+rad)
;
aa=[mz,mx-mz,2.,2.,x0,y0,0]
if keyword_set(moffat) then aa=[aa,1]
a=aa
;prt=1 & stp=1
;stop
perr=0
fit=mpfit2dpeak(z,a,x,y,gauss=gauss,lorentzian=lorentzian,moffat=moffat, $
                tilt=tilt,estimate=aa,error=ze,perr=perr,best=best)
;print,aa,a
;help,perr,best
if n_elements(perr) le 1 then begin
   printf,lu,'refit'
   fit=mpfit2dpeak(z,a,x,y,gauss=gauss,lorentzian=lorentzian,moffat=moffat, $
                   tilt=tilt,estimate=aa,error=ze,perr=perr,best=best)
   endif
;print,aa,a
;help,perr,best
;stop
na=n_elements(a)
dof=np-na
PCERROR = PERR * SQRT(BEST / DOF)
me=(perr(4)+perr(5))/2.*0.05            ;arcsec
a1=a & perr1=perr
;
zdiff=z-fit
sigim=zdiff/ze          ;sigma image
chsq=total(sigim*sigim)
if not finite(chsq) then chsq=best
rchsq=chsq/(np-1)
ext=(a(2)+a(3))/2.                      ;mean extent
mext=fix(ext*5.+0.5)>5
if mext lt rad then begin              ;statistics for source alone
   x1=fix(a(4)-ix0+rad+0.5) & y1=(fix(a(5)-iy0+rad+0.5))>0
   sig1=sigim((x1-mext)>0:(x1+mext)<rad2,(y1-mext)>0:(y1+mext)<rad2)
   np1=n_elements(sig1)
   chsq1=total(sig1*sig1)
   rchsq1=chsq1/(np1-1)
   endif
;  
if keyword_set(prt) then begin
   fmt1='(F11.3)'
   fmt2='(F8.3)'
   if prt eq 1 then begin
      printf,lu,' Fit parameters and errors'
   for i=0,na-1 do printf,lu,i,string(a(i),fmt1),' +/- ',string(perr(i),fmt2), $
         ' (',string(pcerror(i),fmt2),')'
      printf,lu,' '
      endif
   if prt le 2 then begin
      printf,lu,' chi-2 = ',chsq,' Reduced chi-2 = ',rchsq,' (all)  ', $
         string(np,'(I5)')
      if mext lt rad then $
         printf,lu,' chi-2 = ',chsq1,' Reduced chi-2 = ',rchsq1,' (source)', $
         string(np1,'(I4)')
      printf,lu,' mean position err = ',me,' arcsec for 0.05 arcsec pixels'
      endif   
   endif
a=[a,ix0,iy0]
;
if keyword_set(stp) then stop,'TWODFIT>>>'
return
end
