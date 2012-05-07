;************************************************************************
pro chtitle,file,rec,title,helpme=helpme,append=append
if n_params(0) eq 0 then helpme=1
if ifstring(file) ne 1 then helpme=1       ;integer passed
if keyword_set(helpme) then begin   ;help
   print,' '
   print,'* CHTITLE - change title in header vector'
   print,'*    calling sequence: CHTITLE,file,rec,[title]'
   print,'*       file: name of .ICD data file'
   print,'*        rec: record number to be updated'
   print,'*      title: optional string title (prompted if not present)'
   print,'*     both arguments are prompted for if not passed'
   print,'*'
   print,'*   KEYWORDS:'
   print,'*      APPEND, if set, title is appended to current title'
   print,' '
   return
   endif
;
if n_params(0) lt 2 then read,' Enter record number: ',rec
gdat,file,h,w,f,e,rec
ctit,h,nch,title,append=append
if nch ne 1 then kdat,file,h,w,f,e,rec
return
end
