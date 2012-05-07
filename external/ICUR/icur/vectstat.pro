;***********************************************************************
pro vectstat,vect,mv,sdv
nv=n_elements(vect)
if nv lt 1 then begin
   print,' '
   print,' * VECTSTAT - vector statistics'
   print,' *    calling statistics: VECTSTAT,vector,mv,sdv'
   print,' *       mv, sdv: output mean and standard deviations'
   print,' *    all I/O to terminal'
   print,' '
   return
   endif
;
s=size(vect)
nd=s(0)
ns=n_elements(s)
if nd eq 0 then begin
   print,' This is a scalar, value=',vect
   return
   endif
if s(ns-2) eq 7 then begin
   print,' vector is a string array of size ',nv
   return
   endif
if nd eq 2 then print,' vector is 2-dimensional, ',s(1),' by ',s(2)
if nv eq 1 then begin
   print,' This is single element array, value=',vect
   return
   endif
;
mv=mean(vect)
sdv=stddev(vect)
print,' Mean of vector=',mv,'+/-',sdv,'  Median=',median(vect)
print,' Minimum=',min(vect),'   maximum=',max(vect),'   total=',total(vect)
print,' There are ',nv,' points in the vector'
!c=-1
return
end
