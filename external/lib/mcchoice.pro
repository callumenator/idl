;===========================================================================================
; This is a simple selector box routine.  It creates a BLOCKING widget - it will NOT
; return until a selection is made.  The caller is suspended until the selection is
; made.  Two modes exist - A "pulldown" style, or a simple table.  The "default"
; option only makes sense in pulldown mode.

pro mcchoice, mctitle, options, choice, default=dft, pull_down=pd, help=help, heading=heading, _extra=e
   if not(keyword_set(dft)) then dft=options(0)
   if n_elements(options) lt 1 then return
   choice = {s_mcchoice, name:options(0), index: 0}
   if n_elements(options) eq 1 then return 
   col = 1 + n_elements(options)/28
   if keyword_set(pd) then begin
      basid  = widget_base(/column, title='Pull-down chooser:', space=10, xpad=10, ypad=10, /base_align_center)
      if keyword_set(heading) then headid = widget_label(basid, value=heading.text, font=heading.font, /dynamic) 
      mcsel  = cw_bselector(basid, options, /return_name,label_top=mctitle, set_value=dft)
   endif else begin
      basid  = widget_base(/column, title='Chooser box:', space=10, xpad=10, ypad=10, /base_align_center)
      if keyword_set(heading) then headid = widget_label(basid, value=heading.text, font=heading.font, /dynamic) 
      mcsel  =    cw_bgroup(basid, options, /return_name,label_top=mctitle, column=col)
   endelse
   if keyword_set(help) then begin
      if strlen(help) lt 40 then begin
         xs = strlen(help)
         ys = 1
      endif else begin
         xs = 40
         ys = 1 + strlen(help)/40
      endelse
      helpid = widget_text(basid, value=help, /wrap, xsize=xs, ysize=ys)
   endif
   widget_control, /realize, basid
   
   event  = widget_event(basid, bad_id=bad_id)
   if widget_info(event.id, /valid_id) then begin
      idx    = where(event.value eq options)
      choice = {s_mcchoice, name:event.value, index: idx(0)}
   endif else begin
      idx    = where(dft eq options)
      choice = {s_mcchoice, name:dft, index: idx(0)}      
   endelse
   if widget_info(basid, /valid_id) then widget_control, basid, /destroy
end


