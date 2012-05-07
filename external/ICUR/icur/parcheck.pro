;*********************************************************************
;+
;
;*NAME:
;
;    PARCHECK     (GENERAL IDL LIBRARY 01)  30-MAR-1987
;
;*CLASS:
;
;    Error checking
;
;*CATEGORY:
; 
;*PURPOSE:
;
;    To check that a procedure has been called with the minimum of allowed
;    number of parameters. 
; 
;*CALLING SEQUENCE:
;
;    PARCHECK,NPARM,MINPARMS,CALLINGPRO
; 
;*PARAMETERS:
;
;    NPARM       (REQ) (I) (0) (I)
;                required input scalar giving the number of parameters
;                in the procedure call (i.e. n_params(0)).
;
;    MINPARMS    (REQ) (I) (0 1) (I)
;                If scalar, the minimum number of parameters needed for the
;                procedure to execute properly.
;                If an array, it represents the allowed numbers of
;                parameters (e.g. if 3,4 or 6 parameters are allowed,
;                then set minparms([0,1,2]) = [3,4,6] ).
;
;    CALLINGPRO  (REQ) (I) (0) (S)
;                Required string giving the name of the calling procedure.
;
;*EXAMPLES:
;
;    To determine if procedure pro, which contains a
;    call to parcheck has the minimum number of parameters
;    (i.e. 4):
;
;             PARCHECK,N_PARAMS(),4,'PRO'
;
;    If the same procedure can have 4,5,7, or 8 parameters
;    then use:
;
;             PARCHECK,N_PARAMS(),[4,5,7,8],'PRO'
;
;*SYSTEM VARIABLES USED:
;
;*INTERACTIVE INPUT:
;
;*SUBROUTINES CALLED:
;
;    PCHECK
;
;*FILES USED:
;
;*SIDE EFFECTS:
;
;*RESTRICTIONS:
;
;*NOTES:
;
;    tested with IDL Version 2.1.0  (sunos sparc)     	28 Jun 91
;    tested with IDL Version 2.1.0  (ultrix mipsel)   	N/A
;    tested with IDL Version 2.1.0  (vax vms)         	28 Jun 91
;
;*PROCEDURE:
;
;    The input parameters to PARCHECK are first checked themselves
;    using PCHECK. If MINPARMS is a scalar it is compared to NPARM.
;    If NPARM < MINPARMS, then an error message is printed and the
;    procedure returns to the main level. If MINPARMS is a vector,
;    then NPARM is subtracted from each value of MINPARMS and the
;    resulting vector is checked for zeroes. If no values are zero,
;    then error messages are printed and the program returns to the
;    main level.
; 
;*MODIFICATION HISTORY :
;
;    Mar 30 1987    cag  gsfc  initial program
;    Apr    1987    rwt  gsfc  add vector input for parameters
;    Mar 15 1988    cag  gsfc  add vax rdaf-style prolog
;    Jul 12 1989    jtb  gsfc  converted to sun/unix idl
;    Nov  2 1989    rwt  gsfc  correct print format syntax
;    May 10 1991    PJL  GSFC  corrected prolog format
;    Jun 21 1991    gra  casa  cleaned up; tested SUN, DEC, VAX;
;                              updated prolog.
;    Jun 28 1991    PJL  GSFC  added npar test; tested on SUN and VAX; 
;			       updated prolog
;
;-
;***********************************************************************
 pro parcheck,nparm,minparms,callingpro
;
 npar = n_params(0)
 if npar eq 0 then begin
    print,'PARCHECK,NPARM,MINPARMS,CALLINGPRO'
    retall
 endif  ; npar
;
; check input parameters
;
 pcheck,nparm,1,100,0111
 pcheck,minparms,2,110,0111
 pcheck,callingpro,3,100,1000
 cpro = strupcase(callingpro)
;
; check if number of parameters is > minimum (if minparms is scalar)
;
 s = size(minparms)
;
 if s(0) eq 0 then begin
   if nparm lt minparms then begin
      print,format='(1x,3a,i2,a)','Procedure ',cpro,  $
        ' needs at least ',fix(minparms),' parameters to execute.'
      print,format='(1x,a,i2,a)','Only ',fix(nparm),' parameters were specified'
      print,'Action: Returning to the main program level'
      retall
   endif  ; nparm lt minparms
;
; check if nparm is an allowed number of parameters (if minparms is a vector)
;
 endif else begin
   ind = where(minparms - nparm,nonz) ; nonz will be # of non-zero values
   if s(1) eq nonz then begin
      print,'Invalid number of input parameters for procedure ',cpro
      print,'Action: Returning to the main program level'
      retall
   endif  ; s(1) eq nonz
 endelse  ; nparm scalar or vector
;
 return
 end  ; parcheck
