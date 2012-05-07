	PRO FXTAPEWRITE, UNIT, BLFAC, FNAMES, KEYWORD, XWSTR, XWIDGET=XWIDGET,$
		SFDU=SFDU, ERRMSG=ERRMSG
;+
; Project     :	SOHO - CDS
;
; Name        :	FXTAPEWRITE
;
; Purpose     :	Procedure to copy disk FITS files to tape with interactive 
;		capabilities.
;
; Explanation : Writes the FITS files to tape based upon the parameters 
;		inputted or supplied.  If no parameters are supplied, then the 
;		user is asked a series of questions to walk him or her through 
;		copying a number of FITS files from disk to tape.  
;
; Use         : FXTAPEWRITE			; Prompt for all parameters.
;
;		FXTAPEWRITE, UNIT, BLFAC, FNAMES, KEYWORD [, XWSTR]
;
;		FXTAPEWRITE, 0, 1, FNAMES
;			; Writes all FITS files listed in FNAMES to the tape 
;			; associated to UNIT = 0 with 2880 bytes per record.
;		FXTAPEWRITE, 1, 3, 'CDS', 'FILENAME'
;			; Writes all FITS files beginning with the name 'CDS'
;			; to the tape associated to UNIT = 1 with 8640 (2880*3)
;			; bytes per record and includes the keyword 'FILENAME'
;			; in the FITS header which contains the disk file name 
;			; of the file being written.
;
; Inputs      : None necessary.
;
; Opt. Inputs : Interactive users will normally just type FXTAPEWRITE and be 
;		prompted for all parameters.  However, the following 
;		parameters can be passed directly to FXTAPEWRITE:
;
;		UNIT	= Tape unit number (integer scalar).
;
;		BLFAC	= Blocking factor (1-10) = # of 2880 byte records per 
;			  block.
;
;		FNAMES	= File names (string array).  If in interactive mode, 
;			  the file names may either be specified individually, 
;			  or a tapename may be specified, and all files in the 
;			  form "tapename<number>.FITS" will be written to tape.
;
;		KEYWORD	= Name of a FITS keyword to put file names into.  This 
;			  will simplify subsequent reading of the FITS tape, 
;			  since individual filenames will not have to be 
;			  specified.  If you don't want to put the file names 
;			  into the FITS header, then just hit <RETURN> 
;			  (interactive mode) or do not pass this parameter.
;
;		XWSTR	= A string array that contains informational text
;			  concerning the tape I/O.  These strings are printed
;			  either to the screen or to the FILENAME widget (set
;			  internally to XWIDGET) if the XWINTAPE procedure is
;			  driving this routine.
;
; Outputs     : None.
;
; Opt. Outputs: XWSTR	= A string array that contains informational text
;			  concerning the tape I/O.  These strings are printed
;			  either to the screen or to the FILENAME widget (set
;			  internally to XWIDGET) if the XWINTAPE procedure is
;			  driving this routine.  Note that FXTAPEWRITE will
;			  add strings to this array which is then passed back
;			  to the caller.
;
; Keywords    : XWIDGET	= This keyword tells this FXTAPEWRITE that the XWINTAPE
;			  widget procedure is driving this procedure.  If so,
;			  then any informational text is printed to the 
;			  FILENAME widget (internally set to XWIDGET) created
;			  by XWINTAPE.
;
;		SFDU	= If set, then an SFDU header file was placed at the
;			  beginning of the tape.
;
;		ERRMSG	= If defined and passed, then any error messages will 
;			  be returned to the user in this parameter rather 
;			  than being handled by the IDL MESSAGE utility.  If 
;			  no errors are encountered, then a null string is 
;			  returned.  In order to use this feature, the string 
;			  ERRMSG must be defined first, e.g.,
;
;				ERRMSG = ''
;				FXTAPEWRITE, 1, 1, FNAMES, ERRMSG=ERRMSG
;				IF ERRMSG(0) NE '' THEN ...
;
; Calls       : DATATYPE, FITSTAPE, GETFILES, FXTPIO_WRITE
;
; Common      : None.
;
; Restrictions:	Supported under VMS and (NOW) under UNIX running IDL Versions 
;		3.1 or later when the UNIX versions of TAPRD, TAPWRT, etc. are 
;		included in a user library directory.
;
; Side effects:	Tape is not rewound before files are written.  Tape should be
;		positioned with REWIND or SKIPF before calling FXTAPEWRITE.  
;		If you want to append new FITS files to a tape, then call 
;		TINIT (tape init) to position tape between final double EOF.
;
; Category    :	Data Handling, I/O, FITS, Generic.
;
; Prev. Hist. :	William Thompson, March 1992, from FITSWRT by D. Lindler.
;		William Thompson, May 1992, removed call to TINIT.
;		William Thompson, Jan. 1993, changed for renamed FXTPIO_WRITE.
;
; Written     :	William Thompson, GSFC, March 1992.
;
; Modified    :	Version 1, William Thompson, GSFC, 12 April 1993.
;			Incorporated into CDS library.
;		Version 2, Donald G. Luttermoser, GSFC/ARC, 13 March 1995.
;			Included "passed" input parameters and ERRMSG keyword.
;			Reformatted and modified the documentation.
;		Version 3, Donald G. Luttermoser, GSFC/ARC, 9 May 1995.
;			Added the XWIDGET keyword.
;		Version 4, Donald G. Luttermoser, GSFC/ARC, 13 December 1995.
;			Corrected output text such that if an SFDU file was
;			placed at the beginning of the tape (indicated with
;			the added keyword /SFDU), the first FITS file written
;			to the tape is tape file #2 (not #1 as previously done).
;
; Version     :	Version 4, 13 December 1995.
;
;	Converted to IDL V5.0   W. Landsman   October 1997
;-
;
	ON_ERROR, 2	; Return to caller if error is encountered.
	MESSAGE = ''	; Set to non-null string if error is encountered.
