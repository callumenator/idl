;****************************************************************************
function get_ext,file
if n_elements(file) eq 0 then return,''
if not ifstring(file) then return,''             ;not a string
bf=byte(file)
case !version.os_family of
   'vms':  dd=byte(']')                      ;directory?
   'unix': dd=byte('/')                      ;directory?
   else:  dd=byte('\')                      ;windows
   endcase
kd=where(bf eq dd(0),nkd)
kdot=strpos(file,'.',MAX(kd))
if MAX(kdot) eq -1 then return,''
ext=strtrim(strmid(file,kdot+1,20),2)
if strlen(ext) eq 0 then ext=' '
return,ext
end
