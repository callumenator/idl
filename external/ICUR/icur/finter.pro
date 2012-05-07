;*******************************************************************
pro finter,w,w0,f0,e0
;fast interpolation for w vectors with gaps
;w is vector w0 is interpolated to
dl=w(1)-w(0)
n1=n_elements(w) & n2=n_elements(w0)
z=abs(w0-w)
k=where(z gt dl/100.) & k=k(0)
if (k eq -1) and (n1 eq n2) then return    ;w,w0 identical
;
wp0=w((k-1)>0:*)
wp=w0((k-1)>0:*)
fp=f0((k-1)>0:*)
ep=e0((k-1)>0:*)
fpp=interpol(fp,wp,wp0)
epp=interpol(ep,wp,wp0)
if k gt 1 then begin
   e0=[e0(0:k-2),epp]
   f0=[f0(0:k-2),fpp]
   endif else begin     ;initial offset
   e0=epp
   f0=fpp
   endelse
return
end
