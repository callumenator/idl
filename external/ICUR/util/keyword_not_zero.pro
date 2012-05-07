;***************************************************************************
function keyword_not_zero,keyword,helpme=helpme
; returns 1 if keyword exists and is non zero
if keyword_set(helpme) then begin
   print,' '
   print,'* Function KEYWORD_NOT_ZERO'
   print,'* calling sequence: answer=keyword_not_zero(keyword)'
   print,'*    Returns 1 if the keyword is defined and not zero'
   print,'*    The string ''0'' returns 1'
   print,' '
   return,0
   endif
answer=0
if n_elements(keyword) eq 1 then begin
   if strtrim(string(keyword),2) ne '0' then answer=1
   if ifstring(keyword) then if keyword eq '0' then answer=1
   endif
return,answer
end
