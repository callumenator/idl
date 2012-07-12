
pro load_file, Event

	common data, k_vz, k_ut, k_vz_ion, k_lat, k_vz_poly, k_vz_mod, plot_data, list

	!y.style = 1
	!x.style = 1
	!y.range = plot_data.yrange

	restore, list(event.index)

	draw_id = widget_info(event.top, find_by_uname = 'WID_DRAW_0')
	widget_control, draw_id, get_value = win_id
	wset, win_id

	if plot_data.xut eq 1 then begin
		x = k_ut
		c = bytscl(k_lat, top = 220) + 30
		pad = .05
		!x.title = 'UT'
	endif else begin
		x = k_lat
		c = bytscl(k_ut, top = 220) + 30
		pad = 10
		!x.title = 'Lat'
	endelse

	!x.range = [min(x) - pad, max(x) + pad]

	if plot_data.plot eq 1 then begin
		plot, x, k_vz_mod, title = 'Vz Mod'
		oplot, !x.range, [0,0], line = 1, color = 255
		plots, x, k_vz_mod, color = c
		plots, x, k_vz_mod, psym=1, color = c
	endif else begin
		oplot, x, k_vz_mod
		oplot, !x.range, [0,0], line = 1, color = 255
		plots, x, k_vz_mod, color = c
		plots, x, k_vz_mod, psym=1, color = c
	endelse

end

pro select_plot, Event

	common data, k_vz, k_ut, k_vz_ion, k_lat, k_vz_poly, k_vz_mod, plot_data, list

	plot_data.plot = 1
	plot_data.oplot = 0

end

pro plot_vz, Event

	common data, k_vz, k_ut, k_vz_ion, k_lat, k_vz_poly, k_vz_mod, plot_data, list

	draw_id = widget_info(event.top, find_by_uname = 'WID_DRAW_0')
	widget_control, draw_id, get_value = win_id
	wset, win_id

	if plot_data.xut eq 1 then begin
		x = k_ut
		c = bytscl(k_lat, top = 220) + 30
	endif else begin
		x = k_lat
		c = bytscl(k_ut, top = 220) + 30
	endelse

	if plot_data.plot eq 1 then begin
		plot, x, k_vz, title = 'Vz Raw'
		oplot, !x.range, [0,0], line = 1, color = 255
		plots, x, k_vz, color = c
		plots, x, k_vz, psym=1, color = c
	endif else begin
		oplot, x, k_vz
		oplot, !x.range, [0,0], line = 1, color = 255
		plots, x, k_vz, color = c
		plots, x, k_vz, psym=1, color = c
	endelse

end

pro plot_vz_mod, Event

	common data, k_vz, k_ut, k_vz_ion, k_lat, k_vz_poly, k_vz_mod, plot_data, list

	draw_id = widget_info(event.top, find_by_uname = 'WID_DRAW_0')
	widget_control, draw_id, get_value = win_id
	wset, win_id

	if plot_data.xut eq 1 then begin
		x = k_ut
		c = bytscl(k_lat, top = 220) + 30
	endif else begin
		x = k_lat
		c = bytscl(k_ut, top = 220) + 30
	endelse

	if plot_data.plot eq 1 then begin
		plot, x, k_vz_mod, title = 'Vz Mod'
		oplot, !x.range, [0,0], line = 1, color = 255
		plots, x, k_vz_mod, color = c
		plots, x, k_vz_mod, psym=1, color = c
	endif else begin
		oplot, x, k_vz_mod
		oplot, !x.range, [0,0], line = 1, color = 255
		plots, x, k_vz_mod, color = c
		plots, x, k_vz_mod, psym=1, color = c
	endelse

end

pro select_oplot, Event

	common data, k_vz, k_ut, k_vz_ion, k_lat, k_vz_poly, k_vz_mod, plot_data, list

	plot_data.plot = 0
	plot_data.oplot = 1

end

pro set_yrange, Event

	common data, k_vz, k_ut, k_vz_ion, k_lat, k_vz_poly, k_vz_mod, plot_data, list

	temp = plot_data.yrange
	xvaredit, temp, name = 'Set Yrange'

	plot_data.yrange = temp
	!y.range = temp

end

pro set_xrange, Event

	common data, k_vz, k_ut, k_vz_ion, k_lat, k_vz_poly, k_vz_mod, plot_data, list

	temp = plot_data.xrange
	xvaredit, temp, name = 'Set Xrange'

	plot_data.xrange = temp
	!x.range = temp

end

pro plot_vz_poly, Event

	common data, k_vz, k_ut, k_vz_ion, k_lat, k_vz_poly, k_vz_mod, plot_data, list

	draw_id = widget_info(event.top, find_by_uname = 'WID_DRAW_0')
	widget_control, draw_id, get_value = win_id
	wset, win_id

	if plot_data.xut eq 1 then begin
		x = k_ut
	endif else begin
		x = k_lat
	endelse

	if plot_data.plot eq 1 then begin
		plot, x, k_vz_poly, line = 1, title = 'Vz Polynomial', yrange = plot_data.yrange, xrange = plot_data.xrange, /ystyle, /xstyle
	endif else begin
		oplot, x, k_vz_poly, line = 1
	endelse

end

pro use_ut, Event

	common data, k_vz, k_ut, k_vz_ion, k_lat, k_vz_poly, k_vz_mod, plot_data, list

	plot_data.xut = 1
	plot_data.xlat = 0
	!x.title = 'UT'

end

pro use_lat, Event

	common data, k_vz, k_ut, k_vz_ion, k_lat, k_vz_poly, k_vz_mod, plot_data, list

	plot_data.xut = 0
	plot_data.xlat = 1
	!x.title = 'Lat'

end
;
; Empty stub procedure used for autoloading.
;
pro cal_plot_de_eventcb
end
