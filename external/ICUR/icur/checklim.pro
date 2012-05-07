;*****************************************************************
pro checklim,f,lam1,lam2,e
common comxy,xcur,ycur,zerr
if n_params(0) lt 3 then return
if !d.name eq 'PS' then return
np=n_elements(f)
w=findgen(np)
lam0=[lam1,lam2]
psym=!p.psym
!x.title='bin'
!y.title='flux'
!p.title='CHECKLIM'
setxy
!p.position=[.2,.2,.9,.9]
;
restart: 
!c=-1
plot,w,f,psym=0
xcur=mean(!x.crange) & ycur=mean(y.crange)
if n_params(0) ge 4 then begin
   k=wherebad(e,1)
   oplot,w(k),f(k)*0.+!y.crange(0),psym=1
   endif
oplot,[lam1,lam1],!y.crange
oplot,[np-lam2+1,np-lam2+1],!y.crange
z=' Use cursor to mark wavelength region, 0 if OK, 2 to restart'
print,z 
blowup,-1
if zerr eq 48 then goto,ret    ;return
if zerr eq 50 then goto,restart
lam1=long(xcur)>20L
blowup,-1
lam2=long(xcur)
if lam2 lt lam1 then begin
   t=lam2
   lam2=lam1
   lam1=t
   endif
lam2=(np+1-lam2)>20L
print,lam1,lam2
      setxy,lam1,np+1-lam2
      goto,restart
;
ret: 
setxy
return
end
