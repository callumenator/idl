;*****************************************************************************
function get_nspec,file,recs,helpme=helpme
if n_elements(file) eq 0 then helpme=1
if keyword_set(helpme) then begin
   print,' '
   print,'* Function GET_NSPEC : returns number of records in .ICD file'
   print,'* calling sequence: nrec=get_nspec(file,recs)'
   print,'*    recs: optional output array of record numbers'
   print,' '
   return,''
   endif
;
if strlen(get_ext(file)) eq 0 then ext='.icd' else ext=''
direc=''
if not ffile(file+ext) then begin    ;file does not exist
   icurdata=getenv('icurdata')
   if strlen(icurdata) gt 0 then begin
      if ffile(icurdata+file+ext) then direc=icurdata
      endif
   if not ffile(direc+file+ext) then begin    ;file does not exist
      print,' file ',file,' does not exist.
      return,0
      endif
   endif
;
openr,lu,direc+file+ext,/get_lun
p=assoc(lu,bytarr(512))
rec0=p(0)
close,lu & free_lun,lu
rec0off=32
recs=where(rec0(rec0off:*) eq 1b,num)
return,num
end
