

@resolve_nstatic_wind

pro windsim_wave_runner


	restore, where_is('windsim') + 'windsim_save.idlsave'	;\\ Restore here for the meta data


	sample_noise = 10.0	;\\ m/s

	stn_colors = [50, 150, 200, 250]
	mono_color = 255
	bi_color = [70, 110, 150, 190, 230, 250]
	tri_color = [90, 130, 180, 220]

	case_dir = where_is('windsim') + 'cases\waves\' + 'Noise' + string(sample_noise, f='(i02)') + '\'
	file_mkdir, case_dir

	for time_idx = 0, 100 do begin

		run_id = string(time_idx, f='(i04)')

		windsim_generate_fields, fields=fields, wind_params = {u0:100., v0:100.}
		windsim_polarization, 10, 2*!PI/(14*60.), 300.E3, 45., 5.*14.*60.*(time_idx/100.), 0., fields, $
							  u_pert=u_pert, v_pert=v_pert, w_pert=w_pert, properties=wave_props

		fields.wind_u += u_pert
		fields.wind_v += v_pert
		fields.wind_w += w_pert


		samples = 0
		for stn = 0, nels(meta) - 1 do begin
			windsim_sample_fields, meta[stn], fields, samples=stn_samples, noise=sample_noise
			append, stn_samples, samples
		endfor

		windsim_fit_samples, meta, samples, fits=mo_fits, /mono
		windsim_fit_samples, meta, samples, fits=bi_fits, /bi
		windsim_fit_samples, meta, samples, fits=tri_fits, /tri

		windsim_plotbase, meta, fields, stn_colors, map=map
		windsim_visualize_mono,  mo_fits, map=map, color = [39, 100]
		img = tvrd(/true)
		write_png, case_dir + 'Field_' + run_id + '.png', img


		save, filename = case_dir + 'Data_' + run_id + '.idlsave', $
		  	  fields, meta, samples, mo_fits, bi_fits, tri_fits


		print, time_idx
	endfor


end
