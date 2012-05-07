	PRO WEOF, UNIT
;+
; NAME        :	
;	WEOF
;
; PURPOSE     :	
;	Emulates the VMS WEOF routine on UNIX machines.
;
; EXPLANATION :	
;	Emulates the VMS WEOF routine on UNIX machines.
;
;		*** Unix only ***
;
; CALLING SEQUENCE      :
;	WEOF, UNIT
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
; Prev. Hist. :	VERSION 1, R. W. Thompson 11/30/89
;		William Thompson, Apr 1991, rewrote to better emulate VMS
;			version.
;
; Written     :	R. W. Thompson, GSFC/IUE, 30 November 1989.
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
	IF N_PARAMS() NE 1 THEN MESSAGE, 'Syntax:  WEOF, UNIT'
;
;  Call CHECK_TAPE_DR to get the logical unit number the tape drive.
;
	CHECK_TAPE_DRV, UNIT, LOGICAL_DRIVE, DRIVE, LUN
;
;  Call IOCTL to write the end-of-file mark to the tape.
;
	TEST = IOCTL(LUN, /MT_WEOF)
	RETURN
	END
