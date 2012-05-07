	pro CLEAR_WIDGETS, base

;+
; NAME:			CLEAR_WIDGETS
;
; PURPOSE:		This procedure will DESTROY ALL widgets
;
; CATEGORY:		Utility
;
; CALLING SEQUENCE:	clear_widgets
;			clear_widgets, base_id
;
; INPUTS:		
;	(OPTIONAL)	base_id	= id of widget to be destroyed
;
; OUTPUTS:		none
;
; COMMON BLOCKS:
;			none.
; SIDE EFFECTS:
;			ALL widgets (or the nominated base widget) will be 
;			DESTROYED
;
; MODIFICATION HISTORY:
;	Written by: Trevor Harris, IE, HFRD, DSTO
;		March, 1994
;
;-

if (n_elements(base) le 0) then begin
	WIDGET_CONTROL,/RESET
	;anybase = lindgen(1024)
	;valid = WIDGET_INFO(anybase,/VALID_ID)
	;w = where(valid eq 1,count)
	;;;if (count gt 0) then message,/info,anybase(w)
	;for i=0,count-1 do begin
	;    	base = anybase(w(i))
	;	WIDGET_CONTROL,base,BAD=status,/destroy
	;endfor
endif else begin
	if (WIDGET_INFO(base,/VALID_ID)) then $
				WIDGET_CONTROL,base,BAD=status,/destroy
endelse
 
return
end


