;***************************************************************************
pro loglam,w,f,lw,lf,flag
if n_params(0) lt 4 then begin
   print,' '
   print,'* LOGLAM - convert from linear to logarithmic wavelength scale'
   print,'*    calling sequence: LOGLAM,w,f,wl,fl,[flag]'
   print,'*       W,F   : input wavelength and flux vectors'
   print,'*       WL,FL : output vectors, WL is linear in log-lambda'
   print,'*       FLAG  : 1 to force F to input WL scale, default=0'
   print,' '
   return
   end
if n_params(0) lt 5 then flag=0
if n_elements(lw) le 1 then flag=0   ;lw undefined or a scalar
np=n_elements(w)
;
if flag eq 0 then begin
   w0=alog10(double(w(0)))
   w1=alog10(double(w(np-1)))
   dw=(w1-w0)/double(np-1)
   lw=w0+double(indgen(np))*dw
   endif
lf=interpol(f,w,10^(lw))
lw=float(lw)
return
end
