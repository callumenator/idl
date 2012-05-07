;**************************************************************************
function ghrsicurhead,ihf,flux,log,t0,stp=stp        ;make icur-style header
; ihf:  GHRS header vector
; flux: GHRS flux vector
; log:  FITS log 
; t0:   optional title
; h:    output vector
;
s=size(ihf)
ndim=s(0)
sf=size(flux)
;nfl=sf(1)           ;length of flux vector
if sf(0) eq 2 then nfv=sf(2) else nfv=1    ;number of flux vectors
h=intarr(400)                  ;new header vector
h(3)=100+ihf(48)
h(4)=ihf(12)     ;ID number
h(7)=ihf(4)      ;number of points
time=ihf(45)*(ihf(46)>1)*.050        ;time per bin in seconds
ncoadd=h(7)/500                      ;number of steps
time=time*nfv*ncoadd             ;total integration time
h(5)=fix(time)
print,' Integration time = ',time
print,' nfv = ',nfv
date=string(byte(ihf(54:65),0,23))
mos=['JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC']
k=where(mos eq strmid(date,3,3))
h(10)=k+1
h(11)=fix(strmid(date,0,2))
h(12)=fix(strmid(date,9,2))
h(13)=fix(strmid(date,12,2))
h(14)=fix(strmid(date,15,2))
h(15)=fix(strmid(date,18,2))
;
h(200)=ihf(*,0)                      ;insert science log 200-227
if nfv gt 1 then begin
   h(328)=transpose(ihf(20,1:(nfv-1)<3))        ;readouts
   h(331)=transpose(ihf(43,1:(nfv-1)<3))        ;carrousel positions
   endif
;
if n_params(0) lt 3 then return,h                ;no log passed
;
ra=float(sxpar(log,'RTASNTRG'))
degtohms,ra,hr,min,sec
h(40)=hr
h(41)=min
h(42)=fix(sec*100.)
dec=float(sxpar(log,'DECLNTRG'))
degtodms,dec,deg,min,sec
h(43)=deg
h(44)=min
h(45)=fix(sec*100.)
if total(h(40:45)) eq 0 then begin       ;words not in .PLH file
   ra=float(sxpar(log,'RA_TARG'))
   degtohms,ra,hr,min,sec
   h(40)=hr & h(41)=min & h(42)=fix(sec*100.)
   dec=float(sxpar(log,'DEC_TARG'))
   degtodms,dec,deg,min,sec
   h(43)=deg & h(44)=min & h(45)=fix(sec*100.)
   endif
;
if n_elements(t0) eq 0 then t0=''
title=t0+' '+sxpar(log,'rootname')
h(100)=fix(byte(title))
;
if keyword_set(stp) then stop,'GHRSICURHEAD>>>'
;
return,h
end
