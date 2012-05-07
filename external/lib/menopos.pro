function menopos, screensize
   common menopos, mx, my
   if n_elements(mx) eq 0 then begin
      mx = 0.02*screensize(0)
      my = 0
   endif
   my = my + 0.1*screensize(1)
   if my gt 0.8*screensize(1) then begin
      mx = mx + 0.1*screensize(0)
      my = my/10 + 0.1*screensize(1)
   endif
   if mx gt 0.8*screensize(0) then mx = mx/10
   return, [mx, my]
end