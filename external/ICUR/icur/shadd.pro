;************************************************************************
pro shadd,nw,good,wave,flux,fluxerr,f,ferr
; shift and add routine
tf=interpol(flux,wave,nw)
te=interpol(fluxerr,wave,nw)
k=where((nw lt min(wave)) or (nw gt max(wave)),nk)
if nk gt 0 then begin
   tf(k)=0. & te(k)=0.
   endif
k=where((nw ge min(wave)) and (nw le max(wave)),nk)
if nk gt 0 then good(k)=good(k)+1
f=f+tf
ferr=ferr+te
return
end
