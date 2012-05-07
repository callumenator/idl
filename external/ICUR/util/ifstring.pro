;*************************************************************
function ifstring,var,stp=stp
s=n_elements(var)
if s eq 0 then return,0
s=size(var)
if keyword_set(stp) then stop
if s(n_elements(s)-2) eq 7 then return,1 else return,0
end
