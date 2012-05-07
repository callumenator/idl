;**************************************************************************
pro plotsun,x,y,size
if n_params(0) lt 2 then begin
   print,' '
   print,' * PLOTSUN,x,y,size'
   print,' *   size defaults to 8/5'
   print,' '
   return
   endif
if n_params(0) lt 3 then size=8./5.
figsym,2,0,(size>4./5.)
oplot,[x,x],[y,y],linestyle=0,psym=8
figsym,2,1,(size/3)<4./5.
oplot,[x,x],[y,y],linestyle=0,psym=8
return
end
