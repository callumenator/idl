;******************************************************************
pro whereami,z,all=all,verbose=verbose,stp=stp
help,call=c
c=c(1:*)
nlev=n_elements(c)
case 1 of
   keyword_set(all): z=c
   else: z=c(0)
   endcase
;
if n_params() eq 0 then verbose=1
if keyword_set(verbose) then begin
   print,' You are at level',string(nlev-1,'(I2)'),' in ',c(0)
   b='            '      
   if nlev gt 1 then for i=1,nlev-2 do print,b,' called by ',c(i)
   endif
if keyword_set(stp) then stop,'WHEREAMI>>>'
return
end
