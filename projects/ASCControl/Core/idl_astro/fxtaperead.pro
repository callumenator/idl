	PRO FXTAPEREAD, UNIT, LIST, KEYWORD, TAPENAME, FNAMES, XWSTR, $
		NOSUFFIX=NOSUFFIX, SFDU=SFDU, XWIDGET=XWIDGET, ERRMSG=ERRMSG
;+
; Project     : SOHO - CDS
;
; Name        :	FXTAPEREAD
;
; Purpose     : Copy FITS files tape to disk with interactive capabilities.
;
; Explanation :	Copy FITS files from tape onto disk.  Data is left in FITS 
;		format, and not converted to SDAS.  For use on VMS (any 
;		version) and UNIX running IDL Version 3.1 or later (see 
;		Restrictions).
;
; Use         :	FXTAPEREAD                      ; Prompt for all parameters.
;
;		FXTAPEREAD, UNIT, LIST, KEYWORD, TAPENAME, FNAMES [, XWSTR]
;
;		FXTAPEREAD, 1, INDGEN(5)+1, 'IMAGE'
;			; Read the first 5 files on unit 1.  The filenames are
;			; taken from the IMAGE keyword.
;
;		FXTAPEREAD, 1, [2,4], '', '', ['GALAXY', 'STAR']
;			; Read files 2 and 4 on unit 1.  Create files named
;			; GALAXY and STAR.
;
;		FXTAPEREAD, 1, [2,4]
;			; Read files 2 and 4, and prompt for filenames.
;
; Inputs      :	None necessary.
;
; Opt. Inputs :	Interactive users will normally just type FXTAPEREAD and be 
;		prompted for all parameters.  However, the following 
;		parameters can be passed directly to FXTAPEREAD:
;
;		UNIT	= Tape unit number (scalar: 0-9).
;
;		LIST	= Vector containing list of file numbers to read.
;
;		KEYWORD	= Scalar string giving a FITS keyword which will be 
;			  extracted from the headers on tape and used for file 
;			  names.  Set KEYWORD to the null string '', if such a 
;			  keyword is not to be used.
;
;		TAPENAME= Scalar string giving a name for the tape.  Filenames 
;			  will be constructed by concatenating TAPENAME with 
;			  the file number.  TAPENAME is used only if KEYWORD 
;			  is passed as the null string ''.
;
;		FNAMES	= Vector string giving a file name for each file 
;			  number given in LIST.  FNAMES is used only if both 
;			  KEYWORD = '' and TAPENAME = ''.  Spaces are trimmed 
;			  from names in FNAMES.
;
;		XWSTR	= A string array that contains informational text 
;			  concerning tape reading events.  These strings are 
;			  printed either to the screen or to the FILENAME 
;			  widget (internally called XWIDGET) created by the 
;			  XWINTAPE procedure.
;
; Outputs     :	None.
;
; Opt. Outputs:	FNAMES	= If KEYWORD or TAPENAME is set to a non-null string, 
;			  then the filename created by FXTPIO_READ is stored 
;			  in this variable to be returned to the caller.
;
;		XWSTR	= A string array that contains informational text 
;			  concerning tape reading events.  These strings are 
;			  printed either to the screen or to the FILENAME 
;			  widget (internally called XWIDGET) created by the 
;			  XWINTAPE procedure.  Note that FXTAPEREAD adds
;			  strings to this array and passes them back to the
;			  caller.
;
; Keywords    :	ERRMSG	= If defined and passed, then any error messages will
;			  be returned to the user in this parameter rather 
;			  than being handled by the IDL MESSAGE utility.  If
;			  no errors are encountered, then a null string is
;			  returned.  In order to use this feature, the string
;			  ERRMSG must be defined first, e.g.,
;
;				ERRMSG = ''
;				FXTAPEREAD, 1, INDGEN(5)+1, 'IMAGE', $
;					ERRMSG=ERRMSG
;				IF ERRMSG(0) NE '' THEN ...
;
;		NOSUFFIX = Normally FXTAPEREAD (via FXTPIO_READ) will 
;			  automatically append a ".fits" to the end of a 
;			  passed file name.  Setting this keyword prevents
;			  that from happening.
;
;		SFDU	= This keyword tells this routine that the first file
;			  on the tape is an SFDU header file (defined to be
;			  tape file number 1).  If this keyword is set, then
;			  the first file on the tape is skipped after the
;			  initial rewind is preformed.
;
;		XWIDGET	= This keyword tells this routine that an X-window
;			  widget (i.e., XWINTAPE) is driving this program.
;			  If this is the case, any informational messages
;			  generated from this routine will be displayed in the
;			  widget instead of the screen.
;
; Calls       :	DATATYPE, FITSTAPE, GETFILES, FXTPIO_READ
;
; Common      :	None.
;
; Restrictions:	Supported under VMS and (NOW) under UNIX running IDL Versions
;		3.1 or later when the UNIX versions of TAPRD, TAPWRT, etc. are
;		included in a user library directory.
;
; Side effects:	FXTAPEREAD will always rewind the tape before processing.
;
;		The FITS file is copied over record by record with no 
;		conversion, until the <end-of-file> marker is reached.  No 
;		testing is done of the validity of the FITS file.
;
;		Images are NOT converted using BSCALE and BZERO factors in the 
;		header.
;
;		For each tape file a FITS disk file will be created with the 
;		name "<name>.FITS" unless /NOSUFFIX has been set..
;
; Category    :	Data Handling, I/O, FITS, Generic.
;
; Prev. Hist. :	William Thompson, March 1992, from FITSRD by D. Lindler.
;		William Thompson, May 1992, fixed TPOS bug when reading 
;			multiple files.
;		William Thompson, Jan. 1993, changed for renamed FXTPIO_READ.
;
; Written     :	William Thompson, GSFC, March 1992.
;
; Modified    :	Version 1, William Thompson, GSFC, 12 April 1993.
;			Incorporated into CDS library.
;		Version 2, Donald G. Luttermoser, GSFC/ARC, 13 March 1995.
;			Added ERRMSG keyword.  Reformatted and modified the
;			documentation.
;		Version 3, Donald G. Luttermoser, GSFC/ARC, 20 March 1995.
;			Added NOSUFFIX & SFDU keyword.
;		Version 4, Donald G. Luttermoser, GSFC/ARC, 9 May 1995.
;			Added the XWIDGET keyword.
;		Version 5, Donald G. Luttermoser, GSFC/ARC, 13 December 1995.
;			Fixed the output text when an SFDU header file has
;			been written to the tape.  This SFDU file is now 
;			referred to tape file #1 (instead of #0 as previously
;			done) and the first FITS file is tape file #2 (instead
;			of #1).
;
; Version     :	Version 5, 13 December 1995.
;
;	Converted to IDL V5.0   W. Landsman   October 1997
;-
;
	ON_ERROR, 2	; Return to caller if error is encountered.
	MESSAGE = ''	; Set to non-null string if error is encountered.
