;-------------------------------------------------------------
;+
; NAME:
;       TH_WMENU
; PURPOSE:
;       Like wmenu but allows non-mouse menus. Uses widgets if available.
; CATEGORY:
; CALLING SEQUENCE:
;       i = th_wmenu(list)
; INPUTS:
;       list = menu in a string array.        in
; KEYWORD PARAMETERS:
;       Keywords:
;         TITLE=t  item number or a string to use as title (def = no title).
;         INITIAL_SELECTION=s  initial item selected (=default).
;         /NOMOUSE   forces no mouse mode.
;         /NOWIDGETS forces no widget mode.
; OUTPUTS:
;       i = selected menu item number.        out
; COMMON BLOCKS:
; NOTES:
; MODIFICATION HISTORY:
;       Based on WMENU2 in JHUAPL which was written by R. Sterner, 22 May 1990
;		--- T.J. Harris 	IE HFRD DSTO.  2 Feb 1994
;	Now utilises xmenu facility to create a nice number of columns
;		--- T.J. Harris 	IE HFRD DSTO. 23 Feb 1994
;-
;-------------------------------------------------------------
 
	function th_wmenu_mod, list, title=tt, initial_selection=init, help=hlp, $
	  nomouse=nom, nowidgets=now
 
	if (n_params(0) lt 1) or keyword_set(hlp) then begin
	  print,' Like wmenu but allows non-mouse menus. Uses widgets if available.'
	  print,' i = th_wmenu(list)'
	  print,'   list = menu in a string array.        in'
	  print,'   i = selected menu item number.        out'
	  print,' Keywords:'
	  print,'   TITLE=t  item number to use as title (def = no title).'
	  print,'   INITIAL_SELECTION=s  initial item selected (=default).'
	  print,'   /NOMOUSE   forces no mouse mode.'
	  print,'   /NOWIDGETS forces no widget mode.'
	  return, -1
	endif

	list  = string(list)
 
	if n_elements(tt) eq 0 then begin
		title = ''
		wlist = list
		tt = -1
	endif else begin
		sz = size(tt)
		if (sz(sz(0)+1) eq 7) then begin	;tt is a string
			title = tt
			wlist = list
			tt = -1
		endif else begin
			title = list(tt)
			wlist = list(where(list ne title))
		endelse
	endelse

	if n_elements(init) eq 0 then init = -1
 
	name = !d.name				; Plot device name.
	flag = (fix(!d.flags/2.^8 mod 2))	; Set if a window device
	if keyword_set(nom) then flag = 0	; Force no mouse.

	;--------  mouse menu  ----------
	if (flag) then begin
	  if ((!d.flags and 65536) ne 0) and $
	     (not keyword_set(now)) then begin
	    ;-------  Use Widget menu  ---------
	    num = n_elements(wlist)
	    menu_base = widget_base(title="CHOOSE AN OPTION")
            label = WIDGET_LABEL(menu_base,value=title)
	    xmenu, wlist, menu_base, uval=indgen(num), column=(num/20 + 1)
	    widget_control, menu_base, /real
	    e = widget_event(menu_base)
	    widget_control, e.id, get_uval=in
	    widget_control, menu_base, /dest

	    if in ge tt then in = in+1	;since the title has been removed
	    return, in

	  endif else begin
	    ;-------  Old style menus  -------
loop:	    in = wmenu(list, title=tt, init=init)
	    if in lt 0 then goto, loop
	    return, in
	  endelse
	endif else begin
 
	;-------  non-mouse menu  --------
	print,' '
	mx = n_elements(list)-1
	if tt ge 0 then print,'          '+list(tt)
	for i = 0, mx do begin
	  if i ne tt then print,' ',i,' '+list(i)
	endfor
loop2:	txt = ''
	if init ge 0 then begin
	  read,' Choose (def = '+strtrim(init,2)+'): ',txt
	endif else begin
	  read,' Choose: ', txt
	endelse
	if txt eq '' then txt = init
	in = txt + 0
	if (in lt 0) or (in gt mx) then begin
	  print,' You must choose one of the above'
	  goto, loop2
	endif
	if in eq tt then begin
	  print,' You must choose one of the above'
	  goto, loop2
	endif
	return, in

	endelse

	return, -1
 
	end
