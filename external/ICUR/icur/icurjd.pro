;**********************************************************************
function icurjd,head
m=head(10)
d=head(11)
yr=1900+head(12)
jd=julianday(m,d,yr)
sec=double(head(15))
min=double(head(14))+(sec/60.D0)
hr=double(head(13))+(min/60.D0)
utd=hr/24.D0
jd=jd+utd
return,jd
end
