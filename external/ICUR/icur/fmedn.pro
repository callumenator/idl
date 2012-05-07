;**************************************************************************
function fmedn,vector
n=n_elements(vector)
if n lt 3 then return,-999
nm=(n-1)/2    ;median index
s=vector(sort(vector))
return,s(nm)
end
