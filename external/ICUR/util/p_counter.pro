;******************************************************
pro p_counter,i,newline=newline,fmt=fmt,stp=stp,helpme=helpme
if (n_elements(i) eq 0) and (not keyword_set(newline)) then helpme=1
if keyword_set(helpme) then begin
   print,' '
   print,'* P_COUNTER: print counter to terminal'
   print,'* calling sequence: P_COUNTER,i'
   print,'* '
   print,'* KEYWORDS:'
   print,'*    FMT:     format of counter, def=I6'
   print,'*    NEWLINE: set to terminate and start new line'
   print,' '
   return
   end
cr = string("15b)
if n_elements(fmt) eq 0 then fmt='I6'
form="($,"+fmt+",a)"
case 1 of
   keyword_set(newline): print,form="($,a)",string("12b)   ;print new line
   else: print,i,cr
   endcase
if keyword_set(stp) then stop,'P_COUNTER>>>'
return
end
