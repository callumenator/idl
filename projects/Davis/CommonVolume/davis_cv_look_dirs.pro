
pro davis_cv_look_dirs

	file = 'F:\FPSData\Mawson\MAW red_sky_2011_086_date_03_27_630_stripped.0_nm.sky'
	sdi3k_read_netcdf_data, file, meta=meta

	azis = [273, 273, 273, 273, 273]
	eles = [55, 35, 17.5, 10.7, 24]
	colors = [250, 250, 150, 150, 250]
	alts= [240, 240, 120, 120, 240]
	zens = 90 - eles

	window, 0, xs = 800, ys = 800

		mean_ll = [0.5*((station_info('dav')).glat + (station_info('maw')).glat), $
				   0.5*((station_info('dav')).glon + (station_info('maw')).glon)]
		plot_simple_map, mean_ll[0], mean_ll[1], 15, 1, 1, map=map

		plots, map_proj_forward((station_info('dav')).glon, (station_info('dav')).glat, map=map), $
				psym=6, thick = 3, sym = 2, color = 0
		plots, map_proj_forward((station_info('maw')).glon, (station_info('maw')).glat, map=map), $
				psym=6, thick = 3, sym = 2, color = 0

		plot_zonemap_on_map, (station_info('maw')).glat, (station_info('maw')).glon, 0, 0, 110, 180. + abs(meta.oval_angle), 0, map, $
						 meta=meta, /no_outline, front_color = 0
		plot_zonemap_on_map, (station_info('maw')).glat, (station_info('maw')).glon, 0, 0, 240, 180. + abs(meta.oval_angle), 0, map, $
						 meta=meta, /no_outline, front_color = 150

		ell = get_end_lat_lon((station_info('dav')).glat, (station_info('dav')).glon, $
								get_great_circle_length(zens, alts), azis)

		plots, map_proj_forward(ell[*,1], ell[*,0], map=map), color = colors, psym=6, thick = 3
		locs = map_proj_forward(ell[*,1], ell[*,0], map=map)
		xyouts, locs[0,*], locs[1,*], string(indgen(n_elements(azis)), f='(i0)'), color= 0, chars = 2

		for k = 0, n_elements(azis) - 1 do begin
			caz = azis[k]
			czn = zens[k]
			alt = alts[k]

			for ang = 0, 370, 10 do begin
				ell = get_end_lat_lon((station_info('dav')).glat, (station_info('dav')).glon, $
									get_great_circle_length(czn + 3*cos(ang*!dtor), alt), caz + 3*sin(ang*!dtor))
				if ang eq 0 then plots, map_proj_forward(ell[1], ell[0], map=map), color = 0, thick = 2 $
					else plots, map_proj_forward(ell[1], ell[0], map=map), /continue, color = 0, thick = 2
			endfor
		endfor
end