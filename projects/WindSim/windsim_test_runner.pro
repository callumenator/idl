
@resolve_nstatic_wind


pro windsim_test_runner_plotbase, meta, $
								  fields, $
								  stn_colors, $
								  map=map

	window, 0, xs = 800, ys = 800
	aacgmidl
	windsim_visualize_map, fields, map=map, center=[meta[0].latitude, meta[0].longitude], zoom=4
	overlay_geomag_contours, map, lon=10, lat=5, color=[0,255]
	windsim_visualize_intensity, fields, map=map, color=[3,100], thick = 2
	windsim_visualize_wind, fields, 240., map=map, color=[0,150]

	for s = 0, nels(meta) - 1 do begin
		plot_zonemap_on_map, 0,0,0,0, 240, 180 + meta[s].oval_angle, fov, $
							map, front_color=stn_colors[s], /fovEdge, meta=meta[s]
		plots, map_proj_forward(meta[s].longitude, meta[s].latitude, map=map), psym=7, $
				thick=5, color=stn_colors[s], /data
	endfor
end




pro windsim_test_runner


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


sample_noise = 10.0	;\\ m/s

stn_colors = [50, 150, 200, 250]
mono_color = 255
bi_color = [70, 110, 150, 190, 230, 250]
tri_color = [90, 130, 180, 220]

case_dir = where_is('windsim') + 'cases\vertical_wind_timeseries\'

for t_idx = 0, 100 do begin

	dir = case_dir
	file_mkdir, dir

	windsim_generate_fields, fields=fields

	;\\ Add a sinusoidal vertical wind, no noise
	xx = findgen(nels(fields.lat))/(nels(fields.lat))
	nwaves = 3
	pert = shift(20.*sin(nwaves*2*!PI*xx), 2*t_idx)

	pert3d = fields.wind_w
	for fx = 0, nels(pert3d[*,0,0]) - 1 do begin
	for fz = 0, nels(pert3d[0,0,*]) - 1 do begin
		pert3d[fx,*,fz] = pert
	endfor
	endfor

	fields.wind_w += pert3d


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
	write_png, dir + 'Mono_' + string(t_idx, f='(i04)') + '.png', img

	use = where(bi_fits.obsdot lt .7 and max(bi_fits.overlap, dim=1) gt .1 and bi_fits.mangle gt 30, nuse)
	windsim_test_runner_plotbase, meta, fields, stn_colors, map=map
	windsim_visualize_bi,  bi_fits[use], map=map, color = [39, 100]
	img = tvrd(/true)
	write_png, dir + 'Bi_' + string(t_idx, f='(i04)') + '.png', img

	use = where(tri_fits.obsdot lt .7 and max(tri_fits.overlap, dim=1) gt .1, nuse)
	windsim_test_runner_plotbase, meta, fields, stn_colors, map=map
	windsim_visualize_tri,  tri_fits[use], map=map, color = [39, 100]
	img = tvrd(/true)
	write_png, dir + 'Tri_' + string(t_idx, f='(i04)') + '.png', img

	save, filename = dir + 'Data_' + string(t_idx, f='(i04)') + '.idlsave', $
	  	  fields, meta, samples, mo_fits, bi_fits, tri_fits


endfor


end
