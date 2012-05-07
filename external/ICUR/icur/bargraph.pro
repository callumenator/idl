;****************************************
pro bargraph,x,y,ynz=ynz,stp=stp
z=y/max(abs(y))
if keyword_set(ynz) then begin
   ymin=min(z) & ymax=max(z)
   endif else begin
   ymin=-1. & ymax=1.
   if min(z) ge 0. then ymin=0.
   if max(z) le 0. then ymax=0.
   endelse
sp=(ymax-ymin)/20.
nl=22
graph=bytarr(79,nl)+32b
np=n_elements(y)<75
graph(5,*)=byte('|') & graph(78,*)=byte('|')
lab=strarr(nl-1)
for i=0,nl-2 do lab(i)=string(ymin+sp*i,'(F5.2)')
for i=0,nl-2 do graph(0,nl-2-i)=byte(lab(i))
graph(*,0)=byte('_') & graph(*,nl-2)=byte('_')
;
graph(5,nl-1)=byte(strtrim(x(0),2))
graph(5+np-1,nl-1)=byte(strtrim(x(np-1),2))
if sp eq 0. then sp=1.
yp=fix((z-ymin)/sp)
for i=0,np-1 do graph(i+5,nl-2-yp(i))=byte('*')
for i=0,nl-1 do print,string(graph(*,i))
if keyword_set(stp) then stop
return
end
