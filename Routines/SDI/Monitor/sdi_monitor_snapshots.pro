
;\\ Plot the current snapshots
pro sdi_monitor_snapshots, oldest_snapshot=oldest_snapshot	;\\ Oldest snapshot time in days

	common sdi_monitor_common, global, persistent

	if not keyword_set(oldest_snapshot) then oldest_snapshot = 1E9
	if size(persistent, /type) eq 0 then return
	if ptr_valid(persistent.zonemaps) eq 0 then return
	if ptr_valid(persistent.snapshots) eq 0 then return

	;\\ Color map
		color_map = {wavelength:[5577, 6300, 6328, 7320, 8430], $
						 ctable:[  39,   39,   39,    2,    2], $
					 	  color:[ 150,  250,  190,  143,  207]}


	;\\ Get the array of zonemap info
		zonemaps = *persistent.zonemaps


	;\\ Count up unique sites and snapshots
		snapshots = *persistent.snapshots
		snap_ages = (dt_tm_tojs(systime(/ut)) - snapshots.end_time) / (24.*60.*60.)

		;young = where(day_diff le oldest_snapshot, n_young)
		;if n_young eq 0 then return	;\\ Something should happen here - eg blank image, etc
		;snapshots = snapshots[young]

		sites = snapshots.site_code
		s_sites = sites[sort(sites)]
		u_sites = s_sites[uniq(s_sites)]
		n_sites = n_elements(u_sites)

		n_snapshots = intarr(n_sites)
		for k = 0, n_sites - 1 do begin
			snaps = where(sites eq u_sites[k], n_snaps)
			n_snapshots[k] += n_snaps
		endfor


	;\\ Set plot widths
		max_snaps = max(n_snapshots)
		snap_width = 600.
		snap_height = 600.

		wy = snap_width * float(max_snaps)
		wx = snap_height * float(n_sites)

		widget_control, draw_xsize=wx, draw_ysize=wy, global.draw_id[0]
		widget_control, get_value = wset_id, global.draw_id[0]
		wset, wset_id
		loadct, 39, /silent
		erase, 0

	for site_idx = 0, n_sites - 1 do begin

		site = u_sites[site_idx]
		snaps = where(sites eq site, n_snaps)
		ages = snap_ages[snaps]

		;\\ Plot in order of increasing wavelength
			snap_lambdas = float(snapshots[snaps].wavelength)
			no_fits = where(snap_lambdas eq 5890 or $
							snap_lambdas eq 7320, n_no_fits)
			if n_no_fits gt 0 then snap_lambdas[no_fits] *= 5
			cals = where(snap_lambdas eq 6328 or $
						 snap_lambdas eq 5430, n_cals)
			if n_cals gt 0 then snap_lambdas[cals] *= 100
			order = sort(snap_lambdas)
			snaps = snaps[order]
			ages = ages[order]


		for snap_idx = 0, n_snaps - 1 do begin

			snap = snaps[snap_idx]
			snapshot_age = ages[snap_idx]

			snapshot = snapshots[snap]
			have_fits = ptr_valid(snapshot.fits)

			yoff = wy - ((snap_idx + 1) * snap_height)
			xoff = site_idx * snap_width

			offset = [xoff, yoff]

			;\\ Scale the zonemap, zone_bounds, and zone_centers to the correct size
				frac = .9
				zmap_size = n_elements(zonemaps[snapshot.zonemap_index].zonemap[*,0])
				scale = snap_width*frac / float(zmap_size)
				zone_centers = *(zonemaps[snapshot.zonemap_index].centers) * scale
				n_zones = n_elements(zone_centers[*,0])
				zmap_offset = (offset+(1-frac)*snap_width/2.) + [0, 0]


			;\\ If we have spectral fits, make a parameter skymap
				if have_fits eq 1 then begin

					centers = *(zonemaps[snapshot.zonemap_index].centers)
					pix_per_zone = *(zonemaps[snapshot.zonemap_index].pix_per_zone)

					snr_per_scan = (*snapshot.fits).snr / float(snapshot.scans)
					snr_per_scan /= pix_per_zone
					snr_per_scan = median(snr_per_scan)

					case global.background_parameter of

						'Temperature': begin
							parameter = (*snapshot.fits).width
							median_parameter = median(parameter)
							sdi3k_spacesmooth_fits, parameter, 0.09, {nzones:snapshot.nzones}, centers/float(zmap_size)
							case snapshot.wavelength of
								5577: scale = [200, 700]
								5890: scale = [800, 1600]
								6300: scale = [600, 1400]
								8430: scale = [100, 400]
								else: scale = [600, 1200]
							endcase
							scale_to = [50, 250]
							ctable = 39
							unit = 'K'
						end

						'Intensity': begin
							parameter = (*snapshot.fits).area / float(snapshot.end_time - snapshot.start_time)
							parameter /= pix_per_zone
							median_parameter = median(parameter)
							case snapshot.wavelength of
								5577: scale = [0, 100000]
								6300: scale = [0, 10000]
								8430: scale = [50, 5000]
								else: scale = [600, 1200]
							endcase
							scale_to = [50, 250]
							ctable = 39
							unit = ''
						end

						'SNR/Scan': begin
							parameter = (*snapshot.fits).snr / float(snapshot.scans)
							parameter /= pix_per_zone
							median_parameter = median(parameter)
							case snapshot.wavelength of
								5577: scale = [0, 10000]
								6300: scale = [0, 1000]
								8430: scale = [0, 300]
								else: scale = [0, 1000]
							endcase
							scale_to = [50, 250]
							ctable = 23
							unit = ''
						end

						'Chi Squared': begin
							parameter = (*snapshot.fits).chi
							median_parameter = median(parameter)
							scale = [0, 4]
							scale_to = [50, 250]
							ctable = 23
							unit = ''
						end

						else:stop
					endcase

					scl_bar = fltarr(20, .2*snap_height)
					scl_height = n_elements(scl_bar[0,*])
					for j = 0, 19 do scl_bar[j,*] = $
						interpol(scale_to, [0, scl_height], findgen(scl_height))

					scl_param = ((parameter - scale[0]) / (scale[1]-scale[0]))*(scale_to[1]-scale_to[0]) + scale_to[0]
					scl_param = scl_param < scale_to[1]
					scl_param = scl_param > scale_to[0]
					plot_zone_bounds, snap_width*frac, $
								  *(zonemaps[snapshot.zonemap_index].rads), $
								  *(zonemaps[snapshot.zonemap_index].secs), $
								  offset=zmap_offset, ctable=ctable, fill=scl_param

					xpos = offset[0] + snap_width - 35
					ypos = offset[1] + 20
					tv, scl_bar, xpos, ypos
					loadct, 39, /silent
					xyouts, xpos - 5, ypos + scl_height/2., global.background_parameter, orientation=90, $
							align=.5, color=255, /device, chars = 1
					!p.font = 0
					device, set_font="Ariel*15*Bold"
					xyouts, xpos + 10, ypos - 12, string(scale[0], f='(i0)') + ' ' + unit, align=.5, color=255, /device
					xyouts, xpos + 10, ypos + scl_height + 1, string(scale[1], f='(i0)') + ' ' + unit, align=.5, color=255, /device
					!p.font = -1

				endif



			;\\ Plot zone boundaries
				plot_zone_bounds, snap_width*frac, $
								  *(zonemaps[snapshot.zonemap_index].rads), $
								  *(zonemaps[snapshot.zonemap_index].secs), $
								  offset=zmap_offset, ctable=0, color=190
				loadct, 39, /silent


			;\\ Plot the spectra
				spex = *snapshot.spectra
				n_chann = n_elements(spex[0,*])

				spex_cmap_pt = (where(color_map.wavelength eq snapshot.wavelength, n_cmap))[0]
				if n_cmap eq 0 then begin
					loadct, 39, /silent
					spex_color = 100
				endif else begin
					loadct, color_map.ctable[spex_cmap_pt], /silent
					spex_color = color_map.color[spex_cmap_pt]
				endelse


				if have_fits eq 0 then begin
   					spec0 = reform(spex[0,*])
					p = total(spec0 * sin((2*!pi*findgen(n_chann)/float(n_chann))))
					q = total(spec0 * cos((2*!pi*findgen(n_chann)/float(n_chann))))
					c = (atan(p, q) / (2*!pi))*n_chann
					spec_shift = n_chann/2. - c
				endif else begin
					spec_shift = (*snapshot.fits).shft
				endelse

				blank = replicate(' ', 20)
				hwidth = snap_width/sqrt(n_zones)/3.
				ord = spex[sort(spex)]
				rnge = [ord[.15*n_elements(ord)], ord[.985*n_elements(ord)]]
				for zone_idx = 0, n_zones - 1 do begin

					sp = shift(reform(spex[zone_idx, *]), spec_shift)
					sp -= min(sp)

					box = [zmap_offset[0] + zone_centers[zone_idx,0] - hwidth, $
						   zmap_offset[1] + zone_centers[zone_idx,1] - hwidth, $
						   zmap_offset[0] + zone_centers[zone_idx,0] + hwidth, $
						   zmap_offset[1] + zone_centers[zone_idx,1] + hwidth]
					plot, findgen(n_chann), sp, psym=3, /noerase, pos = box, /device, /nodata, $
						  xstyle=9, ystyle=5, xtickname = blank, noclip=1, xticklen=.001
					oplot, findgen(n_chann), sp, color = 255

					if have_fits eq 1 then begin
						;sp = shift(reform(*spex[zone_idx, *]), spec_shift)
						;sp -= min(sp)
					endif
				endfor

			;\\ Get a copy of the image just produced
				currImage = tvrd(offset[0], offset[1], snap_width, snap_height, /true)
				if (snapshot_age gt oldest_snapshot) then begin
					currImage *= .3
					device, decomposed=1
					tv, currImage, offset[0], offset[1], /true
					device, decomposed=0
				endif


			;\\ Add some annotation
				!p.font = 0
				device, set_font="Ariel*15*Bold"

				t_diff = dt_tm_tojs(systime(/ut)) - snapshot.end_time
				yr_diff = (t_diff / (365.*24.*60.*60.))
				dy_diff = (yr_diff mod 1)*365.
				hr_diff = (dy_diff mod 1)*24
				mn_diff = (hr_diff mod 1)*60.

				age = [fix(yr_diff), $
					   fix(dy_diff), $
					   fix(hr_diff), $
					   fix(mn_diff)]

				;\\ Pluralise labels
				not_one = where(age ne 1, n_not_one)
				age_str = [' year', ' day', ' hr', ' min']
				if n_not_one gt 0 then age_str[not_one] += 's'
				age_str[0:2] += ','

				mn = (where(age gt 0, n_mn))[0]
				if n_mn eq 0 then begin
					age_out = string(t_diff, f='(f0.1)') + ' secs'
				endif else begin
					age_out = string(age[mn:*], f='(i4)') + age_str[mn:*]
				endelse
				age_out = ['Age:', age_out]


				;\\ Create a more descriptive name than the site code
				case snapshot.site_code of
					'PKR':site_name = 'Poker Flat, Alaska'
					'HRP':site_name = 'HAARP, Gakona, Alaska'
					'MAW':site_name = 'Mawson, Antarctica'
					'TLK':site_name = 'Toolik Lake, Alaska'
					'KTO':site_name = 'Kaktovik, Alaska'
					else:site_name = snapshot.site_code
				endcase

				times = time_str_from_decimalut(js2ut([snapshot.start_time, snapshot.end_time]))
				labels = ['Site: ' + site_name, $
						  'Wavelength: ' + string(snapshot.wavelength/10., f='(f0.1)') + ' nm']
				if have_fits then labels = [labels, 'SNR/Scan: ' + string(snr_per_scan, f='(i0)')]

				loadct, 0, /silent
				text_color = 220
				n_labels = n_elements(labels)
				xyouts, offset[0] + replicate(3, n_labels), $
						offset[1] + snap_height - (indgen(n_labels)+1)*15 , $
						labels, /device, color=text_color

				n_labels = n_elements(age_out)
				xyouts, offset[0] + replicate(3, n_labels), $
						offset[1] + reverse(findgen(n_labels)+.5)*15 , $
						age_out, /device, color=text_color

				labels = ['Start: ' + times[0] + ' UT', $
						  'End:   ' + times[1] + ' UT', $
						  'Scans:   ' + string(snapshot.scans, f='(i0)')]
				n_labels = n_elements(labels)
				xyouts, offset[0] + snap_width + replicate(0, n_labels), $
						offset[1] + snap_height - (indgen(n_labels)+1)*15 , $
						labels, /device, align=1.05, color=text_color

				if have_fits eq 1 then begin
					label = 'Median: ' + string(median_parameter, f='(f0.1)') + ' ' + unit
					xyouts, offset[0] + snap_width/2., $
							offset[1] + 3, align=.5, label, color=text_color, /device
				endif

				!p.font = -1

		endfor ;\\ snapshot loop
	endfor ;\\ site loop


	;\\ Plot divisions
	loadct, 0, /silent
	for xx = 0, n_sites do begin
		plots, [snap_width*xx-1,snap_width*xx-1], [0, wy], /device, color = 150
	endfor
	for yy = 0, max_snaps do begin
		plots, [0, wx], [snap_height*yy - 1,snap_height*yy - 1], /device, color = 150
	endfor


end