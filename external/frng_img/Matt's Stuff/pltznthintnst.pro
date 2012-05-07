window,1,retain=2,xsize=800,ysize=600

plot, znthtimes,znthintnst,psym=4,pos=[0.11,0.125,0.92,0.875],$
 title='Zenith Relative Intensity!C'+$
  	   'Inuvik, NWT, Canada!C'+$
	   month+' '+day+', '+year,$
 ytitle='Intensity',xtitle='Time, UT',$
 charsize=1.125,charthick=1.50
 
oplot, znthtimes,znthintnst