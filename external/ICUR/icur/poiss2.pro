;**************************************************************
function POISS2,flux,minv=minv,stp=stp    ;POISSON NOISE GENERATOR
;
common poisseed,seed,seed2
FACT=[1.,1.,2.,6.,24.,120.,720.,5040.,40320.,362880.,3628800.,3.99168E7, $
      4.79002E8,6.22702E9,8.71783E10,1.30767E12,2.09228E13,3.55687E14, $
      6.40237E15,1.21645E17,2.4329E18,5.10909E19,1,124E21,2.5852E22,6.20448E23]
flux1=flux
gausslim=10.
if n_elements(minv) eq 0 then minv=0.01
NP=N_ELEMENTS(flux1)
if n_elements(seed) eq 1 then seed=seed+systime(1)/100.
GAUSS=RANDOMN(SEED,NP)
flux2=1.0*flux1+SQRT(abs(1.0*flux1))*GAUSS     ;gaussian noise
if min(flux1) gt gausslim then return,flux2
if max(flux1) lt minv then return,flux2*0.
if n_elements(seed2) eq 1 then seed2=seed2+systime(1)/100.
RAND=RANDOMU(SEED2,NP)
R=RAND*EXP(flux1<gausslim)
k=where(flux1 lt 10.,nk) & if nk gt 0 then flux2(k)=0.
;
kp=where((flux1 lt 10.) and (flux1 ge minv),nk)     ;indices for Poison dist
if nk gt 0 then FOR j=0L,Nk-1L DO BEGIN
   i=kp(j)
   IS=0
   SUM=1.
   WHILE (SUM LT R(i)) AND (IS LT 24) DO BEGIN
      IS=IS+1
      SUM=SUM+flux1(I)^is/FACT(IS)
      ENDWHILE
   flux2(I)=FLOAT(IS)
   CON: 
   ENDFOR
if keyword_set(stp) then stop,'POISS2>>>'
RETURN,flux2
END
