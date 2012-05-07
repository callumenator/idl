;****************************************************************
function ebyte,e
n=n_elements(e)
if n gt 32767 then e1=bytarr(32768L) else e1=bytarr(n)
k=where(e gt 0) & if k(0) ne -1 then e1(k)=0b   ;good data
k=where((e gt -201) and (e le 0)) & if k(0) ne -1 then e1(k)=1b ;extrapolated ITF
k=where((e gt -221) and (e le -201)) & if k(0) ne -1 then e1(k)=2b ;microphonics
k=where((e gt -301) and (e le -221)) & if k(0) ne -1 then e1(k)=3b ;hot spot
k=where((e gt -801) and (e le -301)) & if k(0) ne -1 then e1(k)=4b ;reseau
k=where((e gt -1601) and (e le -801)) & if k(0) ne -1 then e1(k)=5b ;saturated
k=where(e le -1601) & if k(0) ne -1 then e1(k)=6b ;uncorrected
return,e1
end

