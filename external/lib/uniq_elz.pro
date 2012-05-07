function uniq_elz, inarr
   if n_elements(inarr) lt 2 then return, inarr
   outarr = inarr(0)
   for j=1l,n_elements(inarr)-1 do begin
       nin = 0
       inz = where(outarr eq inarr(j), nin)
       if nin eq 0 then outarr = [outarr, inarr(j)]
   endfor
   return, outarr
end