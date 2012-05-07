	PRO TAPRD, ARRAY, UNIT, BYTE_REVERSE
;+
; NAME        :	
;	TAPRD
; PURPOSE     :	
;	Emulates VMS TAPRD procedure on UNIX machines.
;
; EXPLANATION :	
;	Emulates VMS TAPRD procedure on UNIX machines.  However, the
;	actions of this routine may differ from the VMS equivalent in
;	nonstandard situations.
;
;		*** Unix only ***
;
; CALLING SEQUENCE:	
;	TAPRD, ARRAY, UNIT  [, BYTE_REVERSE ]
;
; Inputs      :	ARRAY	= Variable into which the data should be read.  The
;			  datatype and number of values to attempt to read is
;			  based on this array.
;
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
; Outputs     :	The output is read into ARRAY. Also, !ERR is set to the number
;		of bytes actually read.
;
; Opt. Outputs:	None.
;
; Keywords    :	None.
;
; Calls       :	CHECK_TAPE_DRV
;
; Common      :	None.
;
; Restrictions:	This routine may not have all the abilities of the VMS
;		equivalent, particularly in regards to the !ERR system
;		variable.
;
;		The environment variable "MTn", where n corresponds to the
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
;			Rewrote to use READU with TRANSFER_COUNT keyword.
;		Version 2, William Thompson, GSFC, 22 December 1993.
;			Added check of ARRAY variable.
;
; Version     :	Version 2, 22 December 1993.
;	Converted to IDL V5.0   W. Landsman   September 1997
;-
;
	ON_ERROR, 2
;
	IF N_PARAMS() LT 2 THEN MESSAGE,	$
		'Syntax:  TAPRD, ARRAY, UNIT  [, BYTE_REVERSE ]'
;
;  Make sure that ARRAY is defined, and that it is a proper data type.
;
	SZ = SIZE(ARRAY)
	TYPE = SZ[SZ[0]+1]
	CASE TYPE OF
		0:  MESSAGE, 'ARRAY is undefined'
		7:  MESSAGE, 'Operation not supported for strings'
		8:  MESSAGE, 'Operation not supported for structures'
		ELSE:  TYPE = TYPE
	ENDCASE
;
;  Call CHECK_TAPE_DRV to get the logical unit number of the tape drive.
;
	CHECK_TAPE_DRV, UNIT, LOGICAL_DRIVE, DRIVE, LUN
;
;  Read the next record.
;
	READU, LUN, ARRAY, TRANSFER_COUNT=TRANSFER_COUNT
;
;  If zero bytes were read in, then assume that an end-of-file mark was
;  encountered.  Signal this by setting !ERR to -4 and return.
;
	IF TRANSFER_COUNT EQ 0 THEN BEGIN
		!ERR = -4
		RETURN
	ENDIF
;
;  If BYTE_REVERSE was passed, then swap even and odd bytes.
;
	IF N_PARAMS() EQ 3 THEN BYTEORDER,ARRAY,/SSWAP
;
;  Set !ERR to the number of bytes read.
;
	CASE TYPE OF
		1:  N_BYTES = TRANSFER_COUNT
		2:  N_BYTES = TRANSFER_COUNT * 2
		3:  N_BYTES = TRANSFER_COUNT * 4
		4:  N_BYTES = TRANSFER_COUNT * 4
		5:  N_BYTES = TRANSFER_COUNT * 8
		6:  N_BYTES = TRANSFER_COUNT * 8
	ENDCASE
	!ERR = N_BYTES
;
	RETURN
	END
