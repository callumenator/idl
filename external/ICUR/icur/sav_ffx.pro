;************************************************************************
pro sav_ffx,fname,h,fact,stp=stp
nf=n_elements(fact)
rlen=4096L
l=(nf<rlen)*4L                 ;assoc var record length, 4096 max
nr=nf/rlen                      ;number of records
openw,lu,fname+'.ffx',rlen*4,/get_lun
z=assoc(lu,fltarr(l/4))
z(0)=float(h)
z(1)=fact
if nr ge 1 then for i=1,nr do z(1+i)=fact(rlen*i:(rlen*(i+1)-1)<(nf-1))
close,lu
free_lun,lu
if keyword_set(stp) then stop,'SAV_FFX>>>'
return
end
