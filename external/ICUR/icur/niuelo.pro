;*********************************************************************
;+
;*NAME:
;   NIUELO     8 JANUARY 1981
; mod of IUELO for ICUR I/O
; 
;*PURPOSE:  
;   To acquire and calibrate low dispersion spectral
;   data from IUE with optional corrections for THDA
;   sensitivity variation and LWR sensitivity variation.
; 
;*EXECUTION:    
;   IUELO,IMAGET,H,WAVE,FLUX,EPS
; 
;*INPUT:
;        IMAGET - disk file name for eslo or melo file 
;                 containing low-dispersion spectral data  
;                 (character string)
;                 e.g. MELO file for      IMAGET
;         
;                      SWP 7954           'SWP7954L'
;                      LWR 9422           'LWR9422L'
;*OUTPUT:
;           H - header record amended for exposure
;               time input by user, and flags for THDA
;               and LWR degradation corrections.
;        WAVE - wavelength vector (Angstroms)
;        FLUX - absolute flux vector (ergs/sec/cm2/A)
;         EPS - error vector
; 
;*INTERACTIVE INPUT:
;    1)  Exposure time (in minutes,sec,ms), if the header
;        record does not already contain these quantities.
;        If the user types in zeros, then the net flux
;        in IUE units is returned. Values may be integer or real
;        but the total time must be less than 32767 minutes.
;    2)  Correction for THDA sensitivity variation, if entry 68
;        in the header record equals 0 (see description below).
;    3)  Correction for LWR sensitivity degradation, if entry 69
;        in the header records equals 0 (see description below).
;         
;*OUTPUT PLOTS:  
;     wavelength vs net flux
;     wavelength vs. absolute flux
; 
;     In both plots, those data-points with negative values of 
;     epsilon are marked with asterisks.
; 
;*DISK DATA SETS:
;        1) The MELO (eslo) data file must be resident on
;           disk.
;        2) the files, 'IUER_PRODROOT:[DAT]IUECAL.DAT' and IUECAL2.DAT,
;           containing the calibration tables used to convert 
;           fluxes from IUE units to absolute units, must be 
;           available for CALIB. See IUER_PRODROOT:[INF]IUECAL.INF and
;           IUECAL2.INF for more documentation.
;        3) If the THDA correction is requested with a user-specified
;           THDA value, the label portion of the MELO file must be
;           resident on the system disk.
;        4) If the LWR sensitivity degradation correction is requested,
;           the file IUER_PRODROOT:[DAT]DEGRAD.TAB must exist. (See 
;           documentation in IUER_PRODROOT:[INF]DEGRAD.INF.)
;
;*OPERATIONAL NOTES:
;       - HFIX can be run prior to IUELO to set all the flags in 
;         record 0 necessary to allow IUELO to run non-interactively.
;       - CALIB, which is called by IUELO requires that H(580) contains
;         the number of the ITF file used by IUESIPS. This is set either
;         with the new IUECOPY, or using ITFFLAG.
;       - Specifying 0 for the exposure time will result in net fluxes
;         being output rather than absolutely calibrated fluxes.
; 
;*METHOD:
;        IUEGET is used to acquire the header record
;        and the wavelength, net flux, and error 
;        vectors.  The header record is then examined
;        to see if the exposure time was recorded (i.e.
;        non-zero)
;                H(39) - minutes
;                H(40) - seconds
;                H(41) - ms
;        If the exposure time is not recorded, then
;        the user is asked to supply the exposure time
;        (in min, sec, ms) and these data are inserted
;        into the header record. Note that the user may
;        enter these values as either integer or real
;        numbers although real values for ms will be 
;        truncated. The net fluxes are then converted
;        to absolute units with the use of IUECAL or IUECAL2
;        by CALIB (if the exposure time is not zero). CALIB
;        uses H(580) to decide which file is opened (see ITFFLAG).
;        If H(68) = 0, the user is asked if a correction for
;        THDA sensitivity variations is desired. The possible
;        options include no correction, correction using the
;        IUESIPS determined THDA stored in H(61), or correction
;        using a user-specified THDA with the temperature data
;        stored in the label displayed to assist the user.
;        If H(68) < 0, then the correction will be applied 
;        automatically using  -H(68) / 10.0 for the THDA.
;        If H(68) > 0, then the correction is not applied
;        and no user input is required. Note that the default 
;        value for H(68) is 0.
;        If an LWR image is specified, and H(69) = 0, the user
;        is asked if a correction for the LWR sensitivity
;        degradation is desired. If H(69) < 0, then the 
;        correction is applied automatically. If H(69) > 0,
;        then the correction is not applied and no user input
;        is required. Note the default for H(69) is 0.   
;         
;*EXAMPLES:  
;    spectral data for SWP 3373 are acquired via the command:
;             IUELO,'SWP3373L',HEAD,WAVE,ABSFLUX,EPS
;
;*SUBROUTINES CALLED:
;    IUEPLOT
;    CALIB
;    SDC
;    TEMPCOR
;    LTI
;    INTIME
;    IUEGET
;    LABEL
;         
;*MODIFICATION HISTORY:
;        VERSION 1 BY SALLY HEAP   13-FEB-81
;     -  June 11, 1981  change by Sally Heap per change
;        request #18.  Uses COMPOSE before trying to open
;        files, and prints out the first 9 lines of the
;        label before it asks for the exposure time.
;     -  July 20, 1981 by D. Lindler per change request # 73.
;        Corrected to work when the exposure time is already in
;        the header record.
;     -  May 30, 1984 by RWT per URP #177. Corrected to allow either
;        integer or real exposure times.
;     -  December 13, 1984 RWT use new versions of IUEPLOT & CALIB.
;     -  4-28-86 RWT includes LWR sensitivity degradation correction
;          (SDC & new CALIB), a correction for temperature-dependent
;          sensitivity variations (TEMPCOR), corrects problem with 
;          exposure time error, and uses new DIDL IUEGET
;     -  8-27-86 RWT allow exp. times > 32767 sec or >32767 millisec.
;          using new subroutine INTIME
;     -  8-12-87 RWT VAX mods: eliminate subroutines, add PARCHECK,
;         add listing of procedure call, change UIC references, add
;         pause before plot, use vector subscript notation in
;         print statements and use GET_LUN & SET_XY.
;     - 12-31-87 RWT use label information rather than file name for
;         error checking and modify for new LWP absolute calibration
;-
;*********************************************************************
PRO NIUELO,IMAGET,H,WAVE,FCOR,EPS,r1,r2,icdfile=icdfile,helpme=helpme
;
if keyword_set(helpme) then begin
   print,' '
   print,'* NIUELO'
   print,'*    variant of IUELO, saves data to disk file'
   print,'*    calling sequence: NIUELO,image,h,w,f,e,r1'
   print,'* '
   print,'* '
   print,'*    KEYWORDS: ICDFILE'
   print,'*       name of .ICD file, default=IUELO'
   print,' '
   return
   endif
