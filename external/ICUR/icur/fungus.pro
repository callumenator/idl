;****************************************************************************
FUNCTION FUNGUS,x,F,cii=cii,debug=debug
;returns UP TO 5 GAUSSIAN LINES + QUADRATIC BACKGROUND
common custompars,dw,lp,x2,x3,x4,x5
if n_params(0) lt 2 then begin
   print,' FUNGUS: needs to be called with 2 parameters (x,fit params)'
   return,-99.
   endif
xi=findgen(n_elements(x))-0.5
np=n_elements(f)    ;number of parameters
case 1 of
   np eq 1: return,f(0)+xi*0.                     ;constant
   np eq 2: return,f(0)+f(1)*xi                   ;linear
   np eq 3: return,F(0)+F(1)*XI+F(2)*XI*XI        ;quadratic background
   else: FUNG=F(0)+F(1)*XI+F(2)*XI*XI           ;quadratic background
   endcase
;
nlines=(np-3)/3                                   ;number of lines
if keyword_set(debug) then print,'np,NLINES:',np,nlines
if nlines eq 0 then return,fung
;***
spec=0
if n_elements(dw) eq 0. then cii=0
if keyword_set(cii) then lp=1.175            ;1.175 A between lines
if n_elements(lp) eq 0 then lp=0.
if (lp gt 0.001) and (n_elements(dw) gt 0) then spec=1
case spec of
   1: dx=lp/dw 
   else:
   endcase
;print,'FUNGUS: cii=',cii,'  dw=',dw,'  lp=',LP
;***
for i=0,nlines-1 do begin
   K=i*3+3     ;3,6,9 ...   ;amplitude
   L=K+1
   LL=K+2
   case spec of
      1: begin
         if i eq 1 then f(l)=f(4)+dx
         if i eq 3 then f(l)=f(10)+dx
         end
      else:
      endcase
   Z=-13.>(((XI-F(L))/F(LL))<13.)
   FUNG=FUNG+F(K)*EXP(-Z*Z/2.)
   endfor
if keyword_set(debug) then stop,'FUNGUS>>>'
RETURN,fung
END