;
; Check input and get the tape unit number if not supplied.
;
	IF N_PARAMS() EQ 0 THEN BEGIN
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
;  Get tape block size.
;
	IF N_PARAMS() LT 2 THEN BEGIN 
		BLFAC = 0
		READ, 'Enter blocking factor for tape records (1-10): ', BLFAC
	ENDIF
	IF DATATYPE(BLFAC,1) NE 'Integer' THEN MESSAGE = $
		'BLFAC must be an integer in the range: 1 - 10.'
	IF MESSAGE NE '' THEN GOTO, HANDLE_ERROR
	IF (BLFAC LT 1) OR (BLFAC GT 10) THEN MESSAGE = $
		'Blocking factor must be in the range: 1 - 10.'
	IF MESSAGE NE '' THEN GOTO, HANDLE_ERROR
;
;  Initialize tape buffers.
;
	STATUS = FITSTAPE('init', UNIT, BLFAC)
;
;  Get keyword for file names.
;
	IF N_PARAMS() EQ 0 THEN BEGIN
		SELECT = ''
		KEYWORD = ''
		READ, 'Do you want to put filename into FITS header? (Y/N) '+$
			'[N] ',SELECT
		IF STRUPCASE(STRMID(SELECT,0,1)) EQ 'Y' THEN $
			READ, 'Enter header keyword in which to put file '+$
			'name: ',KEYWORD
	ENDIF ELSE IF N_ELEMENTS(KEYWORD) EQ 0 THEN KEYWORD = ''
;
;  Check to see if the XWIDGET keyword has been set (i.e., whether or not
;  XWINTAPE is driving this procedure).
;
IF KEYWORD_SET(XWIDGET) THEN QWIDGET = 1 ELSE QWIDGET = 0
IF N_ELEMENTS(XWSTR) EQ 0 THEN XWSTR = ' '
;
;  Get file names -- menu.
;
MENU:
	TAPENAME=''
	IF N_PARAMS() LT 3 THEN BEGIN
		SELECT = 0
		PRINT, 'How do you want to select files to be written to tape?'
		PRINT, 'Choose one of the following: '
		PRINT, '(1)  Specify tape name: Files are in form '+$
			'tapename<number>.FITS'
		PRINT, '(2)  Specify file names individually.'
		READ,SELECT
;
		CASE SELECT OF
			1:  BEGIN
				PRINT,'Files are in form tapename<number>.FITS'
				READ, 'Enter tape name: ', TAPENAME
				IF TAPENAME NE '' THEN BEGIN
					GETFILES, LIST
					NFILES = N_ELEMENTS(LIST)
				ENDIF
				END
			2:  BEGIN
				PRINT, 'Enter file names (with extension), '+$
					'one per line.'
				PRINT, 'Enter blank line to quit.'
				ST=''
				FIRST = 1
				REPEAT BEGIN
					READ,ST
					IF ST NE '' THEN IF FIRST THEN	$
						FILEBUF = ST	  ELSE	$
						FILEBUF = [FILEBUF,ST]
					FIRST = 0
				ENDREP UNTIL ST EQ ''
				END
			ELSE:  BEGIN
				PRINT, 'ERROR- Invalid choice.'
				GOTO, MENU
				END
		ENDCASE
	ENDIF ELSE FILEBUF = FNAMES
	NFILES = N_ELEMENTS(FILEBUF)
	IF KEYWORD_SET(SFDU) THEN FCNT0 = 2 ELSE FCNT0 = 1
;
;  Loop on files.
;
	FOR I=0,NFILES-1 DO BEGIN
;
;  Get filename.
;
		IF TAPENAME EQ '' THEN BEGIN
			FNAME = STRTRIM(FILEBUF[I], 2)
		END ELSE BEGIN
			FNAME = TAPENAME + STRTRIM(LIST[I], 2) + '.fits'
		ENDELSE
;
;  Write file to tape.
;
		XWSTR = ['Writing '+FNAME+' to tape file #'+$
			STRING(FORMAT='(I4)',I+FCNT0)+'.', XWSTR]
		IF QWIDGET EQ 1 THEN WIDGET_CONTROL, XWIDGET, SET_VALUE=$
			XWSTR ELSE PRINT, XWSTR[0]
		FXTPIO_WRITE, UNIT, FNAME, KEYWORD, ERRMSG=ERRMSG
		IF N_ELEMENTS(ERRMSG) GT 0 THEN IF ERRMSG[0] NE '' THEN RETURN
	ENDFOR
;
	IF N_ELEMENTS(ERRMSG) GT 0 THEN ERRMSG = MESSAGE
	RETURN		; Return with no error.
;
; Error handling portion of the procedure.
;
HANDLE_ERROR:
	IF N_ELEMENTS(ERRMSG) EQ 0 THEN MESSAGE, MESSAGE
	ERRMSG = MESSAGE
	RETURN
;
	END
