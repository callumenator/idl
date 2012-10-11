

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

			'tag_list': begin
				global.state.tag_list_selected = event.index
			end

			'delete_tag': begin
				if (global.state.tag_list_selected ge 0) then begin
					sdi_tag_delete_tag, global.state.tag_list_selected
					global.state.tag_list_selected = -1
					sdi_tag_plot_winds
					sdi_tag_update_taglist
				endif
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

						widget_control, set_list_select = i, global.gui.tag_list
						global.state.tag_list_selected = i

					endif

				endfor

			endif

				js2ymds, (*global.data.meta).start_time[0], y, m, d, s
				dayno = ymd2dn(y, m, d)

				new_tag = global.tag_template
				new_tag.site_code = (*global.data.meta).site_code
				new_tag.year = y
				new_tag.dayno = dayno
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

			;\\ Check for zero (and small) length tag and delete
			if abs((*global.tags)[global.current_tag].ut_end - (*global.tags)[global.current_tag].ut_start) lt 5./60. then begin
				sdi_tag_delete_tag, global.current_tag
				sdi_tag_plot_winds
				break
			endif

			;\\ Check for end time greater than start time, and reverse them
			if ((*global.tags)[global.current_tag].ut_end lt (*global.tags)[global.current_tag].ut_start) then begin
				temp = (*global.tags)[global.current_tag].ut_start
				(*global.tags)[global.current_tag].ut_start = (*global.tags)[global.current_tag].ut_end
				(*global.tags)[global.current_tag].ut_end = temp
			endif

			;\\ Check for range greater than time range, and adjust
			time = js2ut( ((*global.data.wind).start_time[0] + (*global.data.wind).end_time[0])/2.)
			if ((*global.tags)[global.current_tag].ut_end gt max(time)) then $
				(*global.tags)[global.current_tag].ut_end = max(time)
			if ((*global.tags)[global.current_tag].ut_start lt min(time)) then $
				(*global.tags)[global.current_tag].ut_start = min(time)


			;\\ Check for overlap with other tags and merge if overlapping
			sdi_tag_merge_overlaps

			sdi_tag_plot_winds

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


pro sdi_tag_merge_overlaps

	common SDITag_Common, global

	MERGE_START:

	if (size(*global.tags, /type) eq 0) then return
	tags = *global.tags

	for x = 0, n_elements(tags) - 1 do begin
	for y = x+1, n_elements(tags) - 1 do begin

		notover = tags[x].ut_end lt tags[y].ut_start or $
				  tags[x].ut_start gt tags[y].ut_end

		if not notover then begin
			(*global.tags)[x].ut_start = min([tags[x].ut_start, tags[y].ut_start])
			(*global.tags)[x].ut_end = max([tags[x].ut_end, tags[y].ut_end])
			sdi_tag_delete_tag, y
			goto, MERGE_START
		endif
	endfor
	endfor
	sdi_tag_update_taglist
end

pro sdi_tag_update_taglist

	common SDITag_Common, global


	if (size(*global.tags, /type) eq 0) then begin
		widget_control, set_value = [''], global.gui.tag_list
	endif else begin
		tags = *global.tags
		list = string(tags.ut_start, f='(f0.2)') + ' - ' + string(tags.ut_end, f='(f0.2)') + $
			   ' ' + tags.site_code + ' ' + string(tags.dayno, f='(i03)')
		widget_control, set_value = list, global.gui.tag_list
	endelse

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
	sdi_tag_update_taglist
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

	;\\ First save current state
	sdi_tag_save_daydata

	fname = global.state.current_dir + '\' + (*global.state.file_list)[global.state.current_list_index]
	if file_test(fname) eq 0 then return

	sdi3k_read_netcdf_data, fname, meta = meta, winds = wind
	*global.data.meta = meta
	*global.data.wind = wind
	global.data.valid = 1

	ptr_free, global.tags
	global.tags = ptr_new(/alloc)

	widget_control, set_value = 'Current Filename: ' + fname, global.gui.filename_label
	sdi_tag_plot_winds
	sdi_tag_update_taglist
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

pro sdi_tag_save_daydata

	common SDITag_Common, global

	if (file_test(global.state.save_file) eq 1) then begin
		restore, global.state.save_file
	endif

	site = (*global.data.meta).site

	if (size(tags.site, /type) eq 0) then begin

	endif else begin
		saved = tag_names(tags)
		outstruc = 'tags = {'

		pts = where(saved ne site, npts)
		for i = 0, npts - 1 do begin
			outstruc += ' ' + saved[i] + ':tags.' + saved[i]
			if (i lt npts - 1) then outstruc += ', '
		endfor

		if (size(*global.tags, /type) ne 0) then begin
			outstruc += site + ':*global.tags}'
		endif else begin
			outstruct += '}'
		endelse
		print, outstruc
		;res = execute(outstruc)


	endelse

end


pro sdi_tag_cleanup, arg

	common SDITag_Common, global
	heap_gc, /verbose
end

pro sdi_tag

	common SDITag_Common, global

	whoami, home_dir, file
	save_file = home_dir + 'tag.idlsave'

	width = 900.
	height = 500.

	font = 'Ariel*16*Bold'
	base = widget_base(title = 'SDI Tag', col = 1, mbar = menubar, /tlb_size_events, uval = {tag:'base'})

	options = widget_button(menubar, value = 'Options')
	load_dir = widget_button(options, value = 'Select Directory', uval = {tag:'select_directory'})

	filename_label = widget_label(base, value = 'Current Filename:', font=font, xs = .5*width, /align_left)

	base0 = widget_base(base, col=3)

	list = widget_list(base0, font=font, scr_xsize = .2*width, scr_ysize = height, $
					   uval = {tag:'file_list'})

	draw = widget_draw(base0, xs = .7*width, ys = height, keyboard_events = 2, /button_events, /motion_events, $
					   uval = {tag:'draw'})

	tag_base = widget_base(base0, col=1)
	tag_list = widget_list(tag_base, font=font, scr_xsize = .1*width, scr_ysize = height - 35, $
					   uval = {tag:'tag_list'})
	del_button = widget_button(tag_base, value = 'Delete Tag', font=font, uval = {tag:'delete_tag'})


	widget_control, base, /realize
	widget_control, get_value = window_id, draw

	gui = {base:base, $
		   draw:draw, $
		   window_id:window_id, $
		   list:list, $
		   tag_list:tag_list, $
		   filename_label:filename_label, $
		   base_geom:widget_info(base, /geom), $
		   font:font }

	state = {current_dir:'c:\sdidata', $
			 current_list_index:0, $
			 file_list:ptr_new(/alloc), $
			 rbutton_down:0, $
			 tag_list_selected:-1, $
			 save_file:save_file}

	data = {valid:0, $
			meta:ptr_new(/alloc), $
			wind:ptr_new(/alloc) }

	tag_template = {site_code:'', $
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