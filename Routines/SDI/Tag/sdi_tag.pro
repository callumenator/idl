

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


			'filename_filter': begin
				filter = global.state.filename_filter
				xvaredit, filter, group = global.gui.base, name = 'Set New Filter'
				global.state.filename_filter = filter
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
						if global.state.rbutton_down eq 1 then sdi_tag_edit, 'move', event.x, event.y $
							else sdi_tag_edit, 'update_cursor', event.x, event.y
					end

					5: begin ;\\ ascii key press
						if event.release eq 1 then break

						if event.ch eq 127 then begin ;\\ delete
							if (global.state.tag_list_selected ge 0) then begin
								sdi_tag_delete_tag, global.state.tag_list_selected
								global.state.tag_list_selected = -1
								sdi_tag_plot_winds
								sdi_tag_update_taglist
							endif
						endif

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


				new_tag = global.tag_template
				new_tag.site_code = (*global.data.meta).site_code
				new_tag.year = global.data.year
				new_tag.dayno = global.data.dayno
				new_tag.lambda = (*global.data.meta).wavelength_nm
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
				;sdi_tag_plot_winds
				break
			endif

			;\\ Check for end time greater than start time, and reverse them
			if ((*global.tags)[global.current_tag].ut_end lt (*global.tags)[global.current_tag].ut_start) then begin
				temp = (*global.tags)[global.current_tag].ut_start
				(*global.tags)[global.current_tag].ut_start = (*global.tags)[global.current_tag].ut_end
				(*global.tags)[global.current_tag].ut_end = temp
			endif

			;\\ Check for range greater than time range, and adjust
			time = *global.data.time
			if ((*global.tags)[global.current_tag].ut_end gt max(time)) then $
				(*global.tags)[global.current_tag].ut_end = max(time)
			if ((*global.tags)[global.current_tag].ut_start lt min(time)) then $
				(*global.tags)[global.current_tag].ut_start = min(time)

			;\\ Check for overlap with other tags and merge if overlapping
			sdi_tag_merge_overlaps, newIndex
			global.current_tag = newIndex

			;\\ If cloud type tag, generate an offset
			tag = (*global.tags)[global.current_tag]
			pts = where(*global.data.time ge tag.ut_start and $
						*global.data.time le tag.ut_end, npts)
			sub = (*global.data.spek)[pts].velocity
			*(*global.tags)[global.current_tag].offset = median(sub, dim=2)

			sdi_tag_plot_winds

		end

		'move': begin ;\\ update existing

			(*global.tags)[global.current_tag].valid = 1
			(*global.tags)[global.current_tag].ut_end = res[0]
			sdi_tag_plot_winds

			plots, /device, [x,x], [0,1000], line=1
			xyouts, .05, .05, string(res[0], f='(f0.2)'), /normal

		end

		'update_cursor': begin ;\\ update existing

			if (size(*global.gui.draw_cache, /type) ne 0) then begin
				wset, global.gui.window_id
				device, decomposed = 1
				tv, *global.gui.draw_cache, /true
				device, decomposed = 0
				plots, /device, [x,x], [0,1000], line=1
				xyouts, .05, .05, string(res[0], f='(f0.2)'), /normal
			endif else begin
				sdi_tag_plot_winds
			endelse

		end

		else:
	endcase

end


function sdi_tag_js2ut, js

	js2ymds, double(js), y, m, d, s
	xvals = (s/3600.)

	if not keyword_set(wraptimes) then begin
		xvals += (d-d[0])*24.
	endif

	return, xvals

end


