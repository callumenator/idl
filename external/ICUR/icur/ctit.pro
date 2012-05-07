;************************************************************************
pro ctit,h,nch,newt,append=append       ;change title (words 100-159) in header
nh=n_elements(h)
nch=1                              ; no change made
if nh lt 100 then return           ;header too short
nh=(nh-100)<60
hmax=99+nh
if hmax lt 0 then return
title=strtrim(string(byte(h(100:hmax)>32)),2)
ot=byte(title)
t=bytarr(nh)
if n_elements(newt) eq 0 then newt=''
if strlen(newt) eq 0 then begin
   print,' old title:',title 
   newt=' '
   read,' enter new title, CR if OK: ',newt
   endif
if newt eq '' then return
if strlen(newt) gt nh then newt=strmid(newt,0,nh-1)
t(0)=byte(newt)
if keyword_set(append) then t=[ot,32b,t]
h(100)=t
nch=0
print,'revised title: ',string(byte(h(100:159)))
return
end
