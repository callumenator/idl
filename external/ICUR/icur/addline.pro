;*************************************************************
PRO ADDLINE,WAVE,FLUX,lam,sig,tf,helpme=helpme    ; ADD LINE TO FLUX VECTOR
COMMON COM1,H
common comxy,xcur,ycur,zerr,resetscale,lu3
if keyword_set(helpme) then begin
   print,' '
   print,'* ADDLINE,WAVE,FLUX,lam,sig,tf '
   print,'*  Add a single line to the flux vector'
   print,'*     WAVE, FLUX: wavelength and flux vectors. FLUX is modified'
   print,'*     LAM,TF: wavelength and integrated flux of line'
   print,'*     SIG: sigma in bins or -Angstroms (def=2)
   print,'*  '
   print,'*  The LAM, SIG, and TF values are requested if not passed.'
   print,' '
   return
   endif
S=N_ELEMENTS(WAVE)
DISP=(WAVE(50)-WAVE(0))/50.
if n_params() ge 5 then pass=1 else pass=0
if pass then begin
   if (lam le 0) or (tf le 0.) then pass=0
   endif
if not pass then begin
   LAM=0. & SIG=1. & TF=1.E-15
   z=' ENTER WAVELENGTH, SIGMA (BINS), AND INTEGRATED FLUX: '
   ;print,z 
   READ,LAM,SIG,TF,prompt=z
   endif
IF TF EQ 0. THEN RETURN
if lam le 0. then return
if sig eq 0. then sig=2.   ;def=2 bins
if sig lt 0. then sig=abs(sig/disp)          ;passed in Angstroms
AMP=TF/(SIG*DISP*2.5066)
G=FLTARR(S)
i0=xindex(wave,lam)                 ;TABINV,WAVE,LAM,I0
WID=FIX(SIG)*4
I1=FIX(I0)-WID
IF I1 LT 0 THEN I1=0
I2=FIX(I0)+WID
IF I2 GE S THEN I2=S-1
FOR I=I1,I2 DO BEGIN
     Z=(FLOAT(I)-I0)/SIG
     Z=Z*Z
     G(I)=G(I)+AMP*EXP(-Z/2.)
     ENDFOR
FLUX=FLUX+G
if n_elements(h) lt 65 then return
H(60)=999
H(61)=H(61)+1
J=62+(H(61)-1)*3
H(J)=FIX(LAM)
H(J+1)=FIX(1000.*(LAM-FIX(LAM)))
H(J+2)=FIX(ALOG10(ABS(TF))*100.)
if n_elements(lu3) le 0 then begin
   printf,lu3,' 6'
   printf,lu3,lam,sig,TF,' ADDLIN: Lambda,Sigma,Flux'
   endif
RETURN
END  
