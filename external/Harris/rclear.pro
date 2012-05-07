;----------------------------------------------------------------------------
	pro rclear
;+
; NAME:			RCLEAR
;
; PURPOSE:		This is a generic procedure to close windows  
;			(if they are not part of a widget), 
;			redraw TEK screens, close PostScript files etc.. 
;			It will also attempt to close and free all LUNs.
;			The user is then returned to the top level
;
; CATEGORY:		Utility
;
; CALLING SEQUENCE:	rclear
;
; INPUTS:		none
;
; OUTPUTS:		none
;
; COMMON BLOCKS:
;			none.
; SIDE EFFECTS:
;			Windows are deleted, files closed and LUNs freed
;			Uses the CLEAR procedure then RETALL
;
; MODIFICATION HISTORY:
;	Written by: Trevor Harris, Physics Dept., University of Adelaide,
;		July, 1990.
;
;-

	clear
	retall
	return
	end



