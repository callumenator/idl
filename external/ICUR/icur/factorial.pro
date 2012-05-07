;**************************************************************************
function factorial,nn
n=nn
np=n_elements(nn)
k=where(nn gt 33,nk)
   if nk gt 0 then begin
   print,' FACTORIAL: WARNING: values >33 reset to 33'
   n(nk)=33
   endif
k=where(nn lt 1,nk)
   if nk gt 0 then begin
   n(nk)=1
   endif
;
f=dblarr(np)+1.D0
for k=0,np-1 do begin
   if n(k) gt 1 then for i=2L,long(n(k)) do f(k)=f(k)*i
   endfor
if np eq 1 then begin
   f=f(0)
   case 1 of
      f le 32767L: f=fix(f)
      (f gt 32767L) and (f le 2147483647L): f=long(f)
      else: f=float(f)
      endcase
   endif
return,f
end
