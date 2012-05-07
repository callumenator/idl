;********************************************************************
function optfilt,f00,e00,w1,w2,w3,w4,w5,w1s=w1s,w2s=w2s,w3s=w3s,w4s=w4s,w5s=w5s, $
   helpme=helpme,stp=stp
if n_params(0) eq 0 then helpme=1
if keyword_set(helpme) then begin
   print,' '
   print,'* function OPTFILT : returns "optimal" filter'
   print,'* calling sequence: f=OPTFILT(f,e,w1,w2,w3,w4,w5)
   print,'*'
   print,'* filter widths: w5: median filter width for determining whether'
   print,'*                    features are in emission or absorption, def=51'
   print,'*                w1: initial median filter width, def=15 '
   print,'*                w2: width of max (min) filter, def=31 '
   print,'*                w3: width of min (max) filter, def=31 '
   print,'*                w4: final boxcar filter width, def=51 '
   print,'*'
   print,'* filter widths can be passed as keywords.'
   print,' '
   return,-1
   endif
;
if n_elements(f00) le 1 then return,f00
f0=f00
if n_elements(e00) eq 0 then e00=f00*0.
e0=e00
kf=finite(f0)
;
if keyword_set(w1s) then w1=w1s
if keyword_set(w2s) then w2=w2s
if keyword_set(w3s) then w3=w3s
if keyword_set(w4s) then w4=w4s
if keyword_set(w5s) then w5=w5s
;
if n_elements(w1) eq 0 then w1=15     ;default filter widths
if n_elements(w2) eq 0 then w2=31     ;default filter widths
if n_elements(w3) eq 0 then w3=31     ;default filter widths
if n_elements(w4) eq 0 then w4=51     ;default filter widths
if n_elements(w5) eq 0 then w5=51     ;default filter widths
;
if w1 lt 1 then w1=15     ;default filter widths
if w2 lt 1 then w2=31
if w3 lt 1 then w3=31
if w4 lt 1 then w4=51
if w5 lt 1 then w5=51
;
i1=0 & i2=0
s=size(f0)
ndim=s(0)
if ndim ge 2 then begin
   nap=s(2)
   i2=nap-1
   ff20=f0(*,*,0)*0.
   endif
;
f=f0
if n_elements(e0) gt 0 then e=e0
;
for iap=i1,i2 do begin
   if ndim gt 1 then begin
      f=f0(*,iap,0)
      if n_elements(e0) gt 0 then e=e0(*,iap,0)
      endif
;
   case 1 of
      n_elements(e) eq 0: k=wherebad(-1,1)
      (n_elements(e) eq n_elements(f)) and (min(e) ge 0): k=wherebad(e,1)
      (n_elements(e) lt n_elements(f)) and (min(e) ge 0): k=e
      else: k=wherebad(-1,1)
      endcase
;
   ff=median(f,w5)
   z=mean(f-ff)
   ff=median(f,w1)
   if z ge 0. then begin              ;filter emission lines
      ff1=minfilt(ff,k,w2)
      ff2=maxfilt(ff1,k,w3)
      endif else begin                ;filter absorption lines
      ff1=maxfilt(ff,k,w2)            
      ff2=minfilt(ff1,k,w3)
      endelse
   if w4 ge 3 then ff2=smooth(ff2,w4) 
;
   if ndim gt 1 then ff20(*,iap)=ff2
   endfor   ;iap
;
if ndim gt 1 then ff2=ff20
if keyword_set(stp) then stop,'OPTFILT>>>'
return,ff2
end




