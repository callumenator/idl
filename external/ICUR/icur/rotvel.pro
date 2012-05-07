;*******************************************************************
PRO ROTVEL,MODE,WAVE,value           ; SMOOTHING
; MODE=0 FOR STANDARD SMOOTHING
; MODE = 1 FOR ROTATIONAL BROADENING
; MODE = -1 FOR GAUSSIAN SMOOTHING
; MODE = 2 FOR TRIANGULAR KERNEL (TRIKER)
COMMON COM1,H,IK,IFT,V,C
COMMON COMXY,XCUR,YCUR,ZERR,RESC,LU3
if n_params(0) lt 1 then begin
   print,' '
   print,'* ROTVEL - procedure to apply generate smoothing kernel'
   print,'*    calling sequence: ROTVEL,MODE,WAVE,VALUE'
   print,'*       Mode: 0: Boxcar smoothing'
   print,'*             1: Rotational Broadening'
   print,'*            -1: GAUSSIAN SMOOTHING'
   print,'*             2: TRIANGULAR KERNEL'
   print,'*       WAVE: wavelength vector'
   print,'*      VALUE: optional input smoothing value; prompted if not passed'
   print,'*     output: Kernel C in common, for convolution with flux vector'
   print,'*
   print,' '
   return
   endif
;
if mode eq -2 then mode=-1
;
v=1.
;
IF MODE EQ 0 THEN BEGIN
   if n_params(0) lt 3 then begin
      READ,'Enter NSM:',V
      endif else v=value
   V=FIX(V)
   IF V EQ 0 THEN V=1
   IF V LT 0 THEN MODE=2
   ENDIF
zlog='Standard Smoothing: Boxcar width= '+string(V,'(I4)')+' bins'
if mode eq 0 then goto,lognos
;
IF MODE EQ 2 THEN begin
   trism,v
   zlog='Smoothed with a Triangle of width '+string(NSM,'(I4)')+' bins'
   endif
;
if abs(mode) eq 1 then begin
   n=N_ELEMENTS(WAVE)-1
   DISP=(WAVE(N)-WAVE(0))/FLOAT(N)
   W=WAVE(n/2)
   if n_params(0) lt 3 then begin
      IF MODE EQ 1 THEN z='($," ENTER ROTATION VELOCITY (KM/S)")'
      IF MODE EQ -1 THEN z='($," ENTER GAUSSIAN FWHM (Angstroms)")'
      print,FORMAT=z
      READ,V
      endif else v=value
   IF MODE EQ 1 THEN BEGIN
      NB=V*W/2.99792E+05/DISP/SQRT(2.)
      FWHM=1.
      zlog='Rotationally broadened by '+string(V,'(F6.2)')+'Km/S'
      ENDIF
   IF MODE EQ -1 THEN BEGIN
      NB=V/DISP/2.
      FWHM=3.
      zlog='Smoothed with a Gaussian of FHWM='+string(V,'(F6.2)')+' Angstroms'
      ENDIF
   N=FIX(ABS(NB)*FWHM)
   NSM=1+N*2
   IF NSM EQ 1 THEN BEGIN
      v=1. 
      c=fltarr(1)+1.
      PRINT,' SMOOTHING KERNEL LESS THAN 1 BIN WIDE'
      ENDIF else begin
      jj=findgen(n)
      kk=n-jj-1
      jker=(jj-n)*(jj-n)/nb/nb
      case 1 of
         mode eq  1: c=1.-jker
         mode eq -1: c=exp(-jker*0.693)
         endcase
      c=[c,1.,c(kk)]
      C=C/TOTAL(C)
      V=10000+V*100.
      IF MODE EQ 1 THEN V=-V
      endelse
   endif
;
lognos:
if (mode eq 0) and (v eq 1) then begin
   c=FLTARR(1)+1.
   zlog='Smoothing turned off'
   endif
if n_elements(ift) le 0 then return        ; is LU=3 open?
printf,lu3,'-3'
printf,lu3,zlog
RETURN
END
