;****************************************************************************
pro imsmooth,arr,xsmooth=xsmooth,ysmooth=ysmooth,stp=stp
s=size(arr)
if s(0) lt 2 then begin
   print,' IMSMOOTH operates only on images'
   return
   endif
if n_elements(xsmooth) eq 1 then begin
   nsmooth=xsmooth
   if nsmooth lt 0 then begin
      nsmooth=abs(nsmooth)
      tsm=1
      endif else tsm=0
   if nsmooth le 0 then nsmooth=3
   odd=(nsmooth mod 2)
   if tsm eq 1 then begin
      kernel=fltarr(nsmooth)
      if odd then begin
         hp=(nsmooth-1)/2
         i=indgen(nsmooth)
         kernel=float(i+1)/(hp+1.)
         i=hp+indgen(hp)+1
         kernel(i)=kernel(nsmooth-i-1)
         endif else begin                   ;even
         hp=(nsmooth)/2
         i=indgen(nsmooth)
         kernel=float(2.*(i+1))/(nsmooth+1.)
         i=hp+indgen(hp)
         kernel(i)=kernel(nsmooth-i-1)
         endelse
      endif else begin   ;boxcar
      if odd eq 0 then nsmooth=nsmooth+1
      kernel=fltarr(nsmooth)+1.
      endelse
   kernel=kernel/float(total(kernel))
   arr=convol(arr,kernel)
   endif     ;x
if n_elements(ysmooth) eq 1 then begin
   nsmooth=ysmooth
   if nsmooth lt 0 then begin
      nsmooth=abs(nsmooth)
      tsm=1
      endif else tsm=0
   if nsmooth le 0 then nsmooth=3
   odd=(nsmooth mod 2)
   if tsm eq 1 then begin
      kernel=fltarr(nsmooth)
      if odd then begin
         hp=(nsmooth-1)/2
         i=indgen(nsmooth)
         kernel=float(i+1)/(hp+1.)
         i=hp+indgen(hp)+1
         kernel(i)=kernel(nsmooth-i-1)
         endif else begin                   ;even
         hp=(nsmooth)/2
         i=indgen(nsmooth)
         kernel=float(2.*(i+1))/(nsmooth+1.)
         i=hp+indgen(hp)
         kernel(i)=kernel(nsmooth-i-1)
         endelse
      endif else begin   ;boxcar
      if odd eq 0 then nsmooth=nsmooth+1
      kernel=fltarr(nsmooth)+1.
      endelse
   kernel=transpose(kernel)
   kernel=kernel/float(total(kernel))
   arr=convol(arr,kernel)
   endif     ;y
if keyword_set(stp) then stop,'IMSMOOTH>>>'
return
end
