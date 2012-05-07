;*************************************************************************
function stddev,dist,m,nomean=nomean,med=med,md=md,ofmean=ofmean,helpme=helpme
nd=n_elements(dist)
if nd eq 0 then helpme=1
if keyword_set(helpme) then begin
   print,' '
   print,'* STDDEV - returns standard deviation of vector'
   print,'* calling sequence: S=STDDEV(VECT,M)'
   print,'*    VECT: input vector'
   print,'*    M:    output mean'
   print,'* '
   print,'* KEYWORDS:'
   print,'*    NOMEAN: if set, take standard deviation about zero'
   print,'*    MED:    if set, use median rather than mean'
   print,'*    MD:     same as MED'
   print,'*    OFMEAN: return standard deviation of mean'
   print,' '
   return,-1
   endif
if nd lt 2 then return,-1
case 1 of
   keyword_set(nomean): m=0
   keyword_set(med): m=median(dist)
   keyword_set(md): m=median(dist)
   else: m=mean(dist)
   endcase
dev=dist-m
dev=dev*dev
stdev=total(dev)/(nd-1)
stdev=sqrt(stdev)
if keyword_set(ofmean) then stdev=stdev/sqrt(nd)
return,stdev
end
