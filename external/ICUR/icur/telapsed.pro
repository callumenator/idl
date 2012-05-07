;******************************************************************************
function telapsed,starttime
if n_elements(starttime) eq 0 then return,0
z=systime(0)
s=size(starttime)
if s(s(0)+1) eq 7 then begin
   h=fix(strmid(starttime,11,2))
   m=fix(strmid(starttime,14,2))
   s=fix(strmid(starttime,17,2))
   t0=h*3600L+m*60L+s
   endif else t0=starttime
;
h=fix(strmid(z,11,2))
m=fix(strmid(z,14,2))
s=fix(strmid(z,17,2))
t1=h*3600L+m*60L+s
;
t=t1-t0
if t lt 0 then t=t+86400L
if t lt 32766L then t=fix(t)
return,t
end
