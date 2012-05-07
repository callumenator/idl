;********************************************************************
function cluster_pts,ks0,minclu=minclu
; ks is indices of bad points
if n_elements(minclu) eq 0 then minclu=2
; reject clusters of size minclu or smaller
;
ks=ks0
if n_elements(ks) eq 1 then return,ks    ;one bad point
;
dk=[ks(1:*)-ks,999]               
kk=where(dk gt 1,nclu)
k1=[0,kk+1] & k1=k1(0:nclu-1)    ;first points
if n_elements(k1) eq 1 then nclp=n_elements(ks) else begin   ;> one cluster
   nclp=k1(1:*)-k1
   nclp=[nclp,n_elements(ks)-fix(total(nclp))]
   endelse
k=where(nclp le minclu,nk)
if nk eq 0 then kbad=-1 else begin
   kbad=0
   for i=0,nk-1 do begin
      if k(i) eq 0 then j=0 else j=fix(total(nclp(0:k(i)-1)))
      if i eq 0 then kbad=ks(j)+indgen(nclp(k(i))) else $
         kbad=[kbad,ks(j)+indgen(nclp(k(i)))]
      endfor
   endelse
;
if keyword_set(stp) then stop,'CLUSTER_PTS>>>'
return,kbad
end
