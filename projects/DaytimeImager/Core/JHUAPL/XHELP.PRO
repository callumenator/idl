;-------------------------------------------------------------
;+
; NAME:
;       XHELP
; PURPOSE:
;       Widget to display given help text.
; CATEGORY:
; CALLING SEQUENCE:
;       xhelp, txt
; INPUTS:
;       txt = String array with help text to display.  in
; KEYWORD PARAMETERS:
;       Keywords:
;         TITLE=txt  title text or text array (def=none).
;         LINES=lns maximum number of lines to display
;           before added a scroll bar (def=30).
;         EXIT_TEXT=txt Exit button text (def=Quit help).
;         WID=id  returned widget ID of help widget.  This
;           allows the help widget to be automatically
;           destroyed after action occurs.
;         /NOWAIT  means do not wait for exit button to be
;           pressed.  Use with WID for to display help.
;         /WAIT  means wait for OK button without using xmanager
;           to register xmess.  Will not drop through if button
;           is not pressed as in default case.
;         GROUP_LEADER=grp  Assign a group leader to this
;           widget.  When the widget with ID group is destroyed
;           this widget is also.
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
; MODIFICATION HISTORY:
;       R. Sterner, 29 Sep, 1993
;       R. Sterner, 18 Oct, 1993 --- Added LINES and event handler.
;       R. Sterner, 1994 Feb 21 --- Changed title text.
;       R. Sterner, 1994 Sep  7 --- Added /WAIT keyword.
;
; Copyright (C) 1993, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
 
	pro xhelp_event, ev
 
	widget_control, /dest, ev.top
	return
	end
 
;=============================================================
 
	pro xhelp, txt, title=title, lines=lines, exit_text=texit, $
	  wid=b0, group_leader=grp, help=hlp, nowait=nowait, wait=wait
 
	if (n_params(0) lt 1) or keyword_set(hlp) then begin
	  print,' Widget to display given help text.'
	  print,' xhelp, txt'
	  print,'   txt = String array with help text to display.  in'
	  print,' Keywords:'
          print,'   TITLE=txt  title text or text array (def=none).'
	  print,'   LINES=lns maximum number of lines to display'
	  print,'     before added a scroll bar (def=30).'
	  print,'   EXIT_TEXT=txt Exit button text (def=Quit help).'
	  print,'   WID=id  returned widget ID of help widget.  This'
	  print,'     allows the help widget to be automatically'
	  print,'     destroyed after action occurs.'
	  print,'   /NOWAIT  means do not wait for exit button to be'
	  print,'     pressed.  Use with WID for to display help.'
          print,'   /WAIT  means wait for OK button without using xmanager'
          print,'     to register xmess.  Will not drop through if button'
          print,'     is not pressed as in default case.'
	  print,'   GROUP_LEADER=grp  Assign a group leader to this'
	  print,'     widget.  When the widget with ID group is destroyed'
	  print,'     this widget is also.'
	  return
	endif
 
	if n_elements(texit) eq 0 then texit = 'Quit help'
 
	;-------  Set up and display widget  --------
	if n_elements(lines) eq 0 then lines = 30
	b0 = widget_base(title=' ',/column)
	if n_elements(grp) ne 0 then widget_control, b0, group=grp
	nx = max(strlen(txt))
	ny = n_elements(txt)
	if ny gt lines then begin
	  ny = lines
	  scroll = 1
	endif else scroll=0
	if n_elements(title) ne 0 then begin
          for i=0, n_elements(title)-1 do t = widget_label(b0,val=title(i))
	endif
	b2 = widget_text(b0,value=txt,xsize=nx,ysize=ny,scroll=scroll)
	if not keyword_set(nowait) then begin
	  b1 = widget_base(b0,/row)
	  b11 = widget_button(b1,value=texit)
	endif
	widget_control,/real,b0
 
        ;-------  Forced wait  ----------
        if keyword_set(wait) then begin
          widget_control, b11, /input_focus
          tmp = widget_event(b0)
          widget_control, /dest, b0
          return
        endif
 
	;--------  No wait  -----------
	if keyword_set(nowait) then return
 
        widget_control, b11, /input_focus
 
	xmanager, 'xhelp', b0
 
	return
	end
