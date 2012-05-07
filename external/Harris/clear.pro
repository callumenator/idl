;---------------------------------------------------------------------------
	pro clear
;+
; NAME:			CLEAR
;
; PURPOSE:		This is a generic procedure to close windows  
;			(if they are not part of a widget), 
;			redraw TEK screens, close PostScript files etc.. 
;			It will also attempt to close and free all LUNs.
;
; CATEGORY:		Utility
;
; CALLING SEQUENCE:	clear
;
; INPUTS:		none
;
; OUTPUTS:		none
;
; COMMON BLOCKS:
;			none.
; SIDE EFFECTS:
;			Windows are deleted, files closed and LUNs freed
;
; MODIFICATION HISTORY:
;	Written by: Trevor Harris, Physics Dept., University of Adelaide,
;		July, 1990.
;	Mods, 13-Oct-93 T.J.H. to take into account the window unit numbers 
;		allocated to Draw Widgets
;	Mods, 09-Mar-94 T.J.H. to avoid trying to close units attached
;		to special files such as the .help and journal files
;
;-

on_error,2	;return to the caller if an error occurs

;get the window LUN corresponding to Draw Widgets
draw_widget_window = xm_windows()
draw_widget_window = reform(draw_widget_window(*,0))

possible_windows = indgen(128)
num_win = n_elements(possible_windows)
i = 0

case !d.name of
	'SUN' : while (!d.window ge 0) and ( i lt num_win) do begin
			window_idx = possible_windows(i)
			if (total(where(draw_widget_window eq window_idx)) $
			eq -1) then wdelete,window_idx
			i = i+1
		endwhile
	'TEK' : begin & erase & !p.font=-1 & end
	'X'   : while (!d.window ge 0) and ( i lt num_win) do begin
			window_idx = possible_windows(i)
			;print,window_idx
			if (total(where(draw_widget_window eq window_idx)) $
			eq -1) then wdelete,window_idx
			i = i+1
		endwhile
	'PS'  : device,/close
	else  : ; continue
endcase
while (abs(!d.unit) gt 0) do free_lun,abs(!d.unit)
dname = !d.name
set_plot,'ps'
device,/close
set_plot,dname
for i=1,99 do close,i
FOR i = 100, 128 DO BEGIN
    st = fstat(i)
    name =  strupcase(st.name)
    IF ((strpos(name, '.HELP') LT 0) $
        AND (strpos(name, '.PRO') LT 0)) THEN free_lun, i 
ENDFOR

return
end


