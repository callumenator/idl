;***************************************************************************
pro setxy,a,b,c,d,svp=svp,exact=exact            ;mimic IDL V1 SET_XY procedure
if keyword_set(svp) then !p.position=[0.2,0.2,0.9,0.9]
if n_params(0) eq 0 then begin
   !x.range(*)=0.
   !y.range(*)=0.
   return
   endif
if n_params(0) ge 2 then !x.range(*)=[a,b]
if n_params(0) eq 4 then !y.range(*)=[c,d]
;
if keyword_set(exact) then begin
   if !x.style mod 2 eq 0 then !x.style=!x.style+1
   if (n_params(0) eq 4) and (!y.style mod 2 eq 0) then !y.style=!y.style+1
   endif
;
return
end
