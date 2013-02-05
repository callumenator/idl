

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

			'plot_tags': begin
				sdi_tag_plot_tags
			end

			'tagtype_edit': begin
				widget_control, get_value = tag_type, event.id
				global.state.tag_type = tag_type
			end

			'operator_edit': begin
				widget_control, get_value = operator, event.id
				global.state.operator = operator
			end

			'show_skymaps': begin
				sdi_tag_show_skymaps
			end

			'file_list': begin
				global.state.current_list_index = event.index
				sdi_tag_load_file
			end

			'tag_list': begin
				global.state.tag_list_selected = event.index
				sdi_tag_update_tag_edit
			end

			'tag_edit': begin
				sdi_tag_refresh_tag
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
							if global.state.preview_mode eq 1 then begin
								sdi_tag_load_file, /no_preview
							endif
						endif
						if event.press eq 4 then begin ;\\ right button press
							global.state.rbutton_down = 1
							sdi_tag_edit, 'click', event.x, event.y
						endif

					end

					1: begin ;\\ button release

						if event.release eq 4 then begin ;\\ right button release
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


;\\ Tag creation, update, finalize
pro sdi_tag_edit, type, x, y

	common SDITag_Common, global

	if global.data.valid eq 0 then return
	if global.state.preview_mode eq 1 then return

	res = convert_coord(x, y, /device, /to_data)

	case type of

		'click': begin ;\\ create new or edit existing

			;\\ If we clicked inside a current tag, select it in the tag list
			if global.have_tags eq 1 then begin

				for i = 0, n_elements(*global.tags) - 1 do begin

					if res[0] ge (*global.tags)[i].ut_start and $
					   res[0] le (*global.tags)[i].ut_end then begin

						widget_control, set_list_select = i, global.gui.tag_list
						global.state.tag_list_selected = i
						sdi_tag_update_tag_edit
						tag = (*global.tags)[i]
					endif

				endfor

			endif

			;\\ Create the new tag
			new_tag = global.tag_template
			new_tag.positions = ptr_new(/alloc)
			new_tag.metadata = ptr_new(/alloc)

			*new_tag.metadata = *global.data.meta
			new_tag.type = global.state.tag_type
			new_tag.operator = global.state.operator
			new_tag.site_code = (*global.data.meta).site_code
			new_tag.quality = -1
			new_tag.year = global.data.year
			new_tag.dayno = global.data.dayno
			new_tag.filename = global.state.current_dir + '\' + (*global.state.file_list)[global.state.current_list_index]
			new_tag.lambda = (*global.data.meta).wavelength_nm
			new_tag.ut_start = res[0]
			new_tag.ut_end = res[0]

			if global.have_tags eq 0 then begin
				*global.tags = [new_tag]
			endif else begin
				*global.tags = [*global.tags, new_tag]
			endelse

			global.have_tags = 1
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
			time = *global.data.time
			if ((*global.tags)[global.current_tag].ut_end gt max(time)) then $
				(*global.tags)[global.current_tag].ut_end = max(time)
			if ((*global.tags)[global.current_tag].ut_start lt min(time)) then $
				(*global.tags)[global.current_tag].ut_start = min(time)

			;\\ Check for overlap with other tags and merge if overlapping
			sdi_tag_merge_overlaps, newIndex

			global.current_tag = newIndex
			(*global.tags)[global.current_tag].js_created = dt_tm_tojs(systime(/ut))


			;\\ Store the position info for the time range
			tag = (*global.tags)[global.current_tag]
			pts = where(*global.data.time ge tag.ut_start and $
						*global.data.time le tag.ut_end, npts)

			if npts gt 0 then begin
				*(*global.tags)[global.current_tag].positions = (*global.data.spek)[pts].velocity

				;\\ Save js time range
				js_mid = ((*global.data.wind).start_time + (*global.data.wind).end_time) /2.
				(*global.tags)[global.current_tag].js_start = js_mid[min(pts)]
				(*global.tags)[global.current_tag].js_end = js_mid[max(pts)]
			endif

			global.have_tags = 1
			sdi_tag_plot_winds

		end

		'move': begin ;\\ update existing

			(*global.tags)[global.current_tag].valid = 1
			(*global.tags)[global.current_tag].ut_end = res[0]
			sdi_tag_plot_winds

			plots, /device, [x,x], [0,1000], line=1
			xyouts, .05, .05, 'Time: ' + string(res[0], f='(f0.2)') + ' UT', /normal

		end

		'update_cursor': begin ;\\ update existing

			if (size(*global.gui.draw_cache, /type) ne 0) then begin
				wset, global.gui.window_id
				device, decomposed = 1
				tv, *global.gui.draw_cache, /true
				device, decomposed = 0
				plots, /device, [x,x], [0,1000], line=1
				xyouts, .05, .05, 'Time: ' + string(res[0], f='(f0.2)') + ' UT', /normal
			endif else begin
				sdi_tag_plot_winds
			endelse

		end

		else:
	endcase

