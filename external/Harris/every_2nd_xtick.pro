;-----------------------------------------------------------------
		function every_2nd_xtick, inticknames
;+
; NAME:			every_2nd_xtick
;
; PURPOSE:		reduce the tick axis labelling to label only 
;			every 2nd tick
;
; CATEGORY:		Utility
;
; CALLING SEQUENCE:	newticknames = every_2nd_xtick(oldticknames)
;
; INPUTS:		oldticknames = string array of tick labels
;				if not specified will default to !x.tickname
;
; OUTPUTS:		newticknames = oldticknames where every 2nd label 
;				has been blanked out
; COMMON BLOCKS:
;	none.
; SIDE EFFECTS:
;	none.
; MODIFICATION HISTORY:
;	Written by: Trevor Harris, Physics Dept., University of Adelaide,
;		July, 1990.
;
;	Modified  4/11/93 TJH 	Renamed from EVERY_SECOND_XTICK to 
;				EVERY_2ND_XTICK as the original name was too  
;				long for auto-recognition by IDL.  
;				Now handles case of !x.ticks = 0
;
;-

	if (n_elements(inticknames) gt 0) then begin
		nticks = n_elements(inticknames) < 29
		ticknames = inticknames
	endif else begin
		nticks = !x.ticks < 29
		if (nticks le 0) then nticks = 6
		ticknames = !x.tickname(0:nticks)
	endelse

	;only use every 2nd xtickname
	xtickname = ticknames
	i = indgen(nticks+1)
	if (xtickname(1) eq ' ') then remove=1 else $
	  if (strmid(xtickname(1),strlen(xtickname(1))-1,1) eq ' ') then $
			remove = 1 else remove =0
	if (remove) then i=i(2:nticks-1) else i=i(1:nticks-1)
	if (xtickname(nticks-1) eq ' ') then remove=1 else $
	  if (strmid(xtickname(nticks-1),strlen(xtickname(nticks-1))-1,1) eq ' ') then $
			remove = 1 else remove =0
	if (remove) then i = i(0:n_elements(i)-2)
	; now take every 2nd one
	i = ticklimit(i,n_elements(i)/2)
	if (nticks gt 5) then xtickname(i) = ' '

	return,xtickname
	end

