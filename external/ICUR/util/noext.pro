;*****************************************************************
function noext,file
if strlen(get_ext(file)) eq 0 then return,1 else return,0
end
