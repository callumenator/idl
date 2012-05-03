
;\\ Plot the current snapshots
pro sdi_monitor_output, persistent, $
						out_dir, $
						oldest_snapshot=oldest_snapshot	;\\ Oldest snapshot time in days

	if not keyword_set(oldest_snapshot) then oldest_snapshot = 1E9


	wx = 1000.
	wy = 1000.
	window, 0, xs=wx, ys=wy


	;\\ Color map
		color_map = {wavelength:[5577, 6300, 6328, 7320, 8430], $
						 ctable:[  39,   39,   39,    2,    2], $
					 	  color:[ 150,  250,  190,  143,  207]}


	;\\ Count up sites and snapshots
		for k = 0, n_tags(persistent) - 1 do begin
			snapshot_time = convert_js(persistent.(k).end_time)
			current_time = convert_js(dt_tm_tojs(systime()))
			day_diff = 365.*(current_time.year - snapshot_time.year) + (current_time.dayno - snapshot_time.dayno)
			if day_diff le oldest_snapshot then begin
				append, persistent.(k).site_code, sites
				append, k, sites_map
			endif
		endfor
		if size(sites, /type) eq 0 then return

		ord_sites = sites[sort(sites)]
		u_sites = ord_sites[uniq(ord_sites)]
		n_sites = n_elements(u_sites)

		n_snapshots = intarr(n_sites)
		for k = 0, n_sites - 1 do begin
			site = u_sites[k]
			snaps = where(sites eq site, n_snaps)
			n_snapshots[k] = n_snaps
		endfor


	;\\ Set plot widths
		max_snaps = max(n_snapshots)
		snap_width = wx / float(max_snaps)
		snap_height = wy / float(n_sites)
		if (snap_width gt snap_height) then snap_width = snap_height else snap_height = snap_width


	loadct, 39, /silent
	for site_idx = 0, n_sites - 1 do begin

		site_width = wx/float(n_sites)

		site = u_sites[site_idx]
		snaps = sites_map[where(sites eq site, n_snaps)]

		snap_lambdas = intarr(n_snaps)
		for k = 0, n_snaps - 1 do snap_lambdas[k] = persistent.(snaps[k]).wavelength
		order = sort(snap_lambdas)
		snaps = snaps[order]

		for snap_idx = 0, n_snaps - 1 do begin

			snap = snaps[snap_idx]
			xoff = snap_idx * snap_width
			yoff = wy - ((site_idx + 1) * snap_height)
			offset = [xoff, yoff]

			;\\ Scale the zonemap, zone_bounds, and zone_centers to the correct size
				frac = .9
				zmap_size = n_elements(persistent.(snap).zonemap[*,0])
				scale = snap_width*frac / float(zmap_size)
				zone_centers = persistent.(snap).zone_centers * scale
				n_zones = n_elements(zone_centers[*,0])


			;\\ Plot zone boundaries
				zmap_offset = (offset+(1-frac)*snap_width/2.)
				plot_zone_bounds, snap_width*frac, persistent.(snap).rads, persistent.(snap).secs, $
								  offset=zmap_offset, ctable=0, color=190
				loadct, 39, /silent


			;\\ Plot the spectra
				spex = persistent.(snap).spectra
				n_chann = n_elements(spex[0,*])

				spex_cmap_pt = (where(color_map.wavelength eq persistent.(snap).wavelength, n_cmap))[0]
				if n_cmap eq 0 then begin
					loadct, 39, /silent
					spex_color = 100
				endif else begin
					loadct, color_map.ctable[spex_cmap_pt], /silent
					spex_color = color_map.color[spex_cmap_pt]
				endelse

				fs = spex[0,*]
				fs -= min(fs)
				fs /= max(fs)
				fg = gaussfit(findgen(n_chann), fs, coeffs, nterms=3)
				spec_shift = n_chann/2. - coeffs[1]

				blank = replicate(' ', 20)
				hwidth = snap_width/sqrt(n_zones)/3.
				ord = spex[sort(spex)]
				rnge = [ord[.15*n_elements(ord)], ord[.985*n_elements(ord)]]
				for zone_idx = 0, n_zones - 1 do begin

					sp = shift(reform(spex[zone_idx, *]), spec_shift)
					sp -= min(sp)
					sp /= max(sp)
					box = [zmap_offset[0] + zone_centers[zone_idx,0] - hwidth, $
						   zmap_offset[1] + zone_centers[zone_idx,1] - hwidth, $
						   zmap_offset[0] + zone_centers[zone_idx,0] + hwidth, $
						   zmap_offset[1] + zone_centers[zone_idx,1] + hwidth]
					plot, sp, psym=3, /noerase, pos = box, /device, /nodata, $
						  xstyle=9, ystyle=5, xtickname = blank, noclip=1, xticklen=.001
					oplot, sp, psym=3, color = spex_color
				endfor


			;\\ Add some annotation
				!p.font = 0
				device, set_font="Ariel*15*Bold"

				times = time_str_from_decimalut(js2ut([persistent.(snap).start_time, persistent.(snap).end_time]))
				labels = ['Site: ' + persistent.(snap).site_code, $
						  'Wavelength: ' + string(persistent.(snap).wavelength/10., f='(f0.1)') + ' nm', $
						  'Start: ' + times[0] + ' UT', $
						  'End:   ' + times[1] + ' UT', $
						  'Scans:   ' + string(persistent.(snap).scans, f='(i0)')]

				n_labels = n_elements(labels)
				xyouts, offset[0] + replicate(5, n_labels), $
						offset[1] + snap_height - (indgen(n_labels)+1)*15 , $
						labels, /device


				!p.font = -1



		endfor ;\\ snapshot loop
	endfor ;\\ site loop

end