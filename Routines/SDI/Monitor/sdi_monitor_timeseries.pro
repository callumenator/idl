
;\\ Plot the current snapshots
pro sdi_monitor_timeseries

	common sdi_monitor_common, global, persistent

	if ptr_valid(persistent.zonemaps) eq 0 then return
	if ptr_valid(persistent.snapshots) eq 0 then return

	;\\ Things to plot...
		show = [{tag:'width', site:'all', wavelength:'6300', range:[700., 1400.], zone:-1, title:'630nm Temperature (K)', thick:1}, $
				{tag:'width', site:'all', wavelength:'5577', range:[200., 700.], zone:-1, title:'558nm Temperature (K)', thick:1}, $
				{tag:'snr', site:'all', wavelength:'6300', range:[0.,1E4], zone:-1, title:'630nm SNR/Scan', thick:1}, $
				{tag:'snr', site:'all', wavelength:'5577', range:[0.,1E5], zone:-1, title:'558nm SNR/Scan', thick:1}, $
				{tag:'position', site:'all', wavelength:'6300', range:[-100.,100.], zone:0, title:'630nm Vz (m/s)', thick:1}, $
				{tag:'position', site:'all', wavelength:'5577', range:[-100.,100.], zone:0, title:'558nm Vz (m/s)', thick:1}, $
				{tag:'position', site:'all', wavelength:'6300', range:[-100.,100.], zone:0, title:'5 Minute Time-Smoothed 630nm Vz (m/s)', thick:1}, $
				{tag:'position', site:'all', wavelength:'5577', range:[-100.,100.], zone:0, title:'5 Minute Time-Smoothed 558nm Vz (m/s)', thick:1}]

	;\\ Store the current color table
		tvlct, store_red, store_green, store_blue, /get

	;\\ Set draw geometry
		base_geom = widget_info(global.tab_id[1], /geometry)
		widget_control, draw_ysize=350*n_elements(show), draw_xsize = 1200, global.draw_id[1]
		widget_control, get_value = wset_id, global.draw_id[1]
		wset, wset_id
		loadct, 39, /silent
		erase, 0

	;\\ Plot median temperature for each site
		site_colormap = {site:['HRP', 'PKR', 'MAW', 'TLK', 'KTO'], $
						 color:[100, 150, 190, 230, 144], $
						 ctable:[39, 39, 39, 39, 2] }

	;\\ Find timeseries save files
		ts_files = file_search(global.home_dir + '\Timeseries\' + '*_timeseries.idlsave', count = n_series)
		if n_series eq 0 then return

	;\\ Restore them all at once
		data = ptrarr(n_series)
		for k = 0, n_series - 1 do begin
			restore, ts_files[k]
			cnv_series = convert_js(series.start_time)
			xaxis = cnv_series.dayno + cnv_series.sec/(24.*3600.)

				color_pt = (where(site_colormap.site eq meta.site_code, n_match))[0]
				if n_match eq 0 then begin
					color = 255
					ctable = 39
				endif else begin
					color = site_colormap.color[color_pt]
					ctable = site_colormap.ctable[color_pt]
				endelse

			data[k] = ptr_new({series:series, meta:meta, xaxis:xaxis, color:color, ctable:ctable})
		endfor

	;\\ Split up the page
		bounds = split_page(n_elements(show), 1, bounds=[.05, .05, .98, .99], row_gap=.06)

	;\\ Create a time range
		!x.tickinterval = 1/24.
		cnv_current = convert_js(dt_tm_tojs(systime(/ut)))
		frac_day = cnv_current.dayno + cnv_current.sec/(24.*3600.)
		time_range = frac_day + [-20, 2]/24.
		blank = replicate(' ', 30)
		plot, time_range, [0,1], /nodata, xstyle=5, ystyle=5, xtick_get = xvals, xtickint = 2./24., xminor=8
		xtickname = time_str_from_decimalut((xvals mod 1) * 24., /noseconds)

		for p = 0, n_elements(show) - 1 do begin


			if p eq 0 then noerase = 0 else noerase = 1
			loadct, 0, /silent
			yrange = show[p].range
			plot, time_range, yrange, /nodata, /xstyle, /ystyle, $
				  xtickname=xtickname, title = show[p].title, noerase=noerase, xtickint = 2./24., xminor=8, $
				  pos=bounds[p,0,*], yticklen=.003, xtitle = 'Time (UT)', ytick_get=yvals

			plots, [frac_day, frac_day], yrange, line=1
			xyouts, frac_day, yrange[1] - .07*(yrange[1]-yrange[0]), 'Current UTC', align=-.03, /data, color=255


			inc = (yrange[1]-yrange[0])/5.
			for jj = 1, n_elements(yvals) - 2 do oplot, time_range, float([yvals[jj], yvals[jj]]), color = 50


			for k = 0, n_series - 1 do begin

				series = (*data[k]).series
				meta = (*data[k]).meta

				;\\ Check to see if plot applies to this site
				if show[p].site ne 'all' then begin
					site_list = strupcase(strsplit(show[p].site, ',', /extract))
					match = where(meta.site_code eq site_list, n_matching)
					if n_matching eq 0 then continue
				endif

				;\\ Check to see if plot applies to this wavelength
				if show[p].wavelength ne 'all' then begin
					wavelength_list = strupcase(strsplit(show[p].wavelength, ',', /extract))
					match = where(meta.wavelength eq wavelength_list, n_matching)
					if n_matching eq 0 then continue
				endif


				tags = tag_names(series[0].fits)
				match = where(strupcase(show[p].tag) eq tags, n_matching)

				;\\ Get the x axis
				xaxis = (*data[k]).xaxis

				if n_matching eq 0 then begin

					case show[p].tag of
						'exptime': begin
							parameter = (series.end_time - series.start_time)/60.
							sdevs = intarr(n_elements(series))
						end

						else:
					endcase

				endif else begin

					parameter = series.fits.(match[0])
					sdevs = fltarr(n_elements(series))
					for t = 0, n_elements(series) - 1 do sdevs[t] = meanabsdev(parameter[*,t], /nan, /median)


					;\\ One zone, median of all zones, ?
					if show[p].zone eq -1 then begin
						parameter = median(parameter, dim=1)
					endif else begin
						parameter = reform(parameter[show[p].zone, *])
					endelse


				endelse


				;\\ Do special things here
				case show[p].tag of
					'position': begin
						cnv = 3E8*(meta.wavelength/10.)*1E-9/(2.*meta.gap_mm*(1E-3)*meta.scan_channels)
						sdevs = (series.fits.sigma_position * cnv)[0,*]
						errs = sdevs
						parameter *= cnv
						find_contiguous, xaxis, 3./24., blocks, n_blocks=nb
						for kk = 0, nb - 1 do begin
							i0 = blocks[kk,0]
							i1 = blocks[kk,1]

							if (i1-i0) gt 3 then begin
								sub = parameter[i0:i1]
								good = where(abs(sub - median(sub)) lt 10*meanabsdev(sub, /median), ngood)
								if ngood gt 3 then begin

									 sdi_monitor_format, {metadata:meta, series:series[i0:i1]},  $ ;\\ {metadata:{}, series:[{}]}
														 metadata = mm, $
														 spekfits = var, $
														 zone_centers = zone_centers

									sdi3k_drift_correct, var, mm, /data_based, /force
									parameter[i0:i1] = reform(var.velocity[0]*cnv)

								endif
							endif

							if (i1-i0) gt 3 then $
								parameter[i0:i1] -= median(parameter[i0:i1])

							if strmatch(show[p].title, '*Smoothed*') eq 1 then begin
								if i1-i0 gt 10 then begin
									sub = parameter[i0:i1]
									sub_e = errs[i0:i1]
									good = where(abs(sub - median(sub)) lt 8*meanabsdev(sub, /median) and $
												 abs(sub_e - median(sub_e)) lt 8*meanabsdev(sub_e, /median), ngood)
									if ngood gt 5 then begin
										sm = smooth_in_time((xaxis[i0:i1])[good], (parameter[i0:i1])[good], 500, 5./(60.*24.), /gconvol)
										parameter[i0:i1] = interpol(sm, (xaxis[i0:i1])[good], (xaxis[i0:i1]))
									endif
								endif
								sdevs[*] = 0
							endif

						endfor
						oplot, time_range, [0,0], line=1
					end
					'snr': begin
						parameter /= float(series.scans)
					end
					else:
				endcase




				;\\ Get the color for this site
				color = (*data[k]).color
				ctable = (*data[k]).ctable

				if n_elements(series) gt 3 then begin
					loadct, 0, /silent
					errplot, xaxis, parameter - sdevs, parameter + sdevs, color=50, width=.00001, noclip=0
					loadct, ctable, /silent
					append, ptr_new({x:xaxis, y:parameter, color:color, $
									 yrange:yrange, bounds:bounds[p,0,*], $
									 thick:show[p].thick, tag:show[p].tag}), second_pass
					append, meta.site_code, sites_used
					append, color, colors_used
					append, ctable, ctables_used
				endif

			endfor



			if nels(sites_used) gt 0 then begin
				u_sites = uniq(sites_used[sort(sites_used)])
				!p.font = 0
				device, set_font="Ariel*15*Bold"

				for k = 0, n_elements(u_sites) - 1 do begin
					index = u_sites[k]
					loadct, ctables_used[index], /silent
					xyouts, time_range[0] + k*0.05*(time_range[1]-time_range[0]), $
							yrange[1] + .03*(yrange[1]-yrange[0]), sites_used[index], $
							color=colors_used[index], align=0
				endfor
				!p.font = -1
			endif


			sites_used = 0
			ctables_used = ''
			colors_used = ''

		endfor



		for k = 0, n_elements(second_pass) - 1 do begin

			plot, time_range, (*second_pass[k]).yrange, /nodata, xstyle=5, ystyle=5, $
				  /noerase, pos=(*second_pass[k]).bounds, xtickint = 2./24., xminor=8

			x = (*second_pass[k]).x
			y = (*second_pass[k]).y
			find_contiguous, x, 3/24., blocks
			for j = 0, n_elements(blocks[*,0]) - 1 do begin
				sub_x = x[blocks[j,0]:blocks[j,1]]
				sub_y = y[blocks[j,0]:blocks[j,1]]
				if n_elements(sub_x) ge 2 then begin
					oplot, sub_x, sub_y, color=(*second_pass[k]).color, psym=-6, sym=.3, thick=(*second_pass[k]).thick
					;plots, sub_x, sub_y, color=(*second_pass[k]).color, psym=6, sym=.3, thick=1.55
				endif else begin
					plots, sub_x, sub_y, color=(*second_pass[k]).color, psym=6, sym=.3, thick=1.5
				endelse
			endfor
			ptr_free, second_pass[k]
		endfor

	;\\ Draw overplot temperatures for Mark

		;\\ Set draw geometry
			base_geom = widget_info(global.tab_id[2], /geometry)
			widget_control, draw_ysize=350, draw_xsize = 1000, global.draw_id[2]
			widget_control, get_value = wset_id, global.draw_id[2]
			wset, wset_id
			loadct, 39, /silent
			erase, 0

		;\\ Create a time range
			yrange = [200, 1400]
			!x.tickinterval = 1/24.
			cnv_current = convert_js(dt_tm_tojs(systime(/ut)))
			frac_day = cnv_current.dayno + cnv_current.sec/(24.*3600.)
			time_range = frac_day + [-15, 1.5]/24.
			blank = replicate(' ', 30)

			plot, time_range, [0,1], /nodata, /xstyle, /ystyle, yrange=yrange, xtick_get = xvals, xtickint = 2./24., xminor=8, $
				  pos = [.075, .12, .98, .94], chars=1.5, xtickname=blank, ytick_get=yvals, ytitle = 'Temperature (K)', yticklen=.003

			xtickname = time_str_from_decimalut((xvals mod 1) * 24., /noseconds)
			axis, xaxis=0, xtickname = xtickname, /xstyle, xrange=time_range, xtitle = 'Time (UT)', $
				  xtickint = 2./24., xminor=8, chars = 1.5

			loadct, 0, /silent
			plots, [frac_day, frac_day], yrange, line=1
			xyouts, frac_day, yrange[1] - .07*(yrange[1]-yrange[0]), 'Current UTC', align=-.03, /data, color=255
			for jj = 1, n_elements(yvals) - 2 do oplot, time_range, fix([yvals[jj], yvals[jj]]), color = 80

			for k = 0, n_series - 1 do begin
				dat = *data[k]
				case dat.meta.site_code of
					'HRP':color = [39, 100]
					'PKR':color = [39, 150]
					'MAW':color = [39, 190]
					'TLK':color = [39, 230]
					else:color = [0,0]
				endcase

				loadct, color[0], /silent
				x = dat.xaxis
				y = median(dat.series.fits.width, dim=1)
				find_contiguous, x, 3/24., blocks

				for j = 0, n_elements(blocks[*,0]) - 1 do begin
					sub_x = x[blocks[j,0]:blocks[j,1]]
					sub_y = y[blocks[j,0]:blocks[j,1]]
					if n_elements(sub_x) ge 2 then begin
						oplot, sub_x, sub_y, color=color[1], psym=-6, sym=.1
					endif else begin
						plots, sub_x, sub_y, color=color[1], psym=6, sym=.1
					endelse
				endfor

				append, dat.meta.site_code, sites_used
				append, color[1], colors_used
				append, color[0], ctables_used
			endfor

			if nels(sites_used) gt 0 then begin
				u_sites = uniq(sites_used[sort(sites_used)])
				!p.font = 0
				device, set_font="Ariel*18*Bold"

				for k = 0, n_elements(u_sites) - 1 do begin
					index = u_sites[k]
					loadct, ctables_used[index], /silent
					xyouts, time_range[0] + k*0.05*(time_range[1]-time_range[0]), $
							yrange[1] + .015*(yrange[1]-yrange[0]), sites_used[index], $
							color=colors_used[index], align=0
				endfor
				!p.font = -1
			endif

	;\\ Restore the current color table
		tvlct, store_red, store_green, store_blue

	;\\ Clear the x tick int
		!x.tickinterval = 0

	;\\ Free the pointers
		for k = 0, n_series - 1 do begin
			ptr_free, data[k]
		endfor

end