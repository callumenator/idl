;**********************************************************************
function avspt,f,e,kk,bad=bad   ;find single point zeros in IUEHI file and remove
np=n_elements(f)-1
if n_elements(bad) gt 0 then k=bad else case 1 of
      (min(e) eq 0) and (max(e) lt 10): k=where(e gt 1)
      (min(e) lt 0)                   : k=where(e lt -200)
      else                            : k=where(e eq 0)
      endcase
if n_elements(k) le 1 then return,f
nk=n_elements(k)
k1=[k(1:*),np]
k2=[0L,k(0:*)]              ;was :np - fixed by FMW 6/24/93
dk1=(k1-k)-1    ; dist to next point
dk2=(k-k2)-1
dk=dk1*dk2
kz=where(dk ne 0,nkz)   ;single point zeros
if nkz eq 0 then return,f              ;no single point zeros found
kk=k(kz)                ;indices of single point zeros
if kk(0) eq 0 then begin
   if n_elements(kk) gt 1 then kk=kk(1:*) else return,f   ;first point only
   endif
nkk=n_elements(kk)
if kk(nkk-1) eq np then begin
   if nkk gt 1 then kk=kk(0:nkk-2) else return,f   ;last point only
   endif
nkk=n_elements(kk)
ff=f
for i=0,nkk-1 do ff(kk(i))=(ff(kk(i)-1)+ff(kk(i)+1))/2.
if (k(0) eq 0) and (k(1) ne 1) then begin
  ff(0)=ff(1)
  kk=[0,kk]
  nkk=nkk+1
  endif
if (k(nk-1) eq np) and (k(nk-2) ne np-1) then begin
   ff(np)=ff(np-1)
   kk=[kk,np]
   nkk=nkk+1
   endif
if !quiet ne 3 then print,nkk,' single point zeros restored'
return,ff
end
