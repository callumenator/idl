;***************************************************************
pro trism,v,f,helpme=helpme
COMMON COM1,H,IK,IFT,X,C
NSM=FIX(ABS(V))
nmax=(NSM+1)/2
i=indgen(nmax-1)
j=nsm-i-1
c=(1.+findgen(nsm))/float(nmax)
c(j)=c(i)
C=C/TOTAL(C)
if n_elements(f) eq 0 then f=convol(f,c)
return
end
