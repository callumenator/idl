
@resolve_nstatic_wind
@windsim_sample_fields

pro windsim_noise_sensitivity_analysis

	case_dir = where_is('windsim') + 'cases\noise_sensitivity\'

	restore, case_dir + 'Data_Fields.idlsave'
	data = file_search(case_dir + 'Data_noise*.idlsave', count=nfiles)


	restore, data[0]
		bi_use = where(bi_fits.obsdot lt .83 and max(bi_fits.overlap, dim=1) gt .1 and $
						bi_fits.mangle gt 30, nbi_use)


		tri_use = where(tri_fits.obsdot lt .83 and max(tri_fits.overlap, dim=1) gt .1 and $
					total(strmatch(tri_fits.stations, 'PKR') + $
						  strmatch(tri_fits.stations, 'HRP') + $
						  strmatch(tri_fits.stations, 'TLK'), 1) ne 3 , ntri_use)


	noise = fltarr(nfiles)
	bi_mag = fltarr(nfiles, nbi_use)
	tri_mag = fltarr(nfiles, ntri_use)

	if 0 then begin
		for k = 0, nfiles - 1 do begin

			restore, data[k]

			noise[k] = sample_noise

			bi_fits = bi_fits[bi_use]
			model = windsim_field_at(fields, bi_fits.lat, bi_fits.lon, replicate(240., nbi_use))
			for ix = 0, nbi_use - 1 do begin
				wind = project_bistatic_fit(bi_fits[ix], 0)

				;\\ Resolve the real wind along the bistatic axes
				units = get_unit_spherical(bi_fits[ix].lat, bi_fits[ix].lon)
				wind_cartesian = model.u[ix] * units.zonal + $
								 model.v[ix] * units.merid + $
								 model.w[ix] * units.zenith
				wind_plane = [dotp(wind_cartesian, bi_fits[ix].laxis), $
							  dotp(wind_cartesian, bi_fits[ix].maxis) ]

				;bi_mag[k, ix] = norm(wind - [model.u[ix], model.v[ix], 0])
				bi_mag[k, ix] = sqrt( (bi_fits[ix].lcomp-wind_plane[0])^2. + (bi_fits[ix].mcomp-wind_plane[1])^2.)
				wait, 0.0001
			endfor

			tri_fits = tri_fits[tri_use]
			model = windsim_field_at(fields, tri_fits.lat, tri_fits.lon, replicate(240., ntri_use))
			for ix = 0, ntri_use - 1 do begin
				wind = [tri_fits[ix].u, tri_fits[ix].v, 0]
				tri_mag[k, ix] = norm(wind - [model.u[ix], model.v[ix], 0])
				wait, 0.0001
			endfor


			print, k, nfiles
		endfor

		save, filename = case_dir + 'analysis_data.idlsave', noise, bi_mag, tri_mag
	endif else begin
		restore, case_dir + 'analysis_data.idlsave'
	endelse


	restore, data[0]

	unoise = get_unique(noise)
	bi_sdev = fltarr(nels(unoise), nbi_use)
	tri_sdev = fltarr(nels(unoise), ntri_use)
	for k = 0, nels(unoise) - 1 do begin
		sub = where(noise eq unoise[k], n_noise)

		mag_sub = bi_mag[sub, *]
		for ix = 0, nbi_use - 1 do begin
			bi_sdev[k, ix] = stddev(mag_sub[*, ix])
		endfor

		mag_sub = tri_mag[sub, *]
		for ix = 0, ntri_use - 1 do begin
			tri_sdev[k, ix] = stddev(mag_sub[*, ix])
		endfor
	endfor

	bi_grad = fltarr(nbi_use)
	for ix = 0, nbi_use - 1 do begin
		bi_grad[ix] = (linfit(unoise, bi_sdev[*,ix]))[1]
	endfor

	tri_grad = fltarr(ntri_use)
	for ix = 0, ntri_use - 1 do begin
		tri_grad[ix] = (linfit(unoise, tri_sdev[*,ix]))[1]
	endfor

	f = fltarr(ntri_use)
	for k = 0, ntri_use - 1 do begin
		dot12 = dotp(tri_fits[tri_use[k]].losvec1,tri_fits[tri_use[k]].losvec2)
		dot13 = dotp(tri_fits[tri_use[k]].losvec1,tri_fits[tri_use[k]].losvec3)
		dot23 = dotp(tri_fits[tri_use[k]].losvec2,tri_fits[tri_use[k]].losvec3)
		f[k] = dot12+dot13+dot23
	endfor

	col1 = where(total(strmatch(tri_fits[tri_use].stations, 'PKR') + $
 		  		 	   strmatch(tri_fits[tri_use].stations, 'HRP') + $
		  			   strmatch(tri_fits[tri_use].stations, 'KTO'), 1) eq 3)

	col2 = where(total(strmatch(tri_fits[tri_use].stations, 'PKR') + $
 		  		 	   strmatch(tri_fits[tri_use].stations, 'TLK') + $
		  			   strmatch(tri_fits[tri_use].stations, 'KTO'), 1) eq 3)

	col3 = where(total(strmatch(tri_fits[tri_use].stations, 'TLK') + $
 		  		 	   strmatch(tri_fits[tri_use].stations, 'HRP') + $
		  			   strmatch(tri_fits[tri_use].stations, 'KTO'), 1) eq 3)

	color = intarr(ntri_use)
	color[col1] = 250
	color[col2] = 100
	color[col3] = 150

	x0 = total(tri_fits[tri_use].cvDist,1)
	x1 = tri_fits[tri_use].obsdot
	x2 = max(tri_fits[tri_use].overlap, dim=1)
	x3 = (tri_fits[tri_use].aziSum)
	x4 = (tri_fits[tri_use].midvec[2])
	y = tri_grad

	;x0 = (x0-min(x0))/max(x0-min(x0))
	;x1 = (x1-min(x1))/max(x1-min(x1))
	;x2 = (x2-min(x2))/max(x2-min(x2))
	;x3 = (x3-min(x3))/max(x3-min(x3))
	;x4 = (x4-min(x4))/max(x4-min(x4))
	;y = (y-min(y))/max(y-min(y))


	x = transpose([[x1],[x3]])
	cf = regress(x, y, yfit = curve)



	f = cf[0]*x1 + cf[1]*x3
	plot, f, y, /nodata, /xstyle
	plots, f, y, psym=1, color=color


	good = where(finite(bi_grad) eq 1)
	bi_use  = bi_use[good]
	blats = bi_fits[bi_use].lat
	blons = bi_fits[bi_use].lon
	triangulate, blons, blats, tr, b
	bi_mag_map = trigrid(blons, blats, bi_grad[good,0], tr, xout=fields.lon, yout=fields.lat)

	good = where(finite(tri_grad) eq 1)
	tri_use  = tri_use[good]
	tlats = tri_fits[tri_use].lat
	tlons = tri_fits[tri_use].lon
	triangulate, tlons, tlats, tr, b
	tri_mag_map = trigrid(tlons, tlats, tri_grad[good,0], tr, xout=fields.lon, yout=fields.lat)

		stop

end