;\\ After merging other ranges into the current one, return the current one's new index in newIndex
pro sdi_tag_merge_overlaps, newIndex

	common SDITag_Common, global

	MERGE_START:

	if (size(*global.tags, /type) eq 0) then return
	tags = *global.tags

	if (size(look_for, /type) eq 0) then begin
		x = global.current_tag
	endif else begin
		pt = where(tags.ut_start eq look_for.ut_start and $
				   tags.ut_end eq look_for.ut_end, npt)
		x = pt[0]
	endelse

	for y = 0, n_elements(tags) - 1 do begin

		if (y eq x) then continue

		notover = tags[x].ut_end lt tags[y].ut_start or $
				  tags[x].ut_start gt tags[y].ut_end

		if not notover then begin
			(*global.tags)[x].ut_start = min([tags[x].ut_start, tags[y].ut_start])
			(*global.tags)[x].ut_end = max([tags[x].ut_end, tags[y].ut_end])
			look_for = (*global.tags)[x]
			sdi_tag_delete_tag, y
			goto, MERGE_START
		endif
	endfor

	if (size(look_for, /type) eq 0) then begin
		newIndex = global.current_tag
	endif else begin
		newIndex = (where(tags.ut_start eq look_for.ut_start and $
				    	  tags.ut_end eq look_for.ut_end, npt))[0]
	endelse

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

	files = file_search(global.state.current_dir + '\' + global.state.filename_filter + ['*.nc', '*.sky', '*.pf'], count = nfiles)
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

	sdi3k_read_netcdf_data, fname, meta = meta, winds = wind, spek=spek

	if (size(wind, /type) ne 8) then return
	if (size(meta, /type) ne 8) then return
	if (size(spek, /type) ne 8) then return

	;\\ First save current state
	if (global.data.valid eq 1) then sdi_tag_save_daydata

	widget_control, set_list_select = global.state.current_list_index, global.gui.list

	*global.data.meta = meta
	*global.data.wind = wind
	*global.data.spek = spek
	*global.data.time = sdi_tag_js2ut((wind.start_time[0] + wind.end_time[0])/2.)
	*global.data.med_zonal = median(wind.zonal_wind, dimension=1)
	*global.data.med_merid = median(wind.meridional_wind, dimension=1)

	js2ymds, (*global.data.meta).start_time[0], y, m, d, s
	global.data.year = y
	global.data.dayno = ymd2dn(y, m, d)

	global.data.valid = 1

	ptr_free, global.tags
	global.tags = ptr_new(/alloc)
	sdi_tag_restore_daydata

	widget_control, set_value = 'Current Filename: ' + fname, global.gui.filename_label
	sdi_tag_plot_winds
	sdi_tag_update_taglist
end

pro sdi_tag_plot_winds

	common SDITag_Common, global

	if global.data.valid eq 0 then return

	wset, global.gui.window_id
	erase, 0

	meta = *global.data.meta
	wind = *global.data.wind
	time = *global.data.time
	zonal = *global.data.med_zonal
	merid = *global.data.med_merid

	yrange = [min([min(zonal), min(merid)]), max([max(zonal), max(merid)])]
	trange = [min(time), max(time)]

	bounds = split_page(2, 1, bounds=[.1, .1, .98, .98])
	top = bounds[0,0,3]
	bottom = bounds[1,0,1]

	plot, time, time, pos = bounds[0,0,*], /nodata, xstyle=5, ystyle=5

	if (size(*global.tags, /type) ne 0) then begin

		for i = 0, n_elements(*global.tags) - 1 do begin

			tag = (*global.tags)[i]
			if tag.valid eq 0 then continue

			left = (convert_coord(tag.ut_start, 0, /data, /to_normal))[0]
			right = (convert_coord(tag.ut_end, 0, /data, /to_normal))[0]
			polyfill, [left, left, right, right], [bottom,top,top,bottom], /normal, color = 100

		endfor

	endif

	plot, time, time*0, /nodata, xstyle=5, pos = bounds[0,0,*], yrange=yrange, /ystyle, ytitle = 'Zonal', /noerase
	oplot, trange, [0,0], line=1
	oplot, time, zonal, psym=-1, sym=.5

	plot, time, time*0, /nodata, xstyle=9, pos = bounds[1,0,*], /noerase, yrange=yrange, /ystyle, ytitle = 'Merid'
	oplot, trange, [0,0], line=1
	oplot, time, merid, psym=-1, sym=.5

	*global.gui.draw_cache = tvrd(/true)

end

pro sdi_tag_save_daydata

	common SDITag_Common, global

	if (file_test(global.state.save_file) eq 1) then begin
		restore, global.state.save_file
	endif

	site = (*global.data.meta).site_code

	if (size(tags, /type) eq 0) then begin

		if (size(*global.tags, /type) ne 0) then begin
			tags = *global.tags
		endif else begin
			if (file_test(global.state.save_file) eq 1) then begin
				file_delete, global.state.save_file
				return
			endif
		endelse

	endif else begin

		pts = where(tags.site_code eq site and $
					tags.year eq global.data.year and $
					tags.dayno eq global.data.dayno and $
					tags.lambda eq (*global.data.meta).wavelength_nm, nmatch, complement = compts, ncomp = ncompts)

		if (size(*global.tags, /type) ne 0) then begin
			if (ncompts gt 0) then begin
				tags = [tags[compts], *global.tags]
			endif else begin
				tags = *global.tags
			endelse
		endif else begin
			if (ncompts gt 0) then begin
				tags = [tags[compts]]
			endif else begin
				if (file_test(global.state.save_file) eq 1) then begin
					file_delete, global.state.save_file
					return
				endif
			endelse
		endelse
	endelse

	save, file = global.state.save_file, tags

end

pro sdi_tag_restore_daydata

	common SDITag_Common, global

	if (file_test(global.state.save_file) eq 1) then begin
		restore, global.state.save_file
	endif else begin
		return
	endelse

	if (size(tags, /type) eq 0) then return

	site = (*global.data.meta).site_code

	pts = where(tags.site_code eq site and $
				tags.year eq global.data.year and $
				tags.dayno eq global.data.dayno and $
				tags.lambda eq (*global.data.meta).wavelength_nm, nmatch)


	if nmatch eq 0 then return

	*global.tags = tags[pts]

end


pro sdi_tag_cleanup, arg

	common SDITag_Common, global
	sdi_tag_save_daydata
	heap_gc, /verbose
end

pro sdi_tag

	common SDITag_Common, global

	whoami, home_dir, file
	save_file = home_dir + 'tag.idlsave'

	width = 1200.
	height = 500.

	font = 'Ariel*16*Bold'
	base = widget_base(title = 'SDI Tag', col = 1, mbar = menubar, /tlb_size_events, uval = {tag:'base'})

	options = widget_button(menubar, value = 'Options')
	load_dir = widget_button(options, value = 'Select Directory', uval = {tag:'select_directory'})
	file_filter = widget_button(options, value = 'Set Filename Filter', uval = {tag:'filename_filter'})

	filename_label = widget_label(base, value = 'Current Filename:', font=font, xs = .5*width, /align_left)

	base0 = widget_base(base, col=3)

	list = widget_list(base0, font=font, scr_xsize = .35*width, scr_ysize = height, $
					   uval = {tag:'file_list'})

	draw = widget_draw(base0, xs = .5*width, ys = height, keyboard_events = 2, /button_events, /motion_events, $
					   uval = {tag:'draw'})

	tag_base = widget_base(base0, col=1)
	tag_list = widget_list(tag_base, font=font, scr_xsize = .15*width, scr_ysize = height - 35, $
					   uval = {tag:'tag_list'})
	del_button = widget_button(tag_base, value = 'Delete Tag', font=font, uval = {tag:'delete_tag'})


	widget_control, base, /realize
	widget_control, get_value = window_id, draw


	gui = {base:base, $
		   draw:draw, $
		   window_id:window_id, $
		   draw_cache:ptr_new(/alloc), $
		   list:list, $
		   tag_list:tag_list, $
		   filename_label:filename_label, $
		   base_geom:widget_info(base, /geom), $
		   font:font }

	state = {current_dir:'c:\cal\testdata_mine', $
			 current_list_index:0, $
			 file_list:ptr_new(/alloc), $
			 rbutton_down:0, $
			 tag_list_selected:-1, $
			 save_file:save_file, $
			 filename_filter:'*SKY*6300*'}

	data = {valid:0, $
			year:0, $
			dayno:0, $
			meta:ptr_new(/alloc), $
			wind:ptr_new(/alloc), $
			spek:ptr_new(/alloc), $
			time:ptr_new(/alloc), $
			med_zonal:ptr_new(/alloc), $
			med_merid:ptr_new(/alloc) }

	tag_template = {type:'cloud', $
					site_code:'', $
				    year:0, $
				    dayno:0, $
				    lambda:0.0, $
				    ut_start:0D, $
				    ut_end:0D, $
				    offset:ptr_new(/alloc), $
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
