	PRO CHECK_TAPE_DRV, UNIT, LOGICAL_DRIVE, DRIVE, LUN
;+
; NAME        :	
;	CHECK_TAPE_DRV
; PURPOSE     :	
;	Associates tape drive numbers with device files.  *Unix only*
; EXPLANATION :	
;	This is an internal routine to the CDS/SERTS Unix tape handling
;	utilities.  It converts tape drive numbers to actual device
;	names, and checks to make sure that the device file is open.
;
;		**Unix only**
;
; CALLING SEQUENCE:         :	
;	CHECK_TAPE_DRV, UNIT, LOGICAL_DRIVE, DRIVE, LUN
;
; INPUTS      
;	UNIT = Tape unit number.  Tape drives are selected via the UNIX
;		       environment variables "MT1", "MT2", etc.  The desired
;		       tape drive is thus specified by numbers, as in VMS.
;		       Must be from 0 to 9.
;
; OUTPUTS     :	
;	LOGICAL_DRIVE = Name of environment variable pointing to tape
;				drive device file, e.g. "MT0".
;	DRIVE	      = Name of device file, e.g. '/dev/nrst0'.
;	LUN	      = Logical unit number used for reads and writes.
;
; COMMON      :	
;	CHCK_TAPE_DRVS contains array TAPE_LUN, containing logical unit
;		numbers for each tape device, and TAPE_OPEN, which tells
;		whether each device is open or not.
;
; RESTRICTIONS:	
;	The environment variable "MTn", where n corresponds to the
;		variable UNIT, must be defined.  E.g.,
;
;			setenv MT0 /dev/nrst0
;
;		Requires IDL v3.0 or later.
;
; SIDE EFFECTS:	
;	If the device file is not yet open, then the tape is rewound,
;		and a file unit is opened to it.
;
; Category    :	Utilities, I/O, Tape.
;
; Prev. Hist. :	William Thompson, Apr 1991.
;
; Written     :	William Thompson, GSFC, April 1991.
;
; Modified    :	Version 1, William Thompson, GSFC, 21 December 1993.
;			Added keyword /NOSTDIO to OPEN statement.
;			Incorporated into CDS library.
;		Version 2, William Thompson, GSFC, 22 December 1993.
;			Added spawn to "mt rewind".
;		Version 3, W. Landsman GSFC 10-Apr-1996
;			Open for Readonly, if Update access is unavailable
;
; Version     :	Version 3, 10-Apr-1996.
;	Converted to IDL V5.0   W. Landsman   September 1997
;-
;
	COMMON CHCK_TAPE_DRVS, TAPE_LUN, TAPE_OPEN
	ON_ERROR, 2
;
;  Check the number of parameters passed.
;
	IF N_PARAMS() NE 4 THEN MESSAGE,	$
		'Syntax:  CHECK_TAPE, UNIT, LOGICAL_DRIVE, DRIVE, LUN'
;
;  Make sure the common block is initialized.
;
	IF N_ELEMENTS(TAPE_LUN) EQ 0 THEN BEGIN
		TAPE_LUN = LONARR(10)
		TAPE_OPEN = BYTARR(10)
	ENDIF
;
;  Check the value of UNIT.
;
	IF N_ELEMENTS(UNIT) EQ 0 THEN MESSAGE, 'UNIT not defined'
	IF N_ELEMENTS(UNIT) GT 1 THEN MESSAGE, 'UNIT must not be an array'
;
	SZ = SIZE(UNIT)
	TYPE = SZ[SZ[0]+1]
	IF TYPE GT 3 THEN MESSAGE, 'UNIT must be an integer'
	IF (UNIT LT 0) OR (UNIT GT 9) THEN MESSAGE,	$
		'UNIT must be between 0 and 9'
;
;  Form the name of the environment variable, and translate it.
;
	LOGICAL_DRIVE = 'MT' + STRTRIM(UNIT,2)
	DRIVE = GETENV(LOGICAL_DRIVE)
	IF DRIVE EQ '' THEN MESSAGE, 'Drive "' + LOGICAL_DRIVE +	$
		'" not defined'
;
;  Check to see if the device file is already open.  If not, then assign a
;  logical unit number, and open the device file for read and write.  If the
;  drive cannot open for both read and write, then try just read.  But first
;  spawn the Unix rewind command to make sure the device is ready -- otherwise,
;  errors can result.
;
	IF NOT TAPE_OPEN[UNIT] THEN BEGIN
		SPAWN,'mt -f ' + DRIVE + ' rewind'
		GET_LUN, LUN
		OPENU, LUN, DRIVE, /NOSTDIO, ERROR = ERROR 
		IF ERROR NE 0 THEN BEGIN
			OPENR, LUN, DRIVE, /NOSTDIO
			MESSAGE,'Tape Drive Opened for Read Access Only',/INF
                ENDIF
		TAPE_LUN[UNIT] = LUN
		TAPE_OPEN[UNIT] = 1
	END ELSE BEGIN
		LUN = TAPE_LUN[UNIT]
	ENDELSE
;
	RETURN
	END






