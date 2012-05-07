;******************************************************************
;+
; ***** NIUEGET
;*NAME:
;   IUEGET     8 JANUARY 1981
;
;*PURPOSE:  
;   To acquire spectral data for a given order
;   from an IUE diskfile
; 
;*EXECUTION:    
;   IUEGET,LUN,M,H,WAVE,FNET,EPS
; 
;*INPUT:
;   LUN - logical unit of opened file (MEHI or
;         MELO) containing IUE spectral data
;   M - spectral order for which data are to
;         be acquired (1 for low-dispersion spectra,
;         60-125 for high-dispersion spectra)
;*OUTPUT:
;   H - header record
;   WAVE - vector of wavelengths
;   FNET - vector of net fluxes (GROSS-smoothed
;          BACKGROUND) in IUE units
;   EPS - error vector
; 
;*DISK DATA SETS:
;        The disk data file containing the IUE spectrum
;        must be opened for reading before execution of
;        IUEGET and closed after execution.
; 
;*METHOD:
;        The header record is acquired and examined
;        to determine which records contain the data for
;        the specified spectral order.  The wavelength,
;        gross-flux, background-flux, and error vectors
;        are then acquired.  The wavelength vector is
;        converted to angstroms, while the fluxes are
;        converted to IUE units.  The background is first
;        smoothed by a  median filter followed by two 
;        running averages.  The net flux is determined
;        as the difference between the gross flux 
;        and the smoothed background flux.  All the
;        vectors are stripped of padded zeros.
; 
;*OPERATIONAL NOTES:
;        Care should be taken when using this routine.  IUEGET
;        uses the system variable !ERR to determine the record
;        length in the data file.  !ERR is set when the file is
;        first opened.  If the user does anything to change
;        !ERR before calling IUEGET (eg. any input/output from
;        tape or disk), the value of !ERR should be restored.
;        Example:
;                OPENR,1,'S6541L'
;                SAVE=!ERR
;                  ... other work that might change !ERR
;                !ERR=SAVE
;                IUEGET,1,1,H,WAVE,FNET,EPS
; 
;*EXAMPLES;
;        In this example, spectral data for orders
;        93 and 94 of the high-dispersion spectrum,
;        SWP 3323, are acquired and plotted:
;         
;                OPENR,1,'IUER_USERDATA:S3323H'
;                IUEGET,1,93,H,W93,NET93,E93
;                IUEGET,1,94,H.W94,NET94,E94
;                CLOSE,1
;                !XMIN=W94(0) & !XMAX=MAX(W93)
;                PLOT,W94,F94
;                OPLOT,W93,F93
;
;*SUBROUTINES CALLED:
;    GMEDIAN
;    PARCHECK
;  
;*MODIFICATION HISTORY:
;     VERSION 1  BY SALLY HEAP   2-16-81
;   22-OCT-85 KF modified for DIDL (i.e. /ERROR added & change
;                MEDIAN to GMEDIAN
;   19-NOV-85 RWT use intrinsic DIDL MEDIAN instead of GMEDIAN
;    4-13-87  RWT VAX mods: use GMEDIAN, add PARCHECK & remove EXTRACT commands
;-
;**************************************************************************
PRO NIUEGET,LUN,M,H,WAVE,FNET,EPS,fgross,fb
;
; CHECK INPUT PARAMETERS
;
NPAR = N_PARAMS(0)
IF NPAR EQ 0 THEN BEGIN
    PRINT,' IUEGET,LUN,M,H,WAVE,FNET,EPS'
    RETALL & END
;PARCHECK,NPAR,6,'IUEGET'
PCHECK,LUN,1,100,0110
PCHECK,M,2,100,0110
N    = !ERR/2
REC  = ASSOC(LUN,INTARR(N))
;
; GET DESCRIPTIVE DATA FROM HEADER RECORD
;
  H    = REC(0)
  NCAM = H(3) & IMAGE=H(4) & NGRP=H(5)
  NREC = H(2)*NGRP       ; NO. OF SPECTRAL-DATA RECORDS (EXCLUDING HEADER)
  IORD = H(200) - M + 1  ; SPECTRAL ORDER NUMBER-- 1, 2, 3,....
  WO   = H(100+IORD-1)   ; STARTING WAVELENGTH
  NPTS = H(300+IORD-1)   ; NO OF POINTS IN ORDER
  IREC = NGRP*(IORD-1)+1 ; RECORD NO. OF WAVELENTH RECORED FOR ORDER=IORD
;
; CHECK THAT IREC IS ON THE FILE
;
  IF (IREC LE 0) OR (IREC GT NREC-NGRP+1) THEN BEGIN
     PRINT,'ERROR IN IUEGET'
     PRINT,'RECORD ', IREC, 'ASSOCIATED WITH ORDER', M, ' NOT ON FILE'
     PRINT,'ACTION : RETURNING'
     RETALL
  END
;
; READ IN DATA FOR SPECTRAL ORDER
;
  IF M EQ 1 THEN WAVE=0.2*REC(IREC) ELSE WAVE=FLOAT(WO) + .002*REC(IREC)
  EPS = REC(IREC+1)
  G   = H(20) / (2.^H(21)) * REC(IREC+2)
  B   = H(24) / (2.^H(25)) * REC(IREC+3)
;
; TRIM OFF PADDED ZEROS -- PARE DOWN TO NPTS
;
  WAVE = WAVE(0:NPTS-1)
  EPS = EPS(0:NPTS-1)
  G = G(0:NPTS-1)
  B = B(0:NPTS-1)
;
; PROCESS BACKGROUND
;
  IF N LE 600 THEN BEGIN NMED=31 & NSMO=15 & END
  IF N GT 600 THEN BEGIN NMED=63 & NSMO=31 & END
  GMEDIAN,B,NMED,SB
  !ERR=N*2                                            ; RESET NO. OF POINTS
  B = SMOOTH(SB,NSMO) & B = SMOOTH(B,NSMO)
;
; GET NET
;
  FNET = G - B
fgross=g
fb=b
;
RETURN
END
