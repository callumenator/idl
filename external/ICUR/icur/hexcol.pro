;************************************************************************
function hexcol,index
case index of
   0: c=0
   1: c='ffff00'x
   2: c='ff00ff'x
   3: c='00ffff'x
   4: c='0000ff'x
   5: c='00ff00'x
   6: c='ff7f00'x
   7: c='ff007f'x
   8: c='7fff00'x
   9: c='007fff'x
   10: c='ff0000'x
   else: c='ffffff'x
   endcase
;
return,c
end
