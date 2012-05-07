

;\\ GUI EVENT
pro asc_fits_viewer_event, event

	COMMON ASC_FitsViewer, misc

	widget_control, get_uval = uval, event.id

	if size(uval, /type) eq 8 then begin

		case uval.tag of

			'draw': begin
				if event.press eq 1 then begin
					if event.key eq 5 then misc.file_index --
					if event.key eq 6 then misc.file_index ++
					asc_fits_viewer_update
				endif
			end

			'load': begin
				newdir = dialog_pickfile(/directory)
				file_list = file_search(newdir + '*.fits', count = nfiles)
				print, file_list
				*misc.file_list = file_list
				misc.file_index = 0
				asc_fits_viewer_update, /force
			end

		endcase
	endif
end



;\\ UPDATE VIEW
pro asc_fits_viewer_update, force=force

	COMMON ASC_FitsViewer, misc

	if misc.file_index lt 0 then misc.file_index = n_elements(*misc.file_list) - misc.file_index
	if misc.file_index ge n_elements(*misc.file_list) then misc.file_index -= n_elements(*misc.file_list)

	if n_elements(*misc.file_list) eq 0 then return

	if misc.file_index ne misc.current_index or keyword_set(force) then begin
		misc.current_index = misc.file_index

		fits_read, (*misc.file_list)[misc.file_index], image, header
		*misc.current_image = image
		*misc.current_header = header

		wset, misc.gui_tvid
		tvscl, congrid(image, 400, 400, /interp)

		widget_control, set_value = header, misc.gui_list
	endif
end



;\\ CLEANUP
pro asc_fits_viewer_cleanup, event

	COMMON ASC_FitsViewer, misc

	ptr_free, misc.file_list, misc.current_image, misc.current_header

end



;\\ MAIN
pro asc_fits_viewer

	COMMON ASC_FitsViewer, misc

	font = 'Ariel*16'
	base = widget_base(col=2, title = 'ASC Fits Viewer')
	list = widget_text(base, ys = 40, /scroll, xs = 80, font='Ariel*14')
  		b2 = widget_base(base, row=2)
			wind = widget_draw(b2, xs = 400, ys = 400, keyboard_events = 1, uval = {tag:'draw'})
			btn = widget_button(b2, xs = 400, value = 'Load Directory', uval = {tag:'load'}, font=font)

	widget_control, /realize, base
	widget_control, get_value = tvid, wind

	misc = {gui_base:base, $
			gui_tvid:tvid, $
			gui_list:list, $
			file_list:ptr_new(/alloc), $
			file_index:0, $
			current_index:0, $
			current_image:ptr_new(/alloc), $
			current_header:ptr_new(/alloc)}

	xmanager, 'asc_fits_viewer', base, cleanup = 'asc_fits_viewer_cleanup'

end
