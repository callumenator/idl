;********************************************************************
function z2prob,z2,ntrials,prt=prt,helpme=helpme,stp=stp
if n_params() eq 0 then helpme=1
if n_elements(z2) eq 0 then helpme=1
if keyword_set(helpme) then begin
   print,' '
   print,'* FUNCTION Z2PROB - returns probability of getting Z^2'
   print,'* calling sequence: prob=Z2PROB(z2,ntrials)
   print,'*    PROB: probability'
   print,'*    Z2: Z^2 value'
   print,'*    NTRIALS: numbers of trials (optional)'
   print,' '
   return,0
   endif
;
z2t=double(z2)
nz=n_elements(z2)
if n_elements(ntrials) eq 0 then ntrials=1
ntrials=ntrials>1
if keyword_set(prt) then begin
   if n_elements(z2) gt 1 then prt=2
   endif else prt=0
;
zprob=1.D0-chisqr_pdf(z2t,2)    ;Z test probability
;
if ntrials gt 1 then fap=zprob*ntrials*100. else fap=strarr(nz)+' '
case prt of
   1: print,' Probability of getting z^2 of ',z2t,' = ',zprob
   2: begin
         print,' Z^2      Prob      FAP(%)
         for i=0,nz-1 do print,z2(i),zprob(i),fap(i)
         end
   else:
   endcase
;
if keyword_set(stp) then stop,'ZPROB>>>'
case 1 of
   (ntrials le 1): return,zprob
   (ntrials gt 1) and (nz eq 1): return,[zprob,fap]
   (ntrials gt 1) and (nz gt 1): return,[[zprob],[fap]]
   else:
   endcase
;
return,zprob
end
