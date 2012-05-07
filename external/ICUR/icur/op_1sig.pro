;**************************************************************
pro op_1sig,h,wave,flux,esave
if h(33) eq 30 then eps0=flux/esave else eps0=esave
if (h(33) eq 40) or (h(33) eq 30) then begin
   ex=optfilt(eps0)
   fx1=optfilt(flux)
   oplot,wave,fx1+ex,color=c8,linestyle=1
   oplot,wave,fx1-ex,color=c8,linestyle=1
   endif
return
end

