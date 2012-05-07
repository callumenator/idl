;**********************************************************************
function jd_to_date,jd0,reduced=reduced
if jd0 le 0 then begin
   print,' '
   print,'* JD_TO_DATE   -   compute date from Julian day'
   print,'*    calling sequence: [m,d,y]=JD_TO_DATE(jd)'
   print,'*       Keywords:'
   print,'*          REDUCED: set to use reduced julian days'
   print,'* '
   print,'* WARNING: integer days are returned. Date flips at JD 0.5'
   print,' '
   return,0
   endif
;
jd=jd0
fd=jd-long(jd)    ; fractional day   jd=0.5 -> integral UT day
if fd lt 0.5 then jd=jd-1
jd=long(jd)+0.5
day1=[0,31,59,90,120,151,181,212,243,273,304,334]
if keyword_set(reduced) then a=2400000. else a=0.
jd1990=julianday(1,1,1990)-a
dj=jd-jd1990+1
ny=fix(dj/365)
if dj lt 0 then ny=ny-1
year=1990+ny-1
;
dj=999
year=fix(year)-1
while dj gt 366 do begin
   year=year+1
   jdx=julianday(1,1,year)-a
   dj=jd-jdx+1
   endwhile
ly=(year mod 4)
if ly eq 0 then ily=1 else ily=0
if (year mod 100) eq 0 then ily=0    ;not a leap year
if (year mod 400) eq 0 then ily=1
if dj gt 365+ily then begin
   year=year+1
   ly=(year mod 4)
   if ly eq 0 then ily=1 else ily=0
   if (year mod 100) eq 0 then ily=0
   if (year mod 400) eq 0 then ily=1
   mo=1
   dj=dj-365
   endif
if ily eq 1 then day1=day1+[0,0,1,1,1,1,1,1,1,1,1,1]           ;leap year
;if year eq 1900 then dj=dj-1
k=where(dj ge day1) & mo=fix(max(k))+1
day=fix(dj-day1(mo-1))
;
return,[mo,day,year]
end
