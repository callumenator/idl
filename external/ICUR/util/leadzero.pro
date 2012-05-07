;************************************************************************
function leadzero,input,length,stp=stp,blank=blank
if n_params(0) lt 2 then begin
   print,' '
   print,'* function LEADZERO'
   print,'* pad with leading zeros to form fixed length string'
   print,'* calling sequence: out=LEADZERO(input,length)'
   print,'*   INPUT: string or integer'
   print,'*   LENGTH: number of bytes in output string'
   print,'* '
   print,'* KEYWORD:'
   print,'*    BLANK: if set, pad with blanks instead of zeros'
   print,' '
   return,''
   endif
input=strtrim(input,2)
pad='00000000000000000000'
if keyword_set(blank) then pad='                                       '
z=strmid(pad,0,length)
output=z+input
l=strlen(output)
lex=l-length
maxlex=max(lex)
if maxlex gt 0 then for i=1,maxlex do begin
   k=where(lex eq i,nk)
   if nk gt 0 then output(k)=strmid(output(k),i,length)
   endfor
if keyword_set(stp) then stop,'>>>LEADZERO'
return,output
end
