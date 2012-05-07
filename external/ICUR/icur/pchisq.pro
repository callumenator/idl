;**********************************************************************
function pchisq,chi2,dof
if n_params(0) lt 2 then begin
   print,' '
   print,' PCHISQ - returns probability of exceeding chi-square'
   print,'    calling sequence: P=PCHISQ(chi2,dof)'
   print,'       chi2: chi-square of fit'
   print,'       dof : number of degrees of freedom'
   print,' '
   return,0
   endif
if chi2 le 0. then return,1.
k=dof mod 2
if (k eq 1) and (dof gt 25) then k=2     ;round off errors too big
if (k eq 1) and (chi2 ge 50.) then k=2     ;round off errors too big
chi22=double(chi2)/2.D0
j=(dof-2.D0)/2.D0
reset:
case 1 of
   k eq 0: begin       ;even dof
      j=fix(j)
      p=0.D0
      t=1.D0
      if j gt 0 then for i=1,j+1 do begin
         p=p+t
         t=t*chi22/double(i)
         endfor else p=1.D0
      p=p*exp(-chi22)
      end
   k eq 1: begin         ;odd DOF
      pwr=dof/2.D0
      t=1.D0
      p=t/pwr
      imax=1000
      for i=1,imax do begin
         t=-t*chi22/double(i)
         p=p+t/(pwr+double(i))
         if abs(t/p) lt 5.e-6 then goto,out
         endfor
out:
      p=1.-p*(chi22^(pwr))/gamma(pwr)
      end
   k eq 2: begin       ;approximate to avoid round off errors
      dofa=dof-1
      j=(dofa-2)/2
      p=0.D0
      t=1.D0
      for i=1,j+1 do begin
         p=p+t
         t=t*chi22/double(i)
         endfor 
      pa=p
      dofb=dof+1
      j=(dofb-2)/2
      p=0.D0
      t=1.D0
      for i=1,j+1 do begin
         p=p+t
         t=t*chi22/double(i)
         endfor 
      pb=p
      p=(pa+pb)*exp(-chi22)/2.D0
      end
   endcase
return,float(p)
;
end
