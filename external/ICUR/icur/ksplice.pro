;****************************************************
pro ksplice,h,w,e,k1,k2          ;mark splice points as bad
if n_params(0) lt 3 then begin
   print,' KSPLICE must be called with 3 parameters: H,W,E'
   print,'    optional parameters are k1, k2'
   return
   endif
if n_params(0) lt 5 then k2=25
if n_params(0) lt 4 then k1=15
np=n_elements(w)
if h(700) ne 0 then begin
   wsplice=dblarr(h(2)-1)
   for i=0,h(2)-2 do begin
      j=700+i*2
      wsplice(i)=double(h(j))+double(h(j+1))/1000.D0
      endfor
   kspl=xindex(w,wsplice)     ;tabinv,w,wsplice,kspl
   kspl=long(kspl+0.5)
   l=where((wsplice gt w(0)) and (wsplice lt w(np-1)))
   for i=min(l),max(l) do e(((kspl(i)-k1)>0):((kspl(i)+k2)<np-1))=7
   endif
return
end