end


;\\ Convert js to ut
function sdi_tag_js2ut, js
	js2ymds, double(js), y, m, d, s
	xvals = (s/3600.)
	xvals += (d-d[0])*24.
	return, xvals
end


;\\ After merging other ranges into the current one, return the current one's new index in newIndex
pro sdi_tag_merge_overlaps, newIndex

	common SDITag_Common, global

	MERGE_START:

	newIndex = global.current_tag
	if global.have_tags eq 0 then return
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


;\\ Update the widget list containing the list of current tags
pro sdi_tag_update_taglist

	common SDITag_Common, global

	if global.have_tags eq 0 then begin
		widget_control, set_value = [''], global.gui.tag_list
	endif else begin
		tags = *global.tags
		list = string(tags.ut_start, f='(f0.2)') + ' - ' + string(tags.ut_end, f='(f0.2)') + $
			   ' ' + tags.site_code + ' ' + string(tags.dayno, f='(i03)') + ' ' + tags.type
		widget_control, set_value = list, global.gui.tag_list
	endelse
end


;\\ Delete a tag
pro sdi_tag_delete_tag, index

	common SDITag_Common, global

	tags = *global.tags
	if index eq 0 then begin
		if (n_elements(tags) eq 1) then begin
			global.have_tags = 0
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


;\\ Update the tag edit box with current tag info
pro sdi_tag_update_tag_edit

	common SDITag_Common, global

	if global.have_tags eq 0 then return
	tags = *global.tags
	ctag = tags[global.state.tag_list_selected]
	widget_control, set_value = ctag, global.gui.tag_edit
end


;\\ Called when a current tag is edited
pro sdi_tag_refresh_tag

	common SDITag_Common, global

	if global.have_tags eq 0 then return
	widget_control, get_value = ctag, global.gui.tag_edit
	(*global.tags)[global.state.tag_list_selected] = ctag
	sdi_tag_update_taglist
	sdi_tag_plot_winds
end


