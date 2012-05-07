;**********************************************************************
pro spfilt,d,sn,nstd
ihlp=0
if n_params(0) eq 0 then d=-1
if n_elements(d) eq 1 then begin
   print,' '
   print,'* SPFILT - perform single point filter'
   print,'*   calling sequence: SPFILT,D,SN,NSTD
   print,'*       D: data vector'
   print,'*      SN: Signal to noise vector'
   print,'*    NSTD: sigma cutoff, default=3.'
   print,'*'
   print,'* This procedure is called by ICURSPFILT and ECHSPFILT'
   print,' '
   return
   end
;
if n_params(0) lt 3 then nstd=5.
if n_elements(sn) eq 0 then begin     ;SN vector undefined, construct a vector
   np=n_elements(d)/100               ;
   z=d/smooth(d,3)
   sn=z*0.+1./stddev(z)
   endif
;
ylen=n_elements(d)
dd=d-shift(d,1)
n=sort(dd)
std=stddev(dd)
k=where(abs(dd) gt nstd*std)
if k(0) eq 0 then begin                        ;trim ends
   if n_elements(k) gt 1 then k=k(1:*) else k=intarr(1)-1 
   endif
if k(n_elements(k)-1) eq ylen-1 then begin     ;trim ends
   if n_elements(k) gt 1 then k=k(0:n_elements(k)-1) else k=intarr(1)-1
   endif
nbad=n_elements(k)
badindx=intarr(nbad)-1
indx=0
if nbad gt 1 then for j=0,nbad-2 do begin
   if k(j+1)-k(j) eq 1 then begin   ;a pair
      badindx(indx)=k(j)
      j=j+1
      indx=indx+1
      endif
   endfor
if badindx(0) eq -1 then return
badindx=badindx(0:indx-1)
dnew=d
dnew(badindx)=(d(badindx-1)+d(badindx+1))/2.    ;mean
snew=sn
snew(badindx)=(sn(badindx-1)+sn(badindx+1))/2.    ;mean
d=dnew & s=snew
return
end
