;========================================================================
; Create a text widget that displays the contents of a structure.
; Developed to display the msp in_struk information for the Aurora
; Boundaries project.  
;
; inputs:in_struk - structure holding the contents to be displayed in
;                   the text widget
;          parent - keyword specifies the parent widget in which the text
;                   widget is to be drawn
;           title - For top-level widget, this is the window title
;       widget_id - on input, specifies the ID of an existing instance
;                   of this display widget.  If valid, the routine will
;                   just update fields in this widget, not create a 
;                   new one.  On output, it contains the ID of the
;                   (possibly newly-created) display widget.
;            tagz - An array of tag indices, specifying which fileds 
;                   in the structure "in_struk" that we want to display.
;           uname - allows a username to be attached to the display
;                   widget - useful for finding the widget later.
;     break_array - A list of tag indices. Each tag listed will allow
;                   items to be broken over multiple lines if the
;                   corresponding data item is an array.
;                   
;
; Debi-Lee Wilkinson Oct, 1999
; Heavily modified by Mark Conde, Fairbanks, October 1999.
;

pro v_struk_event, event
    widget_control, event.id, set_droplist_select=event.index
    widget_control, event.id, timer=5.

end

Pro v_struk, in_struk, widget_id=widget_id, parent=parent, tagz=tagz, $
                     uname=uname, break_array=break_array, title=title

    if not(keyword_set(uname)) then uname='field settings for structure: ' + tag_names(in_struk, /structure_name)

;...Get the number and names of the tags that we need to display
    if not(keyword_set(tagz)) then tagz = indgen(N_TAGS(in_struk))
    nloop=N_elements(tagz)
    if nloop le 0 then return
    fields=TAG_NAMES(in_struk)         
    fields=fields(tagz)

;...Create the base, if needed:
    if n_elements(widget_id) eq 0 then widget_id = -1L
    if not(widget_info(widget_id, /valid_id)) then begin    
;......Get the size info:
      if (keyword_set(parent)) then begin
           widget_id=widget_base(parent, /align_left, /column, $
                                 group_leader=parent)
           geobase = widget_info(parent, /geometry)
           xsize   = geobase.xsize - 20
       endif else begin
           if not(keyword_set(title)) then title="IDL structure display"
           widget_id=widget_base(/align_left, /column, title=title)
           xsize=200
       endelse

;.....Loop over the selected elements of the structure
      for loop=0,nloop-1 do begin
;.........Make the text to be displayed as: tag name = tag value
          value=string(strcompress(in_struk.(tagz(loop))))  
;.........Loop over the number of elements, in case "value" is an array, and add
;         each array element to make a long string, unless "break_array" specifies 
;         separate lines for these array elements:
          break_this = 0
          break_something = n_elements(break_array) ne 0
          if break_something then begin
             nb = 0
             breakz = where(break_array eq tagz(loop), nb)
             if nb gt 0 then break_this = 1
          endif
          if not(break_this) then begin
             loopstr=fields(loop) + ' = '    
             for ii=0,n_elements(value)-1 do loopstr=loopstr+value(ii) + ', ' 
             loopstr = strmid(loopstr, 0, strlen(loopstr)-2)
             if n_elements(headlist) eq 0 then headlist=loopstr else headlist = [headlist, loopstr]
          endif else begin
             for ii=0,n_elements(value)-1 do begin
                     if strcompress(value(ii), /remove_all) ne '' then begin
                        loopstr=fields(loop) + ' = ' + value(ii)
                        if n_elements(headlist) eq 0 then headlist=loopstr else headlist = [headlist, loopstr]
                     endif
             endfor
          endelse
       endfor  
       handle = widget_droplist(widget_id, /align_left, value=headlist, title='Header:', event_pro='v_struk_event') 
;......Now realize the widget:
       widget_control, widget_id,/realize
       widget_control, widget_id, set_uname=uname
       widget_control, widget_id, timer=5.

;......Save the tag names and label widget IDs in the base widget's uvalue:
       key = {field_names: fields, text_id: handle}
       widget_control, widget_id, set_uvalue=key
    endif else begin
;......It seems we already have created the widget on a previous call.  So,
;      here we just refresh the fields.  First, get a key to the fields:
       widget_control, widget_id, get_uvalue=key
       nowsel = widget_info(key.text_id, /droplist_select)
       for loop=0,nloop-1 do begin
           value   = string(strcompress(in_struk.(tagz(loop))))  
;..........See if this widget has a field for this structure tag:
           nmatch = 0
           match  = where(fields(loop) eq key.field_names, nmatch)
           if nmatch gt 0 then begin
;.............Update the label widget:
              break_this = 0
              break_something = n_elements(break_array) ne 0
              if break_something then begin
                 nb = 0
                 breakz = where(break_array eq tagz(loop), nb)
                 if nb gt 0 then break_this = 1
              endif
              if not(break_this) then begin
                 loopstr=fields(loop) + ' = '    
                 for ii=0,n_elements(value)-1 do loopstr=loopstr+value(ii) + ', ' 
                 loopstr = strmid(loopstr, 0, strlen(loopstr)-2)
                 if n_elements(headlist) eq 0 then headlist=loopstr else headlist = [headlist, loopstr]
              endif else begin
                 for ii=0,n_elements(value)-1 do begin
                     if strcompress(value(ii), /remove_all) ne '' then begin
                        loopstr=fields(loop) + ' = ' + value(ii)
                        if n_elements(headlist) eq 0 then headlist=loopstr else headlist = [headlist, loopstr]
                     endif
                 endfor
              endelse
           endif
       endfor       
       widget_control, key.text_id, set_value=headlist
       widget_control, key.text_id, set_droplist_select=nowsel
    endelse
end