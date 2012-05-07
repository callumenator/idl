;***************************************************************
pro lscale,wf      ;apply logarithmic scaling to image wf
if n_params(0) eq 0 then begin
   print,' '
   print,'* LSCALE - scale linear image to logarithmic intensity scale'
   print,'*    calling sequence: LSCALE,IMAGE'
   print,'*   output is scaled 0-32767 (integers)'
   print,' '
   return
   endif
;m=fix(mean(wf))
m=0
wf=(wf-m)>1
wf=alog10(wf)
mx=32767./max(wf)
wf=fix(wf*mx)
return
end

