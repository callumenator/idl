;-------------------------------------------------------------------------
        pro reset_size
;+
; NAME:			reset_size
;
; PURPOSE:		Resets the size of the PS page
;			Part of the PSETUP Suite of procedures that provide 
;			easy and versatile 
;			customisation of the plotted page for PostScript 
;			(plus other functionality)
;
; CATEGORY:		plot Utility
;
; CALLING SEQUENCE:	reset_size
; INPUTS:		none
;
; OUTPUTS:		none
;
; COMMON BLOCKS:	SCREENSMEM
;			
; SIDE EFFECTS:		resets sizes stored in common SCREENSMEM
;	
; MODIFICATION HISTORY:
;	Written by: Trevor Harris, Physics Dept., University of Adelaide,
;		July, 1990.
;
;-

        common screensmem, alreadycalled, long, short

	;long = 29.7-4.0-4.0
	;short= 21.0-3.5-1.8

	long = 0	&	short = 0

        return
        end
