;**************************************************************************
function doy,day0,dd,yy,leapyear=leapyear,stp=stp,helpme=helpme,prt=prt
if n_params() eq 0 then helpme=1
if n_elements(day0) eq 0 then helpme=1
if keyword_set(helpme) then begin
   print,' '
   print,'* DOY - converts day of year into civil date'
   print,'* calling sequence: DATE=DOY(DAY) or DayofYear=DOY(mm,dd,yyyy)'
   print,'*    DATE: string date (format mmm dd)'
   print,'*    DOY: input day number, 1-365'
   print,'* '
   print,'* KEYWORDS:'
   print,'*    LEAPYEAR: set for leap year'
   print,'*    PRT:      set to print DATE to screen'
   print,' '
   return,''
   endif
;
procname='DoY'
mos='JanFebMarAprMayJunJulAugSepOctNovDec'
dpm=[31,28,31,30,31,30,31,31,30,31,30,31]
;
if (n_elements(yy) gt 0) and (n_elements(dd) gt 0) then begin   ;reverse
   if (yy Ge 50) and (yy lt 100) then yy=yy+1900
   if yy lt 50 then yy=yy+2000
   mo=day0   
   if mo eq 1 then doy=dd else doy=fix(total(dpm(0:mo-2)))+dd
   if (mo gt 2) and (yy mod 4 eq 0) and (yy mod 100 ne 0) then doy=doy+1
   if (mo gt 2) and (yy mod 400 eq 0) then doy=doy+1    ;leap year
   if keyword_set(prt) then print,' Day of year is ',strtrim(doy,2)
   if keyword_set(stp) then stop,procname+'>>>'
   return,doy
   end
;
day=fix(day0)
if keyword_set(leapyear) then dpy=366 else dpy=365
day=day mod (dpy+1)
if day le 0 then while day lt 0 do day=day+dpy
if day eq 0 then day=dpy
;
if keyword_set(leapyear) then dpm(1)=29
cumd=dpm*0.
for i=0,11 do cumd(i)=total(dpm(0:i))         ;days passed at end of month
cumd=[0,cumd]
k=where(day le cumd)
k=k(0)-1
mon=strmid(mos,k*3,3)
dom=fix(day-cumd(k))
zdate=mon+' '+strtrim(dom,2)
if keyword_set(prt) then print,zdate
if keyword_set(stp) then stop,procname+'>>>'
return,zdate
end
