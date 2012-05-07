;**************************************************************
PRO IBIT,V,N,I           ; insert/toggle INDIVIDUAL BITS
; V IS INPUT INTEGER
; N is bit to insert value I into
; I=0,1 to insert, other to toggle
if n_params(0) lt 2 then begin
   PRINT,'IBIT must be called with at least 2 parameters'
   print,'     IBIT,VARIABLE,BIT,FLAG'
   print,'        FLAG = 0 or 1 (default) to insert 0 or 1 in bit BIT of
   print,'        the integer VARIABLE. Other values of FLAG toggle BIT'
   return
   endif
if n_params(0) lt 3 then i=1        ;default is insert 1
if (i lt 0) or (i gt 1) then tog=1 else tog=0   ;1 to toggle bit
s=size(v) & ns=n_elements(s)
type=s(ns-2)
if (type eq 0) or (type gt 3) then return   ;integers only
case 1 of
   type eq 16: nlim=31
   else: nlim=15
   endcase
IF N GT nlim THEN RETURN
IF N LT 0 THEN RETURN
X=2^FIX(N)
bit=FIX(FIX(V) AND X)/X
if (tog eq 0) then begin
   k=where(bit ne i,nk) 
   if nk eq 0 then return
   endif else k=indgen(n_elements(v))
V(k)=FIX(V(k)-((FIX(V(k)) AND X)-FLOAT(X)/2.)*2.)
RETURN
END
