	PRO FXTPIO_READ, UNIT, NAME, KEYWORD, NOSUFFIX=NOSUFFIX, ERRMSG=ERRMSG
;+
; NAME:
;	FXTPIO_READ
;
; PURPOSE:
;	Copies FITS files from tape to disk -- internal routine.
;
; EXPLANATION :	
;	Procedure to copy a FITS file from a tape on the specified tape unit to
;	the disk file <name>.FITS (unless the /NOSUFFIX keyword has been set).
;	For use on VMS (any version) and UNIX running IDL Version 3.1 or later 
;	(see Restrictions).
;
;	The procedure FXTAPEREAD is normally used to read a FITS tape.
;	FXTPIO_READ is a procedure call internal to FXTAPEREAD.
;
; CALLING SEQUENCE:	
;		FXTPIO_READ, UNIT, NAME, [ KEYWORD, /NOSUFFIX, ERRMSG = ]
;
; INPUT PARAMETERS:	
;	UNIT	= Tape unit number (scalar: 0-9).
;	NAME	= File name (without an extension, unless /NOSUFFIX is set).
;
; OPTIONAL INPUT PARAMETERS:	
;	KEYWORD	= If supplied and not equal to the null string then the file 
;		name will be taken from the value of the header keyword 
;		specified.
;
; OUTPUTS:	
;	NAME	= Name of file if input keyword parameter is supplied.
;
;
; OPTIONAL OUTPUT KEYWORD: 
;	ERRMSG	= If defined and passed, then any error messages will be 
;		returned to the user in this parameter rather than being handled
;		by the IDL MESSAGE utility.  If no errors are encountered, then
;		a null string is returned.  In order to use this feature, the 
;		string ERRMSG must be defined first, e.g.,
;
;				ERRMSG = ''
;				FXTPIO_READ, 1, NAME, ERRMSG=ERRMSG
;				IF ERRMSG(0) NE '' THEN ...
;
; OPTIONAL INPUT KEYWORD:
;		NOSUFFIX = Normally FXTPIO_READ will automatically append a
;			  ".fits" to the end of a passed file name.  Setting
;			  this keyword prevents this from happening.
;
; PROCEDURE CALLS:	
;	REMCHAR, FITSTAPE, FXPAR
;
; RESTRICTIONS:	
;	Supported under VMS and (NOW) under UNIX running IDL Versions
;	3.1 or later when the UNIX versions of TAPRD, TAPWRT, etc. are
;	included in a user library directory.
;
; SIDE EFFECTS:	
;	The FITS file is copied to a disk file called <name>.FITS 
;	(unless the /NOSUFFIX keyword has been set).
;
;	The FITS file is copied over record by record with no conversion, until
;	the end-of-file marker is reached.  No testing is done of the validity 
;	of the FITS file.
;
;	Images are NOT converted using BSCALE and BZERO factors in the header.
;
; Category    :	Data Handling, I/O, FITS, Generic.
;
; Prev. Hist. :	William Thompson, March 1992, from FITSREAD by D. Lindler, M. 
;						Greason, and W. Landsman.
;		W. Thompson, May 1992, changed open statement to force 2880 
;			byte fixed length records (VMS).  The software here 
;			does not depend on this file configuration, but other
;			FITS readers might.
;		William Thompson, Jan. 1993, renamed to be compatible with DOS 
;		Version 2, Donald G. Luttermoser, GSFC/ARC, 14 March 1995.
;			Added ERRMSG and NOSUFFIX keywords.
;-
;
	ON_ERROR, 2	; Return to caller if error is encountered.
	MESSAGE = ''	; Set to non-null string if error is encountered.
;
	IF N_PARAMS() LT 3 THEN KEYWORD=''
;
;  Read FITS header.
;
	HEADER = STRARR(100)			;FITS header array
	NHEAD = 0
	NH = 100				;Number of lines in header
	REC = ASSOC(7,BYTARR(2880))		;Define record type
	X = BYTARR(2880)				;FITS records are 2880 bytes
	FOR II=1,100 DO BEGIN
		STATUS = FITSTAPE('read',UNIT,8,X)
		IF STATUS EQ -4 THEN BEGIN
			MESSAGE = 'EOF while reading fits header -- '+$
				'process terminated.'
			GOTO, HANDLE_ERROR
		ENDIF
		IF STATUS LT 0 THEN RETURN
		FOR I=0,35 DO BEGIN			;Process 36 header lines
			H = X[(I*80):(I*80+79)]		;Extract next line
			HEADER[NHEAD] = STRING(H)	;Add to header
			NHEAD = NHEAD + 1
			IF NHEAD EQ NH THEN BEGIN
				HEADER = [HEADER, STRARR(100)]
				NH = NH + 100
			ENDIF
;
;  Check for end of header.
;
			IF STRING(H[0:7]) EQ 'END     ' THEN GOTO,L1
		ENDFOR ; I LOOP
	ENDFOR ; II LOOP
;
L1:
	HEADER = HEADER[0:NHEAD-1]
	NREC = FIX((NHEAD+35)/36)	;Number of 2880 byte records
;
;  Determine file name.
;
	IF KEYWORD NE '' THEN BEGIN
		NAME = FXPAR(HEADER, KEYWORD)
		IF !ERR LT 0 THEN BEGIN
			MESSAGE = 'Keyword '+KEYWORD+' not in header -- '+$
				'no file created.'
			GOTO, HANDLE_ERROR
		ENDIF
	ENDIF
	REMCHAR, NAME, ' '		;Remove all blanks
;
;  Get the UNIT number, and open the file.  Don't add the '.fits' suffix if
;  the /NOSUFFIX keyword has been set.
;
       	GET_LUN, LUN
	IF KEYWORD_SET(NOSUFFIX) THEN OUTNAME = NAME ELSE $
		OUTNAME = NAME+'.fits'
       	OPENW, LUN, OUTNAME, 2880, /BLOCK
;
;  Convert the header to byte and force into 80 character lines.
;
	BHDR = REPLICATE(32B, 80, 36*NREC)
	FOR N = 0,NHEAD-1 DO BHDR[0,N] = BYTE( STRMID(HEADER[N],0,80) )
	WRITEU, LUN, BHDR
;
;  Read and write the rest of the FITS file, until the EOF is reached.
;
NEXT_REC:
	STATUS = FITSTAPE('read', UNIT, 8, X)
	IF STATUS LT 0 THEN BEGIN
		IF STATUS NE -4 THEN MESSAGE,'Unexpected error',/CONTINUE
		GOTO, DONE
	ENDIF
	WRITEU, LUN, X
	GOTO, NEXT_REC
;
;  Close the output file, and return.
;
DONE:
	FREE_LUN, LUN
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
