;*************************************
function icdcts,file,stp=stp,helpme=helpme
;
if n_elements(file) eq 0 then helpme=1
if keyword_set(helpme) then begin
   print,' '
   print,' function ICDCTS - returns total flux in spectrum'
   print,' '
   return,0
   endif
;
nrec=get_nspec(file)
tcts=fltarr(nrec)-1.
;
for i=0,nrec-1 do begin
   gdat,file,h,w,f,e,i,/noprint
   tcts(i)=total(f)
   endfor
;
if keyword_set(stp) then stop,'ICDCTS>>>'
return,tcts
end
