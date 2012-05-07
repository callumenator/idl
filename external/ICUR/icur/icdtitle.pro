;***********************************************************************
function icdtitle,file,rec,helpme=helpme
np=n_params(0)
case np of
   0: helpme=1
   1: if n_elements(file) lt 160 then helpme=1
   2: begin
         if not ifstring(file) then helpme=1
         if n_elements(rec) ne 1 then helpme=1
         end
   endcase
;
if keyword_set(helpme) then begin
   print,''
   print,'* ICDTITLE: returns title of ICD record'
   print,'*   calling sequence: z=icdtitle(file,rec) or'
   print,'*                     z=icdtitle(h)'
   print,'*   FILE,REC: name of .ICD file and record in file'
   print,'*   H:        header vector from .ICD file'
   print,''
   return,''
   endif
;
if np eq 2 then gdat,file,h,w,f,e,rec else h=file
return,strtrim(string(byte(h(100:160)>32b)),2)
end
