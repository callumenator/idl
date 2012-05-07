;===========================================================================================
; This is a simple data entry routine.  It creates a BLOCKING widget - it will NOT
; return until input is provided.  The caller is suspended until the selection is
; made.

pro mc_message, title=title, help=help, heading=heading, _extra=e
    if not(keyword_set(title))   then title="Message Box"
    if not(keyword_set(heading)) then heading={text: 'Click OK to Continue', font: 'Helvetica*Bold*Proof*30'}
    
    basid       = widget_base(/column, title=title, space=10, xpad=10, ypad=10, /base_align_center)
    if keyword_set(heading) then headid = widget_label(basid, value=heading.text, font=heading.font, /dynamic) 
    rowbase     = widget_base(basid, /row, xpad=30)
    canid       = widget_button(rowbase, value='OK')

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
      widget_control, basid, /destroy
   endif
end


