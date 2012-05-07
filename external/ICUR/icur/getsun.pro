;****************************************************************************
pro getsun,w,f,lam=lam,bin=bin,stp=stp,plt=plt
;
gdat,'sun',h,w1,f1,e,0
gdat,'sun',h,w2,f2,e,1
gdat,'sun',h,w3,f3,e,2
minw=w1(0) & maxw=max(w3)
mw1=mean(w1) & dw1=(w1(1:*)-w1(0))/(n_elements(w1)-1) & dw1=mean(dw1)
mw2=mean(w2) & dw2=(w2(1:*)-w2(0))/(n_elements(w2)-1) & dw2=mean(dw2)
mw3=mean(w3) & dw3=(w3(1:*)-w3(0))/(n_elements(w3)-1) & dw3=mean(dw3)
if n_elements(lam) ne 2 then lam=[minw,maxw+1.]
if n_elements(bin) eq 0 then bin=1.
if lam(0) ge maxw then lam(0)=minw
if lam(0) lt minw then lam(0)=minw
if lam(1) le minw then lam(1)=maxw
if lam(1) gt maxw then lam(1)=maxw
case 1 of
   lam(0) le w2(0): bin=bin>dw1
   lam(0) le w3(0): bin=bin>dw2
   else: bin=bin>dw3
   endcase
;
print,lam,bin
;
nw=fix(0.5+(lam(1)+bin-lam(0))/bin)
w=fix(lam(0)+0.999)+bin*findgen(nw)
f=w*0.
n=intarr(nw)
;
if lam(0) lt max(w1) then begin    ;spectrum 1
   ff=interpol(f1,w1,w)
   k1=where(w ge w1(0)) & k1=k1(0)
   k2=where(w gt max(w1)) & k2=k2(0)-1
   print,k1,k2
   n(k1:k2)=n(k1:k2)+1
   f(k1)=ff(k1:k2)
   endif
;
if (lam(0) lt max(w2)) and (lam(1) gt w2(0)) then begin    ;spectrum 2
   ff=interpol(f2,w2,w)
   k1=where(w ge w2(0)) & k1=k1(0)
   k2=where(w gt max(w2)) & k2=k2(0)-1
   print,k1,k2
   n(k1:k2)=n(k1:k2)+1
   f(k1)=f(k1:k2)+ff(k1:k2)
   endif
;
if lam(1) gt w3(0) then begin    ;spectrum 3
   ff=interpol(f3,w3,w)
   k1=where(w ge w3(0)) & k1=k1(0)
   k2=where(w ge max(w3)) & k2=k2(0)-1
   print,k1,k2
   n(k1:k2)=n(k1:k2)+1
   f(k1)=f(k1:k2)+ff(k1:k2)
   endif
;
if n(nw-1) eq 0 then begin
   w=w(0:nw-2)
   f=f(0:nw-2)
   n=n(0:nw-2)
   endif
n=float(n>1)
f=f/n
if keyword_set(plt) then begin
   plot_io,w,f
   if !d.name eq 'X' then wshow
   endif
if keyword_set(stp) then stop,'GETSUN>>>'   
return
end