;\\ Scan a directory for files
pro sdi_tag_scan_dir

	common SDITag_Common, global

	files = file_search(global.state.current_dir + '\' + global.state.filename_filter + ['*.nc', '*.sky', '*.pf'], count = nfiles)
	*global.state.file_list = file_basename(files)
	widget_control, set_value = *global.state.file_list, global.gui.list
end


;\\ Change the currently selected file
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


;\\ Load a new file
pro sdi_tag_load_file, no_preview=no_preview ;\\ set to force using real winds, not image preview

	common SDITag_Common, global
	heap_gc

	;\\ First save current state
	if (global.data.valid eq 1) then sdi_tag_save_daydata

	fname = global.state.current_dir + '\' + (*global.state.file_list)[global.state.current_list_index]
	if file_test(fname) eq 0 or file_test(fname, /directory) eq 1 then return

	;\\ Create the name of the corresponding image, and look for that first
	sdi3k_read_netcdf_data, fname, meta = meta
	if not keyword_set(no_preview) then begin
		pic_dir = global.state.pic_directory + '\' + $
				  dt_tm_fromjs(meta.start_time, format='Y$_'+meta.site_code+'_'+$
				  			   string(meta.wavelength_nm*10, f='(i04)')) + '\Wind_Summary\'
		pic_name = dt_tm_fromjs(meta.start_time, format='Wind_Summary_'+meta.site_code+'_Y$_DOYdoy$_'+$
								string(meta.wavelength_nm*10, f='(i04)')) + '.png'

		if file_test(pic_dir + pic_name) then begin
			global.state.preview_mode = 1
			global.state.current_pic = ptr_new( read_png(pic_dir+pic_name) )
			goto, SDI_TAG_POST_LOAD
		endif
	endif

	ptr_free, global.state.current_pic
	global.state.preview_mode = 0
	sdi3k_read_netcdf_data, fname, winds=wind, spek=spek

	if (size(wind, /type) ne 8) then return
	if (size(meta, /type) ne 8) then return
	if (size(spek, /type) ne 8) then return

	widget_control, set_list_select = global.state.current_list_index, global.gui.list

	*global.data.wind = wind
	*global.data.spek = spek
	*global.data.time = sdi_tag_js2ut((wind.start_time[0] + wind.end_time[0])/2.)
	*global.data.med_zonal = median(wind.zonal_wind, dimension=1)
	*global.data.med_merid = median(wind.meridional_wind, dimension=1)

	global.data.valid = 1

SDI_TAG_POST_LOAD:
	js2ymds, meta.start_time[0], y, m, d, s
	global.data.year = y
	global.data.dayno = ymd2dn(y, m, d)
	*global.data.meta = meta

	global.have_tags = 0
	sdi_tag_restore_daydata

	widget_control, set_value = 'Current Filename: ' + fname, global.gui.filename_label
	sdi_tag_plot_winds
	sdi_tag_update_taglist
end


;\\ Pop up a window showing the RGB skymaps for the current day
pro sdi_tag_show_skymaps

	common SDITag_Common, global

	;\\ First save current state
	if size(*global.data.meta, /type) eq 0 then return

	fname = global.state.current_dir + '\' + (*global.state.file_list)[global.state.current_list_index]
	if file_test(fname) eq 0 or file_test(fname, /directory) eq 1 then return

	;\\ Create the name of the corresponding image, and look for that first
	meta = *global.data.meta

	pic_dir = global.state.pic_directory + '\' + $
			  dt_tm_fromjs(meta.start_time, format='Y$_'+meta.site_code+'_'+$
			  			   string(meta.wavelength_nm*10, f='(i04)')) + '\Temperature_Brightness_RGB_Skymap\'
	pic_name = dt_tm_fromjs(meta.start_time, format='Temperature_Brightness_RGB_Skymap_'+meta.site_code+'_Y$_DOYdoy$_'+$
							string(meta.wavelength_nm*10, f='(i04)')) + '.png'

	if file_test(pic_dir + pic_name) then begin
		image = read_png(pic_dir+pic_name)
		dims = size(image, /dimensions)
		dmax = dims[1] > dims[2]
		scale = 800. / dmax
		base = widget_base(col=1)
		draw = widget_draw(base, xs = dims[1], ys=dims[2], scr_xs=800, scr_ys=800, /scroll)
		widget_control, /realize, base
		widget_control, get_value = id, draw
		wset, id
		tv, image, /true
	endif
end


function sdi_tag_split_page, nrows, ncolumns, $
					 bounds = bounds, $
					 row_gap = row_gap, $
					 col_gap = col_gap, $
					 col_percents = col_percents, $
					 row_percents = row_percents

	if not keyword_set(bounds) then bounds = [.1,.1,.98,.98]
	if n_elements(row_gap) eq 0 then row_gap = .1
	if n_elements(col_gap) eq 0 then col_gap = .1

	ob = fltarr(nrows, ncolumns, 4)

	fwidth = bounds[2] - bounds[0]
	fheight = bounds[3] - bounds[1]

	if keyword_set(col_percents) then begin
		if n_elements(col_percents) eq ncolumns then begin
			col_percents = float(col_percents) / total(col_percents)
			fcolWidth = fwidth*col_percents
		endif
	endif else begin
		fcolWidth = replicate( fwidth/float(ncolumns), ncolumns)
	endelse

	if keyword_set(row_percents) then begin
		if n_elements(row_percents) eq nrows then begin
			row_percents = float(row_percents) / total(row_percents)
			frowWidth = fheight*row_percents
		endif
	endif else begin
		frowWidth = replicate( fheight/float(nrows), nrows)
	endelse

	colWidth = fcolWidth - col_gap/2.
	rowWidth = frowWidth - row_gap/2.

	for r = 0, nrows - 1 do begin
		for c = 0, ncolumns - 1 do begin
			xc = bounds[0] + total(fcolWidth[0:c]) - fcolWidth[c]/2.
			yc = bounds[3] - total(frowWidth[0:r]) + frowWidth[r]/2.
			x0 = xc - colWidth[c]/2.
			x1 = xc + colWidth[c]/2.
			y0 = yc - rowWidth[r]/2.
			y1 = yc + rowWidth[r]/2.
			ob[r,c,*] = [x0,y0,x1,y1]
		endfor
	endfor

	return, ob
end


;\\ Update the zonal and meridional wind plot for the currently selected day
pro sdi_tag_plot_winds

	common SDITag_Common, global

	if ptr_valid(global.state.current_pic) then begin
		wset, global.gui.window_id
		geom = widget_info(global.gui.draw, /geom)
		tv, congrid(*global.state.current_pic, 3, geom.xsize, geom.ysize, /interp), /true
		return
	endif
	if global.data.valid eq 0 then return

	wset, global.gui.window_id
	erase, 0

	meta = *global.data.meta
	wind = *global.data.wind
	time = *global.data.time
	zonal = *global.data.med_zonal
	merid = *global.data.med_merid
	if n_elements(time) lt 2 then return

	;yrange = [min([min(zonal), min(merid)]), max([max(zonal), max(merid)])]
	yrange = [-200, 200]
	trange = [min(time), max(time)]

	bounds = sdi_tag_split_page(2, 1, bounds=[.1, .1, .98, .98])
	top = bounds[0,0,3]
	bottom = bounds[1,0,1]

	plot, time, time, pos = bounds[0,0,*], /nodata, xstyle=5, ystyle=5

	if global.have_tags eq 1 then begin

		for i = 0, n_elements(*global.tags) - 1 do begin

			tag = (*global.tags)[i]
			if tag.valid eq 0 then continue

			left = (convert_coord(tag.ut_start, 0, /data, /to_normal))[0]
			right = (convert_coord(tag.ut_end, 0, /data, /to_normal))[0]
			polyfill, [left, left, right, right], [bottom,top,top,bottom], /normal, color = 100

		endfor
	endif

	title = dt_tm_fromjs(wind[0].start_time[0], format='d$ N$ Y$')

	plot, time, time*0, /nodata, xstyle=5, pos = bounds[0,0,*], yrange=yrange, $
		  /ystyle, ytitle = 'Zonal', /noerase, title = title
	oplot, trange, [0,0], line=1
	oplot, time, zonal, psym=-1, sym=.5, noclip=1

	plot, time, time*0, /nodata, xstyle=9, pos = bounds[1,0,*], /noerase, yrange=yrange, /ystyle, ytitle = 'Merid'
	oplot, trange, [0,0], line=1
	oplot, time, merid, psym=-1, sym=.5, noclip=1

	*global.gui.draw_cache = tvrd(/true)
end



;\\ Save the current tag data
pro sdi_tag_save_daydata

	common SDITag_Common, global

	if global.data.valid eq 0 then return

	if (file_test(global.state.save_file) eq 1) then begin
		restore, global.state.save_file
	endif

	site = (*global.data.meta).site_code

	if (size(tags, /type) eq 0) then begin

		if global.have_tags eq 1 then begin
			tags = *global.tags
		endif else begin
			if (file_test(global.state.save_file) eq 1) then file_delete, global.state.save_file
			return
		endelse

	endif else begin

		pts = where(tags.site_code eq site and $
					tags.year eq global.data.year and $
					tags.dayno eq global.data.dayno and $
					tags.lambda eq (*global.data.meta).wavelength_nm, nmatch, complement = compts, ncomp = ncompts)

		if global.have_tags eq 1 then begin
			if (ncompts gt 0) then begin
				tags = [tags[compts], *global.tags]
			endif else begin
				tags = *global.tags
			endelse
		endif else begin
			if (ncompts gt 0) then begin
				tags = [tags[compts]]
			endif else begin
				if (file_test(global.state.save_file) eq 1) then file_delete, global.state.save_file
				return
			endelse
		endelse
	endelse

	info = {current_dir:global.state.current_dir}
	save, file = global.state.save_file, tags, info

end


;\\ Restore the tag database
pro sdi_tag_restore_daydata

	common SDITag_Common, global

	if (file_test(global.state.save_file) eq 1) then begin
		restore, global.state.save_file
	endif else begin
		return
	endelse

	if (size(tags, /type) eq 0) then return

	if size(*global.data.meta, /type) ne 0 then begin
		site = (*global.data.meta).site_code

		pts = where(tags.site_code eq site and $
					tags.year eq global.data.year and $
					tags.dayno eq global.data.dayno and $
					tags.lambda eq (*global.data.meta).wavelength_nm, nmatch)

		global.have_tags = nmatch ne 0
		print, 'Have tags: ' + string(global.have_tags, f='(i0)')
		if nmatch eq 0 then return
		*global.tags = tags[pts]
	endif

	global.state.current_dir = info.current_dir
end


;\\ Plot a time series of where tags occur
pro sdi_tag_plot_tags

	common SDITag_Common, global

	if (file_test(global.state.save_file) eq 1) then begin
		restore, global.state.save_file
	endif else begin
		return
	endelse

	if (size(tags, /type) eq 0) then return

	sites = tags.site_code
	usites = sites[sort(sites)]
	usites = usites[uniq(usites)]
	loadct, 39, /silent

	;\\ Make 0ne year = 300 pix
	pix_per_year = 500
	js_range = [min(tags.js_start), max(tags.js_end)]
	js2ymds, js_range, y, m, d, s
	xpix = ((y[1] - y[0]) + 1)*pix_per_year
	xpix = xpix > 800

	base = widget_base(col=1)
	draw = widget_draw(base, xs = xpix, ys=600, scr_xs=800, scr_ys=650, /scroll)
	widget_control, /realize, base
	widget_control, get_value = id, draw
	c_wind = !D.WINDOW
	wset, id

	blank = replicate(' ', 20)
	plot, js_range, [0, n_elements(usites) + 1], /nodata, /ystyle, xrange=js_range, $
		  xtickname=blank, xtick_get=xvals, ytickname=[' ', usites, ' ']

	js2ymds, xvals, xy, xm, xd, xs
	xticks = string(xy, f='(i4)') + '!C' + $
			 string(xm, f='(i02)') + '/' + $
			 string(xd, f='(i02)') + '!C' + $
			 time_str_from_decimalut(xs/3600.)
	axis, xaxis=0, xtickname=xticks, xrange=js_range

	;color = indgen(n_elements(usites)) * (200./float(n_elements(usites))) + 50
	h = .15

	for i = 0, n_elements(usites) - 1 do begin
		pts = where(tags.site_code eq usites[i], npts)
		for j = 0, npts - 1 do begin
			case tags[pts[j]].lambda of
				557.7: begin & color = 150 & base = i+1-h & end
				630.0: begin & color = 250 & base = i+1 & end
				else: begin & color = 90 & base = i+1-2*h & end
			endcase

			polyfill, [tags[pts[j]].js_start, tags[pts[j]].js_start, $
					   tags[pts[j]].js_end, tags[pts[j]].js_end], $
					  base + [0, h, h, 0], /data, color=color
		endfor
	endfor

	loadct, 0, /silent
	wset, c_wind
end


;\\ Widget close cleanup, save the database, free heap vars
pro sdi_tag_cleanup, arg

	common SDITag_Common, global

	sdi_tag_save_daydata
	heap_gc, /verbose
end


;\\ Query the tag database, can be called from external code
function sdi_tag_query, site_code, lambda, js, tag_type=tag_type

	whoami, home_dir, file
	save_file = home_dir + 'tag.idlsave'

	heap_gc
	if not keyword_set(tag_type) then tag_type = 'cloud'

	if file_test(save_file) eq 0 then begin
		print, 'NO DATABASE AVAILABLE!'
		return, 0
	endif else begin
		restore, save_file
		pts = where(tags.type eq tag_type and $
					tags.site_code eq site_code and $
					tags.lambda eq lambda and $
					tags.js_end lt js, nmatch)
		if (nmatch gt 0) then return, tags[pts] else return, 0
	endelse

end


;\\ Return the tag database, can be called from external code
function sdi_tag_get_database

	whoami, home_dir, file
	save_file = home_dir + 'tag.idlsave'

	if file_test(save_file) eq 0 then begin
		print, 'NO DATABASE AVAILABLE!'
		return, 0
	endif else begin
		restore, save_file
		return, tags
	endelse
end



;\\ Main entry point
pro sdi_tag, directory = directory

	common SDITag_Common, global

	tag_template = {type:'', $
					boundary:0, $
					filename:'', $
					site_code:'', $
				    year:0, $
				    dayno:0, $
				    lambda:0.0, $
				    ut_start:0D, $
				    ut_end:0D, $
				    js_start:0D, $
				    js_end:0D, $
					metadata:ptr_new(), $
				    positions:ptr_new(), $
				    js_created:0D, $
				    operator:'', $
				    comments:'', $
				    quality:0, $
				    valid:0 }

	if not keyword_set(directory) then directory = 'c:\'

	whoami, home_dir, file
	save_file = home_dir + 'tag.idlsave'
	default_tag = 'cloud'
 	default_pic_dir = 'c:\users\sdi\sdiplots\' ;\\ default directory for finding pictures

	width = 1200.
	height = 500.

	font = 'Ariel*16*Bold'
	base = widget_base(title = 'SDI Tag', col = 1, mbar = menubar, /tlb_size_events, uval = {tag:'base'})

	options = widget_button(menubar, value = 'Options')
	load_dir = widget_button(options, value = 'Select Directory', uval = {tag:'select_directory'})
	file_filter = widget_button(options, value = 'Set Filename Filter', uval = {tag:'filename_filter'})
	plot_tags = widget_button(options, value = 'Plot Tags', uval = {tag:'plot_tags'})


	filename_label = widget_label(base, value = 'Current Filename:', font=font, xs = .5*width, /align_left)

	tag_op_base = widget_base(base, col=2)
	tagtype_base = widget_base(tag_op_base, col=2)
	tagtype_label = widget_label(tagtype_base, value = 'Current Tag Type:', font=font, xs = .1*width, /align_left)
	tagtype_edit = widget_text(tagtype_base, value = default_tag, font=font, xs = 30, $
							   /align_left, /edit, /all, uval = {tag:'tagtype_edit'})

	operator_base = widget_base(tag_op_base, col=2)
	operator_label = widget_label(operator_base, value = 'Operator:', font=font, xs = .06*width, /align_left)
	operator_edit = widget_text(operator_base, value = '', font=font, xs = 30, $
							   /align_left, /edit, /all, uval = {tag:'operator_edit'})

	base0 = widget_base(base, col=3)

	list = widget_list(base0, font='Ariel*14', scr_xsize = .25*width, scr_ysize = height, $
					   uval = {tag:'file_list'})

	draw_base = widget_base(base0, col=1)
	draw = widget_draw(draw_base, xs = .5*width, ys = height, keyboard_events = 2, /button_events, /motion_events, $
					   uval = {tag:'draw'})
	skymap_button_base = widget_base(draw_base, col=1)
	skymap_button = widget_button(skymap_button_base, xs = 250, font=font, value='Show Skymap', uval={tag:'show_skymaps'})

	tag_base_0 = widget_base(base0, col=1)
	tag_base_1 = widget_base(tag_base_0, col=2)
	tag_list = widget_list(tag_base_1, font=font, scr_xsize = .15*width, scr_ysize = height - 35, $
					  	   uval = {tag:'tag_list'})
	tag_edit = widget_table(tag_base_1, font=font, scr_xsize = .18*width, scr_ysize = height - 35, $
					  	    uval = {tag:'tag_edit'}, /column_major, /no_column_headers, value=tag_template, $
					  	    row_labels=tag_names(tag_template), /editable, /all_events)
	del_button = widget_button(tag_base_0, value = 'Delete Tag', font=font, uval = {tag:'delete_tag'})

	widget_control, base, /realize
	widget_control, get_value = window_id, draw


	gui = {base:base, $
		   draw:draw, $
		   window_id:window_id, $
		   skymap_button:skymap_button, $
		   draw_cache:ptr_new(/alloc), $
		   list:list, $
		   tag_list:tag_list, $
		   tag_edit:tag_edit, $
		   filename_label:filename_label, $
		   tagtype_label:tagtype_label, $
		   base_geom:widget_info(base, /geom), $
		   font:font }

	state = {current_dir:directory, $
			 current_list_index:0, $
			 file_list:ptr_new(/alloc), $
			 rbutton_down:0, $
			 tag_list_selected:-1, $
			 save_file:save_file, $
			 filename_filter:'*SKY*6300*', $
			 tag_type:default_tag, $
			 operator:'', $
			 pic_directory:default_pic_dir, $
			 current_pic:ptr_new(), $
			 preview_mode:0}

	data = {valid:0, $
			year:0, $
			dayno:0, $
			meta:ptr_new(/alloc), $
			wind:ptr_new(/alloc), $
			spek:ptr_new(/alloc), $
			time:ptr_new(/alloc), $
			med_zonal:ptr_new(/alloc), $
			med_merid:ptr_new(/alloc) }

	global = {gui:gui, $
			  state:state, $
			  data:data, $
			  tag_template:tag_template, $
			  tags:ptr_new(/alloc), $
			  have_tags:0, $
			  current_tag:0}

	global.tags = ptr_new(/alloc)

	sdi_tag_restore_daydata
	sdi_tag_scan_dir
	sdi_tag_load_file

	xmanager, 'sdi_tag', base, event = 'sdi_tag_event', cleanup = 'sdi_tag_cleanup', /no_block
end
