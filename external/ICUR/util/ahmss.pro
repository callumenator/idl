;**************************************************************
function ahmss,a,digits    ;convert decimal RA -> string HMS
if n_params(0) lt 2 then digits=0
case 1 of
   digits le 0: secf='(F3.0)'
   digits ge 2: secf='(F5.2)'
   else: secf='(F4.1)'
   endcase
h=fix(a/15.)
r=a-h*15.
m=fix(r*4.)
r=a-h*15.-m/4.
s=r*240.
z='!6'+string(h,'(I2)')+'!Uh!N'+string(m,'(I2)')+'!Um!N'
if s le 0.0 then return,z
z=z+string(s,secf)+'!Us!N'
return,z
end
