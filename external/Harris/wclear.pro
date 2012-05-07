	pro wclear, window_id

;+
; NAME:			WCLEAR
;
; PURPOSE:		This is a generic procedure to close the current 
;			window (if it is not part of a widget) 
;			or redraw a TEK screen
;
; CATEGORY:		Utility
;
; CALLING SEQUENCE:	wclear
;			wclear, window_id
;
; INPUTS:		none
;
; OUTPUTS:		none
;
; COMMON BLOCKS:
;			none.
; SIDE EFFECTS:
;			Current Window (or nominated window) is deleted 
;			(if it is not part of a widget)
;
; MODIFICATION HISTORY:
;	Written by: Trevor Harris, Physics Dept., University of Adelaide,
;		July, 1990.
;	Mods, 13-Oct-93 T.J.H. to take into account the window unit numbers 
;		allocated to Draw Widgets
;	Mods, 1-Nov-93 T.J.H. allowed entry of window_id
;
;-
;get the window LUN corresponding to Draw Widgets
draw_widget_window = xm_windows()
draw_widget_window = reform(draw_widget_window(*,0))

if (n_elements(window_id) le 0) then window_id = !d.window

case !d.name of
	'SUN' : if (total(where(draw_widget_window eq window_id)) eq -1) then $
		wdelete,window_id
	'TEK' : erase
	'X'   : if (total(where(draw_widget_window eq window_id)) eq -1) then $
		wdelete,window_id
	else  : ; continue
endcase
return
end


