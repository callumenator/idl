function z2test_a,period,nh=nh
; stripped down version of z2test. No testing of nh; normalization done outside
common selected,st,sph,spi,bt,bph,bpi,nint
;
;if n_elements(nh) eq 0 then nh=1
;nh=nh>1    ;number of harmonics
;
phi=st/period mod 1     ;phases
phi=phi*2.*!pi
;
z2=0.
for k=1,nh do z2=z2+(total(cos(k*phi)))^2 + (total(sin(k*phi)))^2
;
;z2=z2*2./float(n_elements(st))
;
return,z2
end
