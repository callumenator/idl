
@windsim_vz_runner
@windsim_sample_fields

pro windsim_vz_analysis

	case_dir = where_is('windsim') + 'cases\vertical_wind_timeseries\control\'

	files = file_search(case_dir + 'Data*.idlsave', count = nfiles)

	restore, files[0]

	pts = where(bi_fits.mangle lt 3 and $
				bi_fits.obsdot lt .5 and $
				max(bi_fits.overlap, dim=1) gt .1 and $
				bi_fits.stations[0] eq 'PKR' and $
				bi_fits.stations[1] eq 'HRP', nvz)


	tripts = where(tri_fits.obsdot lt .7 and max(tri_fits.overlap, dim=1) gt .1, nvztri)

	bivz = fltarr(nfiles, nvz, 2)
	trivz = fltarr(nfiles, nvztri, 2)
	stvz = fltarr(nfiles, 4, 2)
	vzfield = fltarr(nfiles, 200, 200)

	for f = 0, nfiles - 1 do begin

		restore, files[f]

		vzfield[f, *, *] = fields.wind_w[*, *, 0]

		bivz[f,*,0] = bi_fits[pts].mcomp
		trivz[f,*,0] = tri_fits[tripts].w
		stvz[f,*,0] = samples.zones[0].los

		lats = bi_fits[pts].lat
		lons = bi_fits[pts].lon
		alts = replicate(240, nvz)
		model = windsim_field_at(fields, lats, lons, alts)
		bivz[f,*,1] = model.w

		lats = tri_fits[tripts].lat
		lons = tri_fits[tripts].lon
		alts = replicate(240, nvztri)
		model = windsim_field_at(fields, lats, lons, alts)
		trivz[f,*,1] = model.w

		lats = samples.zones[0].lat
		lons = samples.zones[0].lon
		alts = replicate(240, 4)
		model = windsim_field_at(fields, lats, lons, alts)
		stvz[f,*,1] = model.w

		print, f
		wait, 0.1
	endfor



	windsim_test_runner_plotbase, meta, $
								  fields, $
								  [50, 100, 150, 200], $
								  map=map

	!p.font = 0
	device, set_font="Ariel*17*Bold"


	means = fltarr(nvz)
	for k = 0, nvz - 1 do begin
		means[k] = mean(bivz[*,k,0])
		lat = bi_fits[pts[k]].lat
		lon = bi_fits[pts[k]].lon
		xy = map_proj_forward(lon, lat, map=map)
		xyouts, xy[0], xy[1], /data, string(means[k], f='(f0.1)'), chars = 2, chart = 2, color = 255
	endfor

	!p.font = -1

	stop

end