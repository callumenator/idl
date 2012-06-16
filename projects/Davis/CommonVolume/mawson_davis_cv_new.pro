@resolve_nstatic_wind

pro mawson_davis_cv_new

@sdi3k_ncdf_inc
loadct, 39, /silent

	;\\ I think positive is from davis-to-mawson now...
	mlat = (station_info(['dav','maw'])).mlat
	mlon = (station_info(['dav','maw'])).mlon
	mag_bearing = (map_2points(mlon[0], mlat[0], mlon[1], mlat[1]))[1]
	hvec = [sin(mag_bearing*!DTOR), cos(mag_bearing*!DTOR)]
	glat = (station_info(['dav','maw'])).glat
	glon = (station_info(['dav','maw'])).glon
	geo_sep = ((map_2points(glon[0], glat[0], glon[1], glat[1], /meters))[0])/1000.

	aacgmidl
	redo = 1
	top_dir = where_is('mawson_davis_cv')
	done_list = file_search(where_is('mawson_davis_cv') + 'Data\*.idlsave')

	maw_red_files = file_search(where_is('mawson_data'), '*2011*630*.nc', count = n_maw_red)
	maw_gre_files = file_search(where_is('mawson_data'), '*2011*557*.nc', count = n_maw_gre)

	dav_dates = $
	 ['110410', '110411', '110413', '110414', '110415', '110416', '110417',$
	  '110418', '110419', '110420', '110422', '110423', '110424', '110426',$
	  '110427', '110428', '110429', '110430', '110501', '110503', '110504',$
	  '110505', '110510', '110511', '110512', '110513', '110514', '110515',$
	  '110519', '110520', '110528', '110529', '110530', '110606', '110607',$
	  '110610', '110613', '110615', '110616', '110617', '110618', '110620',$
	  '110623', '110624', '110704', '110709', '110710', '110711', '110712',$
	  '110713', '110716', '110717', '110718', '110719', '110720', '110721',$
	  '110722', '110724', '110808', '110809', '110813', '110814', '110830',$
	  '110831' ]

	dav_dates = ['110704', '110808']

	n_dav = n_elements(dav_dates)

	maw_red_dayn = strmid(file_basename(maw_red_files), 9, 3)
	maw_gre_dayn = strmid(file_basename(maw_gre_files), 9, 3)


	data_count = 0L


	for j = 0, n_dav - 1 do begin

		dav_date = [fix('20' + strmid(dav_dates[j], 0, 2)), $
					fix(strmid(dav_dates[j], 2, 2)), $
					fix(strmid(dav_dates[j], 4, 2))]
		dav_dayn = ymd2dn(dav_date[0], dav_date[1], dav_date[2])
		dav_filename = where_is('davis_data') + '\' + string(dav_date[0], f='(i04)') + '_' + string(dav_dayn, f='(i03)')
		if file_test(dav_filename) eq 0 then stop

		filters = davis_count_filters(0, 0, filename = dav_filename)

		for f = 0, n_elements(filters.number) - 1 do begin

			maw_filename = ''
			maw_lambda = ''

			if filters.wavelengths[f] eq 630.0 then begin
				;\\ Got Mawson red obs?
				match = where(maw_red_dayn eq dav_dayn, nmatch)
				if nmatch eq 1 then begin
					maw_filename = maw_red_files[match[0]]
					maw_lambda = '6300'
				endif
			endif

			if filters.wavelengths[f] eq 557.7 then begin
				;\\ Got Mawson green obs?
				match = where(maw_gre_dayn eq dav_dayn, nmatch)
				if nmatch eq 1 then begin
					maw_filename = maw_gre_files[match[0]]
					maw_lambda = '5577'
				endif
			endif

			if file_test(maw_filename) eq 0 then continue


			;\\ Davis data
				dav_data = drta_make_time_series('', 0, 0, filters.number[f], filters.wavelengths[f], filename = dav_filename, /los, /useLel)

				if dav_data.data eq 0 then stop
				dav_drift = dav_data.drift
				dav_drift = (dav_drift - dav_drift[0])*dav_data.chan_to_vel

			;\\ Mawson data
				meta_loader, out, filename=maw_filename, filter=['*'+maw_lambda+'*'], drift='both', $
							 /auto_flat, /no_usolve, /no_bi, /no_mono, raw_path=where_is('mawson_data')

				maw = out.maw
				maw_vh = fltarr(n_elements(maw.ut))
				for _tt = 0, n_elements(maw.ut) - 1 do begin
					maw_vh[_tt] = dotp([maw.winds[_tt].zonal_wind[0], maw.winds[_tt].meridional_wind[0]], hvec)
				endfor

			;\\ Time range
				cv = where(dav_data.directions.name eq 'Mawson', n_dav_cv)
				dav_cv = dav_data.directions[cv]
				dav_ut = *dav_cv.time
				maw_ut = maw.ut
				time_range = [max([min(dav_ut), min(maw_ut)]), min([max(dav_ut), max(maw_ut)])]

				maw_use = where(maw_ut ge time_range[0] and maw_ut le time_range[1], n_maw_use)
				dav_use = where(dav_ut ge time_range[0] and dav_ut le time_range[1], n_dav_use)

			;\\ Create a common time axis
				common_times = [maw_ut[maw_use], dav_ut[dav_use]]
				common_times = common_times[sort(common_times)]

			;\\ For green line, need to find common vols carefully
			if filters.wavelengths[f] eq 557.7 then begin

				get_zone_locations, maw.meta, altitude = 120., zones=zones	;\\ nominal height, we do better

				sdi_time_interpol, maw.speks_dc.temperature, maw_ut, $
					   			   common_times, i_temperature

				for tt = 0, n_elements(common_times) - 1 do begin

					t_temps = i_temperature[*,tt]

					t_alts = infer_height_from_temp(2011, out.dayno, $
											maw.meta.latitude, $
											maw.meta.longitude, $
											common_times[tt], t_temps)

					zz_ll = get_end_lat_lon(maw.meta.latitude, $
											maw.meta.longitude, $
											get_great_circle_length(zones.mid_zen, t_alts), $
											zones.mid_azi)
					xx = reform(zz_ll[*,1])
					yy = reform(zz_ll[*,0])
					ng = 100.
					xax = (findgen(ng)/(ng-1))*(max(xx)-min(xx)) + min(xx)
					yax = (findgen(ng)/(ng-1))*(max(yy)-min(yy)) + min(yy)

					triangulate, xx, yy, tr, b
					alt_surf = trigrid(xx, yy, t_alts, tr, xout=xax, yout=yax, extrap=b)
					alt_surf_missing = trigrid(xx, yy, t_alts, tr, xout=xax, yout=yax, missing=-999)
					alt_surf = smooth(alt_surf, 20, /edge)

					cv_zenang = get_unique(*dav_cv.zen_ang)
					n_cv = n_elements(cv_zenang)


					;\\ Loop through davis look directions
					for cv_idx = 0, n_cv - 1 do begin

						pt = where(*dav_cv.zen_ang eq cv_zenang[cv_idx])
						cv_azimuth = (*dav_cv.azimuth)[pt[0]]

						dav_azi = cv_azimuth
						dav_zen = cv_zenang[cv_idx]

						;\\ Calculate lat lon as function of distance along ray
						lat0 = (station_info('dav')).glat
						lon0 = (station_info('dav')).glon

						max_arc_len = 400./cos(dav_zen*!DTOR)
						arc_len = (findgen(500)/499.)*max_arc_len
						path_ll = get_end_lat_lon(lat0, lon0, $
									get_great_circle_length(dav_zen, arc_len*cos(dav_zen*!DTOR)), $
									replicate(dav_azi, nels(arc_len)))

						ray_lat = reform(path_ll[*,0])
						ray_lon = reform(path_ll[*,1])
						ray_alt = arc_len*cos(dav_zen*!DTOR)

						lat_idx = interpol(indgen(ng), yax, ray_lat)
						lon_idx = interpol(indgen(ng), xax, ray_lon)
						inrange = where(lat_idx gt 0 and lat_idx lt ng and $
										lon_idx gt 0 and lon_idx lt ng, npts)

						if npts eq 0 then stop

						ray_emission = interpolate(alt_surf, lon_idx, lat_idx)
						ray_emission_missing = interpolate(alt_surf_missing, lon_idx, lat_idx)
						isect = (where(abs(ray_alt - ray_emission) eq min(abs(ray_alt - ray_emission))))[0]

						isect_lat = ray_lat[isect]
						isect_lon = ray_lon[isect]
						isect_alt = ray_alt[isect]

						;\\ Find closest Mawson zone
						distance = fltarr(maw.meta.nzones)
						for zz = 0, maw.meta.nzones - 1 do begin
							distance[zz] = map_2points(isect_lon, isect_lat, zz_ll[zz,1], zz_ll[zz,0], /meters)
						endfor
						min_diff = (where(distance eq min(distance)))[0]
						diff = distance[min_diff]
						cv_zone = min_diff
						common_ll = [ 0.5*(isect_lat+zz_ll[cv_zone,0]), 0.5*(isect_lon+zz_ll[cv_zone,1])]
						cnv_aacgm, common_ll[0], common_ll[1], 240, common_mlat, common_mlon, r, error

						if file_basename(dav_filename) eq '2011_185' or file_basename(dav_filename) eq '2011_220' then begin

							if cv_idx eq 0 and tt eq 0 then begin
								eps, filename = 'C:\cal\Docs\Latex\Papers\DavisMawson_RedGreen_Bistatic\Pics\Intersects\' + $
									 file_basename(dav_filename) + '.eps', /open, xs = 10, ys = 10

								plot, get_great_circle_length(dav_zen, arc_len*cos(dav_zen*!DTOR)), ray_emission, $
										/nodata, xrange = [0,1000], yrange=[0,200], xtitle='Great Circle Distance (km)', $
										ytitle = 'Altitude (km)', chars = .7, chart = 2, pos=[.12, .09, .96, .98]
							endif

							pts = where(ray_emission_missing gt 0)

							oplot, (get_great_circle_length(dav_zen, arc_len*cos(dav_zen*!DTOR)))[pts], ray_emission[pts], $
									color=0, thick=.2

							if cv_idx eq 0 and tt eq  n_elements(common_times) - 1 then begin

								oplot, get_great_circle_length(dav_zen, arc_len*cos(dav_zen*!DTOR)), ray_alt, $
									color= 255, thick=4

								oplot, get_great_circle_length(dav_zen, arc_len*cos(dav_zen*!DTOR)), ray_alt, $
									color= 50, thick=2

							endif

							if cv_idx eq 1 and tt eq  n_elements(common_times) - 1 then begin

								oplot, get_great_circle_length(dav_zen, arc_len*cos(dav_zen*!DTOR)), ray_alt, $
									color= 255, thick=4

								oplot, get_great_circle_length(dav_zen, arc_len*cos(dav_zen*!DTOR)), ray_alt, $
									color= 50, thick=2

								oplot, [geo_sep, geo_sep], [0,10], thick=10, color = 250
								xyouts, /data, geo_sep, 12, 'Mawson', align=.5, chart = 2, chars=.7, color=250

								eps, /close
							endif

						endif


						;\\ Visualize the intersection
						if 0 then begin
							window, 0, xs=900, ys=900
							loadct, 39, /silent
							plot_simple_map, mean((station_info(['maw','dav'])).glat), $
											 mean((station_info(['maw','dav'])).glon), $
						 					 12, 1, 1, map=map

							plot_zonemap_on_map, 0, 0, 0, 0, t_alts[cv_zone], 180+maw.meta.oval_angle, 0, map, $
											 ctable=39, front_color=0, $
											 /no_outline, lineThick=2, meta=maw.meta

							plot_zonemap_on_map, 0, 0, 0, 0, t_alts[cv_zone], 180+maw.meta.oval_angle, 0, map, $
											 onlythesezones=cv_zone, ctable=39, front_color=250, $
											 /no_outline, lineThick=2, meta=maw.meta

							plot_zonemap_on_map, 0, 0, 0, 0, t_alts[cv_zone], 180+maw.meta.oval_angle, 0, map, $
											 onlythesezones=[2], ctable=39, front_color=190, $
											 /no_outline, lineThick=2, meta=maw.meta
							plot_zonemap_on_map, 0, 0, 0, 0, t_alts[cv_zone], 180+maw.meta.oval_angle, 0, map, $
											 onlythesezones=[1], ctable=39, front_color=150, $
											 /no_outline, lineThick=2, meta=maw.meta

							plots, map_proj_forward(isect_lon, isect_lat, map=map), psym=6, /data, thick=5
							plots, map_proj_forward(ray_lon, ray_lat, map=map), /data, color=0

							ang = findgen(361)*!dtor
							zens = dav_zen + 3*cos(ang)
							azis = dav_azi + 3*sin(ang)

							dist = get_great_circle_length(dav_zen, isect_alt)
							ll = get_end_lat_lon((station_info('dav')).glat, $
													  (station_info('dav')).glon, $
													  dist, dav_azi)
							plots, map_proj_forward(ll[1], ll[0] , map=map), /data, psym=6, sym=1, color=0
							print, ll
							plots, map_proj_forward(zz_ll[cv_zone, 1], zz_ll[cv_zone, 0] , map=map), /data, psym=1, sym=.1, color=0

							for dcv1 = 0, 360 do begin
								dist = get_great_circle_length(zens[dcv1], isect_alt)
								ll = get_end_lat_lon((station_info('dav')).glat, $
													  (station_info('dav')).glon, $
													  dist, azis[dcv1])
								plots, map_proj_forward(ll[1], ll[0] , map=map), /data, psym=1, sym=.1, color=0
							endfor

						endif

						;\\ Interpolate to common time
							pts = where(*dav_cv.zen_ang eq cv_zenang[cv_idx] and $
										*dav_cv.azimuth eq cv_azimuth, n_pts)

							dav_los = interpol((*dav_cv.wind)[pts], (*dav_cv.time)[pts], common_times[tt])
							dav_err = interpol((*dav_cv.wind_err)[pts], (*dav_cv.time)[pts], common_times[tt])

							maw_los = maw.speks_dc.velocity[cv_zone]*maw.meta.channels_to_velocity
							maw_err = maw.speks_dc.sigma_velocity[cv_zone]*maw.meta.channels_to_velocity
							maw_tmp = maw.speks_dc.temperature[cv_zone]
							maw_chi = maw.speks_dc.chi_squared[cv_zone]
							maw_los = interpol(maw_los, maw_ut, common_times[tt])
							maw_err = interpol(maw_err, maw_ut, common_times[tt])
							maw_tmp = interpol(maw_tmp, maw_ut, common_times[tt])
							maw_chi = interpol(maw_chi, maw_ut, common_times[tt])

							resolve_nStatic_wind, common_ll[0], $
								  				  common_ll[1], $
								  				  [(station_info('dav')).glat,(station_info('maw')).glat], $
								  				  [(station_info('dav')).glon,(station_info('maw')).glon], $
								  				  [cv_zenang[cv_idx], zones[cv_zone].mid_zen], $
								  				  [cv_azimuth, zones[cv_zone].mid_azi], $
								  				  [isect_alt, isect_alt], $
								  				  [dav_los, maw_los], $
								  				  [dav_err, maw_err], $
								  				  outWind, $
								  				  outErr, $
								  				  outInfo, $
								  				  /assume_direct

							datum = {lat:common_ll[0], $
									 lon:common_ll[1], $
									 mlat:common_mlat, $
									 mlon:common_mlon, $
									 alt:isect_alt, $
									 vz:outwind[1], $
									 vze:outerr[1], $
									 vh:outwind[0], $
									 temp:maw_tmp, $
									 ut:(common_times[tt]), $
									 dayno:out.dayno, $
									 maw_chi:maw_chi, $
									 maw_zone:fix(cv_zone), $
									 lambda:5577, $
									 id:'gcv'+string(cv_idx, f='(i0)')}

							append, datum, day_data


					wait, 0.001
					endfor ;\\ look dir loop


					;\\ Add Mawson and davis zenith obs
						datum = {lat:(station_info('maw')).glat, $
								 lon:(station_info('maw')).glon, $
								 mlat:(station_info('maw')).mlat, $
								 mlon:(station_info('maw')).mlon, $
								 alt:t_alts[0], $
								 vz:(interpol(maw.speks_dc.velocity[0]*maw.meta.channels_to_velocity, maw_ut, common_times[tt])), $
								 vze:(interpol(maw.speks_dc.sigma_velocity[0]*maw.meta.channels_to_velocity, maw_ut, common_times[tt])), $
								 vh:interpol(maw_vh, maw.ut, common_times[tt]), $
								 temp:(interpol(maw.speks_dc.temperature[0], maw_ut, common_times[tt])), $
								 ut:(common_times[tt]), $
								 dayno:out.dayno, $
								 maw_chi:(interpol(maw.speks_dc.chi_squared[0], maw_ut, common_times[tt])), $
								 maw_zone:0, $
								 lambda:5577, $
								 id:'gmaw'}
						append, datum, day_data

						datum = {lat:(station_info('dav')).glat, $
								 lon:(station_info('dav')).glon, $
								 mlat:(station_info('dav')).mlat, $
								 mlon:(station_info('dav')).mlon, $
								 alt:0., $
								 vz:interpol((*dav_data.directions[0].wind), (*dav_data.directions[0].time), common_times[tt]), $
								 vze:interpol((*dav_data.directions[0].wind_err), (*dav_data.directions[0].time), common_times[tt]), $
								 vh:0D, $
								 temp:interpol((*dav_data.directions[0].temp), (*dav_data.directions[0].time), common_times[tt]), $
								 ut:(common_times[tt]), $
								 dayno:out.dayno, $
								 maw_chi:0D, $
								 maw_zone:0, $
								 lambda:5577, $
								 id:'gdav'}
						append, datum, day_data


				endfor	;\\ green time loop

				ids = get_unique(day_data.id)
				for ii = 0, n_elements(ids) - 1 do begin
					slice = where(day_data.id eq ids[ii])
					good = where(abs(day_data[slice].vz - median(day_data[slice].vz)) lt 3*stddev(day_data[slice].vz))
					fit = linfit(day_data[slice[good]].ut, day_data[slice[good]].vz, measure_err=day_data[slice[good]].vze, yfit=curve)
					day_data[slice].vz -= (fit[0] + fit[1]*day_data[slice].ut)
					day_data[slice].vz -= median(day_data[slice].vz)
				endfor
				append, day_data, data
				data_count += n_elements(day_data)
				day_data = ''


			endif else begin ;\\ end green branch


				get_zone_locations, maw.meta, altitude = 240., zones=zones

				cv_zenang = get_unique(*dav_cv.zen_ang)
				good = where(cv_zenang ne (90-17.5))	;\\ at 240 km, this is mawson zenith
				cv_zenang = cv_zenang[good]
				n_cv = n_elements(cv_zenang)


				;\\ Loop through davis look directions
				for cv_idx = 0, n_cv - 1 do begin

					pt = where(*dav_cv.zen_ang eq cv_zenang[cv_idx])
					cv_azimuth = ((*dav_cv.azimuth)[pt])[0]

					ll = get_end_lat_lon((station_info('dav')).glat, (station_info('dav')).glon, $
										 get_great_circle_length(cv_zenang[cv_idx], 240.), $
										 cv_azimuth)

					;\\ Find closest Mawson zone
					distance = fltarr(maw.meta.nzones)
					for zz = 0, maw.meta.nzones - 1 do begin
						distance[zz] = map_2points(ll[1], ll[0], zones[zz].lon, zones[zz].lat, /meters)
					endfor
					min_diff = (where(distance eq min(distance)))[0]
					diff = distance[min_diff]
					cv_zone = min_diff
					common_ll = [ 0.5*(ll[0]+zones[cv_zone].lat), 0.5*(ll[1]+zones[cv_zone].lon)]
					cnv_aacgm, common_ll[0], common_ll[1], 240, common_mlat, common_mlon, r, error

					;\\ Visualize the intersection
						if 0 then begin

							if cv_idx eq 0 then begin
								window, 0, xs=900, ys=900
								wx=900.
								wy=900.
								zoom=10
								loadct, 39, /silent

								loadct, 0, /silent
								polyfill, [0,0,1,1], [0,1,1,0], /normal, color=0

								;\\ Projection
									map = MAP_PROJ_INIT(118, CENTER_LONGITUDE= (station_info('maw')).glon, /gctp)

								;\\ Create a plot window using the UV Cartesian range.
									!p.noerase = 1
									xscale = map.uv_box[[0,2]]/(float(zoom)*(float(wy)/float(wx)))
									yscale = map.uv_box[[1,3]]/(float(zoom))

									yscale -= 8.9E6

									PLOT, xscale, yscale, /NODATA, XSTYLE=5, YSTYLE=5, $
										  color=53, back=0, xticklen=.0001, yticklen=.0001, pos=[0,0,1,1]
									print, map_proj_inverse(xscale, yscale, map=map)

								plot_zonemap_on_map, 0, 0, 0, 0, 240, 180+maw.meta.oval_angle, 0, map, $
												 ctable=39, front_color=90, $
												 /no_outline, lineThick=2, meta=maw.meta
							endif

							plot_zonemap_on_map, 0, 0, 0, 0, 240, 180+maw.meta.oval_angle, 0, map, $
											 onlythesezones=cv_zone, ctable=39, front_color=250, $
											 /no_outline, lineThick=5, meta=maw.meta

							ang = findgen(361)*!dtor
							zens = cv_zenang[cv_idx] + 3*cos(ang)
							azis = cv_azimuth + 3*sin(ang)

							_dist = get_great_circle_length(cv_zenang[cv_idx], 240)
							ll = get_end_lat_lon((station_info('dav')).glat, $
													  (station_info('dav')).glon, $
													  _dist, cv_azimuth)
							;plots, map_proj_forward(ll[1], ll[0] , map=map), /data, psym=6, sym=1, color=0
							;print, ll

							for dcv1 = 0, 360 do begin
								_dist = get_great_circle_length(zens[dcv1], 240)
								ll = get_end_lat_lon((station_info('dav')).glat, $
													  (station_info('dav')).glon, $
													  _dist, azis[dcv1])
								plots, map_proj_forward(ll[1], ll[0] , map=map), /data, psym=1, sym=.1, color=150, thick=2
							endfor
						endif




					;\\ Interpolate to common times
						pts = where(*dav_cv.zen_ang eq cv_zenang[cv_idx] and $
									*dav_cv.azimuth eq cv_azimuth, n_pts)

						dav_los = interpol((*dav_cv.wind)[pts], (*dav_cv.time)[pts], common_times)
						dav_err = interpol((*dav_cv.wind_err)[pts], (*dav_cv.time)[pts], common_times)

						maw_los = maw.speks_dc.velocity[cv_zone]*maw.meta.channels_to_velocity
						maw_err = maw.speks_dc.sigma_velocity[cv_zone]*maw.meta.channels_to_velocity
						maw_tmp = maw.speks_dc.temperature[cv_zone]
						maw_chi = maw.speks_dc.chi_squared[cv_zone]
						maw_los = interpol(maw_los, maw_ut, common_times)
						maw_err = interpol(maw_err, maw_ut, common_times)
						maw_tmp = interpol(maw_tmp, maw_ut, common_times)
						maw_chi = interpol(maw_chi, maw_ut, common_times)


					for tidx = 0, n_elements(common_times) - 1 do begin

						resolve_nStatic_wind, common_ll[0], $
							  				  common_ll[1], $
							  				  [(station_info('dav')).glat,(station_info('maw')).glat], $
								  			  [(station_info('dav')).glon,(station_info('maw')).glon], $
							  				  [cv_zenang[cv_idx], zones[cv_zone].mid_zen], $
							  				  [cv_azimuth, zones[cv_zone].mid_azi], $
							  				  [240., 240.], $
							  				  [dav_los[tidx], maw_los[tidx]], $
							  				  [dav_err[tidx], maw_err[tidx]], $
							  				  outWind, $
							  				  outErr, $
							  				  outInfo, $
							  				  /assume_direct

						datum = {lat:common_ll[0], $
								 lon:common_ll[1], $
								 mlat:common_mlat, $
								 mlon:common_mlon, $
								 alt:240., $
								 vz:outwind[1], $
								 vze:outerr[1], $
								 vh:outwind[0], $
								 temp:maw_tmp[tidx], $
								 ut:common_times[tidx], $
								 dayno:out.dayno, $
								 maw_chi:maw_chi[tidx], $
								 maw_zone:fix(cv_zone), $
								 lambda:6300, $
								 id:'rcv'+string(cv_idx, f='(i0)')}

						append, datum, day_data


						if cv_idx eq 0 then begin
						;\\ Add Mawson and davis zenith obs
							datum = {lat:(station_info('maw')).glat, $
									 lon:(station_info('maw')).glon, $
									 mlat:(station_info('maw')).mlat, $
								 	 mlon:(station_info('maw')).mlon, $
									 alt:240., $
									 vz:(interpol(maw.speks_dc.velocity[0]*maw.meta.channels_to_velocity, maw_ut, common_times[tidx])), $
									 vze:(interpol(maw.speks_dc.sigma_velocity[0]*maw.meta.channels_to_velocity, maw_ut, common_times[tidx])), $
									 vh:interpol(maw_vh, maw.ut, common_times[tidx]), $
									 temp:(interpol(maw.speks_dc.temperature[0], maw_ut, common_times[tidx])), $
									 ut:(common_times[tidx]), $
									 dayno:out.dayno, $
									 maw_chi:(interpol(maw.speks_dc.chi_squared[0], maw_ut, common_times[tidx])), $
									 maw_zone:0, $
									 lambda:6300, $
									 id:'rmaw'}
							append, datum, day_data

							datum = {lat:(station_info('dav')).glat, $
									 lon:(station_info('dav')).glon, $
									 mlat:(station_info('dav')).mlat, $
								 	 mlon:(station_info('dav')).mlon, $
									 alt:240., $
									 vz:interpol((*dav_data.directions[0].wind), (*dav_data.directions[0].time), common_times[tidx]), $
									 vze:interpol((*dav_data.directions[0].wind_err), (*dav_data.directions[0].time), common_times[tidx]), $
									 vh:0D, $
									 temp:interpol((*dav_data.directions[0].temp), (*dav_data.directions[0].time), common_times[tidx]), $
									 ut:(common_times[tidx]), $
									 dayno:out.dayno, $
									 maw_chi:0D, $
									 maw_zone:0, $
									 lambda:6300, $
									 id:'rdav'}
							append, datum, day_data

						endif

						wait, 0.001
					endfor ;\\ time loop

				endfor	;\\ dir loop

				ids = get_unique(day_data.id)
				for ii = 0, n_elements(ids) - 1 do begin
					slice = where(day_data.id eq ids[ii])
					good = where(abs(day_data[slice].vz - median(day_data[slice].vz)) lt 3*stddev(day_data[slice].vz))
					fit = linfit(day_data[slice[good]].ut, day_data[slice[good]].vz, measure_err=day_data[slice[good]].vze, yfit=curve)
					day_data[slice].vz -= (fit[0] + fit[1]*day_data[slice].ut)
					day_data[slice].vz -= median(day_data[slice].vz)
				endfor
				append, day_data, data
				data_count += n_elements(day_data)
				day_data = ''

			endelse	;\\ end red branch
		endfor ;\\ end filter loop

		print, 'Finished: ' + dav_filename
		if data_count ne n_elements(data) then stop
		save, filename=top_dir + 'AllData.idlsave', data
		heap_gc

	endfor	;\\ end day loop







end