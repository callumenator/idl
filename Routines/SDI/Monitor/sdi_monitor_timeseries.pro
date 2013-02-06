
pro sdi_monitor_timeseries, data_dir=data_dir, $
							save_name=save_name ;\\ png image file name

	whoami, dir, file

 	if not keyword_set(timeseries) then timeseries = dir + '\timeseries\'

	;\\ Things to plot...
		show = [{tag:'width', site:'all', wavelength:'6300', range:[700., 1400.], zone:-1, title:'630nm Temperature (K)', thick:.5}, $
				{tag:'width', site:'all', wavelength:'5577', range:[200., 700.], zone:-1, title:'558nm Temperature (K)', thick:.5}, $
				{tag:'snr', site:'all', wavelength:'6300', range:[0.,1E4], zone:-1, title:'630nm SNR/Scan', thick:.5}, $
				{tag:'snr', site:'all', wavelength:'5577', range:[0.,1E5], zone:-1, title:'558nm SNR/Scan', thick:.5}, $
				{tag:'position', site:'all', wavelength:'6300', range:[-100.,100.], zone:0, title:'630nm Vz (m/s)', thick:.5}, $
				{tag:'position', site:'all', wavelength:'5577', range:[-100.,100.], zone:0, title:'558nm Vz (m/s)', thick:.5}, $
				{tag:'position', site:'all', wavelength:'6300', range:[-100.,100.], zone:0, title:'15 Minute Time-Smoothed 630nm Vz (m/s)', thick:.5}, $
				{tag:'position', site:'all', wavelength:'5577', range:[-100.,100.], zone:0, title:'15 Minute Time-Smoothed 558nm Vz (m/s)', thick:.5}]

	;\\ BAD VALUE
		bad_value_temp = 600.

	;\\ Create a window
		window, /free, xs=1200, ys=350*n_elements(show), /pixmap
		wid = !D.WINDOW
		loadct, 39, /silent
		erase, 0

	;\\ Site colors
		site_colormap = {site:['HRP', 'PKR', 'MAW', 'TLK', 'KTO'], $
						 color:[100, 150, 190, 230, 144], $
						 ctable:[39, 39, 39, 39, 2] }

	;\\ Find timeseries save files
		ts_files = file_search(timeseries + '*_timeseries.idlsave', count = n_series)
		if n_series eq 0 then return

	;\\ Use this to get a maximal time range for the current days' data
		current_ut_day = dt_tm_fromjs(dt_tm_tojs(systime(/ut)), format='doy$')
		ut_day_range = [current_ut_day, current_ut_day]
		current_day_ut_range = [24, 0]

	;\\ Restore them all first
		data = ptrarr(n_series)
		for k = 0, n_series - 1 do begin
			restore, ts_files[k]

			js2ymds, series.start_time, y, m, d, s
			curr_year =float( dt_tm_fromjs(dt_tm_tojs(systime(/ut)), format='Y$'))
			keep = where(y eq curr_year, nkeep)
			if nkeep gt 0 then series = series[keep] else continue

			daynos = ymd2dn(y, m, d)
			slice = where(daynos ge ut_day_range[0] and daynos le ut_day_range[1], nsliced)
			if (nsliced ge 2) then begin
				temp_ut = s[slice]/3600.
				if (min(temp_ut) lt current_day_ut_range[0]) then current_day_ut_range[0] = min(temp_ut)
				if (max(temp_ut) gt current_day_ut_range[1]) then current_day_ut_range[1] = max(temp_ut)
			endif

			if (size(series.fits.width, /type) ne 0) then begin
				good = where(median(series.fits.width, dim=1) gt 80 and $
							 median(series.fits.width, dim=1) ne 600 and $
							 median(series.fits.width, dim=1) ne 700, ngood)
				if ngood gt 0 then series = series[good]
			endif

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
		time_range = frac_day + [-3*24, 6]/24.
		blank = replicate(' ', 30)
		plot, time_range, [0,1], /nodata, xstyle=5, ystyle=5, xtick_get = xvals, xtickint = 6./24., xminor=8
		xtickname = time_str_from_decimalut((xvals mod 1) * 24., /noseconds)

		for p = 0, n_elements(show) - 1 do begin

			if p eq 0 then noerase = 0 else noerase = 1
			loadct, 0, /silent
			yrange = show[p].range
			plot, time_range, yrange, /nodata, /xstyle, /ystyle, $
				  xtickname=xtickname, title = show[p].title, noerase=noerase, xtickint = 6./24., xminor=8, $
				  pos=bounds[p,0,*], yticklen=.003, xtitle = 'Time (UT)', ytick_get=yvals

			plots, [frac_day, frac_day], yrange, line=1
			xyouts, frac_day, yrange[1] - .07*(yrange[1]-yrange[0]), 'Current UTC', align=-.03, /data, color=255


			inc = (yrange[1]-yrange[0])/5.
			for jj = 1, n_elements(yvals) - 2 do oplot, time_range, float([yvals[jj], yvals[jj]]), color = 50


			for k = 0, n_series - 1 do begin

				if ptr_valid(data[k]) eq 0 then continue

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
										sm = smooth_in_time((xaxis[i0:i1])[good], (parameter[i0:i1])[good], 500, 15./(60.*24.), /gconvol)
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

			plot, time_range, (*second_pass[k]).yrange, /nodata, /xstyle, ystyle=5, /noerase, $
				  xtickname=xtickname, xtickint = 6./24., xminor=8, $
				  pos=(*second_pass[k]).bounds

			x = (*second_pass[k]).x
			y = (*second_pass[k]).y
			find_contiguous, x, 3/24., blocks
			for j = 0, n_elements(blocks[*,0]) - 1 do begin
				sub_x = x[blocks[j,0]:blocks[j,1]]
				sub_y = y[blocks[j,0]:blocks[j,1]]
				if n_elements(sub_x) ge 2 then begin
					oplot, sub_x, sub_y, color=(*second_pass[k]).color, thick=(*second_pass[k]).thick
				endif else begin
					plots, sub_x, sub_y, color=(*second_pass[k]).color, thick=(*second_pass[k]).thick
				endelse
			endfor
			ptr_free, second_pass[k]
		endfor

		if keyword_set(save_name) then begin
			img = tvrd(/true)
			write_png, save_name, img
		endif
		wdelete, wid


	;\\ Draw all temp time series together on one plot, for red and green wavelengths

		if current_day_ut_range[1] lt current_day_ut_range[0] then goto, MONITOR_TSERIES_END

		;\\ Create a window
			window, /free, xs=1000, ys=350, /pixmap
			wid = !D.WINDOW
			loadct, 39, /silent
			erase, 0

		;\\ Create a time range
			yrange = [200, 1400]
			!x.tickinterval = 1/24.
			cnv_current = convert_js(dt_tm_tojs(systime(/ut)))
			frac_day = cnv_current.dayno + cnv_current.sec/(24.*3600.)
			if (current_day_ut_range[1] - current_day_ut_range[0]) lt 5 then $
				current_day_ut_range[0] -= 5

			current_day_ut_range[1] += 1

			if current_day_ut_range[1] lt current_day_ut_range[0] then begin
				time_range = current_ut_day + [0,5]/24.
			endif else begin
				time_range = current_ut_day + current_day_ut_range/24.
			endelse

			blank = replicate(' ', 30)

			plot, time_range, [0,1], /nodata, /xstyle, /ystyle, yrange=yrange, xtick_get = xvals, xtickint = 2./24., xminor=8, $
				  pos = [.075, .12, .98, .94], chars=1.5, xtickname=blank, ytick_get=yvals, ytitle = 'Temperature (K)', yticklen=.003

			xtickname = time_str_from_decimalut((xvals mod 1) * 24., /noseconds)
			axis, xaxis=0, xtickname = xtickname, /xstyle, xrange=time_range, xtitle = 'Time (UT)', $
				  xtickint = 2./24., xminor=8, chars = 1.5

			loadct, 0, /silent
			for jj = 1, n_elements(yvals) - 2 do oplot, time_range, fix([yvals[jj], yvals[jj]]), color = 80

			for k = 0, n_series - 1 do begin

				if ptr_valid(data[k]) eq 0 then continue

				dat = *data[k]
				if dat.meta.wavelength ne '5577' and dat.meta.wavelength ne '6300' then continue

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

			img = tvrd(/true)
			if keyword_set(save_name) then write_png, file_dirname(save_name) + '\sdi_temp_series.png', img
			wdelete, wid

		;\\ Save a copy of the temp timeseries
			year = dt_tm_fromjs(dt_tm_tojs(systime(/ut)), format='Y$')
			fname = 'c:\users\SDI\SDIPlots\' + year + '_AllStations_6300\Median_Temperature\'
			date = dt_tm_fromjs(dt_tm_tojs(systime(/ut)), format='Y$_DOYdoy$')
			fname += 'Median_Temperature_AllStations_' + date + '_6300.png'
			file_mkdir, file_dirname(fname)
			write_png, fname, img


MONITOR_TSERIES_END:

	;\\ Free the pointers
		for k = 0, n_series - 1 do ptr_free, data[k]
end