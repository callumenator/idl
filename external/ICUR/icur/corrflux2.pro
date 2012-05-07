;******************************************************************
function corrflux2,w,f
; called by FUDGEFLUX
if n_params(0) lt 2 then begin
   print,' '
   print,'* CORRFLUX2 is called by FUDGEFLUX - it is not a standalone procedure'
   print,' '
   return,0
   endif
;
common comxy,xcur,ycur,zerr
plot,w,f
if !d.name eq 'X' then wshow
np=n_elements(f)-1
ff=optfilt(f,0,31,63,63,103) 
oplot,w,ff
xcur=mean(!x.crange)
ycur=mean(!y.crange)
if !d.name eq 'X' then wshow
;
sm1=np/40 & if sm1 mod 2 eq 0 then sm1=sm1+1
sm2=np/20 & if sm2 mod 2 eq 0 then sm2=sm2+1
v1=smooth(maxfilt(f,-1,sm1),sm2)
oplot,w,v1,color=15
;
fact=v1/ff
print,string(7b)
return,fact
end
