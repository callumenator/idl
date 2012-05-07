;*******************************************************
pro rollxy,xin,yin,roll,xout,yout,radians=radians,stp=stp,helpme=helpme
;
if n_params() lt 2 then helpme=1
if keyword_set(helpme) then begin
   print,' '
   print,'* ROLLXY - convert X,Y,roll to unrolled X,Y'
   print,'* calling sequence: ROLLXY,Xin,Yin,roll,Xout,Yout'
   print,'*                or ROLLXY,Xin,Yin,roll'
   print,'*    Xin, Yin: input X, Y values'
   print,'*    ROLL:     roll angle'
   print,'*    Xout,Yout: output X, Y values'
   print,'* '
   print,'* KEYWORDS:'
   print,'*    RADIANS: set if ROLL is in radians, default is degrees.'
   print,' '
   endif
if keyword_set(radians) then r=roll else r=roll/!radeg
xout=xin*cos(r)-yin*sin(r)
yout=xin*sin(r)+yin*cos(r)
if n_params() le 3 then begin
   xin=xout & yin=yout
   endif
if keyword_set(stp) then stop,'ROLLXY>>>'
return
end
