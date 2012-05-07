;***************************************************************
PRO wavel,wl,fl,noprint=noprint                   ;measure screen coordinates
common com1,h,ik
common comxy,xcur,ycur,zerr,resc,lu3
if n_elements(ik) eq 0 then ik=-1
IK=IK+1
YP=!D.Y_SIZE*!Y.WINDOW(1)-(!D.Y_CH_SIZE+1)*FLOAT(IK)
XP=!D.X_SIZE*!X.WINDOW(1)-!D.X_CH_SIZE*20.
WL=xcur
FL=ycur
Z=strtrim(STRING(format='(F9.3)',wl),2)+' '+STRTRIM(STRING(format='(G11.3)',fl),2)
XYOUTS,XP,YP,Z,/DEVICE
if !d.name ne 'TEK' then PRINT,Z
if n_elements(lu3) eq 1 then begin
   printf,lu3,' 4' & PRINTF,lu3,WL,FL,'  Wavelength,Flux'
   endif
TKP,1,WL,FL
RETURN
END
