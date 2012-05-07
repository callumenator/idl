	PRO SKIPF, UNIT, NSKIP, RECORDS
;+
; NAME        :	
;	SKIPF
;
; PURPOSE     :	
;	Emulates the VMS SKIPF function on UNIX machines.
;
; EXPLANATION :	
;	Emulates the VMS SKIPF function on UNIX machines.
;
; CALLING SEQUENCE      :	
;	SKIPF, UNIT, NSKIP
;	SKIPF, UNIT, NSKIP, RECORDS
;
; Inputs      :	UNIT	= Tape unit number.  Tape drives are selected via the
;			  UNIX environment variables "MT1", "MT2", etc.  The
;			  desired tape drive is thus specified by numbers, as
;			  in VMS.  Must be from 0 to 9.
;
;		NSKIP	= Number of files or records to skip.
;
; Opt. Inputs :	RECORDS = If present, then records are skipped instead of
;			  files.
;
; Outputs     :	None.  However, !ERR is set to ABS(NSKIP)
;
; Opt. Outputs:	None.
;
; Keywords    :	None.
;
; Calls       :	CHECK_TAPE_DRV
;
; Common      :	None.
;
; Restrictions:	This routine may not act exactly the same as the VMS
;		equivalent, particularly in regards to the behavior of the !ERR
;		system variable.
;
;		The environment variable "MTn", where n corresponds to the
;		variable UNIT, must be defined.  E.g.,
;
;			setenv MT0 /dev/nrst0
;
;		Requires IDL v3.0 or later.
;
; Side effects:	The device file is opened.  !ERR is set to ABS(NSKIP).
;
; Category    :	Utilities, I/O, Tape.
;
; Prev. Hist. :	VERSION 1, R. W. Thompson 12/4/89
;		William Thompson, Apr 1991, rewrote to better emulate VMS
;			version.
;
; Written     :	R. W. Thompson, GSFC/IUE, 4 December 1989.
;
; Modified    :	Version 1, William Thompson, GSFC, 21 December 1993.
;			Rewrote to use IOCTL.
;
; Version     :	Version 1, 21 December 1993.
;	Converted to IDL V5.0   W. Landsman   September 1997
;-
;
	ON_ERROR, 2
;
;  Check the number of parameters.
;
	IF N_PARAMS() LT 2 THEN MESSAGE,	$
		'Syntax:  SKIPF, UNIT, NSKIP  [, RECORDS ]'
;
;  Call CHECK_TAPE_DR to get the logical unit number of the tape drive.
;
	CHECK_TAPE_DRV, UNIT, LOGICAL_DRIVE, DRIVE, LUN
;
;  If the third parameter was not passed, then skip files.  Otherwise, skip
;  records.
;
	IF N_PARAMS() LT 3 THEN BEGIN
		TEST = IOCTL(LUN, MT_SKIP_FILE=NSKIP)
	END ELSE BEGIN
		TEST = IOCTL(LUN, MT_SKIP_RECORD=NSKIP)
	ENDELSE
;
;  Set !ERR and return.
;
	!ERR = ABS(NSKIP)
	RETURN
	END
