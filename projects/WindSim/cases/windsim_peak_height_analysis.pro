
@resolve_nstatic_wind
@windsim_sample_fields

pro windsim_peak_height_analysis

	case_dir = where_is('windsim') + 'cases\vary_emission_peak_sheared\shear_in_arc\'


	data = file_search(case_dir + 'Data*.idlsave', count=nfiles)

	restore, data[0]
	windsim_plotbase, meta, fields, [50,150,190,250], map=map
	stop


	grida = fltarr(nfiles, 200, 200)
	gridm = fltarr(nfiles, 200, 200)
	pkalt = fltarr(nfiles)
	emission = fltarr(nfiles, 200, 200)
		for j = 0, nfiles - 1 do begin

			restore, data[j]
			pkalt[j] = fields.auroral_peak_height
			emission[j,*,*] = total(fields.emission, 3)

			use = where(bi_fits.obsdot lt .83 and max(bi_fits.overlap, dim=1) gt .1 and $
						bi_fits.mangle gt 30, nuse)

;			ang = fltarr(nuse)
;			mag = fltarr(nuse)
;			model = windsim_field_at(fields, bi_fits[use].lat, bi_fits[use].lon, replicate(240., nuse))
;			for k = 0, nuse - 1 do begin
;				wind = project_bistatic_fit(bi_fits[use[k]], 0)
;				dp = dotp(wind, [model.u[k], model.v[k], 0])
;				nm = (norm(wind)*norm([model.u[k], model.v[k], 0]))
;				ang[k] = acos( (dp/nm) < 1.0  )/!DTOR
;				mag[k] = norm(wind - [model.u[k], model.v[k], 0])
;				wait, 0.0001
;				print, k, j
;			endfor
;			lats = bi_fits[use].lat
;			lons = bi_fits[use].lon



;			ang = fltarr(nels(mo_fits))
;			mag = fltarr(nels(mo_fits))
;			model = windsim_field_at(fields, mo_fits.lat, mo_fits.lon, replicate(240., nels(mo_fits)))
;
;			for k = 0, nels(mo_fits) - 1 do begin
;				wind = [mo_fits[k].u, mo_fits[k].v, 0]
;				dp = dotp(wind, [model.u[k], model.v[k], 0])
;				nm = (norm(wind)*norm([model.u[k], model.v[k], 0]))
;				ang[k] = acos( (dp/nm) < 1.0  )/!DTOR
;				mag[k] = norm(wind - [model.u[k], model.v[k], 0])
;				wait, 0.0001
;				print, k, j
;			endfor
;			lats = mo_fits.lat
;			lons = mo_fits.lon


			use = where(tri_fits.obsdot lt .83 and max(tri_fits.overlap, dim=1) gt .1 and $
						total(strmatch(tri_fits.stations, 'PKR') + $
							  strmatch(tri_fits.stations, 'HRP') + $
							  strmatch(tri_fits.stations, 'TLK'), 1) ne 3 , nuse)
			tri_fits = tri_fits[use]

			ang = fltarr(nuse)
			mag = fltarr(nuse)
			model = windsim_field_at(fields, tri_fits.lat, tri_fits.lon, replicate(240., nuse))

			for k = 0, nuse - 1 do begin
				wind = [tri_fits[k].u, tri_fits[k].v, 0]
				dp = dotp(wind, [model.u[k], model.v[k], 0])
				nm = (norm(wind)*norm([model.u[k], model.v[k], 0]))
				ang[k] = acos( (dp/nm) < 1.0  )/!DTOR
				mag[k] = norm(wind - [model.u[k], model.v[k], 0])
				wait, 0.0001
				print, k, j
			endfor
			lats = tri_fits.lat
			lons = tri_fits.lon

			triangulate, lons, lats, tr, b
			res = trigrid(lons, lats, ang, tr, xout=fields.lon, yout=fields.lat)
			grida[j,*,*] = res
			res = trigrid(lons, lats, mag, tr, xout=fields.lon, yout=fields.lat)
			gridm[j,*,*] = res


		endfor




	window, 0, xs = 1600, ys = 400

	ang_scl = [0, 8]
	mag_scl = [0, 20]

	!p.font = 0
	device, set_font="Ariel*11*Bold"

	for i = 0, 7 do begin
		scale_to_range, reform(smooth(grida[i,*,*] - grida[0,*,*], [1,5,5], /edge)), ang_scl[0], ang_scl[1], a
		loadct, 27, /silent
		tv, congrid(a, 200, 200), i*200, 200

		loadct, 0, /silent
		contour, reform(emission[i,*,*]), c_color = 0, $
				 nlevels = 3, /noerase, pos = [i*200,200,(i+1)*200,400], /device

		xyouts, i*200 + 20, 210, /device, 'Angle Resid (' + string(ang_scl[0], f='(i0)') + $
										  '-' + string(ang_scl[1], f='(i0)') + ' deg) ' + $
										  'Peak Alt: ' + string(pkalt[i], f='(i0)') + ' km', color=0, chart = 2
	endfor

	for i = 0, 7 do begin
		scale_to_range, reform(smooth(gridm[i,*,*] - gridm[0,*,*], [1,5,5], /edge)), mag_scl[0], mag_scl[1], a
		loadct, 27, /silent
		tv, congrid(a, 200, 200), i*200, 0

		loadct, 0, /silent
		contour, congrid(reform(emission[i,*,*]), 200, 200), c_color = 0, $
				 nlevels = 3, /noerase, pos = [i*200,0,(i+1)*200,200], /device

		xyouts, i*200 + 20, 10, /device, 'Mag. Resid (' + string(mag_scl[0], f='(i0)') + $
										  '-' + string(mag_scl[1], f='(i0)') + ' m/s) ' + $
										  'Peak Alt: ' + string(pkalt[i], f='(i0)') + ' km', color=0, chart = 2
	endfor

	!p.font = -1


	stop



	;\\ Spatial residuals
	ogrid = fltarr(6,200,200)
	for r = 0, nruns - 1 do begin
		data = file_search(runs[r] + '\*.idlsave', count=nfiles)
		grid = fltarr(nfiles, 200, 200)
		for j = 0, nfiles - 1 do begin

			restore, data[j]

			use = where(bi_fits.obsdot lt .7 and max(bi_fits.overlap, dim=1) gt .1, nuse)
			lats = bi_fits[use].lat
			lons = bi_fits[use].lon
			triangulate, lons, lats, tr, b
			res = trigrid(lons, lats, bi_resid, tr, xout=fields.lon, yout=fields.lat, /quintic)

			grid[j,*,*] = res
		endfor


		scale_to_range, abs(reform(grid[10,*,*]) - total(grid, 1)/float(nfiles)), 0, 10, ores
		ogrid[r,*,*] = smooth(ores, 5, /edge)

	endfor

	stop

end
