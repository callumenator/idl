;************************************************
function indexofrefrac,wave
; wave in A
lam=wave/1.e4    ;microns
sig=1.D0/lam
n=1.D0+1.e-7*(643.28D0+294981.D0/(146.-sig*sig)+2554.0D0/(41.D0-sig*sig))
return,n
end
