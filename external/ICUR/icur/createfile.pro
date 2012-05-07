;*************************************************************************
pro createfile,name
if n_params(0) eq 0 then begin
   print,' '
   print,'* CREATEFILE - create an ascii file'
   print,'*    calling sequence: CREATEFILE,filename'
   print,' '
   return
   endif
get_lun,lu
openw,lu,name
close,lu
free_lun,lu
return
end
