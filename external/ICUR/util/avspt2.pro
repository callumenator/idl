;**********************************************************************
function avspt2,f0,e,kk,bad=bad,stp=stp,silent=silent
        ;find single point zeros in image and remove
f=f0
np=n_elements(f)-1
if n_elements(bad) gt 0 then k=bad else case 1 of
      (min(e) eq 0) and (max(e) lt 10): k=where(e gt 1)
      (min(e) lt 0)                   : k=where(e lt -200)
      else                            : k=where(e eq 0)
      endcase
if n_elements(k) le 1 then return,f
nk=n_elements(k)
zp=twodwhere(f,k)           ;2-d indices
s=size(f)
xlen=s(1) & ylen=s(2)
ff=fix(f)*0+1
ff(k)=0      ;zero ALL bad indices
xllim=(zp(*,0)-1)>0
xulim=(zp(*,0)+1)<(xlen-1)
yllim=(zp(*,1)-1)>0
yulim=(zp(*,1)+1)<(ylen-1)
for i=0,nk-1 do begin
   sarr=f(xllim(i):xulim(i),yllim(i):yulim(i))
   nt=ff(xllim(i):xulim(i),yllim(i):yulim(i))
   sarr=sarr*nt
   kb=where(nt eq 1,nk)    ;valid points
   if nk ge 1 then begin
      t=median(sarr(kb))    ;median of good points
      f(k(i))=t
      endif else begin
;      print,i,' AVSPT2: no good points'
;      t=total(sarr)/float(total(nt>1))   ;mean value of surrounding good points
      endelse
   endfor
;
if keyword_set(stp) then stop,'AVSPT2>>>'
return,f
end
