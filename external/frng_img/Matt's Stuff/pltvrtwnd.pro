window,3,retain=2,xsize=1100,ysize=900

plot, znthtimes,znthwnd,psym=4,pos=[0.09,0.125,0.92,0.875],$
 title='Vertical Winds in the Upper Thermosphere!C'+$
 	   'Inuvik, NWT, Canada!C'+$
	   month+' '+day+', '+year,$
 ytitle='Vertical wind (m/s)',xtitle='Time, UT',$
 charsize=1.125,charthick=1.50, yrange=[-100,100],/ystyle
; yticks=3,yminor=4
; xrange=[4.,14.],/xstyle
 
oplot, znthtimes,znthwnd
errplot, znthtimes,znthwnd-znthwnderr, znthwnd+znthwnderr
