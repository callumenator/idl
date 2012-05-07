;**************************************************************
pro kgap,h,w,wgap,ngap,e,eval
ngap=h(900)
if ngap le 0 then return                  ;no gaps
if n_elements(eval) le 0 then eval=7
wgap=dblarr(ngap,2)
for i=0,ngap-1 do begin
   wgap(i,0)=double(h(901+i*4))+h(902+i*4)/30000.D0
   wgap(i,1)=double(h(903+i*4))+h(904+i*4)/30000.D0+wgap(i,0)
   k=where((w gt wgap(i,0)) and (w lt wgap(i,1)))
   k=[k(0)-1,k]
   e(k)=eval    ;gap
   endfor
return
end
