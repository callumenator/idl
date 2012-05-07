;********************************************************************
pro setps,hcpy
ps=0
case 1 of
   ifstring(hcpy): ps=1
   n_elements(hcpy) eq 0: ps=0
   n_elements(hcpy) eq 1: if hcpy ne 0 then ps=1
   else:
   endcase
if ps then sp,'ps'
return
end
