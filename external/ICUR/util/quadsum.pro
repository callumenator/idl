;*******************************************************************
function quadsum,a,b,c,d,e,f,g,h,i,j,helpme=helpme,prt=prt
;
np=n_params()
if (n_elements(a) eq 0) or (np eq 0) then helpme=1
if keyword_set(helpme) then begin
   print,' '
   print,'* QUADSUM: return sqrt(total(a*a))'
   print,' '
   return,0
   endif
;
case 1 of
   np eq 1: s=sqrt(total(a*a))
   np ge 11: begin
      print,' This mode only good for up to 10 variables'
      s=0
      end
   else: begin
      s=a*a
      if np ge 2 then s=s+b*b
      if np ge 3 then s=s+c*c
      if np ge 4 then s=s+d*d
      if np ge 5 then s=s+e*e
      if np ge 6 then s=s+f*f
      if np ge 7 then s=s+g*g
      if np ge 8 then s=s+h*h
      if np ge 9 then s=s+i*i
      if np ge 10 then s=s+j*j
      s=sqrt(total(s))
      end
   endcase
if keyword_set(prt) then print,' Sum in quadrature is ',s
return,s
end
