;******************************************************************
function shfth2,w0,f0,f1,lw,uw
; input=list of records
common com1,hd,ik,ift,nsm,c,ndat,ifsm,kblo,h2
common comxy,xcur,ycur,zerr
ik=0
ift=0
nsm=1
c=1.
ndat=2
ifsm=0
;
if n_params(0) lt 4 then lw=2794.
if n_params(0) lt 5 then uw=2797.
hd=intarr(400)
setxy,lw,uw
e0=f0*0
e1=e0
e=e0
w1=w0
s=0
redo:
wshift,1,w0,f0,e0,f1,e1,e,w1,ofb
s=s+ofb
print,' accumulated shift=',s
oplot,w0,f1,psym=0
print,' OK? 1 to redo'
blowup,-1
if zerr eq 49 then goto,redo
setxy
return,-s
end
