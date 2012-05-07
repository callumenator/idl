;*************************************************************************
pro DEGtoHMS,a,h,m,s,prt=prt,nsigfig=nsigfig,strings=strings,helpme=helpme
if n_params() eq 0 then helpme=1
if keyword_set(helpme) then begin
   print,' '
   print,'* DEGtoHMS - convert decimal degrees to hours, minutes, seconds'
   print,'* calling sequence: DEGtoHMS,a,h,m,s'
   print,'*    A: input decimal degrees'
   print,'*    H,M,S: output hours, minutes, seconds'
   print,'* '
   print,'* KEYWORDS:'
   print,'*    PRT: set to print to screen, def if n_params() eq 1'
   print,'*    NSIGFIG: number of significant figures on S'
   print,'*    STRING:  set to return formatted string, def if n_params<4'
   print,' '
   return
   endif
;
s=size(a)
ndim=s(0)
np=n_elements(a)
k=where(a lt 0.,nk) & if nk gt 0 then a(k)=360.+a(k)
h=fix(a/15.)
m=fix((a-h*15)*4.)
s=(a-(h*15.)-m/4.)*240.
if n_params(0) eq 1  then prt=1
if n_params(0) lt 4  then strings=1
if n_elements(nsigfig) eq 0 then nsigfig=3
nf=4+nsigfig
fmt='(F'+strtrim(nf,2)+'.'+strtrim(nsigfig,2)+')'
ifmt='(I3)'
if keyword_set(prt) then begin
   if ndim eq 0 then print,string(h,ifmt),string(m,ifmt),string(s,fmt) else $
      for i=0,np-1 do print,string(h(i),ifmt),string(m(i),ifmt),string(s(i),fmt)
   endif
if keyword_set(strings) then h=string(h,ifmt)+string(m,ifmt)+string(s,fmt)
return
end
