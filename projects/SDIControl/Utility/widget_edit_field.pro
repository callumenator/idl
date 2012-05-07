
pro widget_edit_field, base, $
					   label = label, $
					   font = font, $
					   ids = ids, $
					   start_value = start_value, $
					   edit_uval = uval, $
					   column=column

	if not keyword_set(label) then label = ''
	if not keyword_set(uval) then uval = {descr:'edit_box'}
	if not keyword_set(start_value) then start_value = ''

	if keyword_set(column) then begin
		edit_base = widget_base(base, col = 2)
	endif else begin
		edit_base = widget_base(base, row = 2)
	endelse
	label_wid = widget_label(edit_base, value = label, font = font)
	text_wid = widget_text(edit_base, /edit, font=font, uval = uval, value = start_value)
	ids = {label:label_wid, text:text_wid}

end