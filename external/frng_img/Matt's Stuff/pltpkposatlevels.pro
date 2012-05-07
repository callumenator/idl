load_pal,culz,idl=[3,1]
window,retain=2, xsize=1100, ysize= 900
graphinfo='!CWhite - Measureed zenith peak position, Blue - Shifted trailer pressure,!CYellow - Measured, shifted trailer temp., Orange - Response corrected trailer temp. profile, shifted,!CGreen - Drift correction, Rose - Drift corrected zenith peak position,!CWheat - Polynomial fit to drift corrected peak position, Cyan - Final corrected zenith peak position'
plot,znthtimes,znthpkpos,pos=[0.1,0.25,0.9,0.9],$
 xtitle='Time, UT',yrange=[-1., 1.],/ystyle,$
 title='Zenith Peak Position Drift Correction Analysis',$
 subtitle=graphinfo,charsize=1.25
 oplot,znthtimes,smthznthpkpos,color=culz.green
 oplot,znthtimes,corrznthpkpos,color=culz.rose
 oplot,znthtimes,polyznthpkpos,color=culz.wheat
 oplot,znthtimes,fnlznthpkpos,color=culz.cyan
 oplot,tgrid,shfttrlpress,color=culz.blue
 oplot,tgrid,shfttrltemp,color=culz.orange
 oplot,znthtimes,temsave-mean(temsave),color=culz.yellow