;----------------------------------------------------------------------------
	pro amulti, number, column=column, row = row
;+
; NAME:			AMULTI
;
; PURPOSE:		Automatically select the !p.multi values to allow 
;			reasonable display of "number" plots.
;			Tries to force 4 columns.
;
; CATEGORY:		Screen utilities
;
; CALLING SEQUENCE:	amulti,number
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

tmp1 = fix((number-1)/4.) + 1
tmp2 = fix((number-1)/tmp1) + 1
ncols = min([tmp1,tmp2])
nrows = max([tmp1,tmp2])

if (number gt ncols*nrows) then begin

	tmp1 = fix((number)/4.) + 1
	tmp2 = fix((number)/tmp1) + 1
	ncols = min([tmp1,tmp2])
	nrows = max([tmp1,tmp2])

endif

if (keyword_set(column)) then begin
	tmp = ncols
	ncols = nrows
	nrows = tmp
endif

!p.multi = [0,ncols,nrows]

return
end