;
; CHECK INPUT PARAMETER
;
IF N_PARAMS(0) EQ 0 THEN BEGIN
  PRINT,' IUELO,IMAGET,H,WAVE,FCOR,EPS'
  RETALL & END
np=n_params(0)
s=size(imaget) & ns=n_elements(s)
if s(ns-2) eq 7 then imelo=0 else imelo=1     ;0 for file, 1 for array
if imelo eq 0 then begin
   PCHECK,IMAGET,1,100,1000
   DECOMPOSE,IMAGET,DISK,UIC,NAME,EXT,VERS
   !p.title=name
   FILE=DISK + UIC + NAME + '.DAT' + VERS
   LABFILE=DISK + UIC + NAME + '.LAB' + VERS
   ;
   ; CHECK LABEL FILE TO DETERMINE PROPER FILE TYPE
   ;
   GET_LUN,LUN
   OPENR,LUN,LABFILE
   trec=fstat(lun)
   REC = ASSOC(LUN,BYTARR(trec.rec_len))
;   BLOCK = STREBCASC(REC(1) > 240B < 249B)
;   IF FIX(STRMID(BLOCK,33,4)) NE 7 THEN BEGIN
;      PRINT,'FILE MUST BE AN ESLO OR MELO FILE (TYPE =L)'
;      PRINT,'ACTION: RETURNING'
;      RETALL & END
   CLOSE,LUN
;
; OPEN DATA FILE & USE IUEGET TO ACQUIRE DATA
;
   OPENR,LUN,FILE
   NIUEGET,LUN,1,H,WAVE,FNET,EPS,fg,fb
   FREE_LUN,LUN
   endif else begin
   nolab=0
   if (np ge 6) then asclab=record else nolab=1
   if (np ge 7) then record=r2 else record=-1
   niueg2,imaget,h,wave,fnet,eps,fg,fb   ;read array directly
   !p.title=''
   endelse
;
; GET EXPOSURE TIME FROM USER IF NOT ALREADY IN THE HEADER
;
PRINT,' '
IF TOTAL(H(39:41)) EQ 0 THEN BEGIN
   PRINT,' YOU WILL NEED TO ENTER THE EXPOSURE TIME '
   PRINT,' HERE IS THE LABEL TO HELP YOU '
   PRINT,' '
   if imelo eq 0 then LABEL,LABFILE,1,9 else begin
      if nolab eq 0 then print,asclab(0:9) else print,' No label passed'
      endelse
   INTIME,H
   END ; INTERACTIVE WORK WITH USER
;
MN=H(39)
SC=H(40)
MS=H(41)
PRINT,'EXPOSURE TIME (MIN,SEC,MSEC):',MN,SC,MS
EXPS = 1.E-3*MS + SC + 60. *MN
;
; GET FLUX = ABS CORR FLUX (EXPS GT 0) OR NET FLUX (EXPS EQ 0)
;
IF EXPS GT 0 THEN BEGIN
  PRINT,' '
  IF (H(3) EQ 2) AND (H(69) EQ 0) THEN SDC,H  ;ck. for LWR sens. degrad. corr.
  CALIB,H,WAVE,FNET,EXPS,FABS      ;apply abs. cal. (& LWR corr. if desired)
  PRINT,' '
  IF H(68) EQ 0 THEN LTI,H,IMAGET             ;ck. for THDA correction
  IF H(68) LT 0 THEN TEMPCOR,H,FABS,FCOR  ELSE FCOR=FABS
  END ELSE FCOR=FNET               ;use net flux if no exposure time given
;
; modify header for icur
if h(39) gt 546 then h(5)=-h(39) else h(5)=60*h(39)+h(40)
h(34:38)=0
;
; PLOT OUT THE RESULTS (after pause) & END
;
;WAIT,5
XMIN=!X.range(0) & XMAX=!X.range(1) & YMIN=!Y.range(0) & YMAX=!Y.range(1)
!x.range(0)=0.
!y.range(0)=0.
if exps gt 0 then IUEPLOT,H,WAVE,FCOR,EPS else begin
   iueplot,h,wave,fg,eps & oplot,wave,fb
   endelse
!x.range=[XMIN,XMAX] & !y.range=[YMIN,YMAX]
if keyword_set(icdfile) then begin
   if not ifstring(icdfile) then icfile='iuelo.icd'
   if (n_params(0) ge 6) then record=r1 else record=-1
   kdat,icdfile,h,wave,fcor,eps,record
   endif
RETURN
END
