;******************************************************************************
pro strip_tab,z,verbose=verbose,ltab=ltab                ;replace tab characters with spaces
if n_params(0) eq 0 then begin
   print,' '
   print,'* STRIP_TAB '
   print,'*    calling sequence: STRIP_TAB,Z'
   print,'*    strip TAB characters from string and replace with blanks '
   print,'*  KEYWORDS:'
   print,'*    VERBOSE: set for debugging printout'
   print,' '
   return
   endif
if not ifstring(z) then begin
   print,' STRIP_TAB: Argument must be a string'
   return
   endif
;
if not keyword_set(ltab) then ltab=8
if keyword_set(verbose) then ivb=1 else ivb=0
b=byte(z)
k=where(b eq 9b,ntab)
if ivb then begin
   print,z
   print,b
   print,' Number of tabs found:',ntab
   endif
if ntab eq 0 then return     ;no tabs
while ntab gt 0 do begin
   kk=k(0)
   nsp=(kk/ltab+1)*ltab-kk
   b=[b(0:kk-1),32b+bytarr(nsp),b(kk+1:*)]
   if ivb then begin
      print,k,kk,nsp
      print,z,string(b)
      endif
   k=where(b eq 9b,ntab)
   endwhile
z=string(b)
return
end
