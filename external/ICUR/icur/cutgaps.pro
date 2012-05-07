;*********************************************************************
pro cutgaps,h,w,f,e,ngap,wgap1,wgap2
h(900)=ngap
if ngap le 0 then return
help,w
for i=0,ngap-1 do begin
   print,' cutting gap',i,wgap1(i),wgap2(i)
   dw=wgap2(i)-wgap1(i)
   k=where((w lt wgap1(i)) or (w gt wgap2(i)))
   w=w(k)
   f=f(k)
   e=e(k)
   h(901+i*4)=fix(wgap1(i))
   h(902+i*4)=fix(30000.*(wgap1(i)-h(901+i*4)))
   h(903+i*4)=fix(dw)
   h(904+i*4)=fix(30000.*(dw-h(903+i*4)))
   endfor
help,w
return
end
