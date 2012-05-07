;*********************************************************************
function get_ffx,name,w0,stp=stp
if ifstring(name) ne 1 then name='FUDGE'
openr,lu,name+'.ffx',/get_lun
tlen=fstat(lu)
rlen=tlen.rec_len/4             ;record length
z=assoc(lu,fltarr(rlen))
h=fix(z(0))
l=h(7)
;f4=[0,0,0,0,1,1,1,1,0,1,1,1]
;df=f4((h(0)>0)<11)
;if df eq 0 then df=1000.D0 else df=10000.D0
df=float(h(19))
w0=double(h(20))+double(h(21))/df
dw=double(h(22))+double(h(23))/df
w0=w0+dw*findgen(l)                     ;wavelength vector
nr=(l-1)/rlen          ;number of records
fact=z(1)
if nr ge 1 then for i=1,nr do fact=[fact,z(i+1)]
fact=fact(0:l-1)
close,lu
free_lun,lu
if keyword_set(stp) then stop,'GET_FFX>>>'
return,fact
end
