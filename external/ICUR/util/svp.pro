;***********************************************************
pro svp,fact
if n_params(0) eq 0 then fact=1.
if fact lt 1. then fact=1./fact
range=0.7/fact
r0=0.2
!p.position=[r0,r0,range+r0,r0+range]
;set_viewport,r0,range+r0,r0,r0+range
return
end
