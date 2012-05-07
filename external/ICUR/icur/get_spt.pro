;***************************************************************************
function get_spt,title
if n_elements(title) eq 0 then return,''
if ifstring(title) ne 1 then return,''
t=strtrim(title,2)
nt=n_elements(t)
bt=byte(t)
k=where(bt eq 32b,ns)
if ns eq 0 then return,''
k=max(k)
return,strmid(t,k+1,10)
end
