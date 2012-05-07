;***********************************************************************
function ismx,e0,lam=lam
; ISM cross sections from Morrison & McCammon 1983 ApJ 270, 119
; as used in XSPEC
;
if keyword_set(lam) then e=12.4/e0 else e=e0   ;Angstroms passed
el=[0.03,0.1,0.284,0.40,0.532,0.707,0.867,1.303,1.84,2.471,3.210,4.038, $
    7.111,8.331]
eh=[el(1:*),10.0]
c0=[17.3,34.6,78.1,71.4,95.5,308.9,120.6,141.3,202.7,342.7,352.2,433.9, $
    629.0,701.2]
c1=[608.1,267.9,18.8,66.8,145.8,-380.6,169.3,146.8,104.7,18.7,18.7,-2.4, $
    30.9,25.2]
c2=[-2150.,-476.1,4.3,-51.4,-61.1,294.0,-47.7,-31.5,-17.0,0.0,0.0,0.75,0.0,0.0]
;
nseg=n_elements(el)
ee=0.03+findgen(9971)*0.001
sig=ee*0.
for i=0,nseg-1 do begin
   k=where((ee ge el(i)) and (ee le eh(i)))
   x=ee(k)
   sig(k(0))=(c0(i)+c1(i)*x+c2(i)*x*x)
   endfor
sig=sig/(ee*ee*ee)*1.e-24
sig=interpol(sig,ee,e)
return,sig
end
