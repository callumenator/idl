;*******************************************************************
PRO USERPRO,W,F,E                     ; USER DEFINED PROCEDURE
COMMON COM1,H,IK,IFT,NSM,C,NDAT,IFSM
COMMON COMXY,XCUR,YCUR,ZERR
PRINT,' '
PRINT,' '
PRINT,' USERPRO is a user defined procedure. ICUR compiles'
PRINT,' USERPRO out of the user directory (and gives an'
PRINT,' error message if no such procedure exists).'
PRINT,' The call is  USERPRO,W,F,E, where W,F, and E are'
PRINT,' the wavelength, flux, and epsilon vectors.'
PRINT,' Other parameters are passes through the common blocks'
PRINT,'      COM1,H,IK,IFT,NSM,C,NDAT,IFSM  '
PRINT,'      COMXY,XCUR,YCUR,ZERR                 '
PRINT,' XCUR and YCUR are the cursor screen position. ZERR is the  '
PRINT,' value of !ERR from the cursor call. H is the header  '
PRINT,' vector. NSM is the smoothing flag. IK,IFT,NDAT, and IFSM'
PRINT,' are miscellaneous flags.   '
RETURN
END