;
; Check input and get the tape unit number if not suppied.
;
	IF N_ELEMENTS(UNIT) NE 1 THEN BEGIN
		UNIT = 0
		READ, 'Enter tape drive unit number (0-9): ', UNIT
	ENDIF
	IF DATATYPE(UNIT,1) NE 'Integer' THEN MESSAGE = $
		'UNIT must be an integer in the range: 0 - 9.'
	IF MESSAGE NE '' THEN GOTO, HANDLE_ERROR
	IF (UNIT LT 0) OR (UNIT GT 9) THEN MESSAGE = $
		'Tape unit number must be in the range: 0 - 9.'
	IF MESSAGE NE '' THEN GOTO, HANDLE_ERROR
;
; Get files to process.
;
	NFILES = N_ELEMENTS(LIST)
	IF NFILES EQ 0 THEN BEGIN
		GETFILES, LIST
		NFILES = N_ELEMENTS(LIST)
	ENDIF ELSE BEGIN
		IF NFILES EQ 1 THEN LIST = INTARR(1) + LIST
		IF DATATYPE(LIST,1) NE 'Integer' THEN MESSAGE = $
			'LIST must be an array of integers.'
		IF MESSAGE NE '' THEN GOTO, HANDLE_ERROR
	ENDELSE
;
; Check parameters.
;
	IF N_ELEMENTS(KEYWORD) NE 1 THEN KEYWORD = '' ELSE GOTO,READER  
	IF N_ELEMENTS(TAPENAME) NE 1 THEN TAPENAME = '' ELSE GOTO,READER
	IF N_ELEMENTS(FNAMES) NE 0 THEN GOTO,READER   
