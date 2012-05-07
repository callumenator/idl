;**************************************************************************
function lfactorial,nn,nolog=nolog,helpme=helpme
if keyword_set(helpme) then begin
   print,' '
   print,'* FUNCTION LFACTORIAL'
   print,'*    calling sequence: x=lfactorial(n)'
   print,'*    returns log(n!), unless /NOLOG is set
   print,'*    n is forced to be an integer'
   print,' '
   return,-1
   endif
n=fix(nn)
if n le 1 then return,0
f=0.
for i=2L,long(n) do f=f+alog10(float(i))
if keyword_set(nolog) and (f le 38.) then begin
   f=10^f
   case 1 of
      f lt 32767.: f=fix(f)
      f lt 2.^(31): f=long(f)
      else:
      endcase
   endif
return,f
end
