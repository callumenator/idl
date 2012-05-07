;-------------------------------------------------------------
;+
; NAME:
;       SWINDOW
; PURPOSE:
;       Create a scrolling window.  Works much like window.
; CATEGORY:
; CALLING SEQUENCE:
;       swindow
; INPUTS:
; KEYWORD PARAMETERS:
;       keywords:
;         INDEX=ind Returned window index, base number, and
;           sw index:
;           ind = [indx, base, sw_ind].  Use ind in wset, base
;           is not be needed directly, sw_ind is used in swdelete.
;         COLORS=c  Set number of colors to use in windows.
;           Must be given for the first window created.
;         XSIZE=xs  Set total window X size in pixels.
;         YSIZE=ys  Set total window Y size in pixels.
;           Defaults = 500 x 400.
;         X_SCROLL_SIZE=xsc  Set visible window X size in pixels.
;         Y_SCROLL_SIZE=ysc  Set visible window Y size in pixels.
;           Defaults = total window size up to 2/3 screen size.
;         TITLE=txt  Set optional window title.
;         /QUIET  means do not list window number when created.
;         RETAIN=r  Set backing store type (def=2, see manual).
;         /PIXMAP means use pixmap instead of screen window.  If
;          given then an ordinary window is used.
; OUTPUTS:
; COMMON BLOCKS:
;       swindow_com
; NOTES:
;       Notes: A draw widget is used to make a scrolling window.
;         Differences between windows and draw widgets prevent
;         exact emulation of the window command.
;         See also swdelete, and swlist.
; MODIFICATION HISTORY:
;       R. Sterner, 14 Jun, 1993
;       R. Sterner, 29 Sep, 1993
;       R. Sterner, 30 Dec, 1993 --- added /QUIET.
;       R. Sterner, 1995 Dec 20 --- removed window size extension.
;       R. Sterner, 1997 Sep 24 --- Handled Win95 Y scroll bug.
;
; Copyright (C) 1993, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
 
	pro swindow, index=indx, colors=colors, quiet=quiet, $
	  xsize=xsize, ysize=ysize, x_scroll_size=xscr, extend=extend, $
	  y_scroll_size=yscr, title=title, retain=retain, $
	  pixmap=pix, help=hlp
 
	common swindow_com, index_table, base_table, sw_ind, swcnt, $
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
	  print,' Create a scrolling window.  Works much like window.'
	  print,' swindow'
	  print,' keywords:'
	  print,'   INDEX=ind Returned window index, base number, and'
	  print,'     sw index:'
	  print,'     ind = [indx, base, sw_ind].  Use ind in wset, base'
	  print,'     is not be needed directly, sw_ind is used in swdelete.'
	  print,'   COLORS=c  Set number of colors to use in windows.'
	  print,'     Must be given for the first window created.'
	  print,'   XSIZE=xs  Set total window X size in pixels.'
	  print,'   YSIZE=ys  Set total window Y size in pixels.'
	  print,'     Defaults = 500 x 400.'
	  print,'   X_SCROLL_SIZE=xsc  Set visible window X size in pixels.'
	  print,'   Y_SCROLL_SIZE=ysc  Set visible window Y size in pixels.'
	  print,'     Defaults = total window size up to 2/3 screen size.'
	  print,'   TITLE=txt  Set optional window title.'
	  print,'   /QUIET  means do not list window number when created.'
	  print,'   RETAIN=r  Set backing store type (def=2, see manual).'
	  print,'   /PIXMAP means use pixmap instead of screen window.  If'
	  print,'    given then an ordinary window is used.'
	  print,' Notes: A draw widget is used to make a scrolling window.'
	  print,'   Differences between windows and draw widgets prevent'
	  print,'   exact emulation of the window command.'
	  print,'   See also swdelete, and swlist.'
	  return
	endif
 
	;--------  Set defaults  -----------
	if n_elements(ind) eq 0 then ind = 0		; Def window = 0.
	if n_elements(colors) eq 0 then colors = 0	; Use default # colors.
	if n_elements(xsize) eq 0 then xsize = 500	; Default window size.
	if n_elements(ysize) eq 0 then ysize = 400
	device, get_screen_size=ss			; Get screen size.
	xmx = ss(0)*2/3					; Max allowed default
	ymx = ss(1)*2/3					;   window size.
	if n_elements(xscr) eq 0 then xscr = xsize<xmx	; Default scroll size.
	if n_elements(yscr) eq 0 then yscr = ysize<ymx
	if n_elements(retain) eq 0 then retain = 2	; Default backing store.
 
	;--------  Deal with pixmap  ---------------
	if keyword_set(pix) then begin
	  window,/free,xs=xsize,ys=ysize, $		; Ordinary window.
	    colors=colors, retain=retain, /pixmap
	  indx = !d.window
	  if not keyword_set(quiet) then print,' Pixmap '+strtrim(indx,2)
	  return
	endif
 
	;--------  Create scrolling window  --------
	add = 0					; Handle window extend.
	;-------  Window number and title  ----------
	if n_elements(swcnt) eq 0 then swcnt = 99	; Init next window num.
	swcnt = swcnt + 1				; Next window num.
	if n_elements(title) eq 0 then begin		; Make a title.
	  if xsize ge 127 then begin			;   Big window.
	    title = 'swindow '+strtrim(swcnt,2)
	  endif else begin				;   Little window.
	    title = strtrim(swcnt,2)
	  endelse
	endif
	;-------  Deal with Win95 IDL bug  --------------
	winbug = 0
	if (!version.os eq 'Win32') then winbug=-1
 
	;-------  Make Scrolling window  ----------------
	b = widget_base(title=title)
	t = widget_draw(b,xs=xsize+add,ys=ysize+add,x_scr=xscr+add,$
	  y_scr=yscr+add+winbug, colors=colors, retain=retain)
	widget_control, b, /real
 
	;--------  Update common  ----------
	;---  Common is used to match window indices with widget bases.
	;---  This allows swdelete to find the widget to delete.
	;-----------------------------------
	if n_elements(base_table) eq 0 then begin
	  index_table = [-2L]
	  base_table = [-2L]
	  sw_titl = strarr(1)
	  sw_ind = intarr(1)
	  sw_fx = lonarr(1)
	  sw_fy = lonarr(1)
	  sw_vx = intarr(1)
	  sw_vy = intarr(1)
	  sw_flag = intarr(1)
	endif
	w = where(index_table lt 0, cnt)
	if cnt gt 0 then begin		; Replace a deleted value.
	  index_table(w(0)) = !d.window
	  base_table(w(0)) = b
	  sw_titl(w(0)) = title
	  sw_ind(w(0)) = swcnt
	  sw_fx(w(0)) = xsize+add
	  sw_fy(w(0)) = ysize+add
	  sw_vx(w(0)) = xscr+add
	  sw_vy(w(0)) = yscr+add
	  sw_flag(w(0)) = add gt 0
	endif else begin		; Put new values at front.
	  index_table = [!d.window, index_table]
	  base_table = [b, base_table]
	  sw_titl = [title,sw_titl]
	  sw_ind = [swcnt,sw_ind]
	  sw_fx = [xsize+add,sw_fx]
	  sw_fy = [ysize+add,sw_fy]
	  sw_vx = [xscr+add,sw_vx]
	  sw_vy = [yscr+add,sw_vy]
	  sw_flag = [add gt 0,sw_flag]
	endelse
 
	;--------  Return window index  -----------
	indx = [!d.window,b, swcnt]
	if not keyword_set(quiet) then print,' Window '+strtrim(!d.window,2)
 
	return
	end
