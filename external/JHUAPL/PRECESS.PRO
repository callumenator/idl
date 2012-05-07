;-------------------------------------------------------------
;+
; NAME:
;       PRECESS
; PURPOSE:
;       Precess celestial coordinates to a new date.
; CATEGORY:
; CALLING SEQUENCE:
;       precess, date1, ra1, dec1, date2, ra2, dec2
; INPUTS:
;       date1 = original date (like 1 Jan, 1950).   in.
;       ra1 = original R.A. in hrs.                 in.
;       dec1 = original Dec in deg.                 in.
;       date2 = new date (like 25 Nov, 1987).       in.
; KEYWORD PARAMETERS:
; OUTPUTS:
;       ra2 = new R.A. in hrs.                      out.
;       dec2 = new Dec in deg.                      out.
;       
; COMMON BLOCKS:
; NOTES:
; MODIFICATION HISTORY:
;       R. Sterner. 25 Nov, 1987.
;       Johns Hopkins University Applied Physics Laboratory.
;       RES 17 Oct, 1989 --- converted to SUN.
;
; Copyright (C) 1987, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
 
	PRO PRECESS, DATE1, RA1, DEC1, DATE2, RA2, DEC2, help=hlp
 
	IF (N_PARAMS(0) LT 6) or keyword_set(hlp) THEN BEGIN
	  PRINT,' Precess celestial coordinates to a new date.'
	  PRINT,' precess, date1, ra1, dec1, date2, ra2, dec2' 
	  PRINT,'   date1 = original date (like 1 Jan, 1950).   in.
	  PRINT,'   ra1 = original R.A. in hrs.                 in.
	  PRINT,'   dec1 = original Dec in deg.                 in.
	  PRINT,'   date2 = new date (like 25 Nov, 1987).       in.
	  PRINT,'   ra2 = new R.A. in hrs.                      out.
	  PRINT,'   dec2 = new Dec in deg.                      out.
	  PRINT,' '
	  RETURN
	ENDIF
 
	PI2 = 360./!RADEG
 
	DATE2YMD, DATE1, Y1, M1, D1
	DATE2YMD, DATE2, Y2, M2, D2
	T = (YMD2JD(Y2,M2,D2) - YMD2JD(Y1,M1,D1))/36525.
	M = 3.07234 + 0.00186*T
	N = 20.0468 + 0.00850*T
 
	DRA = (M/3600.) + (N/15./3600.)*SIN(RA1/24.*PI2)*TAN(DEC1/!RADEG)
	DDEC = (N/3600.)*COS(RA1/24.*PI2)
 
	RA2 = RA1 + DRA*T*100.
	DEC2 = DEC1 + DDEC*T*100.
 
	RETURN
	END
