;----------------------------------------------------------------------------
	function th_wscreens, multi, TITLE=title, MESSAGE_ID=message_base, $
			PARENT=parent, LUN=wlun, SAME=same, NEXT=next,$
			HORIZONTAL=horizontal,VERTICAL=vertical,$
			PORTRAIT=portrait,LANDSCAPE=landscape,_EXTRA=extra
;+
; NAME:			TH_WSCREENS
;
; PURPOSE:		Widget based routine to open multiple draw widgets
;			If the device does not have widgets, then the result 
;			is the same as calling SCREENS
;
; CATEGORY:		Plot Utility
;
; CALLING SEQUENCE:	base_id = TH_WSCREENS(	number_windows,$
;						LUN=lun, $
;						TITLE=title,$
;						NEXT=next,$
;						HORIZONTAL=horizontal,$
;						VERTICAL=vertical,$
;						PORTRAIT=portrait,$
;						LANDSCAPE=landscape,$
;						MESSAGE_ID=message_id)
;
;	Example:
;			base_id = TH_WSCREENS(2,TITLE="two windows",/PORTRAIT)
;
; INPUTS:
;   OPTIONAL PARAMETERS:
;			multi	= number of individual draw widgets (default=1)
;	KEYWORDS:
;			TITLE 	= Window title if on a windowed device
;			PARENT	= the id of a parent widget if any
;			NEXT 	= if set then append a number to the file name
;				  if a plot device (see PSETUP), otherwise 
;				  create a new window on windowed devices or 
;				  clear the plot screen if in TEK 
;				  This keyword allows multiple files/screens 
;				  to be generated without overwriting each  
;				  other. The append file number is incremented
;				  with each call to TH_WSCREENS,/NEXT
;				  For the PS device the number is reset with 
;				  the /RESET keyword using PSFILE
;			HORIZONTAL = setup display in landscape mode
;				(longer side aligned with x-axis)
;			LANDSCAPE = setup display in landscape mode
;				(longer side aligned with x-axis)
;			VERTICAL = setup display in portrait mode
;				(longer side aligned with y-axis)
;			PORTRAIT = setup display in portrait mode
;				(longer side aligned with y-axis)
;
; OUTPUTS:		
;			base_id	= the id of the main base for the draw widgets
;	KEYWORDS:
;			LUN	= Array of dimension multi containing the unit
;				  number of each draw widget
;			MESSAGE_ID = the id of a base that can be used for 
;				  user messages
;			
;			New files/windows may be opened or screens erased 
;
; COMMON BLOCKS:	SCREENSMEM
;	
; SIDE EFFECTS:
;			New files/windows may be opened or screens erased 
;	
; MODIFICATION HISTORY:
;	Based on SCREENS, which was..
;	Written by: Trevor Harris, Physics Dept., University of Adelaide,
;		July, 1990.
;	This routine written by,
;		TJH March, 1994,	IE, HFRD, DSTO
;
;-

common screensmem, alreadycalled, long, short

!p.multi(0) = 0

if (n_elements(multi) eq 0) then multi = 1
if (keyword_set(title)) then wtitle = title else wtitle = "IDL DISPLAY"

horiz=0
if (keyword_set(horizontal)) then horiz=1
if (keyword_set(vertical)) then horiz=0
if (keyword_set(landscape)) then horiz=1
if (keyword_set(portrait)) then horiz=0

if (keyword_set(same) and n_elements(alreadycalled)) then $
	what = 'something_else' else what = strupcase(!d.name)

ans = ' ' 

if (!d.flags and 2L^8) ne 0 then begin	;has widgets
	
	; Set up the main widget bases.

	if (keyword_set(parent)) then begin
		main_base = WIDGET_BASE(parent, TITLE = wtitle, /column)
	endif else begin 
		main_base = WIDGET_BASE(TITLE = wtitle, /column)
	endelse

	message_base = WIDGET_BASE(main_base,$
				/column,/frame,xsize=600,ysize=40)

	if (horiz) then begin				;create the main base
		draw_base= WIDGET_BASE(main_base,/column,space=2,xpad=1,ypad=1)
		ysize = 800/multi
		xsize = 660
	endif else begin
		draw_base= WIDGET_BASE(main_base,/row,   space=2,xpad=1,ypad=1)
		ysize = 600
		xsize = 1000/multi
	endelse

	win_id = 0L
	for w = 0, multi-1 do begin 
		uval = strcompress(wtitle+"_"+string(w),/rem)
		Window = WIDGET_DRAW(draw_base, $
			xsize=xsize, ysize=ysize, UVAL=uval, /BUTTON_EV, /FRAM)
		win_id = [win_id, Window]
	endfor
	win_id = win_id(1:*)
	base_id = main_base

	;create message_base here so that it is the full size !!
	;message_base = WIDGET_BASE(main_base,/row,/frame,xsize=600,ysize=40)
	WIDGET_CONTROL,main_base,/realize

	wlun = 0L
	for w = 0, multi-1 do begin 
		WIDGET_CONTROL, win_id(w), GET_VALUE=win_lun
		wlun = [wlun,win_lun]
	endfor
	wlun = wlun(1:*)
endif else begin
	screens,title,horiz=horiz,next=next,same=same, _EXTRA=extra
	wlun = !d.window
endelse

alreadycalled = 1

return,base_id

end


