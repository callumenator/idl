;**************************************************************************
function eqwid,w,f,lamcen,dl,b1,b2,db1,db2,stp=stp   ;estimate equivalent widths
if n_params(0) lt 2 then begin
   print,' '
   print,'* function EQWID - estimate equivalent widths'
   print,'*    calling sequence X=EQWID(W,F,LAM,DL,B1,B2,DB1,DB2)'
   print,'*         W,F: input wavelength and flux vectors'
   print,'*         LAM: wavelength of feature to be measured, def = H-alpha'
   print,'*          DL: width to integrate over, default=5 A'
   print,'*       B1,B2: beginning wavelengths of background region,'
   print,'*              defaults=LAM-20 A,LAM+10 A'
   print,'*     DB1,BD2: widths of background region, default=10 Angstroms'
   print,'*           X: output equivalent width in units of W'
   print,' '
   return,0.
   endif
dw=mean(w(1:*)-w)             ;Angstroms per bin
;
if n_params(0) lt 3 then lamcen=-1
if n_params(0) lt 4 then dl=-1
if n_params(0) lt 8 then db2=-1
if n_params(0) lt 7 then db1=-1
if n_params(0) lt 6 then b2=-1
if n_params(0) lt 5 then b1=-1
;
if lamcen lt 0 then lamcen=6563.        ;default to H-alpha
if dl lt 0 then dl=5.                   ;default to 5 Angstroms width
if db1 lt 0 then db1=10.                ;default to 20 bins
if db2 lt 0 then db2=db1                ;default to 20 bins
if b2 lt 0 then b2=lamcen+10.           ;default to Lamcen+20 bins
if b1 lt 0 then b1=lamcen-20.           ;default to Lamcen-10 bins
if (b1 lt w(0)) or (b2+db2 gt max(w)) then begin
   print,' region not completely contained within spectrum - returning'
   return,-9999.
   endif
;
ff=optfilt(f)
dl2=dl/2.
WV=[b1,b1+db1,b2,b2+db2,lamcen-dl2,lamcen+dl2]
ii=xindex(w,wv)                          ;tabinv,w,wv,ii
; do first background region
mw1=b1+db1/2.      ;mean wavelength
fi1=fix(ii(0)) & fi2=fix(ii(1))
fb1=total(ff(fi1+1:fi2))+ff(fi1)*(fi1+1.-ii(0))+ff(fi2+1)*(ii(1)-fi2)
fb1=fb1*dw/(db1+dw)             ;flux per A
; do second background region
mw2=b2+db2/2.      ;mean wavelength
fi1=fix(ii(2)) & fi2=fix(ii(3))
fb2=total(ff(fi1+1:fi2))+ff(fi1)*(fi1+1.-ii(2))+ff(fi2+1)*(ii(3)-fi2)
fb2=fb2*dw/(db2+dw)             ;flux per A
;
; do line
fi1=fix(ii(4)) & fi2=fix(ii(5))
fl=total(f(fi1+1:fi2))+f(fi1)*(fi1+1.-ii(4))+f(fi2+1)*(ii(5)-fi2)
fl=fl*dw
;
fb=fb1+(fb2-fb1)*(lamcen-mw1)/(mw2-mw1)          ;interpolated background
ew=(fb*dl-fl)/fb
;
if keyword_set(stp) then stop,'EQWID>>>'
return,ew
end
