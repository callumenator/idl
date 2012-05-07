;*********************************************************************
function ifext,file
helpme=0
if n_elements(file) eq 0 then helpme=1
if not ifstring(file) then helpme=1
if helpme then begin
   print,' '
   print,'* IFEXT tests for the existence of an extension to a file name'
   print,'* calling sequence: IFEXT,file'
   print,'*'
   print,'* IFEXT returns 1 if there is an extension on the file name'
   return,0
   endif
;
if strlen(get_ext(file)) eq 0 then return,0 else return,1
end
