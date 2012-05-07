;********************************************************
PRO BDATA,h,X,W,F,E,BW,BF,BDF,V        ; SET BAD DATA VECTOR
IF X EQ -1 THEN GOTO,BDAT
WX=X
i=xindex(w,wx)
I=FIX(I+0.5)
IF N_PARAMS(0) LT 8 THEN V=-1111
if (i ge 0) and (i le (n_elements(e)-1)) then E(I)=V
;
BDAT: ; SET BAD DATA VECTORS
if n_elements(e) lt n_elements(f) then e=f*0+100   ;e not passed or scalar passed
if n_elements(h) lt 33 then h33=0 else h33=h(33)
bw=-1 & bf=-1
case 1 of
   h33 eq 30: bad=where(e le -1000.,nbad)          ; S/N vector
   h33 eq 40: bad=where(e lt 0.,nbad)              ;error bars
   else:       bad=where(e lt 0.,nbad)
   endcase
;
if nbad gt 0 then begin
   BW=W(BAD) & BF=F(BAD)
   endif
if n_elements(bdf) eq 1 then bdf=(bdf+1) mod 2
RETURN
END
