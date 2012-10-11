

pro sdi_tag_event, event

	common SDITag_Common, global

	widget_control, get_uval = uval, event.id

	if (size(uval, /type) eq 8) then begin

		case uval.tag of

			'base':begin ;\\ resize event

				xdiff = event.x - global.gui.base_geom.xsize
				ydiff = event.y - global.gui.base_geom.ysize
				global.gui.base_geom = widget_info(global.gui.base, /geom)
				draw_geom = widget_info(global.gui.draw, /geom)

				widget_control, xsize = draw_geom.xsize + xdiff, $
								ysize = draw_geom.ysize + ydiff, $
								global.gui.draw
				sdi_tag_plot_winds

			end

			'select_directory': begin
				dir = dialog_pickfile(title = 'Select a data directory', /dir)
				global.state.current_dir = dir
				sdi_tag_scan_dir
			end

			'file_list': begin
				global.state.current_list_index = event.index
				sdi_tag_load_file
			end

			'draw': begin


				case event.type of

					0: begin ;\\ button pressed

						if event.press eq 1 then begin	;\\ left button press

						endif
						if event.press eq 4 then begin ;\\ right button press
							global.state.rbutton_down = 1
							sdi_tag_edit, 'click', event.x, event.y
						endif

					end

					1: begin ;\\ button release

						if event.release eq 4 then begin ;\\ right button press
							global.state.rbutton_down = 0
							sdi_tag_edit, 'release', event.x, event.y
						endif

					end

					2: begin ;\\ motion event
						if global.state.rbutton_down eq 1 then sdi_tag_edit, 'move', event.x, event.y
					end

					5: begin ;\\ ascii key press
						if event.release eq 1 then break
						print, string(event.ch)
					end

					6: begin ;\\ non-ascii key press
						if event.release eq 1 then break

						if event.key eq 5 then sdi_tag_change_file, 'previous'
						if event.key eq 6 then sdi_tag_change_file, 'next'

					end

					else:
				endcase

			end


			else:
		endcase

	endif

end

pro sdi_tag_edit, type, x, y

	common SDITag_Common, global

	if global.data.valid eq 0 then return

	res = convert_coord(x, y, /device, /to_data)

	case type of

		'click': begin ;\\ create new or edit existing

			editing_current = 0
			if (size(*global.tags, /type) ne 0) then begin

				for i = 0, n_elements(*global.tags) - 1 do begin

					if res[0] ge (*global.tags)[i].ut_start and $
					   res[0] le (*global.tags)[i].ut_end then begin

						print, i

					endif

				endfor

			endif



				new_tag = global.tag_template
				new_tag.site_code = (*global.data.meta).site_code
				new_tag.ut_start = res[0]
				new_tag.ut_end = res[0]

				if (size(*global.tags, /type) eq 0) then begin
					*global.tags = [new_tag]
				endif else begin
					*global.tags = [*global.tags, new_tag]
				endelse

				global.current_tag = n_elements(*global.tags) - 1



		end

		'release': begin ;\\ finalize existing

			if ((*global.tags)[global.current_tag].ut_end eq (*global.tags)[global.current_tag].ut_start) then begin
				sdi_tag_delete_tag, global.current_tag
				break
			endif

			if ((*global.tags)[global.current_tag].ut_end lt (*global.tags)[global.current_tag].ut_start) then begin
				temp = (*global.tags)[global.current_tag].ut_start
				(*global.tags)[global.current_tag].ut_start = (*global.tags)[global.current_tag].ut_end
				(*global.tags)[global.current_tag].ut_end = temp
				break
			endif



		end

		'move': begin ;\\ update existing

			(*global.tags)[global.current_tag].valid = 1
			(*global.tags)[global.current_tag].ut_end = res[0]

		end

		else:
	endcase

	if (global.state.rbutton_down) then sdi_tag_plot_winds
	print, 'Nels: ', n_elements(*global.tags)
end

pro sdi_tag_delete_tag, index

	common SDITag_Common, global

	tags = *global.tags
	if index eq 0 then begin
		if (n_elements(tags) eq 1) then begin
			ptr_free, global.tags
			global.tags = ptr_new(/alloc)
		endif else begin
			tags = tags[1:*]
			*global.tags = tags
		endelse
		return
	endif

	if index eq n_elements(tags) - 1 then begin
		tags = tags[0:n_elements(tags) - 2]
		*global.tags = tags
		return
	endif

	tags = [ tags[0:index-1], tags[index+1:*]]
	*global.tags = tags
end


