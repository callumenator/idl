;***********************************************************************
function fixbadpts,vect,bad
;
iret=0
np=n_elements(vect)
if np lt 3 then iret=1
if n_params(0) lt 2 then iret=1
if iret eq 1 then begin
   print,' '
   print,'* FIXBADPTS - fix bad points by linear interpolation'
   print,'*    calling sequence: V=FIXBADPTS(VECT,BAD)'
   print,'*       VECT: input vector'
   print,'*        BAD: indices of bad data points'
   print,'*          V: output vector'
   print,'*    technique: linearly interpolate over bad data points'
   print,' '
   return,vect
   endif
;
k=bad
nbad=n_elements(k)                ;number of bad points
svec=n_elements(vect)                ;number of points
if nbad ge svec then return,vect     ;all points marked as bad
if nbad eq 1 then k=intarr(1)+k   ;make array
if k(0) eq -1 then return,vect    ;no bad data
x=findgen(np)
y=x
y(k)=-999.
z=sort(y)
y=y(z)
tv=vect(z)
y=y(nbad:*)
tv=tv(nbad:*)
if n_elements(tv) eq 1 then return,intarr(svec)+tv(0)    ;only one good point
return,interpol(tv,y,x)
end
