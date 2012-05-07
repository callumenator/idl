;***************************************************************************
function cumdist,x
np=n_elements(x)
if np lt 2 then return,-1
z=x
z(0)=x(0)
for i=1L,np-1L do z(i)=z(i-1)+x(i)
;for i=0L,np-1L do z(i)=total(x(0:i))
return,z
end
