;******************************************************************
function get_idat,file
if !version.os ne 'vms' then begin
   read,' GET_IDAT: Because UNIX is stupid, Please enter IDAT (0-11)',IDAT
   return,idat
   endif
idat=-1
if not ifstring(file) then return,file
f=file
k=strpos(f,'.')
if k eq -1 then f=f+'.dat'
on_ioerror,nofile
openr,lun,f,/get_lun
on_ioerror,null
t=fstat(lun)
zerr=t.rec_len
;zerr=!err
z=assoc(lun,bytarr(zerr))
k=z(0)
id1=k(0)+k(1)   ;valid for idat=5,6,7,8
if id1 gt 10 then begin
   z=assoc(lun,fltarr(zerr/4))
   k=fix(z(0))
   id1=k(0)
   endif
idat=id1
close,lun
free_lun,lun
nofile:
return,fix(idat)
end
