;***********************************************************************
function avbad,f1,e,kk,bad=bad     ;expunge bad data points
;
f=f1
; first, get rid of single points
f=avspt(f,e,kz,bad=bad)
if n_elements(kz) eq 0 then kk=-1 else kk=kz           ;indices of single pts
;
np=n_elements(f)-1
if n_elements(bad) gt 0 then k=bad else case 1 of
      (min(e) eq 0) and (max(e) lt 10): k=where(e gt 1)
      (min(e) lt 0)                   : k=where(e lt -200)
      else                            : k=where(e eq 0)
      endcase
nk=n_elements(k)          ;number of bad points
nkk=n_elements(kz)        ;number of bad single points
nsp=nk-nkk                ;number of other bad points
if nk le 0 then return,f
if nsp le 0 then return,f 
;
if nkk gt 0 then begin     ;there are single bad points
   for i=0,nkk-1 do k(where(k eq kk(i)))=-1
   k=k(where(k gt -1))
   nk=n_elements(k)
   if nk ne nsp then begin
      print,' AVBAD: Warning: nk=',nk,' nk-nkk=',nsp
      endif
   endif
;
k1=k(1:*)-k       ;difference
k2=where(k1 gt 1,nk2)
if nk2 eq 0 then k2=[0,n_elements(k)] else k2=[0,k2+1,n_elements(k)]
nk2=nk2+1      ;number of bad intervals
print,nk2,' bad intervals being interpolated'
for i=0,nk2-1 do begin
   i1=k(k2(i))-1 & i2=k(k2(i+1)-1)+1
   case 1 of
      i1 eq -1: f(0:i2-1)=f(i2)
      i2 ge np: f(i1+1:*)=f(i1)
      else: begin
         np1=i2-i1    ;number of points
         sl=(f(i2)-f(i1))/np1
         x=f(i1)+findgen(np1)*sl
         f(i1)=x
         end
      endcase
   endfor
;
return,f
end
