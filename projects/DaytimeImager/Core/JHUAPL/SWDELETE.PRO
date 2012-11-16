;-------------------------------------------------------------
;+
; NAME:
;       SWDELETE
; PURPOSE:
;       Delete a scrolling window.
; CATEGORY:
; CALLING SEQUENCE:
;       swdelete, [index]
; INPUTS:
;       index = optional window index (def=current window).  in
; KEYWORD PARAMETERS:
; OUTPUTS:
; COMMON BLOCKS:
;       swindow_com
; NOTES:
;       Notes: index may point to either a scrolling window made
;         by swindow or to an ordinary window.
; MODIFICATION HISTORY:
;       R. Sterner, 14 Jun, 1993
;
; Copyright (C) 1993, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
 
	pro swdelete, ind0, help=hlp
 
;	common swindow_com, indx, base
        common swindow_com, indx, base, sw_ind, swcnt, $
          sw_titl, sw_fx, sw_fy, sw_vx, sw_vy, sw_flag
        ;-------------------------------------------------------------
        ;  Scrolling windows common (only for scrolling windows):
        ;    index_table = array of window numbers to be used by wset.
        ;    base_table = array of window widget base numbers.
        ;    swcnt = Current count of scrolling windows.
        ;    sw_titl = array of window titles.
        ;    sw_ind = array of window numbers as seen by user (100+).
        ;    sw_fx = array of window full x sizes.
        ;    sw_fy = array of window full y sizes.
        ;    sw_vx = array of window visible x sizes.
        ;    sw_vy = array of window visible y sizes.
        ;    sw_flag = array of extend flag statuses.
        ;--------------------------------------------------------------
 
	if keyword_set(hlp) then begin
	  print,' Delete a scrolling window.'
	  print,' swdelete, [index]'
	  print,'   index = optional window index (def=current window).  in'
	  print,' Notes: index may point to either a scrolling window made'
	  print,'   by swindow or to an ordinary window.'
	  return
	endif
 
	;------  No window index given, use current window  -----
	if n_elements(ind0) ne 0 then ind = ind0	; Copy.
	if n_elements(ind) eq 0 then ind = !d.window	; Use default.
	if ind lt 0 then return			; No current window.
	if n_elements(indx) eq 0 then return	; No scroll windows.
 
;	w = where(indx eq ind, cnt)
	;------  Look for window index in tables  -------
	if ind lt 100 then begin		; Index was IDL index.
	  w = where(indx eq ind, cnt)
	endif else begin			; Index was swindow index.
	  w = where(sw_ind eq ind, cnt)
	  if cnt gt 0 then ind = indx(w(0))	; Want IDL window index.
	endelse
	;-------  Decrement swindow num if deleting highest swindow  ---
	if cnt gt 0 then if sw_ind(w(0)) eq swcnt then swcnt=swcnt-1
	;--------  Deal with index  ------------
	if cnt gt 0 then begin		; Found a scroll window.
	  widget_control, base(w(0)), /destroy
	  w = where(indx ne ind, cnt)	; Find all other indices.
	  if cnt gt 0 then begin	; Keep just these other indices.
	    indx = indx(w)
	    base = base(w)
            sw_ind = sw_ind(w)
            sw_titl = sw_titl(w)
	    sw_fx = sw_fx(w)
	    sw_fy = sw_fy(w)
	    sw_vx = sw_vx(w)
	    sw_vy = sw_vy(w)
	    sw_flag = sw_flag(w)
	  endif else begin		; Just one index.
	    indx(0) = -2		; Clear index from table.
	    base(0) = 0
	    sw_ind(0) = -2
	    swcnt = 99
	  endelse
	endif else begin
	  wdelete, ind			; Index not found in scroll window
	endelse				; list so assume a regular window.
 
	return
	end
