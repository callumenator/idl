;*********************************************************************
function get_ffl,name,stp=stp
if ifstring(name) ne 1 then name='FUDGE'
openr,lu,name+'.ffl',/get_lun
readf,lu,nl
wl=fltarr(nl)
readf,lu,wl
close,lu
free_lun,lu
if keyword_set(stp) then stop,'GET_FFL>>>'
return,wl
end
