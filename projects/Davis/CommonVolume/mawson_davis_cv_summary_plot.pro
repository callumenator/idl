
pro mawson_davis_cv_summary_plot, all_cv

	plot_dir = where_is('mawson_davis_cv') + 'Pics\RedGreen\'

	n_red = (n_tags(all_cv.red) - 9) > 0
	n_gre = (n_tags(all_cv.green) - 9) > 0

	if n_red eq 0 then return

	cv_tag = fltarr(n_red + n_gre, 2)
	all_lons = fltarr(n_red+n_gre)
	all_lambda = fltarr(n_red+n_gre)
	for k = 0, n_red+n_gre - 1 do begin
		cv_tag[k,0] = 2+floor(k/n_red)
		cv_tag[k,1] = 6 + (k mod n_red)
		all_lons[k] = (all_cv.(cv_tag[k,0]).(cv_tag[k,1]))[0].dav_ll[1]
		all_lambda[k] = (all_cv.(cv_tag[k,0]).(cv_tag[k,1]))[0].wavelength
	endfor
	order = (sort(all_lons))
	cv_tag = cv_tag[order, *]
	all_lambda = all_lambda[order]
	all_lons = all_lons[order]

	greens = where(all_lambda eq 557.7, ngreens)
	reds = where(all_lambda eq 630.0, nreds)

	pairs = [[-1.], [-1.], [-1.]]

	if ngreens gt 0 then begin
		green_used = intarr(ngreens)
		for k = 0, nreds - 1 do begin
			rlat = all_lons[reds[k]]
			diff = abs(rlat - all_lons[greens])
			if min(diff) lt 0.05 then begin
				pt = (where(diff eq min(diff)))[0]
				pairs = [pairs, [[reds[k]], [greens[pt]], [rlat]]]
				green_used[pt] = 1
			endif else begin
				pairs = [pairs, [[reds[k]], [-1], [rlat]]]
			endelse
		endfor

		for k = 0, ngreens - 1 do begin
			if green_used[k] eq 0 then begin
				glat = all_lons[greens[k]]
				pairs = [pairs, [[-1], [greens[k]], [glat]]]
			endif
		endfor

	endif else begin
		for k = 0, nreds - 1 do begin
			rlat = all_lons[reds[k]]
			pairs = [pairs, [ [reds[k]], [-1], [rlat]]]
		endfor
	endelse

	pairs = pairs[1:*, *]
	pair_order = (sort(pairs[*,2]))
	pairs = pairs[pair_order, *]
	n_plots = n_elements(pairs[*,0]) + 2

	red_color = [3, 127]
	gre_color = [8, 144]

	set_plot, 'ps'
	device, filename = plot_dir + all_cv.date.yymmdd_string + '.eps', /encaps, xs = 15, ys = 13, /color, bits=8

		bounds = split_page(n_plots, 2, bounds = [.05, .06, .99, .98], row_gap = .015, col_gap = .2, col_percents = [.6, .4])

		plot_count = 0
		loadct, 39, /silent
		!p.charsize = .6
		erase

		;\\ Time range
			if n_red gt 0 then trange = [min(all_cv.red.maw_ut),max(all_cv.red.maw_ut)]
			if n_red eq 0 then trange = [min(all_cv.green.maw_ut),max(all_cv.green.maw_ut)]
			trange = trange + [-1.5, 1.5]

		!y.range = [-100,100]
		!y.title = 'Vz (m/s)'
		!x.style = 5
		!x.range = trange

		tsm = 10./60.

		;\\ Mawson Zenith
		loadct, 0, /silent
			if n_red ne 0 then begin
				plot, all_cv.red.maw_ut, all_cv.red.maw_zenith, pos = bounds[plot_count, 0, *], /noerase, /nodata
				oplot, trange, [0,0], line=1
				loadct, red_color[0], /silent

				ut = all_cv.red.maw_ut
				vz = all_cv.red.maw_zenith
				vz -= median(vz)
				vze = all_cv.red.maw_zenith_err

				vz = smooth_in_time(ut, vz, 1000., tsm, /gconvol)

				errplot, ut, vz - vze, vz + vze, color = red_color[1], thick = .4, width = 0.002
				oplot, ut, vz, color = red_color[1], psym=-6, sym=.2
				plot_count ++
			endif

			if n_gre ne 0 then begin

				ut = all_cv.green.maw_ut
				vz = all_cv.green.maw_zenith
				vz -= median(vz)
				vze = all_cv.green.maw_zenith_err

				vz = smooth_in_time(ut, vz, 1000., tsm, /gconvol)

				if plot_count eq 1 then begin
					loadct, gre_color[0], /silent
					errplot, ut, vz-vze, vz+vze, color = gre_color[1], thick = .4, width = 0.002
					oplot, ut, vz, color=gre_color[1], psym=-6, sym=.2
				endif else begin
					loadct, 0, /silent
					plot, ut, vz, pos = bounds[plot_count, 0, *], /noerase, /nodata
					oplot, trange, [0,0], line=1
					loadct, gre_color[0], /silent
					errplot, ut, vz-vze, vz+vze, color = gre_color[1], thick = .4, width = 0.002
					oplot, ut, vz, color = gre_color[1], psym=-6, sym=.2
					plot_count ++
				endelse
			endif

		;\\ Common Volumes
			for k = 0, n_elements(pairs[*,0]) - 1 do begin
				first_plot = 1
				for pidx = 0, 1 do begin

					if pairs[k,pidx] ne -1 then begin

						tidx = pairs[k,pidx]
						dat =  all_cv.(cv_tag[tidx,0]).(cv_tag[tidx,1])
						if dat[0].wavelength eq 630.0 then color = red_color
						if dat[0].wavelength eq 557.7 then color = gre_color
						good = where(dat.dav_missing ne 1, ng)
						if ng lt 2 then continue

						ut = dat[good].ut
						vz = dat[good].mcomp
						vz -= median(vz)
						vze = dat[good].merr
						temp = dat[good].temperature
						temp = smooth_in_time(ut, temp, 1000, 30./60., /gconvol)
						temp = temp - smooth_in_time(ut, temp, 1000, 2., /gconvol)


						vz = smooth_in_time(ut, vz, 1000., tsm, /gconvol)

						loadct, 0, /silent
						if first_plot eq 1 then begin
							plot, ut, vz, pos = bounds[plot_count, 0, *], /noerase, /nodata, $
									title = 'CV Lon: ' + string(dat[0].dav_ll[1], f='(f0.1)')
						endif
						oplot, trange, [0,0], line=1

						errplot, ut, vz-vze, vz+vze, thick = .4, $
							color = color[1], width = 0.002
						loadct, color[0], /silent
						oplot, ut, vz, color = color[1], psym=-6, sym=.2
						oplot, ut, temp, color = color[1], thick=.5

						loadct, 0, /silent
						;if pidx eq 0 then begin
						;	oplot, dat[good].ut, dat[good].stn_los[0], color = 100, line=1
						;	oplot, dat[good].ut, dat[good].stn_los[1], color = 100, line=2
						;endif

						first_plot = 0
					endif
				endfor
				plot_count ++
			endfor

		;\\ Davis Zenith
			if n_red ne 0 then begin
				ut = all_cv.red.dav_ut
				vz = all_cv.red.dav_zenith
				vz -= median(vz)
				vze = all_cv.red.dav_zenith_err

				vz = smooth_in_time(ut, vz, 1000., tsm, /gconvol)

				loadct, 0, /silent
				plot, ut, vz, pos = bounds[plot_count, 0, *], /noerase, /nodata, $
						xstyle=9, xtitle = 'Time (UT)'
				oplot, trange, [0,0], line=1
				loadct, red_color[0], /silent

				errplot, ut, vz-vze, vz+vze, color = red_color[1], thick = .4, width = 0.002
				oplot, ut, vz, color = red_color[1], psym=-6, sym=.2
				plot_count ++
			endif

			if n_gre ne 0 then begin

				ut = all_cv.green.dav_ut
				vz = all_cv.green.dav_zenith
				vz -= median(vz)
				vze = all_cv.green.dav_zenith_err

				vz = smooth_in_time(ut, vz, 1000., tsm, /gconvol)

				if plot_count eq n_plots then begin
					loadct, gre_color[0], /silent
					errplot, ut, vz-vze, vz+vze, color = gre_color[1], thick = .4, width = 0.002
					oplot, ut, vz, color=gre_color[1], psym=-6, sym=.2
				endif else begin
					loadct, 0, /silent
					plot, ut, vz, pos = bounds[plot_count, 0, *], /noerase, /nodata, $
						xstyle=9, xtitle = 'Time (UT)'
					oplot, trange, [0,0], line=1
					loadct, gre_color[0], /silent
					errplot, ut, vz-vze, vz+vze, color = gre_color[1], thick = .4, width = 0.002
					oplot, ut, vz, color = gre_color[1], psym=-6, sym=.2
					plot_count ++
				endelse
			endif

		;\\ Plot drift curves
			yrange = [min([min(all_cv.maw_drift), min(all_cv.dav_drift)]), max([max(all_cv.maw_drift), max(all_cv.dav_drift)])]
			plot, all_cv.maw_drift_ut, all_cv.maw_drift, pos = bounds[n_elements(bounds[*,0,0])-1, 1, *], /noerase, /nodata, $
					xstyle=9, xtitle = 'Time (UT)', yrange = yrange, title = 'Drift - Tri=Davis, Box=Mawson', ytitle = 'Drift (m/s)'
			oplot, all_cv.maw_drift_ut, all_cv.maw_drift, psym=-6, sym=.3
			oplot, all_cv.dav_drift_ut, all_cv.dav_drift, psym=-5, sym=.3

		loadct, 0, /silent
		!p.charsize = 0
		!y.title = ''
		!y.range = 0
		!x.range = 0
		!x.style = 0

		;\\ Plot a location map
			mean_ll = [0.5*((station_info('dav')).glat + (station_info('maw')).glat), $
					   0.5*((station_info('dav')).glon + (station_info('maw')).glon)]
			plot_simple_map, mean_ll[0], mean_ll[1], 15, 1, 1, map=map, backColor = [100, 1], $
				bounds = [bounds[0,1,0],bounds[1,1,1],bounds[0,1,2],bounds[0,1,3]]

			plots, map_proj_forward((station_info('dav')).glon, (station_info('dav')).glat, map=map), $
					psym=6, thick = 3, sym = .6, color = 0
			plots, map_proj_forward((station_info('maw')).glon, (station_info('maw')).glat, map=map), $
					psym=6, thick = 3, sym = .6, color = 0

			for k = 0, n_elements(order) - 1 do begin
				dat =  all_cv.(cv_tag[k,0]).(cv_tag[k,1])
				if dat[0].wavelength eq 630.0 then color = red_color
				if dat[0].wavelength eq 557.7 then color = gre_color

				loadct, 39, /silent
				plots, map_proj_forward([dat[0].dav_ll[1], dat[0].maw_ll[1]], $
						[dat[0].dav_ll[0], dat[0].maw_ll[0]], map=map), psym=-5, thick = 3, sym = .3, color = [50,150]

				plot_zonemap_on_map, (station_info('maw')).glat, (station_info('maw')).glon, 0, 0, dat[0].altitude, 180. - abs(dat[0].maw_meta.oval_angle), 0, map, $
						 meta=dat[0].maw_meta, /no_outline, front_color = 150, onlyTheseZones=[dat[0].maw_zone]

				print, dat[0].maw_zone
				loadct, color[0], /silent
				plots, map_proj_forward(dat[0].lon, dat[0].lat, map=map), psym=6, thick = 3, sym = .3, color = color[1]
			endfor




	device, /close
	set_plot, 'win'

end