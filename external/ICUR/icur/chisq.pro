;*************************************************************************
function chisq,y,dy,model
; return chi-square value
if n_params(0) eq 0 then return,-1
if n_params(0) eq 1 then dy=sqrt(y)
if n_params(0) lt 3 then model=mean(y)
n=n_elements(y)
ddy=dy & k=where(ddy eq 0.,nk) & if nk gt 0 then ddy(k)=1.
z=(y-model)/ddy
chisq=total(z*z)
return,chisq
end
