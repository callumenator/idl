


pro drta_interactive_plotter_flistUpdate
	common drtaPlotShare, misc, gui
	flist = file_search(misc.path + '\*')
	misc.flist = ptr_new(file_basename(flist))
	widget_control, set_value = *misc.flist, gui.listID
end


pro drta_interactive_plotter_event, event
	common drtaPlotShare, misc, gui

	widget_control, get_uval = uval, event.id

	if size(uval, /type) ne 0 then begin
		if strmid(uval, 0, 6) eq 'Filter' then begin
			if event.select eq 1 then begin
				misc.filter = float(strmid(uval, 6, 1))
			endif
		endif
		if uval eq 'Path Select' then begin
			misc.path = dialog_pickfile(/dir)
			drta_interactive_plotter_flistUpdate
		endif
	endif

	if event.id eq gui.listID then begin
		year = float(strmid((*misc.flist)(event.index), 0, 4))
		dayno = float(strmid((*misc.flist)(event.index), 5, 3))
		davis_real_time_analysis_ploteach, 	misc.path + '\', $
									   	   	'', $
									       	630, $
									   		misc.filter, $
									   		year = year, $
									   		dayno = dayno, $
									   		windowID = gui.drawID, $
									   		/nosave
	endif

end

pro drta_interactive_plotter
	common drtaPlotShare, misc, gui

	misc = {path:'C:\Cal\IDLSource\DavisRTNew\drta\saves', $
			flist:ptr_new(), $
			filter:2}

	nfilters = 6

	font = 'Aerial*Bold*18'
	base = widget_base(col = 2, title = 'Davis Interactive Plotter')

	drawBase = widget_base(base, col = 1)
	draw = widget_draw(drawBase, xs=800, ys=900)

	leftBase = widget_base(base, col = 1)

	filtLabel = widget_label(leftBase, value = 'Filter Select', font=font)
	butBase = widget_base(leftBase, col = nfilters, /exclusive, /align_center)
	filterButton = lonarr(nfilters)
	for k = 1, nfilters do begin
		filterButton(k-1) = widget_button(butBase, value = string(k, f='(i0)'), $
						uvalue='Filter'+string(k, f='(i0)'), font=font)
	endfor

	filtLabel = widget_label(leftBase, value = 'File Select', font=font)
	pathButton = widget_button(leftBase, value = 'Path: ' + misc.path, $
							   font=font, uvalue='Path Select')
	listBase = widget_base(leftBase, col = 1, /align_center)
	list = widget_list(listBase, value = '', $
					   ysize = 40, $
					   xsize = 40, $
					   font=font)

	widget_control, /realize, base
	widget_control, get_value = drawID, draw
	widget_control, /set_button, filterButton(misc.filter-1)

	gui = {baseID:base, $
		   drawID:drawID, $
		   listID:list}

	drta_interactive_plotter_flistUpdate

	xmanager, 'drta_interactive_plotter', base, $
			  event = 'drta_interactive_plotter_event'

end
