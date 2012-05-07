;-------------------------------------------------------------
;+
; NAME:
;       XTXTIN
; PURPOSE:
;       Widget based text input.
; CATEGORY:
; CALLING SEQUENCE:
;       xtxtin, out
; INPUTS:
; KEYWORD PARAMETERS:
;       Keywords:
;         TITLE=tt   Widget title text (def="Enter text").
;           May be a text array.
;         DEFAULT=def  Initial text string (def=null).
;         MENU=txt   Optional text array with additional entries.
;           To select one of these items its button is pressed.
;         /TOP means put optional buttons on top (def=bottom).
;         /WAIT  means wait for returned result.
; OUTPUTS:
;       out = Returned text string (null for CANCEL).    out
; COMMON BLOCKS:
; NOTES:
; MODIFICATION HISTORY:
;       R. Sterner, 1994 Mar, 14
;       R. Sterner, 1995 Mar 21 --- Added optional buttons.
;
; Copyright (C) 1994, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
 
	pro xtxtin_event, ev
 
	widget_control, ev.id, get_uval=name
	widget_control, ev.top, get_uval=m
 
	if (name eq 'OK') or (name eq 'TEXT') then begin
done:	  widget_control, m.idtxt, get_val=val
	  widget_control, m.res, set_uval=val(0)
	  widget_control, ev.top, /dest
	  return
	endif
 
	if name eq 'CLEAR' then begin
	  widget_control, ev.top, get_uval=wids
	  widget_control, m.idtxt, set_val=''
	  return
	endif
 
	if name eq 'CANCEL' then begin
	  widget_control, ev.top, get_uval=wids
	  widget_control, m.res, set_uval=''
	  widget_control, ev.top, /dest
	  return
	endif
 
	menu = m.menu
	widget_control, m.idtxt, set_value=menu(name)
	goto, done
 
	return
	end
 
;=====================================================================
;	xtxtin.pro = Widget text input.
;	R. Sterner, 1994 Mar 14.
;=====================================================================
 
	pro xtxtin, out, title=title, default=def, wait=wait, $
	  menu=menu, top=btop, help=hlp
 
	if keyword_set(hlp) then begin
	  print,' Widget based text input.'
	  print,' xtxtin, out'
	  print,'   out = Returned text string (null for CANCEL).    out'
	  print,' Keywords:'
	  print,'   TITLE=tt   Widget title text (def="Enter text").'
	  print,'     May be a text array.'
	  print,'   DEFAULT=def  Initial text string (def=null).'
	  print,'   MENU=txt   Optional text array with additional entries.'
	  print,'     To select one of these items its button is pressed.'
	  print,'   /TOP means put optional buttons on top (def=bottom).'
          print,'   /WAIT  means wait for returned result.'
	  return
	endif
 
	if n_elements(title) eq 0 then title='Enter text'
	if n_elements(def) eq 0 then def=''
 
	;------  Lay out widget  ----------
	top = widget_base(/column,title=' ')
	n = n_elements(title)
	m = max(strlen(title))
	id = widget_text(top,xsize=m,ysize=n,val=title)
	;-------  Text entry above any buttons (def)  -------
	if not keyword_set(btop) then $
	  idtxt = widget_text(top,/edit,xsize=40,ysize=1,val=def,uval='TEXT')
	;-------  Optional buttons  ------
	nm = n_elements(menu)
	if nm gt 0 then begin
	  for i = 0, nm-1 do begin
	    b = widget_base(top,/row)
	    id = widget_button(b,val='-',uval=strtrim(i,2))
	    id = widget_label(b,val=menu(i))
	  endfor
	endif
	;-------  Text entry below any buttons  -------
	if keyword_set(btop) then $
	  idtxt = widget_text(top,/edit,xsize=40,ysize=1,val=def,uval='TEXT')
	;------------------------------------------------
	but = widget_base(top, /row)
	bok = widget_button(but, val='Accept entry',uval='OK')
	b = widget_button(but, val='Clear text',uval='CLEAR')
	b = widget_button(but, val='Cancel entry',uval='CANCEL')
 
	;------  Package and store needed info  ------------
	res = widget_base()
	if n_elements(menu) eq 0 then begin
	  map = {idtxt:idtxt, res:res}
	endif else begin
	  map = {idtxt:idtxt, res:res, menu:menu}
	endelse
	widget_control, top, set_uval=map
 
	;------  realize widget  -----------
	widget_control, top, /real
	if def eq '' then begin
	  widget_control, idtxt, /input_focus
	endif else begin
	  widget_control, bok, /input_focus
	endelse
 
	;------  Event loop  ---------------
        if n_elements(wait) eq 0 then wait = 0
	xmanager, 'xtxtin', top, modal=wait
 
	;------  Get result  ---------------
	widget_control, res, get_uval=out
 
	return
	end
