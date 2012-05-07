;***********************************************************************
pro vectstat,vect,mv,sdv,lu=lu
nv=n_elements(vect)
if nv lt 1 then begin
   print,' '
   print,' * VECTSTAT - vector statistics'
   print,' *    calling statistics: VECTSTAT,vector,mv,sdv'
   print,' *       mv, sdv: output mean and standard deviations'
   print,' *'
   print,' * KEYWORDS:'
   print,' *   LU: logical unit for output, default=terminal'
   print,' '
   return
   endif
;
if n_elements(lu) eq 0 then lu=-1
s=size(vect)
nd=s(0)
ns=n_elements(s)
if nd eq 0 then begin
   printf,lu,' This is a scalar, value=',vect
   return
   endif
if s(ns-2) eq 7 then begin
   printf,lu,' vector is a string array of size ',nv
   return
   endif
if nd eq 2 then printf,lu,' vector is 2-dimensional, ',s(1),' by ',s(2)
if nv eq 1 then begin
   printf,lu,' This is single element array, value=',vect
   return
   endif
;
mv=mean(vect)
sdv=stddev(vect)
sdvm=sdv/sqrt(nv)
printf,lu,' Mean=',mv,' +/-',sdvm,'  Median=',median(vect)
printf,lu,' StdDev=',sdv
printf,lu,' Minimum=',min(vect),'   maximum=',max(vect),'   total=',total(vect)
printf,lu,' There are ',nv,' points in the vector'
!c=-1
return
end
