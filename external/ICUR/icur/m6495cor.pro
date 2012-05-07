;***********************************************************************
pro m6495cor,dum
openr,lu,'m6495.dta',/get_lun
rec=0
dm=0.
bmv=0.
genrd,lu,rec,dm,bmv
close,lu
free_lun,lu
k=sort(bmv)
dm=dm(k)
bmv=bmv(k)
figsym,2,1
!x.title='!7d!6M!D6495!N'
!y.title='!6B-V'
plot,dm,bmv,psym=8
k=where(bmv le 1.35)
lsqre,dm(k),bmv(k),s,b,ds,db,r
x=0.1*findgen(14)
y=b+x*s
print,'Correlation slope=',s,' +/-',ds,' intercept=',b,' +/-',db
print,' Correlation coefficient=',r
oplot,x,y,psym=0
lplt,'X'
end
