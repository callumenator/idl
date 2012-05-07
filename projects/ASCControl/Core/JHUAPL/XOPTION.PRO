;-------------------------------------------------------------
;+
; NAME:
;       XOPTION
; PURPOSE:
;       Widget option selection panel.
; CATEGORY:
; CALLING SEQUENCE:
;       opt = xoption(menu)
; INPUTS:
;       menu = string array, one element per option.  in
;         These are the option button titles (from top down).
; KEYWORD PARAMETERS:
;       Keywords:
;         VALUES=val  Array of values corresponding to each option.
;           Default value is the menu element index (numeric).
;         DEFAULT=n Button to use as default value (top is val(0)).
;           Sets mouse to point at this element.  If VALUES are
;           given DEFAULT must be one of those values.
;         TITLE=txt A scalar text string to use as title (def=none).
;         SUBOPTIONS=sopt Array of optional suboption names.
;           If given this creates a new bank of buttons, one for
;           each suboption name.
;         /EXCLUSIVE means make the suboption buttons exclusive
;           (only one active at a time), else non-exclusive.
;         SUBSET=set  Suboption initial settings, an array of
;           0 (off) or 1 (on), one for each suboption button.
;           The updated button status is returned here also.
;           For exclusive buttons only the active button number
;           is returned, -1 for none.
;         SUB2OPTIONS=s2opt Optional second suboption menu.
;         /EX2 Second suboption buttons are exclusive.
;         SUB2SET=set2  Second suboption initial settings.
; OUTPUTS:
;       opt = returned option value.                 out
; COMMON BLOCKS:
; NOTES:
;       Notes: An example calls:
;         opt = xoptions(['OK','Abort','Continue'])
;         opt = xoptions(['A','B','C'],val=['a','b','c'],def='b')
; MODIFICATION HISTORY:
;       R. Sterner, 1994 Jan 10.
;       R. Sterner, 1994 Jan 13 --- Added DEFAULT keyword.
;       R. Sterner, 1994 Apr 12 --- Added TITLE keyword.
;       R. Sterner, 1995 Dec 22 --- Added suboptions.
;
; Copyright (C) 1994, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
 
	function xoption, txt, values=val, default=def, title=ttl, $
	  suboptions=subopt, subset=subset, exclusive=excl, help=hlp, $
	  sub2options=sub2opt, sub2set=sub2set, ex2=ex2
 
	if (n_params(0) lt 1) or keyword_set(hlp) then begin
	  print,' Widget option selection panel.'
	  print,' opt = xoption(menu)'
	  print,'   menu = string array, one element per option.  in'
	  print,'     These are the option button titles (from top down).'
	  print,'   opt = returned option value.                 out'
	  print,' Keywords:'
	  print,'   VALUES=val  Array of values corresponding to each option.'
	  print,'     Default value is the menu element index (numeric).'
	  print,'   DEFAULT=n Button to use as default value (top is val(0)).'
	  print,'     Sets mouse to point at this element.  If VALUES are'
	  print,'     given DEFAULT must be one of those values.'
	  print,'   TITLE=txt A scalar text string to use as title (def=none).'
	  print,'   SUBOPTIONS=sopt Array of optional suboption names.'
	  print,'     If given this creates a new bank of buttons, one for'
	  print,'     each suboption name.'
	  print,'   /EXCLUSIVE means make the suboption buttons exclusive'
	  print,'     (only one active at a time), else non-exclusive.'
	  print,'   SUBSET=set  Suboption initial settings, an array of'
	  print,'     0 (off) or 1 (on), one for each suboption button.'
	  print,'     The updated button status is returned here also.'
	  print,'     For exclusive buttons only the active button number'
	  print,'     is returned, -1 for none.'
	  print,'   SUB2OPTIONS=s2opt Optional second suboption menu.'
	  print,'   /EX2 Second suboption buttons are exclusive.'
	  print,'   SUB2SET=set2  Second suboption initial settings.'
	  print,' Notes: An example calls:'
	  print,"   opt = xoptions(['OK','Abort','Continue'])"
	  print,"   opt = xoptions(['A','B','C'],val=['a','b','c'],def='b')"
	  return,''
	endif
 
	;--------  Defaults  -------------
	n = n_elements(txt)
	if n_elements(val) eq 0 then val = indgen(n)
	if n_elements(def) eq 0 then def = val(0)
	dsave = -1		; WID of default button.
	def2 = (where(def eq val))(0)
 
	;---------  Suboptions  ------------
	nsub = n_elements(subopt)		; Any suboptions?
	exc = keyword_set(excl)			; Button type.
	nonexc = 1-exc				; Exclusive or nonexclusive.
	if nsub ne 0 then begin			; None set, all off.
	  if n_elements(subset) eq 0 then subset=bytarr(nsub)
	endif
	if (exc eq 1) and (n_elements(subset) eq 1) then begin	; /excl case.
	  is = subset				; Handle single value setting.
	  subset=bytarr(nsub)			; Expand to all buttons.
	  subset(is) = 1
	endif
 
	;---------  2nd Suboptions  ------------
        nsub2 = n_elements(sub2opt)		; Any 2nd suboptions?
	exc2 = keyword_set(ex2)			; Button type.
	nonexc2 = 1-exc2			; Exclusive or nonexclusive.
	if nsub2 ne 0 then begin		; None set, all off.
	  if n_elements(sub2set) eq 0 then sub2set=bytarr(nsub2)
	endif
	if (exc2 eq 1) and (n_elements(sub2set) eq 1) then begin ; /excl case.
	  is = sub2set				; Handle single value setting.
	  sub2set=bytarr(nsub2)			; Expand to all buttons.
	  sub2set(is) = 1
	endif
 
	;-------  Set up widget  -------------
	top = widget_base(/column,title=' ')
	if n_elements(ttl) ne 0 then id=widget_label(top,val=ttl)
	top2 = widget_base(top,/row)
 
	lft = widget_base(top2,/column)		; Left or only column.
	for i = 0, n-1 do begin
          b = widget_base(lft,/row)
          id = widget_button(b,val='-',uval=val(i))
	  if i eq def2 then dsave = id
          id = widget_label(b,val=txt(i))
	endfor
 
	if n_elements(subopt) ne 0 then begin	; Suboptions.
	  rgt = widget_base(top2,/column,/frame,exclusive=exc,$
	    nonexclusive=nonexc)
	  for i=0,nsub-1 do begin
	    id = widget_button(rgt,val=subopt(i),uval='# '+strtrim(i,2))
	    if subset(i) ne 0 then widget_control,id,/set_button
	  endfor
	endif
 
	if n_elements(sub2opt) ne 0 then begin	; 2nd Suboptions.
	  rgt2 = widget_base(top2,/column,/frame,exclusive=exc2,$
	    nonexclusive=nonexc2)
	  for i=0,nsub2-1 do begin
	    id = widget_button(rgt2,val=sub2opt(i),uval='$ '+strtrim(i,2))
	    if sub2set(i) ne 0 then widget_control,id,/set_button
	  endfor
	endif
 
        widget_control, top, /real
	if dsave ge 0 then widget_control, dsave, /input_focus
 
	;--------  Process events  ---------------
loop:   ev = widget_event(top)
        widget_control, ev.id, get_uval=uval
	if getwrd(uval) eq '#' then begin	; Suboption button.
	  but = getwrd(uval,1)+0		; Which?
	  subset(but) = ev.select		; Set it.
;	  print,but,ev.select
	  goto, loop
	endif
	if getwrd(uval) eq '$' then begin	; 2nd suboption button.
	  but = getwrd(uval,1)+0		; Which?
	  sub2set(but) = ev.select		; Set it.
;	  print,but,ev.select
	  goto, loop
	endif
 
	widget_control, top, /dest
 
	if exc eq 1 then subset=(where(subset eq 1))(0)	   ; Only one value.
	if exc2 eq 1 then sub2set=(where(sub2set eq 1))(0) ; Only one value.
 
	return, uval
 
	end
