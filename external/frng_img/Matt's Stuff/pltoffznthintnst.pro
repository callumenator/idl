window,8,retain=2,xsize=1100,ysize=900

plot, offznthtimes,offznthintnst,psym=4,pos=[0.11,0.125,0.92,0.875],$
 title='Offzenith Relative Intensity!C'+month+' '+day+', '+year,$
 ytitle='Intensity',xtitle='Time, UT',$
 charsize=1.125,charthick=1.50
 
oplot, offznthtimes,offznthintnst