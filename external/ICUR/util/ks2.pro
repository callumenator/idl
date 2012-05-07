;*******************************************************
function ks2,d1i,d2i    ;2 sided K-S test
d1=d1i
d2=d2i
d1=d1(sort(d1))
d2=d2(sort(d2))
n1=n_elements(d1)
n2=n_elements(d2)
i1=1
i2=1
fo1=0.
fo2=0.
d=0.
while (i1 lt n1) and (i2 lt n2) do begin   ;loop
   if (d1(i1-1) lt d2(i2-1)) then begin
      fn1=float(i1)/float(n1)
      dt=abs(fn1-fo2)>abs(fo1-fo2)
      d=dt>d
      fo1=fn1
      i1=i1+1
      endif else begin
      fn2=float(i2)/float(n2)
      dt=abs(fn2-fo1)>abs(fo2-fo1)
      d=dt>d
      fo2=fn2
      i2=i2+1
      endelse
   endwhile
alam=D*sqrt(float(n1*n2)/float(n1+n2))
p=probks(alam)
return,p
end
