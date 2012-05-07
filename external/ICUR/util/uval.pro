;***********************************************************
function uval,var,prt=prt,maxval=maxval,stp=stp,helpme=helpme
if n_elements(var) eq 0 then helpme=1
if n_elements(maxval) eq 0 then maxval=100
if keyword_set(helpme) then begin
   print,' '
   print,'* UVAL: return unique values of variable'
   print,'* calling sequence: values=UVAL(var)'
   print,'*    VAR: variable'
   print,'* '
   print,'* KEYWORDS:'
   print,'*    MAXVAL: maximum number of unique values to print (if /PRT), def=',maxval
   print,'*    PRT: if set, print unique values '
   print,' '
   return,0
   endif
if n_elements(var) eq 1 then return,var
v=var
v=v(sort(v))    ;sort variable
k=v(uniq(v))
nk=n_elements(k)
if keyword_set(prt) then begin
   if nk le maxval then print,k else print,nk,' unique values found'
   endif
if keyword_set(stp) then stop,'UVAL>>>'
return,k
end
