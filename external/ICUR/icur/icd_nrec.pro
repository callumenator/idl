;****************************************************************************
function icd_nrec,file
if ifext(file) then f=file else f=file+'.icd'
if not ffile(f) then begin
   print,' File ',f,' not found - returning'
   return,-999
   endif
openu,lu,f,/get_lun
p=assoc(lu,bytarr(512))
rec0=p(0)
close,lu & free_lun,lu
;
rec0off=32
k=where(rec0(rec0off:*) gt 0b)   ;bytes 0:rec0off-1 reserved
nrec=max(k)+1        ;next free record
return,nrec
end
