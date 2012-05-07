;**************************************************************************
pro bell,number,nmax=nmax
if n_elements(nmax) eq 0 then nmax=10
if n_params(0) eq 0 then number=1
for i=1,(number<nmax) do begin
   print,FORMAT="($,A1)",string(7b) & wait,0.1
   endfor
return
end
