load_pal,culz,idl=[3,1]
window,retain=2, xsize=1100, ysize= 900
plot,znthtimes,znthpkpos,pos=[0.1,0.1,0.9,0.9],yrange=[-1., 1.]
  oplot,znthtimes,smthznthpkpos,color=culz.green
  oplot,znthtimes,corrznthpkpos,color=culz.red
  oplot,tgrid,shfttrlpress,color=culz.blue
  oplot,tgrid,shfttrltemp,color=culz.orange
  oplot,znthtimes,temsave-mean(temsave),color=culz.yellow