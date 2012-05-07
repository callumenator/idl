;-------------------------------------------------------------
;+
; NAME:
;       XCURSOR
; PURPOSE:
;       Cursor coordinate display in a pop-up widget window.
; CATEGORY:
; CALLING SEQUENCE:
;       xcursor, x, y
; INPUTS:
; KEYWORD PARAMETERS:
;       Keywords:
;         /DATA   display data coordinates (default).
;         /DEVICE display device coordinates.
;         /NORMAL display normalized coordinates.
;         /ORDER  Reverse device y coordinate (0 at window top).
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
; MODIFICATION HISTORY:
;       R. Sterner, 1 Nov, 1993
;       R. Sterner, 1995 Jun 30 --- Added x,y and /ORDER.
;
; Copyright (C) 1993, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
 
	pro xcursor, x, y, data=data, normal=norm, device=dev, $
	  order=order, help=hlp
 
	if keyword_set(hlp) then begin
	  print,' Cursor coordinate display in a pop-up widget window.'
	  print,' xcursor, x, y'
	  print,'   x, y = Cursor coordinates.            in,out'
	  print,' Keywords:'
	  print,'   /DATA   display data coordinates (default).'
	  print,'   /DEVICE display device coordinates.'
	  print,'   /NORMAL display normalized coordinates.'
          print,'   /ORDER  Reverse device y coordinate (0 at window top).'
	  return
	endif
 
	;-------  Determine coordinate system  ---------
	typ = 'Data'
	ctyp = 2
	if keyword_set(norm) then begin
	  typ = 'Normalized'
	  ctyp = 1
	endif
	if keyword_set(dev) then begin
	  typ = 'Device'
	  ctyp = 0
	endif
	if strupcase(strmid(typ,0,2)) eq 'DA' then begin
	  if !x.s(1) eq 0 then begin
	    print,' Data coordinate system not established.'
	    return
	  endif
	endif
 
 
        ;------  Find ranges and start in device coordinates  ----
        if keyword_set(dev) then begin              ;----  DEVICE  -----
          xxdv=[0,!d.x_size-1]                      ; Device range.
          yydv=[0,!d.y_size-1]
          if n_elements(x) eq 0 then x=!d.x_size/2
          x = x>0<(!d.x_size-1)
          if n_elements(y) eq 0 then y=!d.y_size/2
          y = y>0<(!d.y_size-1)
        endif else if keyword_set(norm) then begin  ;---  NORMAL  -----
          xxdv=[0,!d.x_size-1]                      ; Normal range.
          yydv=[0,!d.y_size-1]
          if n_elements(x) eq 0 then x=.5
          x = x>0<1.
          if n_elements(y) eq 0 then y=.5
          y = y>0<1.
        endif else begin
	  if !x.type eq 2 then begin		    ;----  MAPS  ------
	    xxdv = [0,!d.x_size-1]
	    yydv = [0,!d.y_size-1]
            if n_elements(x) eq 0 then x = !map.out(9)*!radeg
            if n_elements(y) eq 0 then y = !map.out(8)*!radeg
	  endif else begin			    ;----  DATA  ------
            xx = [min(!x.crange), max(!x.crange)]     ; Data range in x.
            if !x.type eq 1 then xx=10^xx             ; Handle log x axis.
            yy = [min(!y.crange), max(!y.crange)]     ; Data range in y.
            if !y.type eq 1 then yy=10^yy             ; Handle log y axis.
            tmp = convert_coord(xx,yy,/to_dev)        ; Convert to device coord.
            xxdv = tmp(0,0:1)                         ; Device coord. range.
            yydv = tmp(1,0:1)
            xxdv = xxdv(sort(xxdv))                   ; Allow for reversed axes.
            yydv = yydv(sort(yydv))
            if n_elements(x) eq 0 then x = total(xx)/2.
            x = x>xx(0)<xx(1)
            if n_elements(y) eq 0 then y = total(yy)/2.
            y = y>yy(0)<yy(1)
	    endelse
        endelse
        ;-----  Handle y reversal  --------
	y0 = y			; Initial y.
        if (ctyp eq 0) and keyword_set(order) then y=(!d.y_size-1)-y
 
	;-------  Set cursor initial position  ----------
        tmp = convert_coord(x,y,dev=dev,norm=norm,data=data,/to_dev)
        xdv = tmp(0)<xxdv(1)  & ydv = tmp(1)<yydv(1)
        tvcrs, xdv, ydv                         ; Place cursor.
 
	;-------  Set up display widget  ----------
	top = widget_base(/column,title=' ')
	id = widget_label(top,val=typ+' coordinates')
	id = widget_label(top,val='    Press any button to exit    ')
	id = widget_label(top,val=' ',/dynamic_resize)
	widget_control, top, /real
	widget_control, id, set_val=strtrim(string(x,y0),2)
 
	;---------  Cursor loop  ------------
	!err = 0
	while !err eq 0 do begin
	  cursor, x, y, data=data, norm=norm, dev=dev, /change
          ;-----  Handle y reversal  --------
          if (ctyp eq 0) and keyword_set(order) then y=(!d.y_size-1)-y
	  widget_control, id, set_val=strtrim(string(x,y),2)
	endwhile
 
	widget_control, top, /dest
 
	return
	end
