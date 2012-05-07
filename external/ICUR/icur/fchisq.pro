;*******************************************************************
FUNCTION FCHISQ,nfree,y,yfit,weight
; called by FFIT2
; returns chi-2 value
;
if n_params(0) lt 3 then begin
   print,' '
   print,' * FCHISQ'
   print,' *    returns chi-2 of fit YFIT to data Y, given errors SIG'
   print,' *    calling sequence: CHI2=FCHISQ(NFREE,Y,YFIT,WEIGHT)'
   print,' *       NFREE: number of free parameters (greater than 0)'
   print,' *           Y: data'
   print,' *        YFIT: fit to data'
   print,' *      WEIGHT: weights of data, default = uniform weighting'
   print,' '
   return,-99.  ;not enough parameters
   endif
;
IF NFREE le 0 then return,-1.              ; not enough degrees of freedom
if n_params(0) lt 4 then weight=y*0.+1.    ;equal weights
CHISQ=WEIGHT*(Y-YFIT)*(Y-yfit)
FCHI=total(CHISQ)/float(nFREE)
RETURN,fchi
END

