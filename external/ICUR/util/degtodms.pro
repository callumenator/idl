;*************************************************************************
pro DEGtoDMS,d,dd,dm,ds,prt=prt,nsigfig=nsigfig,strings=strings,stp=stp
s=size(d)
ndim=s(0)
if ndim eq 0 then d=intarr(1)+d
np=n_elements(d)
dd=fix(d)
dm=fix((d-dd)*60)
ds=(d-dd-dm/60.)*3600.
k=where(d lt 0)
if k(0) ne -1 then begin   ;negative declinations - leave only most sign. neg
   k1=where(dd lt 0)
   if k1(0) ne -1 then begin
      dm(k1)=abs(dm(k1)) & ds(k1)=abs(ds(k1))
      endif
   k1=where(dm lt 0)
   if k1(0) ne -1 then ds(k1)=abs(ds(k1))
   endif
if ndim eq 0 then begin
   d=d(0)
   dd=dd(0)
   dm=dm(0)
   ds=ds(0)
   endif
if n_params(0) eq 1 then prt=1
hfmt='(I4)'
mfmt='(I3)'
if n_elements(nsigfig) eq 0 then nsigfig=2
nf=nsigfig+4
fmt='(F'+strtrim(nf,2)+'.'+strtrim(nsigfig,2)+')'
if keyword_set(prt) then begin
   if ndim eq 0 then print,string(dd,hfmt),string(dm,mfmt),string(ds,fmt) $
      else for i=0,np-1 do print,string(dd(i),hfmt),string(dm(i),mfmt),string(ds(i),fmt)
   endif
if keyword_set(strings) then begin
   case nsigfig of
      0: mxd=59.
      1: mxd=59.9
      2: mxd=59.99
      3: mxd=59.999
      4: mxd=59.9999
      else: mxd=59.99999
      endcase
   isign=strarr(np)+' '
   k=where(d lt 0.,nk)
   if nk gt 0 then isign(k)='-'
   dd='   '+isign+strtrim(string(abs(dd),hfmt),2)
   sl=strlen(dd)
   dd=strmid(dd,2,3)
   k=where(abs(ds) gt mxd,nk) & if nk gt 0 then ds(k)=mxd  ;getimage dies on 60.0
   dd=dd+string(abs(dm),mfmt)+string(abs(ds),fmt)
   endif
if keyword_set(stp) then stop,'DECtoDMS>>>'
return
end




