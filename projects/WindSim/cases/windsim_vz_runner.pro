
@resolve_nstatic_wind




pro windsim_vz_runner


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

case_dir = where_is('windsim') + 'cases\vertical_wind_geometry\rotate\'

dir = case_dir
file_mkdir, dir


for angle_idx = 0, 360, 10 do begin
for mag_idx = 50, 150, 10 do begin

	run_name = 'ang_' + string(angle_idx, f='(i03)') + '_mag_' + string(mag_idx, f='(i03)')

	angle = angle_idx*!DTOR
	u0 = mag_idx*cos(angle)
	v0 = mag_idx*sin(angle)
	windsim_generate_fields, fields=fields, wind_params={u0:u0, v0:v0}

	;\\ Add a sinusoidal vertical wind, no noise
	;xx = findgen(nels(fields.lat))/(nels(fields.lat))
	;nwaves = 3
	;pert = shift(20.*sin(nwaves*2*!PI*xx), 2*t_idx)

	;pert3d = fields.wind_w
	;for fx = 0, nels(pert3d[*,0,0]) - 1 do begin
	;for fz = 0, nels(pert3d[0,0,*]) - 1 do begin
	;	pert3d[fx,*,fz] = pert
	;endfor
	;endfor

	;fields.wind_w += pert3d

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
	write_png, dir + 'Mono_' + run_name + '.png', img

	use = where(bi_fits.obsdot lt .7 and max(bi_fits.overlap, dim=1) gt .1 and bi_fits.mangle gt 30, nuse)
	windsim_plotbase, meta, fields, stn_colors, map=map
	windsim_visualize_bi,  bi_fits[use], map=map, color = [39, 100]
	img = tvrd(/true)
	write_png, dir + 'Bi_' + run_name + '.png', img

	use = where(tri_fits.obsdot lt .7 and max(tri_fits.overlap, dim=1) gt .1, nuse)
	windsim_plotbase, meta, fields, stn_colors, map=map
	windsim_visualize_tri,  tri_fits[use], map=map, color = [39, 100]
	img = tvrd(/true)
	write_png, dir + 'Tri_' + run_name + '.png', img

	save, filename = dir + 'Data_' + run_name + '.idlsave', $
	  	  fields, meta, samples, mo_fits, bi_fits, tri_fits

endfor
endfor

end
