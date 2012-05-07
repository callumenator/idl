;*******************************************************************
pro opdate,prog
; print todays date on plot at lower RH corner
if n_params(0) eq 0 then prog=' ' else prog=strtrim(prog,2)
ZTIME=systime(0)
ZTIME='!6'+prog+' '+STRMID(ZTIME,4,7)+strmid(ztime,20,4)+' '+strmid(ztime,11,5)
XD=!D.X_SIZE*!X.WINDOW(1)+1.1*!D.Y_CH_SIZE
YD=!D.Y_SIZE*!Y.WINDOW(0)
XYOUTS,XD,YD,ZTIME,orient=90.,/DEVICE,charsize=!p.charsize<1.4
return
end
