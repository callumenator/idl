	PRO TAPWRT, ARRAY, UNIT, BYTE_REVERSE
;+
; NAME        :	
;	TAPWRT
;
; PURPOSE     :	
;	Emulates VMS TAPWRT procedure on UNIX machines.
;
; EXPLANATION :	
;	Emulates VMS TAPWRT procedure on UNIX machines.
;
;		*** Unix only ***
;
; CALLING SEQUENCE:	
;	TAPWRT, ARRAY, UNIT  [, BYTE_REVERSE ]
;
; Inputs      :	ARRAY	= Variable into which the data should be read.
;		UNIT	= Specifies the magnetic tape unit.  Not to be confused
;			  with logical unit numbers.  In UNIX, the number
;			  refers to one of the environment variables MT0, MT1,
;			  etc., which translate into a physical device name,
;			  e.g.
;
;					setenv MT0 /dev/nrst0
;
; Opt. Inputs :	BYTE_REVERSE = If present, then even and odd bytes are swapped.
;
; Outputs     :	None.
;
; Opt. Outputs:	None.
;
; Keywords    :	None.
;
; Calls       :	CHECK_TAPE_DRV
;
; Common      :	None.
;
; Restrictions:	The environment variable "MTn", where n corresponds to the
;		variable UNIT, must be defined.  E.g.,
;
;			setenv MT0 /dev/nrst0
;
;		Requires IDL v3.0 or later.
;
; Side effects:	The device file is opened.
;
; Category    :	Utilities, I/O, Tape.
;
; Prev. Hist. :	William Thompson, GSFC, June 1991.
;
; Written     :	William Thompson, GSFC, June 1991.
;
; Modified    :	Version 1, William Thompson, GSFC, 21 December 1993.
;			Rewrote to use WRITEU.
;
; Version     :	Version 1, 21 December 1993.
;	Converted to IDL V5.0   W. Landsman   September 1997
;-
;
	ON_ERROR, 2
;
	IF N_PARAMS() LT 2 THEN MESSAGE,	$
		'Syntax:  TAPWRT, ARRAY, UNIT  [, BYTE_REVERSE ]'
;
;  Call CHECK_TAPE_DR to get the logical unit number of the tape drive.
;
	CHECK_TAPE_DRV, UNIT, LOGICAL_DRIVE, DRIVE, LUN
;
;  Use WRITEU to write to the tape.  If BYTE_REVERSE is passed, then reverse
;  the even and odd bytes.
;
	IF N_PARAMS() EQ 3 THEN BEGIN
		TEMP = ARRAY
		BYTEORDER,TEMP,/SSWAP
		WRITEU, LUN, TEMP
	END ELSE WRITEU, LUN, ARRAY
;
	RETURN
	END