pro sdi_tag_scan_dir

	common SDITag_Common, global

	files = file_search(global.state.current_dir + '\' + '*SKY*' + ['*.nc', '*.sky', '*.pf'], count = nfiles)
	*global.state.file_list = file_basename(files)
	widget_control, set_value = *global.state.file_list, global.gui.list
end


pro sdi_tag_change_file, direction

	common SDITag_Common, global

	if (direction eq 'next') then begin
		if (global.state.current_list_index lt n_elements(*global.state.file_list) - 1) then begin
			global.state.current_list_index++
		endif else begin
			global.state.current_list_index = 0
		endelse
	endif
	if (direction eq 'previous') then begin
		if (global.state.current_list_index gt 0) then begin
			global.state.current_list_index--
		endif else begin
			global.state.current_list_index = n_elements(*global.state.file_list) - 1
		endelse
	endif
	sdi_tag_load_file
end

pro sdi_tag_load_file

	common SDITag_Common, global

	fname = global.state.current_dir + '\' + (*global.state.file_list)[global.state.current_list_index]
	if file_test(fname) eq 0 then return

	sdi3k_read_netcdf_data, fname, meta = meta, winds = wind
	*global.data.meta = meta
	*global.data.wind = wind
	global.data.valid = 1
	sdi_tag_plot_winds

	widget_control, set_value = 'Current Filename: ' + fname, global.gui.filename_label
end

pro sdi_tag_plot_winds

	common SDITag_Common, global

	if global.data.valid eq 0 then return

	meta = *global.data.meta
	wind = *global.data.wind
	time = js2ut((wind.start_time[0] + wind.end_time[0])/2.)

	zonal = median(wind.zonal_wind, dimension=1)
	merid = median(wind.meridional_wind, dimension=1)

	yrange = [min([min(zonal), min(merid)]), max([max(zonal), max(merid)])]
	trange = [min(time), max(time)]

	bounds = split_page(2, 1, bounds=[.1, .1, .98, .98])

	plot, time, time*0, /nodata, xstyle=5, pos = bounds[0,0,*], yrange=yrange, /ystyle, ytitle = 'Zonal'
	oplot, trange, [0,0], line=1
	oplot, time, zonal, psym=-1, sym=.5

	top = (convert_coord(0, yrange[1], /data, /to_device))[1]

	plot, time, time*0, /nodata, xstyle=9, pos = bounds[1,0,*], /noerase, yrange=yrange, /ystyle, ytitle = 'Merid'
	oplot, trange, [0,0], line=1
	oplot, time, merid, psym=-1, sym=.5

	bottom = (convert_coord(0, yrange[0], /data, /to_device))[1]

	if (size(*global.tags, /type) ne 0) then begin

		for i = 0, n_elements(*global.tags) - 1 do begin

			tag = (*global.tags)[i]
			if tag.valid eq 0 then continue

			left = (convert_coord(tag.ut_start, 0, /data, /to_device))[0]
			right = (convert_coord(tag.ut_end, 0, /data, /to_device))[0]
			polyfill, [left, left, right, right], [bottom,top,top,bottom], /device, color = 50

		endfor

	endif

	plot, time, time*0, /nodata, xstyle=5, pos = bounds[0,0,*], yrange=yrange, /ystyle, ytitle = 'Zonal', /noerase
	oplot, trange, [0,0], line=1
	oplot, time, zonal, psym=-1, sym=.5

	plot, time, time*0, /nodata, xstyle=9, pos = bounds[1,0,*], /noerase, yrange=yrange, /ystyle, ytitle = 'Merid'
	oplot, trange, [0,0], line=1
	oplot, time, merid, psym=-1, sym=.5


end


pro sdi_tag_cleanup, arg

	common SDITag_Common, global

	heap_gc, /verbose

end

pro sdi_tag

	common SDITag_Common, global

	width = 900.
	height = 500.

	font = 'Ariel*16*Bold'
	base = widget_base(title = 'SDI Tag', col = 1, mbar = menubar, /tlb_size_events, uval = {tag:'base'})

	options = widget_button(menubar, value = 'Options')
	load_dir = widget_button(options, value = 'Select Directory', uval = {tag:'select_directory'})

	filename_label = widget_label(base, value = 'Current Filename:', font=font, xs = .5*width, /align_left)

	base0 = widget_base(base, col=2)

	list = widget_list(base0, font=font, scr_xsize = .25*width, scr_ysize = height, $
					   uval = {tag:'file_list'})

	draw = widget_draw(base0, xs = .75*width, ys = height, keyboard_events = 2, /button_events, /motion_events, $
					   uval = {tag:'draw'})

	widget_control, base, /realize
	widget_control, get_value = window_id, draw

	gui = {base:base, $
		   draw:draw, $
		   window_id:window_id, $
		   list:list, $
		   filename_label:filename_label, $
		   base_geom:widget_info(base, /geom), $
		   font:font }

	state = {current_dir:'c:\sdidata', $
			 current_list_index:0, $
			 file_list:ptr_new(/alloc), $
			 rbutton_down:0 }

	data = {valid:0, $
			meta:ptr_new(/alloc), $
			wind:ptr_new(/alloc) }

	tag_template = {site_code:'', $
				    filename:'', $
				    year:0, $
				    dayno:0, $
				    ut_start:0D, $
				    ut_end:0D, $
				    valid:0 }

	global = {gui:gui, $
			  state:state, $
			  data:data, $
			  tag_template:tag_template, $
			  tags:ptr_new(/alloc), $
			  current_tag:0 }

	sdi_tag_scan_dir
	sdi_tag_load_file

	xmanager, 'sdi_tag', base, event = 'sdi_tag_event', cleanup = 'sdi_tag_cleanup', /no_block

end