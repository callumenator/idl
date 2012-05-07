;****************************************************************
function spshft,f0,f1,e0,e1,nit,debug=debug
; f0 is reference spectrum; F1 is presumably shifted
; linear shifts only
common trim,ntr,ntr1,range,kr,irg,r2
n=n_elements(f0)
npts0=n
if n gt 7500 then ihi=1 else ihi=0
if n_params(0) lt 5 then nit=1         ;reference spectrum=f0
if n_params(0) lt 3 then begin
   e0=intarr(n)+100
   e1=e0
   endif
if n_elements(e0) lt n then e0=intarr(n)+100
if n_elements(e1) lt n then e1=intarr(n)+100
diflim=2.5
;
; get reference spectrum
;
get_lun,lu
if nit le 1 then begin
   case 1 of
      ihi eq 0: begin
         range=60  ;bins
         ntr=(125<(npts0-range*2))>0   ;points to trim
         kr=7
         end
      ihi eq 1: begin     ;high dispersion
         range=120  ;bins
         ntr=3000   ;points to trim
         kr=11
         np=fix(alog10(n)/alog10(2))     ;number of points to save
         ntr=(n-(2L^np))/2L
         end
      endcase
   ntr1=ntr
   irg=kr*3
   r2=2*range
;stop
   if keyword_set(debug) then checklim,f0,ntr,ntr1,e0
   if ihi eq 1 then f0s=optfilt(f0,e0,0,0,0,201) else f0s=optfilt(f0,e0)
   fref=f0-(f0s)
   np=n_elements(f0)
   fref=fref/max(fref)
   fref=fref(ntr:np-ntr1-1)   ;trim ends
   eref=e0(ntr:np-ntr1-1)   ;trim ends of e vector
   k=wherebad(eref,1)
   fref(k)=0.
   fref=fref-mean(fref)
   if nit eq 1 then begin    ;save to disk
      n=n_elements(fref)
      k=fix(n/4096)
      if k eq 0 then arrlen=n else arrlen=4096
      openw,lu,'spshft.tmp',arrlen*4
      z=assoc(lu,fltarr(arrlen))
      z(0)=[float(k),float(arrlen)]
      if k eq 0 then z(1)=fref else begin
         fr=fltarr(arrlen*long(k+1))-999.
         fr(0)=fref
         help,fref
         for i=0,k do z(i+1)=fr(i*arrlen:(i+1)*arrlen-1)
         endelse
      endif              ;nit eq 1
   endif else begin      ;retrieve reference spectrum
   openr,lu,'spshft.tmp'
   trec=fstat(lu)
   z=assoc(lu,fltarr(trec.rec_len/4))
   z0=z(0)
   k=fix(z0(0)) & arrlen=fix(z0(1))
   if k eq 0 then fref=z(1) else begin
      fref=fltarr(long(k+1)*long(arrlen))
      for i=0,k do fref(i*arrlen)=z(i+1)
      k=where(fref eq -999.)
      fref=fref(0:k(0)-1)
      help,fref
      endelse
   endelse
close,lu
free_lun,lu
;
if ihi eq 1 then f11=optfilt(f1,e1,0,0,0,201) else f11=optfilt(f1,e1)
f11=f1-f11
f11=f11/max(f11)
np=n_elements(fref)
np1=n_elements(f1)
ccor=fltarr(r2+1)
range=range<ntr
range1=range<ntr1
r2=range+range1
for i=-range,range1 do begin
   start=ntr+i
   fshift=f11(start:start+np-1)
   eshift=e1(start:start+np-1)
   k=wherebad(eshift,1)
   fshift(k)=0.
   fshift=fshift-mean(fshift)
   ccor(i+range)=total(fshift*fref)
   endfor
p1=range-irg
p2=range+irg
np=2*irg+1
xp=indgen(2*irg+1)-irg
x=indgen(r2+1)-range
ccp=ccor(p1:p2)
k=where(ccp eq max(ccp)) & k=k(0)
if (k lt kr) or k ge (np-kr) then begin
   if keyword_set(debug) then plot,x,ccor
   return,-1000.    ;too close to edge
   endif
zc=[ccp(0:(k-2*kr)>0),ccp((k+2*kr)<(np-1):*)]
mn=mean(zc)
loop:  centrd,xp,ccp,mn,(k-kr)>0,(k+kr)<np,xcen
;
if abs(xcen-xp(k)) gt 3. then begin
   kr=kr/2
   if kr gt 2 then goto,loop else xcen=xp(k)
   endif
;
zc=[ccor(0:(k+p1-2*kr)>0),ccor((k+p1+2*kr)<np:np)]
z=zc-mean(zc)
crms=sqrt(total((zc-mean(zc))*(zc-mean(zc)))/(n_elements(zc)-1))
diff=(max(ccp)-mean(zc))/crms
if keyword_set(debug) then print,'(max-mean)/RMS:',diff
;
xcen=xcen+p1+0.25
!c=!c+p1
shft=xcen-p1
if (xcen lt 0.0) or (xcen gt r2+1) then shft=0.
if shft ne 0. then isign=shft/abs(shft) else isign=1.
;shft=fix(shft+isign*0.5)
;shft=shft+isign*0.5
!p.title='cntrd='+strtrim(xcen-p1,2)+' max @ '+strtrim(k+p1-range,2)
!x.title='bin shift'
!y.title='Xcor'
if keyword_set(debug) then begin
   setxy
   plot,x,ccor
   oplot,x,mn+ccor*0.
   oplot,[shft,shft],[mn,max(ccp)]
   endif
case 1 of
   diff lt diflim: shft=-9000.+shft     ;peak too small
   else:
   endcase
Return,shft
end
