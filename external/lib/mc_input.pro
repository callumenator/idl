;===========================================================================================
; This is a simple data entry routine.  It creates a BLOCKING widget - it will NOT
; return until input is provided.  The caller is suspended until the selection is
; made.

pro mc_input, var, title=title, prompt=prompt, help=help, slider=slider, heading=heading, _extra=e, exit_reason=exit_reason
    if not(keyword_set(title))  then title="Data Entry"
    if n_elements(var) eq 0 then var = ' '
    if not(keyword_set(prompt)) then prompt="Value " + strcompress(string(indgen(n_elements(var))), /remove_all) + ':'
    sliders = -1

    basid       = widget_base(/column, title=title, space=2, xpad=0, ypad=4, /base_align_center)
    if keyword_set(heading) then headid = widget_label(basid, value=heading.text, font=heading.font, /dynamic)

    for j=0, n_elements(var)-1 do begin
       rowbase     = widget_base(basid, /row, xpad=10, space=10)
       shimbase    = widget_base(rowbase, /col, ypad=8)
       fieldid     = cw_field(shimbase, _extra=e, /all_events, title=prompt(j) + "  ", value=var(j))
       if j eq 0 then fields = fieldid else fields = [fields, fieldid]
       if keyword_set(slider) then begin
          st       = 'Range: ' + strcompress(string(slider(j).min, format=slider(j).format), /remove_all) + ' to ' + $
                                 strcompress(string(slider(j).max, format=slider(j).format), /remove_all)
          slidid   = cw_fslider(rowbase, format=slider(j).format, /suppress_value, title=st, $
                             max=slider(j).max, min=slider(j).min, value=slider(j).value, xsize=slider(j).ysize)
          if j eq 0 then sliders = slidid else sliders = [sliders, slidid]
       endif
    endfor

    rowbase     = widget_base(basid, /row, xpad=10, space=10)
    okid        = widget_button(rowbase, value='Ok')
    canid       = widget_button(rowbase, value='Cancel')

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
   
   vsave = var
   
EVENT_LOOP:   
   event  = widget_event(basid, bad_id=bad_id)
   if widget_info(event.id, /valid_id) then begin
      for j=0, n_elements(var)-1 do begin
          if event.id eq fields(j) then begin
             vsave(j) = event.value
            ; widget_control, fields(j), set_value = event.value
             if keyword_set(slider) then widget_control, sliders(j), set_value = event.value
          endif
          if keyword_set(slider) then begin
             if event.id eq sliders(j) then begin
                vsave(j) = event.value
                widget_control, fields(j), set_value = event.value
                if keyword_set(slider) then widget_control, sliders(j), set_value = event.value
             endif 
          endif
      endfor
   endif
   if event.id ne okid and event.id ne canid then goto, EVENT_LOOP
   
   exit_reason = 'Cancel'
   if event.id eq okid then begin
      var = vsave
      exit_reason = 'Ok'
   endif
   widget_control, basid, /destroy
end


