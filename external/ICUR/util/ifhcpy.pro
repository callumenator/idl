;*****************************************************************
pro ifhcpy,hcpy=hcpy,square=square,color=color,yscale=yscale
case 1 of
   ifstring(hcpy): hc=1
   keyword_set(hcpy): hc=1
   else: hc=0
   endcase
;print,hc
if hc then sp,'ps',square=square,color=color,yscale=yscale $
   else sp,'X',square=square,color=color,yscale=yscale
return
end
