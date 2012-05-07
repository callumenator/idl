;************************************************************************
pro spxcor,f1,f2,xc,cut
if n_params(0) lt 4 then cut=50
np=n_elements(f1)
temp=f1(cut:np-1-cut)    ;cut off 50 points
xc=fltarr(1+2*cut)
for i=0,cut*2 do xc(i)=total(temp*f2(i:i+np-1-2*cut))
return
end
