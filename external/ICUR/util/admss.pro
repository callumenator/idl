;**************************************************************
function admss,a,digits,sl    ;convert decimal DEC -> string DMS
if n_params(0) lt 2 then digits=0
case 1 of
   digits le 0: secf='(F3.0)'
   digits eq 2: secf='(F5.2)'
   digits ge 3: secf='(F6.3)'
   else: secf='(F4.1)'
   endcase
degtodms,a,d,m,s
if s gt 60.-10^(-digits) then begin
   s=0. & m=m+1
   if m ge 60 then begin
      m=m-60 & d=d+1
      endif
   endif
isign=''
case 1 of
   d eq 0: sd='0'
   d ge 10.: sd=string(d,'(I2)')
   d gt 0.: sd=string(d,'(I1)')
   d le -10.: sd=string(d,'(I3)')
   else: sd=string(d,'(I2)')
   endcase
sl=strlen(sd)+1
sd=sd+'!6!Uo!N'
if m eq 0 then sm=' 0' else sm=string(abs(m),'(I2)')
if m lt 0 then isign='-'
sl=sl+strlen(sm)+1
z=isign+sd+sm+'!6!Um!N'
if isign eq '-' then isadd=1 else isadd=0
if abs(s) le 10.^(-digits) then return,z
ss=string(abs(s),secf)
if s lt 0. then isign='-'
;print,d,m,s
sl=sl+strlen(ss)+1
if isign eq '-' then sl=sl+1
z=z+ss+'!6!Us!N'
if isadd eq 0 then z=isign+z
return,z
end
