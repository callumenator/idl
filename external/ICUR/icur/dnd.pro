;***************************************************************
PRO DND,H,WAVE,FLUX                   ; DIVIDE BY ND RESPONSE
common comxy,xcur,ycur,zerr
common icdisk,icurdisk,icurdata
IF (h(3) lt 4) or (h(3) ge 100) THEN begin     ;only valid for KPNO blue data
   zerr=68
   return                   ;wrong data type
   endif
gdat,icurdata+'optstd',hs,w,f,e,0
IF ABS(W(0)-WAVE(0)) GT 500. THEN BEGIN
   PRINT,' *** WAVELENGTH RANGE WRONG FOR QUARTZ REMOVAL'
   zerr=68
   RETURN
   ENDIF
FF=INTERPOL(F,W,WAVE)
FLUX=FLUX*FF
RETURN
END
