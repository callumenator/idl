;****************************************************************************
pro filter_back,gbb,filter,bad
if n_elements(filter) eq 0 then return
if filter le 0. then return
m=mean(gbb)
ssd=(stddev(gbb)*filter)>1.
k=where((gbb ge (m-ssd)) and (gbb le (m+ssd)),nk)
if n_params() eq 3 then bad=where((gbb lt (m-ssd)) or (gbb gt (m+ssd)))
if nk ge 1 then gbb=gbb(k) else $      ;removed filtered points
   print,' WARNING: No valid background points '
return
end
