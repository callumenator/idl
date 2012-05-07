function z2test,period,nh=nh

;common rosat,direc,root,poff,events,mex,head,rootobs
;common rosattimes,tstart,tstop,ontime,setdelay,t0,obt1,obt2,gmt1,gmt2,jdref, $
;       sczero,bcappl
;common source,src,xs,ys0,srad,bi,bo,sevents,bevents,sm,bm, $
;       sarr,xc,yc
common selected,st,sph,spi,bt,bph,bpi,nint
;
if n_elements(nh) eq 0 then nh=1
nh=nh>1    ;number of harmonics
;
np=n_elements(st)
phi=st/period mod 1     ;phases
phi=phi*2.*!pi
;
z2=0.
for k=1,nh do z2=z2+(total(cos(k*phi)))^2 + (total(sin(k*phi)))^2
;
z2=z2*2./float(np)
;
return,z2
end
