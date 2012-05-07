;********************************************************
pro op_lsa,wave,flux,ERR,yfit,ybox1,stp=stp,color=color
COMMON COM2,A,B,FH,FIXT,ISHAPE
if n_elements(color) eq 0 then color=2
f61='(F6.1)'
k=fix(xindex(wave,a(4)))-16+findgen(32)
kp=fix(xindex(wave,a(4)))-64+findgen(128)
ybox=flux*0.
ybox(k)=a(3)
ybox1=conv_gsn(ybox,4.4)
sc=total(flux(k)-a(0))/total(ybox1(k))
ybox1=ybox1*sc+a(0)
oplot,wave(kp),ybox1(KP),color=color
; DO Chi-square analysis
np=48
k1=fix(xindex(wave,a(4)))-np/2+findgen(np)
k2=k1-b(0)     ;indices for fit
chfit=total(((yfit(k2)-flux(k1))/err(k1))^2)/(np-1)
chbox=total(((ybox1(k1)-flux(k1))/err(k1))^2)/(np-1)
print,' Reduced Chi-2: Gaussian = ',string(chfit,F61),'  box = ',string(chbox,F61)
if keyword_set(stp) then stop,'OP_LSA>>>'
return
end
