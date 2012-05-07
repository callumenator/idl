;***********************************************************************
pro ic_err_anal,h,w,f,e,mflen=mflen,smlen=smlen,filt=filt
COMMON COMXY,XCUR,YCUR,ZERR,RESETSCALE,lu3,zzz
;
print,' Use cursor to mark region to analyze'
wshow
blowup,-1
blowup,1
x1=!x.range(0)
x2=!x.range(1)
k=where((w ge (x1<x2)) and (w le (x1>x2)),nk)
if nk eq 0 then begin
   print,' Invalid range specified - returning
   return
   endif
;
PLDATA,0,W,F
op_1sig,h,w,f,e
;
if n_elements(mflen) eq 0 then mflen=21
if n_elements(smlen) eq 0 then smlen=7
;
f1s=smooth(median(f(k),mflen),smlen)
f1m=median(f(k))
e1s=optfilt(e(k))
if keyword_set(filt) then f10=f1s else f10=f1m
rl=float(n_elements(f1s))
k1=where((f gt (f10+e1s)) or (f lt (f10-e1s)),nk1)
frac1=float(nk1)/rl
k1=where((f gt (f10+2.*e1s)) or (f lt (f10-2.*e1s)),nk1)
frac2=float(nk1)/rl
print,'Frac > 1 sigma = ',frac1,'  Frac > 2 sigma = ',frac2,'  NP=',fix(rl)
return
end
