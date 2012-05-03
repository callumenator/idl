
pro plot_skymap_series, series, $
						filename=filename, $
						plot_dir=plot_dir

	;series = ['temperature', 'intensity+wind']
	;overlay_contour = {type:'intensity', ctable:39, color:0, thick:2}

	if not keyword_set(plot_dir) then plot_dir = where_is('sdi_skymap_series')

	if not keyword_set(filename) then begin
		files = file_search(where_is('fpsdata') + 'Haarp_Campaign\' + ['*HAARP*630*.nc', '*HAARP*558*'], count = nfiles)
	endif else begin
		files = [filename]
		nfiles = 1
	endelse


	for fidx = 0, nfiles - 1 do begin

		file = files[fidx]
		sdi3k_read_netcdf_data, file, meta=meta, spekfits=fits, spex=spex, winds=winds, zone_centers=zone_centers

		pix_scaling = pixels_per_zone(meta, /relative)

		mapwidth = 200.
		ncols = 10.
		ygap = 30.
		xgap = 10.
		nrows = ceil(meta.maxrec/ncols) + 1

		winx = ncols*(mapwidth+xgap)
		winy = nrows*(mapwidth+ygap)

		nseries = n_elements(series)
		scale_title = ''

		;\\ Pick good vals for scaling
			snr = abs(fits.signal2noise)
			chi = abs(fits.chi_squared)
			good = where(snr gt mean(snr) - 2*meanabsdev(snr) and $
					 	 chi gt mean(chi) - 2*meanabsdev(chi), ng)

			if ng lt 5 then good = indgen(meta.maxrec)

		for s = 0, nseries - 1 do begin

			this_series = series[s]
			split = strsplit(this_series, '+', /extract)
			if n_elements(split) gt 1 then overlay_wind = 1 else overlay_wind = 0
			this_series = split[0]

			case this_series of
				'intensity': begin
					data = fits.intensity
					scdata = data[good]
					top = (scdata[sort(scdata)])[n_elements(scdata)*.99]
					scale = [0, top]/min(pix_scaling)
					ctable = 13
				end
				'temperature': begin
					data = fits.temperature
					sdi3k_spacesmooth_fits, data, .15, meta, zone_centers, /progress
					scdata = data[good]
					top = (scdata[sort(scdata)])[n_elements(scdata)*.98]
					bot = (scdata[sort(scdata)])[n_elements(scdata)*.02]
					scale = round([bot, top] + .05*[-bot, top])
					;scale = [500, 1100]
					scale_title = 'Temperature (K)'
					ctable = 13
				end
				'chisq': begin
					data = fits.chi_squared
					sdi3k_spacesmooth_fits, data, .1, meta, zone_centers, /progress
					scdata = data[good]
					top = (scdata[sort(scdata)])[n_elements(scdata)*.95]
					bot = (scdata[sort(scdata)])[n_elements(scdata)*.05]
					scale = [bot, top] + .05*[-bot, top]
					ctable = 0
				end
				'snr': begin
					data = fits.signal2noise
					sdi3k_spacesmooth_fits, data, .05, meta, zone_centers, /progress
					top = (data[sort(data)])[n_elements(data)*.95]
					bot = (data[sort(data)])[n_elements(data)*.05]
					scale = [bot, top] + .05*[-bot, top]
					ctable = 0
				end
				else:
			endcase

			ut = js2ut(winds.start_time[0])

			window, xs = winx, ys = winy
			for t = 0, meta.maxrec - 1 do begin

				if this_series eq 'intensity' then this_data = reform(data[*,t])/pix_scaling $
					else this_data = reform(data[*,t])

				xpos = (t mod ncols)*(mapwidth + xgap) + xgap/2.
				ypos = winy - (fix(t/ncols)+1)*mapwidth - fix(t/ncols)*ygap


				display_skymap, this_data, $				;\\ Data array [nzones]
								scale=scale, $  			;\\ [min, max]
								metadata=meta, $
								ctable=ctable, $
								skymap_out=skymap_out, $
								/nodisplay
				loadct, ctable, /silent
				tv, congrid(skymap_out, mapwidth, mapwidth, /interp), xpos, ypos, /device
				loadct, 0, /silent

				if overlay_wind eq 1 then begin
					wind_scale = .2
					xs = mapwidth/n_elements(skymap_out[*,0])
					ys = mapwidth/n_elements(skymap_out[0,*])
					loadct, 39, /silent
					zc = zone_centers[*,0:1]*mapwidth + [[replicate(xpos, meta.nzones)], [replicate(ypos, meta.nzones)]]
					angle = meta.rotation_from_oval*!DTOR
					rzn = (winds[t].zonal_wind*cos(angle) - winds[t].meridional_wind*sin(angle))*wind_scale
					rmr = (winds[t].zonal_wind*sin(angle) + winds[t].meridional_wind*cos(angle))*wind_scale
					arrow, zc[*,0] - .5*rzn, $
						   zc[*,1] - .5*rmr, $
						   zc[*,0] + .5*rzn, $
						   zc[*,1] + .5*rmr, $
						   color = 255, hsize = 5, thick = 1

				endif

				xyouts, xpos + mapwidth/2., ypos - .7*ygap, /device, $
					time_str_from_decimalut(ut[t]) + ' UT', align=.5


				;\\ Overlay a contour if requested
				if size(overlay_contour, /type) ne 0 then begin
					loadct, overlay_contour.ctable, /silent
					case overlay_contour.type of
						'intensity':begin
							contour, reform(fits[t].intensity)/pix_scaling, reform(zone_centers[*,0]), reform(zone_centers[*,1]), $
								nlevels = 5, c_color = overlay_contour.color, /noerase, xstyle=5, ystyle=5, pos = [xpos,ypos,xpos+mapwidth,ypos+mapwidth], $
								/device, /irregular, c_thick = overlay_contour.thick

						end
						else:
					endcase
				endif

			endfor

		;\\ Plot a scale bar
			scalebar = fltarr(256, 20)
			for j = 0, 19 do scalebar[*,j] = indgen(256)
			xpos = 50
			ypos = winy - (nrows)*mapwidth - fix(nrows)*ygap + mapwidth/2.

			loadct, ctable, /silent
			tv, scalebar, xpos, ypos

			loadct, 0, /silent
			xyouts, xpos + 128, ypos + 25, /device, color = 255, align=.5, scale_title
			xyouts, xpos, ypos + 7, /device, color = 255, align=1.5, string(scale[0], f='(i0)')
			xyouts, xpos + 256, ypos + 7, /device, color = 255, align=-.5, string(scale[1], f='(i0)')



		;\\ Save the image
			file_name = file_basename(file)
			file_name = strmid(file_name, 0, strlen(file_name) - 4)

			dates = convert_js(winds[0].start_time[0])
			pic = tvrd(/true)
			out_plot_dir = plot_dir + this_series
			exist = file_test(out_plot_dir, /directory)
			if exist ne 1 then begin
				file_mkdir, out_plot_dir
			endif
			write_png, out_plot_dir + '\' + file_name + '.png', pic
			wdelete, !d.window

		endfor ;\\ Plot type loop

	endfor ;\\ File index loop

end