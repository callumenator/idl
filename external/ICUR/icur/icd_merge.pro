;****************************************************************************
pro icd_merge,file,w,f,e,r1=r1,r2=r2,plt=plt,helpme=helpme,stp=stp
;
if n_elements(file) eq 0 then helpme=1
if not keyword_set(stp) then stp=0
if keyword_set(helpme) then begin
   print,' '
   print,'* ICD_MERGE,file,w,f,e '
   print,' '
   return
   endif
;
if n_elements(r1) eq 0 then r1=0
if n_elements(r2) eq 0 then r2=get_nspec(file)-1
nr=r2-r1+1
print,file,r1
specmerge,w,f,e,r1,r1+1,file
if keyword_set(plt) then plot,w,f
if stp gt 1 then stop,'ICD_MERGE(2)>>>'
if nr gt 2 then begin
   for i=2,nr-1 do begin
      r0=r1+i
      print,file,r0
      specmerge,w,f,e,r0,r0,file,/vect
      if keyword_set(plt) then plot,w,f
      if stp gt 1 then stop,'ICD_MERGE(2)>>>'
      endfor
   endif
;
if keyword_set(stp) then stop,'ICD_MERGE>>>'
return
end
