;***************************************************************************
pro setxy,a,b,c,d,svp=svp,exact=exact,yonly=yonly
;
;mimic IDL V1 SET_XY procedure
;
if keyword_set(svp) then !p.position=[0.2,0.2,0.9,0.9]
np=n_params()
if np eq 0 then begin
   a=0. & b=0. & c=0. & d=0.
   endif

case 1 of
   keyword_set(yonly): begin
      if np eq 2 then begin
         c=a & d=b
         endif
      !y.range(*)=[c,d]
      end
   else: begin
      if np eq 0 then begin
         !x.range(*)=0.
         !y.range(*)=0.
         endif else begin
         if n_params(0) ge 2 then !x.range(*)=[a,b]
         if n_params(0) eq 4 then !y.range(*)=[c,d]
         endelse
      end
   endcase
;
if keyword_set(exact) then begin
   if !x.style mod 2 eq 0 then !x.style=!x.style+1
   if (n_params(0) eq 4) and (!y.style mod 2 eq 0) then !y.style=!y.style+1
   endif
;
return
end
