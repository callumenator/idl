;************************************************************************
FUNCTION MEAN,VECTOR,weights,unc=unc,helpme=helpme   ;COMPUTE MEAN OF VECTOR
N=N_ELEMENTS(VECTOR)
IF N le 0 THEN helpme=1
if keyword_set(helpme) then begin
   print,' '
   print,'* MEAN - returns mean of vector'
   print,'* calling sequence: m=MEAN(v,w)'
   print,'*    V: input vector'
   print,'*    W: weights (optional)'
   print,' '
   RETURN,-1   ;NO ARRAY PASSED
   endif
IF n EQ 1 THEN RETURN,VECTOR   ;SCALAR PASSED
;
if n_elements(weights) eq n then begin
   MEAN=TOTAL(double(VECTOR*weights))/total(weights)
   unc=sqrt(1./total(weights*weights))
   endif else MEAN=TOTAL(double(VECTOR))/double(N)
RETURN,MEAN
END
