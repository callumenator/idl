
@resolve_nstatic_wind

pro mawson_davis_cv

@sdi3k_ncdf_inc

	redo = 1
	top_dir = where_is('mawson_davis_cv')
	done_list = file_search(where_is('mawson_davis_cv') + 'Data\*.idlsave')

	maw_red_files = file_search(where_is('mawson_data'), '*2011*630*.nc', count = n_maw_red)
	maw_gre_files = file_search(where_is('mawson_data'), '*2011*557*.nc', count = n_maw_gre)
	dav_files = file_search(where_is('davis_data'), '2011*', count = n_dav)


	maw_red_dayn = strmid(file_basename(maw_red_files), 9, 3)
	maw_gre_dayn = strmid(file_basename(maw_gre_files), 9, 3)
	dav_dayn = strmid(file_basename(dav_files), 5, 3)

	pairs = [[''],['']]
	days = [0]
	wavelength = [0.]
	filter = [0]

	for j = 0, n_dav - 1 do begin

		if redo eq 0 then begin
			fn = file_basename(dav_files[j])
			yr = float(strmid(fn, 0, 4))
			dn = float(strmid(fn, 5, 3))
			ydn2md, yr, dn, m, d
			dname = string(yr - 2000, f='(i02)') + string(m, f='(i02)') + string(d, f='(i02)')
			match = where(strmid(file_basename(done_list), 0, 6) eq dname, matchyn)
			if matchyn eq 1 then begin
				restore, done_list[match[0]]
				mawson_davis_cv_summary_plot, all_cv
			endif
			if j eq n_dav -1 then stop else continue

		endif

		filters = davis_count_filters(0, 0, filename = dav_files[j])

		for f = 0, n_elements(filters.number) - 1 do begin
			if filters.wavelengths[f] eq 630.0 then begin

				;\\ Got Mawson red obs?
				match = where(maw_red_dayn eq dav_dayn[j], nmatch)
				if nmatch eq 1 then begin
					pairs = [pairs, [[maw_red_files[match[0]]], [dav_files[j]]]]
					days = [days, dav_dayn[j]]
					wavelength = [wavelength, 630.0]
					filter = [filter, filters.number[f]]
				endif

			endif

			if filters.wavelengths[f] eq 557.7 then begin

				;\\ Got Mawson green obs?
				match = where(maw_gre_dayn eq dav_dayn[j], nmatch)
				if nmatch eq 1 then begin
					pairs = [pairs, [[maw_gre_files[match[0]]], [dav_files[j]]]]
					days = [days, dav_dayn[j]]
					wavelength = [wavelength, 557.7]
					filter = [filter, filters.number[f]]
				endif

			endif
		endfor
	endfor

	n_pairs = n_elements(pairs[*,0])
	if n_pairs eq 0 then stop
	pairs = pairs[1:*,*]
	days = days[1:*]
	wavelength = wavelength[1:*]
    filter = filter[1:*]
	n_pairs = n_elements(pairs[*,0])

	done = bytarr(n_pairs)

	;\\ Loop through pairs
	for p = 0, n_pairs - 1 do begin


		;\\ Already done?
			if done[p] eq 1 then continue

		;\\ How many wavelengths?
			lambda_pts = where(days eq days[p], npts)

		red = -1
		green = -1

		for ldx = 0, npts - 1 do begin

			cp = lambda_pts[ldx]
			print, 'Day: ' + string(days[cp], f='(i0)') + ', Lambda: ' + string(wavelength[cp], f='(f0.1)')

			if wavelength[cp] eq 630.0 then altitude = 240.
			if wavelength[cp] eq 557.7 then altitude = 110.

			;\\ Mawson data
				sdi3k_read_netcdf_data, pairs[cp,0], meta=maw_meta, winds=maw_winds, spek=speks
				if size(maw_winds, /type) ne 8 then continue

				diff = maw_winds[0].azimuths[2] - (180 - abs(maw_meta.oval_angle))
				maw_winds.azimuths -= diff

				maw_speks = speks
				;\\ Flat field...
					wind_offset = 0
					sdi3k_auto_flat, maw_meta, wind_offset, extend_valid_time = 90.*24.*60.*60.
					print, 'WIND OFFSET: ', total(abs(wind_offset))
					for kk = 0, n_elements(maw_speks.velocity[0])-1 do maw_speks[kk].velocity[1:*] = maw_speks[kk].velocity[1:*] - wind_offset[1:*]

					ncid_index = {filename: "bound_to_not_exist", $
                       	ncid: -1, $
              			write_allowed: 0, $
                       	xdim: 256, $
                       	ydim: 256, $
                   		zone_map: intarr(1024, 1024), $
                 		zmap_valid: 0}
				las_file = sdi_find_cal_from_sky(pairs[cp, 0])
				if las_file eq '' then begin
					sdi3k_drift_correct, maw_speks, maw_meta, /force, /data
				endif else begin
					sdi3k_drift_correct, maw_speks, maw_meta, /force, insfile=las_file
				endelse
	    		sdi3k_remove_radial_residual, maw_meta, maw_speks, parname='VELOCITY'
				maw_drift = maw_speks.velocity[0] - speks.velocity[0]
				maw_drift = (maw_drift - maw_drift[0])*maw_meta.channels_to_velocity


				maw_speks.velocity = maw_meta.channels_to_velocity*maw_speks.velocity
				maw_speks.sigma_velocity = maw_meta.channels_to_velocity*maw_speks.sigma_velocity
			    posarr = maw_speks.velocity
			    vertical = reform(posarr[0,*])
			    ;sdi3k_timesmooth_fits,  posarr, winds[0].time_smoothing, metadata
			    ;sdi3k_spacesmooth_fits, posarr, winds[0].space_smoothing, metadata, centers
			    maw_speks.velocity = posarr
			    maw_speks.velocity[0] = vertical
			    nobs = n_elements(maw_speks)
		    	if nobs gt 2 then maw_speks.velocity = maw_speks.velocity - $
		    		total(maw_speks(1:nobs-2).velocity(0))/n_elements(maw_speks(1:nobs-2).velocity(0))

				maw_ut = js2ut(0.5*(maw_winds.start_time[0] + maw_winds.end_time[0]))
				date_stuff = convert_js(maw_winds[0].start_time[0])

			;\\ Davis data
				dav_data = drta_make_time_series('', 0, 0, filter[cp], wavelength[cp], filename = pairs[cp,1], /los, /useLel)

				if dav_data.data eq 0 then stop
				dav_drift = dav_data.drift
				dav_drift = (dav_drift - dav_drift[0])*dav_data.chan_to_vel


			;\\ Mawson Zone locations
				get_zone_lat_lon, indgen(maw_meta.nzones), maw_meta, maw_winds, maw_lat, maw_lon, $
						  useAltitude=altitude

			;\\ Davis CV locations
				cv = where(dav_data.directions.name eq 'Mawson', dav_cv_yn)
				if dav_cv_yn eq 0 then continue

				dav_cv = dav_data.directions[cv]
				cv_zenang = get_unique(*dav_cv.zen_ang)
				if wavelength[cp] eq 630 then begin
					good = where(cv_zenang ne (90-17.5))
				endif else begin
					good = where(cv_zenang ne -1)
				endelse
				cv_zenang = cv_zenang[good]
				n_cv = n_elements(cv_zenang)

			;\\ Common time grid
				common_times = [maw_ut, *dav_cv.time]


				for cv_idx = 0, n_cv - 1 do begin
					pt = where(*dav_cv.zen_ang eq cv_zenang[cv_idx])
					cv_azimuth = (*dav_cv.azimuth)[pt]

					ll = get_end_lat_lon((station_info('dav')).glat, (station_info('dav')).glon, $
							get_great_circle_length(cv_zenang[cv_idx], altitude), cv_azimuth[cv_idx])

					;\\ Find closest Mawson zone
					distance = maw_lat
					distance[*] = 0
					for kk = 0, n_elements(maw_lat) - 1 do begin
						distance[kk] = map_2points(ll[1], ll[0], maw_lon[kk], maw_lat[kk], /meters)
					endfor
					min_diff = (where(distance eq min(distance)))[0]
					diff = distance[min_diff]
					cv_zone = min_diff
					common_ll = [ 0.5*(ll[0]+maw_lat[cv_zone]), 0.5*(ll[1]+maw_lon[cv_zone])]

					;\\ Interpolate to common times
					pts = where(*dav_cv.zen_ang eq cv_zenang[cv_idx] and $
								*dav_cv.azimuth eq cv_azimuth[cv_idx], n_pts)
					dav_los = interpol((*dav_cv.wind)[pts], (*dav_cv.time)[pts], maw_ut)
					dav_err = interpol((*dav_cv.wind_err)[pts], (*dav_cv.time)[pts], maw_ut)

	stop

					;\\ Zero any Davis data that was interpolated past the Davis start/end time
					ptlo = where(maw_ut lt min((*dav_cv.time)[pts]), n_lo)
					pthi = where(maw_ut gt max((*dav_cv.time)[pts]), n_hi)
					if n_lo gt 0 then dav_los[ptlo] = -999
					if n_hi gt 0 then dav_los[pthi] = -999

					cv_struc = {lcomp:0., mcomp:0., $
								lerr:0., merr:0., $
								ut:0., obsdot:0., $
								laxis:[0.,0.,0.], maxis:[0.,0.,0.], $
								lat:0., lon:0., $
								mangle:0., $
								stn_name:['',''], $
								stn_los:[0., 0.], $
								stn_err:[0., 0.], $
								wavelength:0., $
								altitude:0., $
								temperature:0.0, $
								dav_zen:0., dav_azi:0., dav_ll:[0.,0.], $
								maw_zen:0, maw_azi:0., maw_zone:0, maw_ll:[0.,0.], maw_meta:maw_meta, $
								dav_missing:0, $
								maw_chisq:0.0}

					this_cv = replicate(cv_struc, n_elements(maw_ut))

					for tidx = 0, n_elements(maw_ut) - 1 do begin
						resolve_nStatic_wind, common_ll[0], $
							  				  common_ll[1], $
							  				  [ll[0],maw_lat[cv_zone]], $
							  				  [ll[1],maw_lon[cv_zone]], $
							  				  [cv_zenang[cv_idx], maw_winds[0].zeniths[cv_zone]], $
							  				  [cv_azimuth[cv_idx], maw_winds[0].azimuths[cv_zone]], $
							  				  [altitude, altitude], $
							  				  [dav_los[tidx], maw_speks[tidx].velocity[cv_zone]], $
							  				  [dav_err[tidx], maw_speks[tidx].sigma_velocity[cv_zone]], $
							  				  outWind, $
							  				  outErr, $
							  				  outInfo, $
							  				  /assume_direct

						this_cv[tidx].lcomp = outwind[0]
						this_cv[tidx].mcomp = outwind[1]
						this_cv[tidx].lerr = outerr[0]
						this_cv[tidx].merr = outerr[1]
						this_cv[tidx].laxis = outinfo.laxis
						this_cv[tidx].maxis = outinfo.maxis
						this_cv[tidx].mangle = outinfo.mangle
						this_cv[tidx].ut = maw_ut[tidx]
						this_cv[tidx].stn_name = ['dav','maw']
						this_cv[tidx].stn_los = [dav_los[tidx], maw_speks[tidx].velocity[cv_zone]]
						this_cv[tidx].stn_err = [dav_err[tidx], maw_speks[tidx].sigma_velocity[cv_zone]]
						this_cv[tidx].lat = common_ll[0]
						this_cv[tidx].lon = common_ll[1]
						this_cv[tidx].altitude = altitude
						this_cv[tidx].temperature = maw_speks[tidx].temperature[cv_zone]

						this_cv[tidx].dav_zen = cv_zenang[cv_idx]
						this_cv[tidx].dav_azi = cv_azimuth[cv_idx]
						this_cv[tidx].dav_ll = ll

						this_cv[tidx].maw_zen = maw_winds[0].zeniths[cv_zone]
						this_cv[tidx].maw_azi = maw_winds[0].azimuths[cv_zone]
						this_cv[tidx].maw_ll = [maw_lat[cv_zone],maw_lon[cv_zone]]

						this_cv[tidx].maw_zone = cv_zone
						this_cv[tidx].wavelength = wavelength[cp]
						this_cv[tidx].dav_missing = (dav_los[tidx] eq -999)

						this_cv[tidx].maw_chisq = maw_speks[tidx].chi_squared[cv_zone]

					endfor

					res = execute('cv' + string(cv_idx, f='(i02)') + '= this_cv')
				endfor

				if wavelength[cp] eq 630.0 then lambda_str = 'red'
				if wavelength[cp] eq 557.7 then lambda_str = 'green'

				cv_str = '{maw_ut:maw_ut, maw_zenith:maw_speks.velocity[0], dav_ut:*dav_data.directions(0).time'
				cv_str = cv_str + ', dav_zenith:*dav_data.directions(0).wind, maw_zenith_err:maw_speks.sigma_velocity[0]'
				cv_str = cv_str + ', dav_zenith_err:*dav_data.directions(0).wind_err, '
				for cv_cnt = 0, n_cv - 1 do begin
					cv_str += 'cv' + string(cv_cnt, f='(i02)') + ':cv' + string(cv_cnt, f='(i02)')
					cv_str += ', '
				endfor
				cv_str = cv_str + 'maw_zenith_temps:maw_speks.temperature[0], maw_zenith_chisq:maw_speks.chi_squared[0], '
				cv_str = cv_str + 'dav_zenith_chisq:*dav_data.directions(0).chisq}'

				res = execute(lambda_str + '=' + cv_str )
			done[cp] = 1
		endfor

		if size(red, /type) ne 2 and size(green, /type) ne 2 then all_cv = {date:date_stuff, dayn:days[p], red:red, green:green, $
																			maw_drift:maw_drift, maw_drift_ut:maw_ut, $
																			dav_drift:dav_drift, dav_drift_ut:dav_data.drift_ut}
		if size(red, /type) ne 2 and size(green, /type) eq 2 then all_cv = {date:date_stuff, dayn:days[p], red:red, green:0, $
																			maw_drift:maw_drift, maw_drift_ut:maw_ut, $
																			dav_drift:dav_drift, dav_drift_ut:dav_data.drift_ut}
		if size(red, /type) eq 2 and size(green, /type) ne 2 then all_cv = {date:date_stuff, dayn:days[p], red:0, green:green, $
																			maw_drift:maw_drift, maw_drift_ut:maw_ut, $
																			dav_drift:dav_drift, dav_drift_ut:dav_data.drift_ut}

		save, filename = 'C:\RSI\IDLSource\NewAlaskaCode\Davis\CommonVolume\Data\' + $
			  date_stuff.yymmdd_string + '.idlsave', all_cv

		heap_gc
		mawson_davis_cv_summary_plot, all_cv

	endfor
end