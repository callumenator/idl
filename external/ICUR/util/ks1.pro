;**********************************************************************
function ks1,d1,func,cumd=cumd,stp=stp
np=n_elements(d1)
cumd=cumdist(d1)
cumd=float(cumd)/max(cumd)                ;normalize cumulative distribution
;
d=d1(sort(d1))               ;sort data
nf=n_elements(func)
if nf eq 0 then func=findgen(np)/(np-1) else begin   ;normalize
   if nf ne np then func=interpol(func,nf,np)
   func=func-min(func)
   func=func/max(func)
   endelse
k=where(func eq max(func)) & if k(0) eq 0 then func=reverse(func)
;
dist=abs(func-cumd)
dist=max(dist)
p=probks(dist*sqrt(np))
if keyword_set(stp) then stop,'KS1>>>'
return,p
end
;	SUBROUTINE KSONE(DATA,N,FUNC,D,PROB);
;	DIMENSION DATA(N;)
;	CALL SORT(N,DATA)
;	EN=N
;	D=0.
;	FO=0.
;	DO J=1,N
;		FN=J/EN
;		FF=FUNC(DATA(J))
;		DT=AMAX1(ABS(FO-FF),ABS(FN-FF))
;		IF(DT.GT.D)D=DT
;		FO=FN
;	ENDDO
;	PROB=PROBKS(SQRT(EN)*D)
;	RETURN
;	END
