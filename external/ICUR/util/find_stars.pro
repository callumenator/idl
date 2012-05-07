;**************************************************************************
pro find_stars,arr,x,y,marr, $       ;find stars using FIND
    sigma=sigma,mask=mask,trim=trim,helpme=helpme,rn=rn,gain=gain, $ 
    fwhm=fwhm,pc=pc,sharplim=sharplim,roundlim=roundlim,stp=stp, $
    out=out,display=display,all=all,verbose=verbose
;
if keyword_set(helpme) then begin
   print,' '
   print,'* FIND_STARS: wrapper for DAO FIND routine'
   print,'* calling sequence: FIND_STARS,ARR,X,Y,MARR'
   print,'*    ARR: input image array'
   print,'*    X,Y: output X,Y indices of identified sources'
   print,'*    MARR: output masked array'
   print,'* '
   print,'* KEYWORDS:'
   print,'*    ALL:  set to return all stars, def=unique stars'
   print,'*    FWHM: initial source FWHM, def=1.5'
   print,'*    GAIN: photons/ADU, def=1.'
   print,'*    MASK: set to mask image, set if MARR specified'
   print,'*    PC:   set for PC trim, RN, GAIN'
   print,'*    RN:   read noise, def=1.
   print,'*    SIGMA: cut level in units of Standard Dev, def=2'
   print,'*    TRIM: 4-element vector with # edge points to trim: [x,x,y,y]'
   print,'*    OUT:  name of printout file, def= find.lst'
   print,'*    SHARPLIM,ROUNDLIM: inputs for FIND'
   print,' '
   return
   endif

if n_elements(fwhm) eq 0 then fwhm=1.5
if n_elements(sigma) eq 0 then sigma=1.0
if n_elements(roundlim) eq 0 then roundlim=[-1.0,1.0]
if n_elements(sharplim) eq 0 then sharplim=[0.2,1.0]
if n_params() ge 4 then mask=1     ;set mask if marr passed
;
s=size(arr) & sx=s(1) & sy=s(2)
if n_elements(rn) eq 0 then rn=1.
if n_elements(gain) eq 0 then gain=1.
if keyword_set(pc) then begin
   trim=[48,0,55,0]
   rn=1.5
   gain=7
   endif
if n_elements(trim) gt 2 then begin    ;mask vignetted regions
   if n_elements(trim) eq 2 then trim=[trim(0),0,trim(1),0]
   arr(0:trim(0),*)=0
   if trim(1) gt 0 then arr(sx-1-trim(1):sx-1,*)=0
   arr(*,0:trim(2))=0
   if trim(3) gt 0 then arr(*,sy-1-trim(3):sy-1)=0
   endif
;
md=median(arr)
sd=stddev(arr,/md)
print,md,sd
exc=md+sd
minval=0.
if md lt 0. then minval=-exc
k=where((arr gt minval) and (arr le exc),nk)
if nk gt 3 then begin
   md=median(arr(k))
   sd=stddev(arr(k),/md)
   print,md,sd
   endif   
md1=md & sd1=sd
;
find,arr,x,y,f,sharp,rnd,md+sigma*sd,fwhm,roundlim,sharplim,/silent
k=reverse(sort(f))             ;sort by decreasing flux
x=x(k) & y=y(k) & f=f(k) & sharp=sharp(k) & rnd=rnd(k)
np=n_elements(x)
group,x,y,10,grps
kuniq=intarr(np)+1
mg=max(grps)
for i=0,mg-1 do begin & k=where(grps eq i,nk) & if nk gt 1 then  $
   kuniq(k(1:*))=0 & endfor
kgrp=where(kuniq eq 1)             ;unique stars
;
; mask out sources
;f10=where(f lt 5000.,nk)
;if nk eq 0 then begin
;   print,' Something wrong here: no faint sources!'
;   stop
;   return
;   endif
;ns=20
;ins=indgen(ns)
;f10=f10(0)+ins    ;pick 10 stars
;mag=15.+fltarr(ns)
;sky=md+fltarr(ns)
;getpsf,arr,x(f10),y(f10),mag,sky,1.5,7.,gsf,psf,ins,25.,15.,'test' ;make PSF
;
if keyword_set(mask) then begin
   if mask gt 1 then mlim=mask else mlim=0.
   marr=arr
   k=where(f gt mlim,nb)
   print,' Masking out ',nb,' sources'
   mr=((f/500.)<25)>10
   for i=0,nb-1 do begin    ;mask out bright sources
      mask=make_mask(sx,sy,x(i),y(i),rad=mr(i),/neg)
      marr=temporary(marr)*mask
      endfor
   kg=where(marr gt 0.,nkg)
   if nkg eq 0 then begin
      print,' No valid points left in array!'
      stop
      return
      endif
   md=median(marr(kg)) & sd=stddev(marr(kg),/md)
   print,md,sd
   k=where(marr eq 0.,nk) & if nk gt 0 then marr(k)=md
;
   find,arr,x,y,f,sharp,rnd,md+sigma*sd,fwhm,roundlim,sharplim,/silent
   k=reverse(sort(f))             ;sort by decreasing flux
   x=x(k) & y=y(k) & f=f(k) & sharp=sharp(k) & rnd=rnd(k)
   np=n_elements(x)
   if np gt 1 then group,x,y,10,grps else grps=0
   kuniq=intarr(np)+1
   mg=max(grps)
   for i=0,mg-1 do begin
      k=where(grps eq i,nk)
      if nk gt 1 then kuniq(k(1:*))=0
      endfor
   kgrp=where(kuniq eq 1)             ;unique stars
   zm=' after masking'
   endif else zm=''
ngrp=n_elements(kgrp)
if keyword_set(display) then begin
   tvs,(arr>md1)<(md1+3.*sd1)
   for i=0,np-1 do opcirc,x(i),y(i),10,/pixel
   endif
;
; return unique stars only
if not keyword_set(all) then begin
   zall=' Unique sources only'
   x=x(kgrp) & y=y(kgrp)
   f=f(kgrp) & grps=grps(kgrp)
   sharp=sharp(kgrp) & rnd=rnd(kgrp)
   np=n_elements(x)
   endif else zall=' All sources returned'
;
if keyword_set(out) then begin
   if not ifstring(out) then out='findstars'
   if noext(out) then out=out+'.lst'
   openw,lu,out,/get_lun
   printf,lu,' FIND_STARS output, run at ',systime()
   printf,lu,zall
   printf,lu,' input image sixe = ',sx,'x ',sy
   printf,lu,' median sky = ',md,' StDev=',sd,zm
   printf,lu,ngrp,' unique sources found at threshhold of ',sigma,' StdDev'
   printf,lu,np,' sources identified'
   printf,lu,' '
   printf,lu,'  #    X         Y          peak flux    sharp   round    group'
   lnp=strtrim(fix(alog10(np)+1.),2)
   ifmt='(I'+lnp+')'
   ffmt='(F9.3)'
   fmt2='(F6.2)'
   fmt81='(F8.1)'
   for i=0,np-1 do $
      printf,lu,string(i,ifmt),string(x(i),ffmt),string(y(i),ffmt), $
      string(f(i),fmt81),string(sharp(i),fmt2),string(rnd(i),fmt2), $
      string(grps(i),ifmt)
   close,lu & free_lun,lu
   print,' output is in ',out
   endif
;
if keyword_set(stp) then stop,'FIND_STARS>>>'
return
end
