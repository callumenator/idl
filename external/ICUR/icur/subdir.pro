;***************************************************************************
function subdir,helpme=helpme
cd,current=x
bx=byte(x)
case 1 of               ;delimiters
   strupcase(!version.os) eq 'VMS': z=byte('.')
   strupcase(!version.os) eq 'VMS': z=byte(x,'/')
   strupcase(!version.os) eq 'UNIX': z=byte(x,'\')
   else: return,x
   endcase
k=where(bx eq z(0),nk)
if nk gt 0 then bx=bx(k(nk-1)+1:*)
sl=n_elements(bx)
if strupcase(!version.os) eq 'VMS' then bx=bx(0:sl-2)    ;cut ]
return,string(bx)
end
