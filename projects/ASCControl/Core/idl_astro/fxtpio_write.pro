	PRO FXTPIO_WRITE, UNIT, FILE, KEYWORD, ERRMSG=ERRMSG
;+
; NAME:	
;	FXTPIO_WRITE
;
; PURPOSE:	
;	Copy FITS files from disk to tape -- internal routine.
;
; EXPLANATION:	
;	Procedure will copy a disk FITS file to the specified tape  unit, at 
;	the current tape position.  Used for true disk FITS files, not 
;	SDAS/Geis files.  Called by FXTAPEWRITE.
;
; CALLING SEQUENCE:	
;		FXTPIO_WRITE, UNIT, FILE, [ KEYWORD, ERRRMSG = ]
;
; INPUTS:	
;	UNIT	= IDL tape unit number (scalar: 0-9).
;	FILE	= Disk FITS file name, with extension.
;
; OPTIONAL INPUTS:	
;	KEYWORD	= Keyword to place file name into.  If not supplied or 
;		equal to the null string '' then the file name is 
;		not put into the header before writing it to tape.
;
; OUTPUTS:	
;	NONE
;
; OPTIONAL KEYWORD OUTPUT: 
;	ERRMSG	= If defined and passed, then any error messages will
;		be returned to the user in this parameter rather than being 
;		handled by the IDL MESSAGE utility.  If no errors are 
;		encountered, then a null string is returned.  In order to use 
;		this feature, the string ERRMSG must be defined first, e.g.,
;
;				ERRMSG = ''
;				FXTPIO_WRITE, 1, FILE, ERRMSG=ERRMSG
;				IF ERRMSG(0) NE '' THEN ...
;
; PROCEDURE CALLS:	
;	REMCHAR, FXHREAD, FXPAR, FDECOMP, FXADDPAR, FITSTAPE
;
; RESTRICTIONS:	
;	Supported under VMS and (NOW) under UNIX running IDL Versions
;	3.1 or later when the UNIX versions of TAPRD, TAPWRT, etc. are
;	included in a user library directory.
;
; REVISION HISTORY:
; 		William Thompson, March 1992, from FITSWRITE by D. Lindler, W.
;						Landsman, and M. Greason.
;		William Thompson, Jan. 1993, renamed to be compatible with DOS 
;		Version 2, Donald G. Luttermoser, GSFC/ARC, 14 March 1995.
;			Added ERRMSG keyword.  Updated documentation concerning
;			UNIX.
;		Version 3, Donald G. Luttermoser, GSFC/ARC, 9 May 1995.
;			Removed the "PRINT, FILE" line from this routine and
;			placed it in FXTAPEWRITE which drives this procedure.
;-
;
	ON_ERROR,2	; Return to caller if error is encountered.
	MESSAGE = ''	; Set to non-null string if error is encountered.
;
	REMCHAR, FILE, ' '
	OPENR, LUN, FILE, /BLOCK, /GET_LUN
	FXHREAD, LUN, H, STATUS		; Get FITS header
	IF STATUS LT 0 THEN BEGIN
		FREE_LUN, LUN
		MESSAGE = 'Error reading FITS header.'
		GOTO, HANDLE_ERROR
	ENDIF
;                    
;  Add file name to supplied keyword.
;
	IF N_PARAMS() LT 3 THEN KEYWORD = ''
	IF KEYWORD NE '' THEN BEGIN
		FDECOMP, FILE, DISK, DIR, NAME, EXTEN, VERS
		FXADDPAR, H, KEYWORD, NAME
	ENDIF
;
;  Write FITS header to tape.
;
	NLINES = 1			; Count of lines in header.
	WHILE STRMID(H[NLINES-1],0,8) NE 'END     ' DO NLINES=NLINES+1
	NRECS=(NLINES+35)/36		; Number of 2880 byte records required.
	NWRITE = 0
	FOR I=0,NRECS-1 DO BEGIN
		HBUF = BYTARR(2880)+32B	; Blank header
		FOR J=0,35 DO BEGIN
			LINE = I*36+J
			IF LINE LT NLINES THEN HBUF[J*80] = BYTE(H[LINE])
		ENDFOR
		STATUS = FITSTAPE('write', UNIT, 8, HBUF)
		NWRITE = NWRITE+1
		IF STATUS LT 0 THEN BEGIN
			MESSAGE = 'Error in writing FITS data to tape.'
			GOTO, HANDLE_ERROR
		ENDIF
	ENDFOR
;
;  Read and write the rest of the FITS file, until the EOF is reached.
;
	X = BYTARR(2880)
	ON_IOERROR, DONE
	WHILE NOT EOF(LUN) DO BEGIN
		READU, LUN, X
		STATUS = FITSTAPE('write', UNIT, 8, X)
		IF STATUS LT 0 THEN BEGIN
			MESSAGE,'Unexpected error',/CONTINUE
			GOTO, DONE
		ENDIF
	ENDWHILE
;
;  Close the input file.
;
DONE:
	FREE_LUN, LUN
;
;  Write two EOF marks, and position between them.
;
	STATUS = FITSTAPE('weof', UNIT)
	STATUS = FITSTAPE('weof', UNIT)
	SKIPF, UNIT, -1
;
	IF N_ELEMENTS(ERRMSG) GT 0 THEN ERRMSG = MESSAGE
	RETURN		; Return with no errors.
;
; Error handling portion of the procedure.
;
HANDLE_ERROR:
	IF N_ELEMENTS(ERRMSG) EQ 0 THEN MESSAGE, MESSAGE
	ERRMSG = MESSAGE
	RETURN
;
	END
