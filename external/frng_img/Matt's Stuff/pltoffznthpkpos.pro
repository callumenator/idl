load_pal,culz,idl=[3,1]
window,4,retain=2,xsize=1200,ysize=500

plot,offznthtimes,offznthpkpos
oplot,offznthtimes,offznthpkpos,psym=1,color=culz.green
oplot,offznthtimes,corroffznthpkpos,color=culz.red
oplot,offznthtimes,smthoffznthpkpos,color=culz.blue