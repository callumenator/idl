
@resolve_nstatic_wind


pro windsim_noise_sensitivity_runner


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

stn_colors = [50, 150, 200, 250]
mono_color = 255
bi_color = [70, 110, 150, 190, 230, 250]
tri_color = [90, 130, 180, 220]

case_dir = where_is('windsim') + 'cases\noise_sensitivity\'

dir = case_dir
file_mkdir, dir


for noise_idx = 0, 10 do begin
for run_idx = 0, 100 do begin

	run_name = 'noise_' + string(noise_idx, f='(i03)') + '_run_' + string(run_idx, f='(i03)')

	u0 = 0
	v0 = 0
	windsim_generate_fields, fields=fields, wind_params={u0:u0, v0:v0}

	sample_noise = 3.*noise_idx

	samples = 0
	for stn = 0, nels(meta) - 1 do begin
		windsim_sample_fields, meta[stn], fields, samples=stn_samples, noise=sample_noise
		append, stn_samples, samples
	endfor

	windsim_fit_samples, meta, samples, fits=mo_fits, /mono
	windsim_fit_samples, meta, samples, fits=bi_fits, /bi
	windsim_fit_samples, meta, samples, fits=tri_fits, /tri


	save, filename = dir + 'Data_' + run_name + '.idlsave', $
	  	  meta, samples, mo_fits, bi_fits, tri_fits, sample_noise, run_idx

	if noise_idx eq 0 and run_idx eq 0 then save, filename = dir + 'Data_Fields.idlsave', fields

endfor
endfor

end
