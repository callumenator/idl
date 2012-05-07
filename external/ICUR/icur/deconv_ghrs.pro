;**********************************************************************
function deconv_ghrs,w,f,grat,psf_file=psf_file
common com1,h
COMMON COMXY,XCUR,YXUR,ZERR
common icurunits,xunits,yunits,title,c1,c2,c3,ch
; psfs for 120,140,170,210,270
c=[120,140,170,210]           ;,270]   270 not available
;
if not keyword_set(psf_file) then begin
   wcen=mean(w)
   d=abs(wcen-c*10.)
   m=where(d eq min(d))
   cent=c(m) & CENT=CENT(0)
   np=n_elements(f)
   case 1 of
      np le 600: ext='_1'
      np ge 1500: ext='_4'
      else: ext='_2'
      endcase
   file='psf'+strtrim(cent,2)+ext
   endif else file=psf_file
;
icurdata=getenv('icurdata')
file=icurdata+file
if get_ext(file) eq '' then file=file+'.dat'
print,' PSF FILE: ',file
s=0. & psf=0.
openr,lu,file,/get_lun
genrd,lu,s,psf
;psf0=psf              ;units are arcsec
;
; disp is dispersion in A/diode
dgrat=[.054,.069,.078,.092,.57]    ;crude dispersions
if (grat ge 1) and (grat le 5) then begin
   disp=dgrat(grat-1) 
   dpa=disp*4.     ;angstroms per arcsec  ; diode=0.25 arcsec
   s=s*dpa         ;PSF scale per angstrom
   ds=max(s)-min(s)      ;length of psf
   dl=w(1)-w(0)          ;bin size
   npsfp=fix(ds/dl)      ;number of points
   if npsfp mod 2 eq 0 then npsfp=npsfp+1
   hp=(npsfp-1)/2
   ss=(findgen(npsfp)-hp)*dl
   psf=interpol(psf,s,ss)
   endif
;   disp=0.
;   print,' WARNING: Dispersion undefined. please enter dispersion in A/diode'
;   read,disp
;   endelse
;
psf=psf/total(psf)
print,' type number of iterations (1-9, 0=10), Q to abort'
blowup,-1
if (zerr lt 48) or (zerr gt 57) then return,f
niter=zerr-48
if niter eq 0 then niter=10
lucy_guess,niter,f,psf,newf
h(2)=1000+niter
;
while (niter ge 0) and (niter le 10) do begin
   oplot,w,newf,color=c2
   nd=strtrim((h(2)-1000),2)
   print,nd,' iterations done. Enter number to do (1-9, 0=10), Q to abort'
   blowup,-1
   if (zerr lt 26) or (zerr gt 81) or (zerr eq 113) then return,f
   if (zerr lt 48) or (zerr gt 57) then return,newf
   niter=zerr-48
   if niter eq 0 then niter=10
   lucy_guess,niter,f,psf,newf,guess=newf
   h(2)=h(2)+niter
   endwhile
;
return,newf
end
