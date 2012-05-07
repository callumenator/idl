	PRO DISMOUNT, UNIT, UNLOAD=UNLOAD, NOUNLOAD=NOUNLOAD
;+
; NAME:	
;	DISMOUNT
;
; PURPOSE:	
;	Emulates the VMS DISMOUNT function in Unix.
;
; EXPLANATION :	
;	Emulates the VMS DISMOUNT function in the Unix environment.
;	Although this is not a standard IDL function, it is available
;	as a separate LINKIMAGE routine for VMS.
;
;		The main purpose of this procedure is to close the file unit
;		open on the tape device, and optionally to unload the tape.
;		Errors can result if the tape is unloaded manually rather than
;		using this routine.
;
;		**Unix only**
;
; CALLING SEQUENCE:	
;	DISMOUNT, UNIT
;
; Inputs      :	UNIT = Tape unit number.  Tape drives are selected via the UNIX
;		       environment variables "MT1", "MT2", etc.  The desired
;		       tape drive is thus specified by numbers, as in VMS.
;		       Must be from 0 to 9.
;
; Opt. Inputs :	None.
;
; Outputs     :	None.
;
; Opt. Outputs:	None.
;
; Keywords    :	NOUNLOAD = If set, then the tape is simply rewound, not taken
;			   off line.
;
; Calls       :	CHECK_TAPE_DRV
;
; Common      :	CHCK_TAPE_DRVS contains array TAPE_LUN, containing logical unit
;		numbers for each tape device, and TAPE_OPEN, which tells
;		whether each device is open or not.
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
; Prev. Hist. :	None.
;
; Written     :	William Thompson, GSFC, 21 December 1993.
;
; Modified    :	Version 1, William Thompson, GSFC, 21 December 1993.
;
; Version     :	Version 1, 21 December 1993.
;	Converted to IDL V5.0   W. Landsman   September 1997
;-
;
	COMMON CHCK_TAPE_DRVS, TAPE_LUN, TAPE_OPEN
	ON_ERROR, 2
;
;  Check the number of parameters.
;
	IF N_PARAMS() NE 1 THEN MESSAGE, 'Syntax:  DISMOUNT, UNIT'
;
;  Call CHECK_TAPE_DR to get the logical unit number associated with the tape
;  drive.
;
	CHECK_TAPE_DRV, UNIT, LOGICAL_DRIVE, DRIVE, LUN
;
;  Call IOCTL to dismount the tape.
;
	IF KEYWORD_SET(NOUNLOAD) THEN BEGIN
		TEST = IOCTL(LUN, /MT_REWIND)
	END ELSE BEGIN
		TEST = IOCTL(LUN, /MT_OFFLINE)
	ENDELSE
;
;  Free the logical unit number, and mark the unit as closed in the common
;  block.
;
	FREE_LUN, LUN
	TAPE_OPEN[UNIT] = 0
;
	RETURN
	END
