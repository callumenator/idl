
@resolve_nstatic_wind


pro windsim_peak_height_runner


;	meta_loader, out, ymd='100124', /no_mono, /no_bi, /no_usolve
;	meta1 = out.pkr.meta
;	meta2 = out.hrp.meta
;	meta3 = out.hrp.meta
;		stn = station_info('tlk')
;		meta3.latitude = stn.glat
;		meta3.longitude = stn.glon
;		meta3.oval_angle = stn.oval_angle
;		meta3.site_code = ['TLK']
;	meta4 = out.hrp.meta
;		stn = station_info('kto')
;		meta4.latitude = stn.glat
;		meta4.longitude = stn.glon
;		meta4.oval_angle = stn.oval_angle
;		meta4.site_code = ['KTO']
;	meta = [meta1, meta2, meta3, meta4]

	restore, where_is('windsim') + 'windsim_save.idlsave'	;\\ Restore here for the meta data


sample_noise = 0.0	;\\ m/s
peak_shifts = [0., 10., 20., 30., 40., 50., 60., 70.]

stn_colors = [50, 150, 200, 250]
mono_color = 255
bi_color = [70, 110, 150, 190, 230, 250]
tri_color = [90, 130, 180, 220]

case_dir = where_is('windsim') + 'cases\vary_emission_peak_sheared\shear_in_arc\'

file_mkdir, case_dir

for pk_idx = 0, nels(peak_shifts) - 1 do begin

	run_id = pk_idx

		windsim_generate_fields, fields=fields, auroral_peak_height = 240 - peak_shifts[pk_idx], auroral_brightness = 5.
		windsim_plotbase, meta, fields, stn_colors, map=map


		samples = 0
		for stn = 0, nels(meta) - 1 do begin
			windsim_sample_fields, meta[stn], fields, samples=stn_samples, noise=sample_noise
			append, stn_samples, samples
		endfor

		windsim_fit_samples, meta, samples, fits=mo_fits, /mono
		windsim_fit_samples, meta, samples, fits=bi_fits, /bi
		windsim_fit_samples, meta, samples, fits=tri_fits, /tri


		windsim_test_runner_plotbase, meta, fields, stn_colors, map=map
		windsim_visualize_mono,  mo_fits, map=map, color = [39, 100]
		img = tvrd(/true)
		write_png, case_dir + 'Mono_' + string(peak_shifts[pk_idx], f='(i0)') + '.png', img

		use = where(bi_fits.obsdot lt .7 and max(bi_fits.overlap, dim=1) gt .1 and bi_fits.mangle gt 30, nuse)
		windsim_plotbase, meta, fields, stn_colors, map=map
		windsim_visualize_bi,  bi_fits[use], map=map, color = [39, 100]
		img = tvrd(/true)
		write_png, case_dir + 'Bi_' + string(peak_shifts[pk_idx], f='(i0)') + '.png', img

		use = where(tri_fits.obsdot lt .7 and max(tri_fits.overlap, dim=1) gt .1, nuse)
		windsim_plotbase, meta, fields, stn_colors, map=map
		windsim_visualize_tri,  tri_fits[use], map=map, color = [39, 100]
		img = tvrd(/true)
		write_png, case_dir + 'Tri_' + string(peak_shifts[pk_idx], f='(i0)') + '.png', img

		save, filename = case_dir + 'Data_' + string(run_id, f='(i0)') + '.idlsave', $
		  	  fields, meta, samples, mo_fits, bi_fits, tri_fits

endfor


end
