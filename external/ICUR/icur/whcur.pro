;******************************************************************
pro whcur,x,y,z
common comxy,xcur,ycur,zerr
print,' Position cursor and hit any key, 0 to quit'
blowup,-1
while zerr ne 48 do begin
   x=xcur
   y=ycur
   z=zerr
   tkp,1,x,y
   if n_params(0) lt 2 then print,' Cursor at X=',x,', Y=',y
   blowup,-1
   endwhile
return
end
