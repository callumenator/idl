;******************************************************************
function corrflux1,w,f
; called by CORRFLUX
if n_params(0) lt 2 then begin
   print,' '
   print,'* CORRFLUX1 is called by CORRFLUX - it is not a standalone procedure'
   print,' '
   return,0
   endif
;
common comxy,xcur,ycur,zerr
plot,w,f
if !d.name eq 'X' then wshow
np=n_elements(f)-1
if (!x.range(0) eq 0) and (!x.range(1) eq 0) then ff=optfilt(f) else begin
   k=where((w ge !x.crange(0)) and (w le !x.crange(1)))
   k1=(k(0)-200)>0 & k2=(max(k)+200)<np
   ff=f
   z=optfilt(f(k1:k2))
   ff(k1)=z
   endelse
oplot,w,ff
xcur=mean(!x.crange)
ycur=mean(!y.crange)
if !d.name eq 'X' then wshow
print,string(7b)
print,' mark 2 extrema, Q to quit'
blowup,-1
x1=xcur
if (zerr eq 26) or (zerr eq 81) or (zerr eq 113) then return,-999
blowup,-1
x2=xcur
if (zerr eq 26) or (zerr eq 81) or (zerr eq 113) then return,-999
if x1 gt x2 then begin
   t=x1
   x1=x2
   x2=t
   endif
print,' mark region to exclude from interpolation, 0 if none'
blowup,-1
if zerr ne 48 then begin
   x3=xcur
   blowup,-1
   x4=xcur
   if x3 gt x4 then begin
      t=x3
      x3=x4
      x4=t
      endif
   endif else begin
   x3=-1 & x4=-1
   endelse
k=where(w gt x1) & k1=k(0)>0 
k=where(w gt x2) & k2=k(0)>0
k=where(w gt x3) & k3=k(0)>0
k=where(w gt x4) & k4=k(0)>0
length=k2-k1+1
val1=mean(ff((k1-10)>0:(k1+10)<np))
val2=mean(ff((k2-10)>0:(k2+10)<np))
v1=val1+(val2-val1)/length*findgen(length)    ;linear interpolation
;
fact=ff
fact(k1)=v1
fact=fact/ff
if x3 ge 0 then begin     ;avoidance region
   val3=fact(k3)
   val4=fact(k4)
   length2=k4-k3+1
   v2=val3+(val4-val3)/length2*findgen(length2)    ;linear interpolation
   fact(k3)=v2
   endif
return,fact
end
