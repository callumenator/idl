;*************************************************************************
function ffile,disk,direc,mfile,ext,notify=notify
if n_params(0) lt 1 then return,0
if n_elements(disk) eq 0 then return,0
case 1 of
   n_params(0) eq 1: file=disk
   n_params(0) eq 2: file=disk+'.'+direc
   n_params(0) eq 3: file=disk+direc+'.'+mfile
   else:             file=disk+':'+direc+mfile+'.'+ext
   endcase
on_ioerror,dne
get_lun,lu
openr,lu,file
igo=1   ;file exists
close,lu
goto,ret
dne: igo=0
if keyword_set(notify) then begin
   bell
   print,' *** FILE ',file,' was not found. ***'
   endif
on_ioerror,null
ret: free_lun,lu
return,igo
end
