;-------------------------------------------------------------------------
        pro show_size
;+
; NAME:			show_size
;
; PURPOSE:		Prints the currently selected size of the PS page
;			Part of the PSETUP Suite of procedures that provide 
;			easy and versatile 
;			customisation of the plotted page for PostScript 
;			(plus other functionality)
;
; CATEGORY:		plot Utility
;
; CALLING SEQUENCE:	show_size
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
;		July, 1990
;
;-

        common screensmem, alreadycalled, long, short

	cm = "( ' PostScript Pagesize set at ',f5.1,' x',f5.1,' cm ')"
        if (n_elements(long) and n_elements(short)) then $
		if ((long * short) gt 0) then print,short,long,form=cm $
		else print, 21.0-3.5-1.8, 29.7-4.0-4.0, form=cm $
	else print, 21.0-3.5-1.8, 29.7-4.0-4.0, form=cm 

        return
        end
