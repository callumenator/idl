;********************************************************************
function minfilt,f,kbad,nb
;kbad vector contains indices of bad data points
; nb is number of bins
if n_params(0) eq 0 then return,-1
if n_params(0) lt 3 then nb=5
n=n_elements(f)-1L
if n_params(0) eq 1 then kbad=intarr(1)-1
f1=f
if kbad(0) ne -1 then f1(kbad)=1.E20
ff=f
for i=0L,n do begin
   ff(i)=min(f1((i-nb)>0:(i+nb)<n))
   endfor
return,ff
end
