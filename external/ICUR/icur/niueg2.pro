;*********************************************************************
PRO NIUEG2, MELO, H, WAVE, FLUX, EPS, g,b
;
;+
; NAME: NIUEG2
; Modified 7/5/88 from IUELOW to be called by NIUELO
; now passes gross and background vectors ala NIUELO
;
; PURPOSE:
;      procedure for getting final output from SDPS' MELO array
;      (analogous to iuelo.pro)
; CATEGORY:
; CALLING SEQUENCE:
; INPUTS:
;              MELO - melo array
; OUTPUTS:
;         H,WAVE, FLUX, EPS arrays 
;         where FLUX = net flux if exp_time is not given
;                    = absolute flux if exp_time is given
; OPTIONAL OUTPUT PARAMETERS:
; COMMON BLOCKS:
; SIDE EFFECTS:
; RESTRICTIONS:
; PROCEDURE:
; MODIFICATION HISTORY:
;  VERSION 1 by Sally Heap, August 1987
;          2                SEP 1987 - put in LWR degradation correction
;  VERSION 3 by jkf/acc - renamed IUELOW...originally FROMMELO and removed
;      calibration.
;-

;               
SZ=SIZE(MELO) & NS=SZ(1) & NL=SZ(2)
IF NL NE 7 THEN BEGIN
   PRINT,' Input array is not the correct size (7) for MELO,  size=',nl
   RETURN
   END

IF NS EQ 1024 THEN MELO=MELO(2:1023,*)

;
; GET DESCRIPTIVE DATA FROM HEADER RECORD
;
  H  = MELO(*,0)
  NCAM=H(3) & IMAGE=H(4) & NGRP=H(5)
  NREC=H(2)*NGRP        ; NO. OF SPECTRAL-DATA RECORDS (EXCLUDING HEADER )
  IORD=H(200)           ; SPECTRAL ORDER NUMBER-- 1, 2, 3,....
  WO=H(100+IORD-1)      ; STARTING WAVELENGTH
  NPTS=H(300+IORD-1)    ; NO OF POINTS IN ORDER
  IREC=NGRP*(IORD-1) + 1; RECORD NO. OF WAVELENGTH RECORDED FOR ORDER=IORD
;
;
  WAVE=0.2*MELO(*,IREC) 
  EPS=MELO(*,IREC+1)
  g=h(20)/(2.^h(21))*melo(*,irec+2)
  b=h(24)/(2.^h(25))*melo(*,irec+3)
  NET=H(28)/(2.^H(29))*MELO(*,IREC+4)
;
; TRIM OFF PADDED ZEROS -- PARE DOWN TO NPTS
;
  WAVE= WAVE(0:NPTS-1)
  EPS =  EPS(0:NPTS-1)
  FLUX=  NET(0:NPTS-1)
  G =  G(0:NPTS-1)
  B=  B(0:NPTS-1)
;
  IF Npts LE 600 THEN BEGIN NMED=31 & NSMO=15 & END
  IF Npts GT 600 THEN BEGIN NMED=63 & NSMO=31 & END
  GMEDIAN,B,NMED,SB
  !ERR=Npts*2                                            ; RESET NO. OF POINTS
  B = SMOOTH(SB,NSMO) & B = SMOOTH(B,NSMO)
;
RETURN
END
