;***************************************************************
function makekernel,s
if s le 1 then return,1
if s mod 2 eq 0 then s=s+1
n=(s+1)/2
z=[1+indgen(n-1),n,reverse(1+indgen(n-1))]
c=fltarr(s,s)
for i=0,n-1 do c(i*s)=z+i
for i=n,s-1 do begin
   j=s-1-i
   c(i*s)=z+j
   endfor
c=c/total(c)
return,c
end
