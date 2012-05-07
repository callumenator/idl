
		pro sides, left=leftedge, right=rightedge, $
			top=topedge, bottom=bottomedge

;+
; NAME:			SIDES
;
; PURPOSE:		Uses !p.multi to determine whether the current plot is
;			positioned at the top, bottom, left or right of the 
;			page for the current set of displays.
;
; CATEGORY:		Plot Utility
;
; CALLING SEQUENCE:	sides, left=leftedge, right=rightedge, 
;			top=topedge, bottom=bottomedge
;
; INPUTS:		reads the !p.multi system plot variable
;
; OUTPUTS:
;	KEYWORDS:	top, bottom, left, right = variable is set if the 
;				position matches the description
;
; COMMON BLOCKS:
;	none.
; SIDE EFFECTS:
;	none.
; MODIFICATION HISTORY:
;	Written by: Trevor Harris, Physics Dept., University of Adelaide,
;		July, 1992.
;
;-


	ncols = !p.multi(1) > 1
	nrows = !p.multi(2) > 1

	framecount = ncols*nrows-!p.multi(0)
	if framecount eq ncols*nrows then framecount = 0

	if (framecount lt ncols) then topedge=1 else topedge=0
	if ((framecount mod ncols) eq 0) then leftedge=1 else leftedge=0
	if ((framecount mod ncols) eq ncols-1) then rightedge=1 else rightedge=0
	if ((framecount/ncols) eq nrows-1) then bottomedge=1 else bottomedge=0
	
	print,'----------------- plot ',framecount

	print,leftedge,rightedge,topedge,bottomedge

	return
	end
