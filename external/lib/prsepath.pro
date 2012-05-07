;================================================================
;  This function ensures that a path string is terminated by
;  the appropriate delimiter for the current OS:
function prsepath, inpath
    places = expand_path(!path)
    if strpos(places, "]") ge 0 then sep = "" 
    if strpos(places, "/") ge 0 then sep = "/" 
    if strpos(places, "\") ge 0 then sep = "\"
    
    fullpath = inpath
    if strmid(inpath, strlen(inpath)-1, 1) ne sep then fullpath = fullpath + sep
    return, fullpath
end
