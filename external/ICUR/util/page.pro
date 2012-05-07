;*************************************************************************
pro page,h,nl=nl,helpme=helpme
nh=n_elements(h)
nl0=22
if nh eq 0 then helpme=1
if not ifstring(h) then helpme=1
if keyword_set(helpme) then begin
   print,' '
   print,'* PAGE:  page through string array'
   print,'* calling sequence: PAGE,H'
   print,'* '
   print,'* KEYWORDS:'
   print,'*    NL: number of lines per page, def= ',strtrim(nl0,2)
   print,' '
   return
   endif
;
igo=' '
if n_elements(nl) eq 0 then nl=nl0
np=1+(nh-1)/nl0
for i=0,np-1 do begin
   print,h(i*nl0:(i+1)*nl0)
   read,igo,prompt='       <RETURN to continue> '
   if strupcase(igo) eq 'Q' then goto,out
   endfor
;
out:
return
end
