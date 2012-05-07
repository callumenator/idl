load_pal,culz,idl=[3,1]
window,5,retain=2,xsize=1200,ysize=500

plot,offznthtimes,offznthpkpos
oplot,znthtimes,znthpkpos,color=culz.cyan
oplot,znthtimes,znthpkpos,psym=1,color=culz.green
oplot,znthtimes,corrznthpkpos,color=culz.red
oplot,znthtimes,smthznthpkpos,color=culz.blue
oplot,offznthtimes,offznthpkpos,psym=1,color=culz.orange
oplot,offznthtimes,corroffznthpkpos,color=culz.yellow
oplot,offznthtimes,smthoffznthpkpos,color=culz.lilac