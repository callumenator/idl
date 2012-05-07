;-------------------------------------------------------------------------
        pro set_size,width,height

;+
; NAME:			set_size
;
; PURPOSE:		Sets the size of the PS page
;			Part of the PSETUP Suite of procedures that provide 
;			easy and versatile 
;			customisation of the plotted page for PostScript 
;			(plus other functionality)
;
; CATEGORY:		plot Utility
;
; CALLING SEQUENCE:	set_size, width, height
;
; INPUTS:		width, height = dimensions of page
;				the height is the longside and 
;				the width is the shortside (see PSETUP)
;
; OUTPUTS:		none
;
; COMMON BLOCKS:	SCREENSMEM
;			
; SIDE EFFECTS:		sets sizes stored in common SCREENSMEM
;	
; MODIFICATION HISTORY:
;	Written by: Trevor Harris, Physics Dept., University of Adelaide,
;		July, 1990.
;
;-

        common screensmem, alreadycalled, long, short

        long = height   &       short = width

        return
        end
