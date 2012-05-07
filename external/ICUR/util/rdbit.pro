;*************************************************************
function RDBIT,V,N           ; READ INDIVIDUAL BITS
; V IS INPUT INTEGER
; N is bit to be read
s=size(v) & ns=n_elements(s)
type=s(ns-2)
case 1 of
   (type lt 1): return,-1   ;undefined
   (type eq 1): nlim=7
   (type eq 2): nlim=15 
   (type eq 3): nlim=31
   (type eq 5): nlim=63
   type ge 6: return,-1
   else: nlim=31
   endcase
IF N GT nlim THEN RETURN,-1
IF N LT 0 THEN RETURN,-1
X=2L^FIX(N)
case 1 of
   n le 15: bit=FIX(V AND X)/X
   else: bit=LONG(V AND X)/X
   endcase
RETURN,bit
END
