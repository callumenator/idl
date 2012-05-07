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
;	  /LIST      use a list widget rather than button menu.
;
; OUTPUTS:
;       i = selected menu item number.        out
; COMMON BLOCKS:
; NOTES:
; MODIFICATION HISTORY:
;       Based on WMENU2 in JHUAPL which was written by R. Sterner, 22 May 1990
;		--- T.J. Harris 	IE HFRD DSTO.  2 Feb 1994
;	Now utilises xmenu facility to create a nice number of columns
;		--- T.J. Harris 	IE HFRD DSTO. 23 Feb 1994
;	Ammended to use a list widget if requested.
;		--- T.J. Harris 	IE HFRD DSTO. 12 Jan 1995 
;-
;-------------------------------------------------------------

FUNCTION Th_wmenu, list, TITLE=tt, INITIAL_SELECTION=init, HELP=hlp, $
                   NOMOUSE=nom, NOWIDGETS=now, LIST=use_list_widget
  
  IF (N_PARAMS(0) LT 1) OR KEYWORD_SET(hlp) THEN BEGIN
    print, ' Like wmenu but allows non-mouse menus. Uses widgets if available.'
    print, ' i = th_wmenu(list)'
    print, '   list = menu in a string array.        in'
    print, '   i = selected menu item number.        out'
    print, ' Keywords:'
    print, '   TITLE=t  item number to use as title (def = no title).'
    print, '   INITIAL_SELECTION=s  initial item selected (=default).'
    print, '   /NOMOUSE   forces no mouse mode.'
    print, '   /NOWIDGETS forces no widget mode.'
    print, '   /LIST      use a list widget rather than button menu.'
    RETURN, -1
  ENDIF

  list  = string(list) 
  
  IF N_ELEMENTS(tt) EQ 0 THEN BEGIN
    title = ''
    wlist = list
    tt = -1
  ENDIF ELSE BEGIN
    sz = size(tt) 
    IF (sz(sz(0) +1) EQ 7) THEN BEGIN ;tt is a string
      title = tt
      wlist = list
      tt = -1
    ENDIF ELSE BEGIN
      title = list(tt) 
      wlist = list(where(list NE title) ) 
    ENDELSE
  ENDELSE

  IF N_ELEMENTS(init) EQ 0 THEN init = -1
  
  name = !D.name                ; Plot device name.
  flag = (fix(!D.flags /2.^8 MOD 2) ) ; Set if a window device
  IF KEYWORD_SET(nom) THEN flag = 0 ; Force no mouse.

                                ;--------  mouse menu  ----------
  IF (flag) THEN BEGIN
    IF ((!D.flags AND 65536) NE 0) AND $
      (NOT KEYWORD_SET(now) ) THEN BEGIN
                                ;-------  Use Widget menu  ---------
      num = N_ELEMENTS(wlist) 
      plot_ident, /DONT_WRITE, /SHORT, /NOPROG, ROUTINE=3, /NOUID, /NOTIME, $
        OUT=plot_ident_str
      menu_base = WIDGET_BASE(TITLE=plot_ident_str, /COLUMN) 
      label = WIDGET_LABEL(menu_base, VALUE=title) 
      xmenu_base = WIDGET_BASE(menu_base) 
      IF KEYWORD_SET(use_list_widget) THEN $
        L = WIDGET_LIST(xmenu_base, VALUE=wlist, YSIZE=(num < 30) ) $
      ELSE $
        xmenu, wlist, xmenu_base, UVAL=indgen(num), COLUMN=(num /30 + 1) 
      WIDGET_CONTROL, menu_base, /REAL
      e = WIDGET_EVENT(menu_base) 
      IF KEYWORD_SET(use_list_widget) THEN $
        in = e.index $
      ELSE $
        WIDGET_CONTROL, e.id, GET_UVAL=in
      WIDGET_CONTROL, menu_base, /DEST

      IF in GE tt THEN in = in +1 ;since the title has been removed
      RETURN, in

    ENDIF ELSE BEGIN
                                ;-------  Old style menus  -------
      Loop:	    in = wmenu(list, TITLE=tt, INIT=init) 
      IF in LT 0 THEN GOTO, loop
      RETURN, in
    ENDELSE
  ENDIF ELSE BEGIN
    
                                ;-------  non-mouse menu  --------
    print, ' '
    mx = N_ELEMENTS(list) -1
    IF tt GE 0 THEN print, '          ' +list(tt) 
    FOR i = 0, mx DO BEGIN
      IF i NE tt THEN print, ' ', i, ' ' +list(i) 
    ENDFOR
    Loop2:	txt = ''
    IF init GE 0 THEN BEGIN
      read, ' Choose (def = ' +strtrim(init, 2) +'): ', txt
    ENDIF ELSE BEGIN
      read, ' Choose: ', txt
    ENDELSE
    IF txt EQ '' THEN txt = init
    in = txt + 0
    IF (in LT 0) OR (in GT mx) THEN BEGIN
      print, ' You must choose one of the above'
      GOTO, loop2
    ENDIF
    IF in EQ tt THEN BEGIN
      print, ' You must choose one of the above'
      GOTO, loop2
    ENDIF
    RETURN, in

  ENDELSE

  RETURN, -1
  
END
