;****************************************************************************
pro imcoadd,arr,ncoadd=ncoadd,stp=stp
s=size(arr)
if s(0) lt 2 then begin
   print,' IMCOADD operates only on images'
   return
   endif
;
if n_elements(ncoadd) eq 0 then return
if ncoadd le 1 then return
;
np=(size(arr))(2)
nw=(size(arr))(1)
nb=fix(np/ncoadd)
f1=arr
arr=fltarr(nw,nb)
k0=indgen(nb)
k=indgen(nb)*ncoadd
for i=0,nb-1 do arr(long(k0(i)*nw))=f1(*,k(i))
for j=1,ncoadd-1 do $
      for i=0,nb-1 do arr(long(k0(i)*nw))=arr(*,(k0(i)))+f1(*,k(i)+j)
arr=arr/float(ncoadd)
f1=0
;
if keyword_set(stp) then stop,'IMCOADD>>>'
return
end
