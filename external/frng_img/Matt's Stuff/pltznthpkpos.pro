load_pal,culz,idl=[3,1]
window,11,retain=2,xsize=1000,ysize=800

plot,znthtimes,znthpkpos, pos=[0.1,0.1,0.9,0.9]
;oplot,znthtimes,corrznthpkpos,color=culz.green
;oplot,znthtimes,polyznthpkpos,color=culz.wheat
oplot,znthtimes,fnlznthpkpos,color=culz.red
oplot,znthtimes,smthznthpkpos,color=culz.blue