;
; MENU: used only if no parameters for filename given.
;
MENU:
	SELECT = 0
	PRINT, 'How do you want to name files to be written to disk?'
	PRINT, 'Choose one of the following: '
	PRINT, ' (1)  Use specified FITS keyword.'
	PRINT, ' (2)  Use tape name concatenated with file number.'
	PRINT, ' (3)  Specify file names individually.'
	READ,SELECT
;
	CASE SELECT OF
		1:  READ,'Specify FITS keyword to use for file names.',KEYWORD
		2:  BEGIN
			PRINT, 'Specify tape name (no extension).  File will'+$
				' be created'
			READ, 'from tape name and file number: ',TAPENAME
			END
		3:  BEGIN
			FNAMES = STRARR(NFILES)		; Read file names.
			PRINT, 'Specify file names, one per line (no '+$
				'extension).'
			FOR I=0,NFILES-1 DO BEGIN
				ST = ''
				READ,'file '+STRING(LIST[I])+': ',ST
				FNAMES[I] = ST
			ENDFOR ; I
			END
		ELSE: BEGIN
			PRINT, 'ERROR- Not a valid choice!'
			GOTO, MENU
			END
	ENDCASE
;
; Process tape file by file.
;
READER:
;
; Check to see if a widget is driving this program.
;
	IF KEYWORD_SET(XWIDGET) THEN QWIDGET = 1 ELSE QWIDGET = 0
;
	IF N_ELEMENTS(XWSTR) EQ 0 THEN XWSTR = $
		'FXTAPEREAD: Rewinding tape ...' ELSE XWSTR = $
		['FXTAPEREAD: Rewinding tape ...', ' ', XWSTR]
	IF QWIDGET EQ 1 THEN WIDGET_CONTROL, XWIDGET, SET_VALUE=XWSTR $
		ELSE PRINT, XWSTR[0]
	REWIND, UNIT		; Rewind tape.
	TPOS = 1		; Present file position.
	IF (KEYWORD NE '') OR (TAPENAME NE '') THEN FNAMES = STRARR(NFILES)
;
; Position tape after SFDU file if it exists.
;
	IF KEYWORD_SET(SFDU) THEN BEGIN
		XWSTR = ['FXTAPEREAD: Positioning the tape after the SFDU '+$
			'header file.', XWSTR]
		IF QWIDGET EQ 1 THEN WIDGET_CONTROL, XWIDGET, SET_VALUE=XWSTR $
			ELSE PRINT, XWSTR[0]
		SKIPF,UNIT,1
		FCNT0 = 1
	ENDIF ELSE FCNT0 = 0
	PRINT,' '
;
; Now read the FITS files.
;
	FOR I=0,NFILES-1 DO BEGIN
		STATUS = FITSTAPE('init', UNIT, 10)
		NSKIP = LIST[I] - TPOS		; Number of files to skip.
		IF NSKIP GT 0 THEN SKIPF,UNIT,NSKIP
		TPOS = TPOS + NSKIP
;
; Determine file name if not from keyword.
;
		IF KEYWORD EQ '' THEN BEGIN
			IF TAPENAME EQ '' THEN NAME=STRTRIM(FNAMES[I],2) $
					  ELSE NAME=TAPENAME+STRTRIM(LIST[I],2)
		ENDIF
;
; Read file.
;
		XWSTR = ['File: '+STRING(LIST[I]+FCNT0), XWSTR]
		IF QWIDGET EQ 1 THEN WIDGET_CONTROL, XWIDGET, SET_VALUE=XWSTR $
			ELSE PRINT, XWSTR[0]
		IF KEYWORD_SET(NOSUFFIX) THEN FXTPIO_READ, UNIT, NAME, $
			KEYWORD, /NOSUFFIX, ERRMSG=ERRMSG ELSE $
			FXTPIO_READ, UNIT, NAME, KEYWORD, ERRMSG=ERRMSG
		IF N_ELEMENTS(ERRMSG) GT 0 THEN IF ERRMSG[0] NE '' THEN RETURN
		XWSTR = ['   '+NAME, XWSTR]
		IF QWIDGET EQ 1 THEN WIDGET_CONTROL, XWIDGET, SET_VALUE=XWSTR $
			ELSE PRINT, XWSTR[0]
;
		IF (KEYWORD NE '') OR (TAPENAME NE '') THEN $
			FNAMES[I] = NAME    ; Return generated name to caller.
		TPOS = TPOS + 1
	ENDFOR
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
