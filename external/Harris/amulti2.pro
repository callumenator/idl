;---------------------------------------------------------------------------
	pro amulti2, number
;+
; NAME:			AMULTI2
;
; PURPOSE:		Automatically select the !p.multi values to allow 
;			reasonable display of "number" plots.
;			Tries to force 2 columns.
;
; CATEGORY:		Screen utilities
;
; CALLING SEQUENCE:	amulti2,number
;
; INPUTS:	
;		NUMBER	= the number of plots to display
;
;	KEYWORDS:	
;		COLUMN	= force more columns than rows
;		ROWS	= force more rows than columns
;
; OUTPUTS:
;		no explicit outputs;
;
; COMMON BLOCKS:
;	none.
; SIDE EFFECTS:
;	
;		Sets the system varaible, !p.multi
;
; MODIFICATION HISTORY:
;	Written by: Trevor Harris, Physics Dept., University of Adelaide,
;		July, 1990.
;
;-

tmp1 = fix((number-1)/2.) + 1
tmp2 = fix((number-1)/tmp1) + 1
ncols = min([tmp1,tmp2])
nrows = max([tmp1,tmp2])

if (number gt ncols*nrows) then begin

	tmp1 = fix((number)/4.) + 1
	tmp2 = fix((number)/tmp1) + 1
	ncols = min([tmp1,tmp2])
	nrows = max([tmp1,tmp2])

endif

!p.multi = [0,ncols,nrows]

return
end


