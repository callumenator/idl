;****************************************************************************
pro MPFUNGUS,x,F,ymod,debug=debug
;returns GAUSSIAN LINES + QUADRATIC BACKGROUND
ymod=x*0.
if n_params(0) lt 2 then begin
   print,' MPFUNGUS: needs to be called with 2 parameters (x,fit params)'
   return
   endif
xi=findgen(n_elements(x))-0.5
np=n_elements(f)    ;number of parameters
case 1 of
   np eq 1: ymod=f(0)+xi*0.                     ;constant
   np eq 2: ymod=f(0)+f(1)*xi                   ;linear
   else: ymod=F(0)+F(1)*XI+F(2)*XI*XI           ;quadratic background
   endcase
;
nlines=(np-3)/3                                   ;number of lines
if keyword_set(debug) then print,'np,NLINES:',np,nlines
if nlines eq 0 then return
;***
for i=0,nlines-1 do begin
   K=i*3+3     ;3,6,9 ...   ;amplitude
   L=K+1
   LL=K+2
   Z=-13.>(((XI-F(L))/F(LL))<13.)
   ymod=ymod+F(K)*EXP(-Z*Z/2.)
   endfor
if keyword_set(debug) then stop,'MPFUNGUS>>>'
RETURN
END
