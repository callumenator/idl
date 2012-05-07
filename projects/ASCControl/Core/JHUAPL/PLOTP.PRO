;-------------------------------------------------------------
;+
; NAME:
;       PLOTP
; PURPOSE:
;       Pencode plot routine.  Allows disconnected lines.
; CATEGORY:
; CALLING SEQUENCE:
;       plotp, x, y, [p]
; INPUTS:
;       x,y = arrays of x and y coordinates to plot.       in
;       p = optional pen code array.                       in
;           0: move to point, 1: draw to point.
; KEYWORD PARAMETERS:
;       Keywords:
;         /DATA plots in data coordinates (default).
;         /DEVICE plots in device coordinates.
;         /NORMAL plots in normalized coordinates.
;         COLOR=clr.  Set plot color.
;         LINESTYLE=ls.  Set linestyle.
;         /CLIP means clip to plot window (/DATA only).
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
; MODIFICATION HISTORY:
;       R. Sterner, 18 Oct, 1989
;       R. Sterner, 10 Dec, 1990 --- added LINESTYLE.
;       R. Sterner, 19 Dec, 1991 --- made loop index long.
;
; Copyright (C) 1989, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
 
	pro plotp, x, y, p, help=hlp, data=dt, device=dv, normalized=nm, $
	  color=clr, linestyle=linestyle, clip=clip
 
	if (n_params(0) lt 2) or keyword_set(hlp) then begin
	  print,' Pencode plot routine.  Allows disconnected lines.'
	  print,' plotp, x, y, [p]
	  print,'   x,y = arrays of x and y coordinates to plot.       in'
	  print,'   p = optional pen code array.                       in'
	  print,'       0: move to point, 1: draw to point.'
	  print,' Keywords:'
	  print,'   /DATA plots in data coordinates (default).'
	  print,'   /DEVICE plots in device coordinates.'
	  print,'   /NORMAL plots in normalized coordinates.'
	  print,'   COLOR=clr.  Set plot color.'
	  print,'   LINESTYLE=ls.  Set linestyle.'
	  print,'   /CLIP means clip to plot window (/DATA only).'
	  return
	endif
 
	;----  Make a pencode array if needed.  -------
	if n_params(0) lt 3 then p = x*0 + 1
 
	;----  set plot coordinate system  ------
	flg = 1				 		; Default = data.
	if keyword_set(dt) then flg = 1    		; data
	if keyword_set(dv) then flg = 2   		; device
	if keyword_set(nm) then flg = 3    		; normalized
	if n_elements(clr) eq 0 then clr = !p.color	; color
	if n_elements(linestyle) eq 0 then linestyle=!p.linestyle  ; linestyle.
 
	;-----  Check clipping flag  --------
	if keyword_set(clip) and (flg ne 1) then begin
	  print,' Error in plotp: /CLIP only allowed for /DATA.'
	  return
	endif
 
	;-----  Find breaks in curve  -------
	p2 = p			; Copy pencode array.
	p2(0) = 0		; Force first value to 0.
	w0 = where([p2,0] eq 0)	; Find all 0s, add 0 to end of p.
	nw0 = n_elements(w0)
 
	;-----  plot curve  ---------
	for i = 0L, nw0-2 do begin
	  xx = x(w0(i):(w0(i+1)-1))	; Extract first connected set.
	  yy = y(w0(i):(w0(i+1)-1))
	  if keyword_set(clip) then begin
	    oplot, xx, yy, color=clr, linestyle=linestyle
	  endif else begin
	    case flg of			; Use correct coordinate system.
1:	      plots, xx, yy, /data, color=clr, linestyle=linestyle
2:	      plots, xx, yy, /device, color=clr, linestyle=linestyle
3:	      plots, xx, yy, /normal, color=clr, linestyle=linestyle
	    endcase
	  endelse
	endfor
 
	return
	end
