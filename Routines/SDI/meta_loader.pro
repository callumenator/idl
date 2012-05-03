
;\\ Load multi-station data, including bistatic and usolve if available

pro meta_loader, out, $
				 ydn = ydn, $			;\\ four digit year, 2 or 3 digit day number
				 ymd = ymd,	$ 			;\\ 2 digit year, 2 digit month, 2 digit day
				 filename=filename, $	;\\ from a filename
				 raw_paths=raw_paths, $	;\\ raw data search paths
				 filter = filter, $		;\\ string array of filters - site code, wavelength, whatever
				 make_pic = make_pic, $	;\\ make a picture showing zones on a map, include in data structure
				 no_mono = no_mono, $
				 no_bi = no_bi, $
				 no_usolve = no_usolve, $
				 no_lasers = no_lasers, $
				 get_allsky_ims = get_allsky_ims, $
				 auto_flat = auto_flat, $	;\\ Apply flat-field correction
				 drift_type = drift_type 	;\\ 'none', 'data', 'laser', 'both'

    if not keyword_set(drift_type) then drift_type = 'data'


;\\ SOME DEFAULT PATHS
	if not keyword_set(raw_paths) then obs_data_path = [where_is('poker_data'), where_is('gakona_data')] $
		else obs_data_path = raw_paths
	monostatic_data_path = where_is('monostatic_fits')
	bistatic_data_path = where_is('bistatic_fits')
	bi_usolve_data_path = where_is('usolve_fits')


;\\ SORT OUT THE DATE
	date_yn = 0
	if keyword_set(ydn) then begin
		out = {err_code:'No Date Supplied/Bad Date: ' + ydn}

		packed = strcompress(ydn, /remove_all)
		year = fix(strmid(packed, 0, 4))
		if strlen(packed) eq 7 then dayn = fix(strmid(packed, 4, 3)) $
			else if strlen(packed) eq 6 then dayn = fix('0' + strmid(packed, 4, 2)) $
				else if strlen(packed) gt 7 then return

		ydn2md, year, dayn, month, day

		year = string(year, f='(i04)')
		month = string(month, f='(i02)')
		day = string(day, f='(i02)')
		dayn = string(dayn, f='(i03)')

		date_yn = 1
	endif

	if keyword_set(ymd) then begin
		out = {err_code:'No Date Supplied/Bad Date: ' + ymd}

		packed = strcompress(ymd, /remove_all)
		year = fix(strmid(packed, 0, 2))
		if year gt 80 then year+=1900 else year+=2000
		month = fix(strmid(packed, 2, 2))
		day = fix(strmid(packed, 4, 2))

		dayn = ymd2dn(year, month, day)
		year = string(year, f='(i04)')
		month = string(month, f='(i02)')
		day = string(day, f='(i02)')
		dayn = string(dayn, f='(i03)')

		date_yn = 1
	endif

	if keyword_set(filename) then begin
		out = {err_code:'No Date Supplied/Bad Filename: ' + filename}

		;sdi3k_read_netcdf_data, filename, metadata = meta, /close
		;dt = convert_js(meta.start_time)

		filename = file_basename(filename)

		byte_name = byte(filename)
		pts = where(byte_name eq 32, nspaces)
		if nspaces gt 0 then byte_name[pts] = byte('_')
		filename = string(byte_name)

		split = strsplit(file_basename(filename), '_', /extract)
		dayn = float(split[2])
		year = float(split[1])

		ydn2md, year, dayn, month, day

		year = string(year, f='(i04)')
		month = string(month, f='(i02)')
		day = string(day, f='(i02)')
		dayn = string(dayn, f='(i03)')

		date_yn = 1
	endif

	if date_yn eq 0 then return

	if not keyword_set(filter) then filter = ['*630*']


;\\ SEARCH FOR FILES
	obs_date = '*' + year + '_' + dayn + '*'
	obs_files = ['']
	for j = 0, n_elements(obs_data_path) - 1 do begin
		obs_files = [obs_files, file_search(obs_data_path[j] + obs_date + '*sky*' + ['*.nc', '*.sky'], count = nobs)]
	endfor

	if n_elements(obs_files) gt 0 then begin
		obs_files = obs_files[1:*]
		valid = where(obs_files ne '', nvalid)
		if nvalid gt 0 then begin
			obs_files = obs_files[valid]
			nobs = nvalid
		endif else begin
			nobs = 0
		endelse
	endif else begin
		nobs = 0
	endelse

	obs_date = '*' + year + '_' + dayn + '*'
	las_files = ['']
	for j = 0, n_elements(obs_data_path) - 1 do begin
		las_files = [las_files, file_search(obs_data_path[j] + obs_date + '*cal*' + ['*.pf', '*.nc', '*.las'], count = nlas)]
	endfor
	if n_elements(las_files) gt 0 then begin
		las_files = las_files[1:*]
		valid = where(las_files ne '', nvalid)
		if nvalid gt 0 then begin
			las_files = las_files[valid]
			nlas = nvalid
		endif else begin
			nlas = 0
		endelse
	endif else begin
		nlas = 0
	endelse


	mo_date = '*' + year + '-' + month + '-' + day + '*'
	mo_files = file_search(monostatic_data_path + 'MonoStaticFits' + mo_date, count = nmo)

	bi_date = mo_date
	bi_files = file_search(bistatic_data_path + 'BiStaticFits' + bi_date, count = nbi)

	biu_date = mo_date
	biu_files = file_search(bi_usolve_data_path + 'USolveFits' + biu_date, count = nbiu)

	found = {obs:0, las:0, mono:0, bi:0, usolve:0}

	if nobs gt 0 then begin
		match = intarr(nobs)
		for k = 0, n_elements(filter) - 1 do begin
			match += strmatch(obs_files, '*'+filter[k]+'*', /fold)
		endfor
		obs_in = where(match eq n_elements(filter), nin)
		if nin gt 0 then begin
			obs_files = obs_files[obs_in]
			found.obs = nin
		endif
	endif

	if nlas gt 0 then begin
		n_filter = ['*']
		match = intarr(nlas)
		for k = 0, n_elements(n_filter) - 1 do begin
			match += strmatch(las_files, '*'+n_filter[k]+'*', /fold)
		endfor
		las_in = where(match eq n_elements(n_filter), nin)
		if nin gt 0 then begin
			las_files = las_files[las_in]
			found.las = nin
		endif
	endif



	n_filter = ['*']

	if nmo gt 0 then begin
		match = intarr(nmo)
		for k = 0, n_elements(n_filter) - 1 do begin
			match += strmatch(mo_files, '*'+n_filter[k]+'*', /fold)
		endfor
		mo_in = where(match eq n_elements(n_filter), nin)
		if nin gt 0 then begin
			mo_files = mo_files[mo_in]
			found.mono = nin
		endif
	endif

	if nbi gt 0 then begin
		match = intarr(nbi)
		for k = 0, n_elements(n_filter) - 1 do begin
			match += strmatch(bi_files, '*'+n_filter[k]+'*', /fold)
		endfor
		bi_in = where(match eq n_elements(n_filter), nin)
		if nin gt 0 then begin
			bi_files = bi_files[bi_in]
			found.bi = nin
		endif
	endif

	if nbiu gt 0 then begin
		match = intarr(nbiu)
		for k = 0, n_elements(n_filter) - 1 do begin
			match += strmatch(biu_files, '*'+n_filter[k]+'*', /fold)
		endfor
		biu_in = where(match eq n_elements(n_filter), nin)
		if nin gt 0 then begin
			biu_files = biu_files[biu_in]
			found.usolve = nin
		endif
	endif

	print, 'Found:'
	print, 'Raw Obs: ' + string(found.obs,f='(i0)')
	print, 'Raw Las: ' + string(found.las,f='(i0)')
	print, 'MonoStatic: ' + string(found.mono,f='(i0)')
	print, 'BiStatic: ' + string(found.bi,f='(i0)')
	print, 'USolve: ' + string(found.usolve,f='(i0)')

	if keyword_set(no_mono) then found.mono = 0
	if keyword_set(no_bi) then found.bi = 0
	if keyword_set(no_usolve) then found.usolve = 0
	if keyword_set(no_lasers) then found.las = 0

	top_level_list = ['']

	;\\ RAW OBS
	real_raw_obs = 0
	for k = 0, found.obs - 1 do begin
		if keyword_set(get_allsky_ims) then begin
			sdi3k_read_netcdf_data, obs_files[k], metadata = meta, winds=winds, spek=speks, images=images, zone_centers=zone_centers, /close
		endif else begin
			sdi3k_read_netcdf_data, obs_files[k], metadata = meta, winds=winds, spek=speks, zone_centers=zone_centers, /close
		endelse
		ut = js2ut(0.5*(winds.start_time + winds.end_time))


		if size(speks, /type) eq 7 then begin
			;\\ No speks really, lets skip this.
			continue
		endif

		;\\ Apply flat field
		if keyword_set(auto_flat) then begin
			sdi3k_auto_flat, meta, wind_offset, extend_valid_time = 10*3600.*24.
			for kk = 0, n_elements(speks.velocity[0])-1 do speks[kk].velocity[1:*] = speks[kk].velocity[1:*] - wind_offset[1:*]
		endif

		if meta.site_code eq 'PKR' then begin
			;drift_type eq 'laser' or
			if drift_type eq 'both' then this_drift_type = 'data' else this_drift_type = drift_type
		endif else begin
			this_drift_type = drift_type
		endelse

		drift = 0
		if this_drift_type eq 'data' then begin
			speks_dc = speks
			sdi3k_drift_correct, speks_dc, meta, /force, /data_based
			vz = speks_dc.velocity[0]*meta.channels_to_velocity
			drift_curve = (speks.velocity - speks_dc.velocity)*meta.channels_to_velocity
			drift_curve = drift_curve - drift_curve[0]
			drift = 1
		endif

		if this_drift_type eq 'laser' then begin
			match = strmatch(las_files, '*' + meta.site_code + '*', /fold)
			yes = where(match eq 1, nyes)
			if nyes eq 1 then begin
				speks_dc = speks
				insfile = (las_files[yes[0]])[0]
				drift_correct, speks_dc, meta, /force, insfile=insfile
				vz = speks_dc.velocity[0]*meta.channels_to_velocity
			endif else begin
				speks_dc = speks
				sdi3k_drift_correct, speks_dc, meta, /force, /data_based
				vz = speks_dc.velocity[0]*meta.channels_to_velocity
				print, 'No Laser Found For ' + meta.site_code + ' - data-based drift correction applied...'
			endelse
			drift_curve = (speks.velocity - speks_dc.velocity)*meta.channels_to_velocity
			drift_curve = drift_curve - drift_curve[0]
			drift = 1
		endif

		if this_drift_type eq 'both' then begin
			match = strmatch(las_files, '*' + meta.site_code + '*', /fold)
			yes = where(match eq 1, nyes)
			if nyes eq 1 then begin
				speks_dc = speks
				insfile = (las_files[yes[0]])[0]
				drift_correct, speks_dc, meta, /force, insfile=insfile
				sdi3k_drift_correct, speks_dc, meta, /force, /data_based
				vz = speks_dc.velocity[0]*meta.channels_to_velocity
			endif else begin
				speks_dc = speks
				sdi3k_drift_correct, speks_dc, meta, /force, /data_based
				vz = speks_dc.velocity[0]*meta.channels_to_velocity
				print, 'No Laser Found For ' + meta.site_code + ' - data-based drift correction applied...'
			endelse
			drift_curve = (speks.velocity - speks_dc.velocity)*meta.channels_to_velocity
			drift_curve = drift_curve - drift_curve[0]
			drift = 1
		endif

		if this_drift_type eq 'none' or drift eq 0 then begin
			speks_dc = speks
			vz = speks_dc.velocity[0]*meta.channels_to_velocity
			vz = vz - median(vz)
			drift_curve = (speks.velocity - speks_dc.velocity)*meta.channels_to_velocity
			drift_curve = drift_curve - drift_curve[0]
		endif

		case meta.wavelength_nm of
			630.0: alt = 240.
			557.7: alt = 115.
			843.0: alt = 90.
			else: alt = 0.
		endcase

		aziPlus = 180 - (winds[0].azimuths[2] - meta.oval_angle)

			get_zone_lat_lon, findgen(meta.nzones), meta, winds, lat, lon, $
				  aziPlus= 180 - (winds[0].azimuths[2] - meta.oval_angle), useAltitude=alt



		;\\ ALSO PLOT A SIMPLE MAP SHOWING ZONE LOCATIONS, ETC.
		if keyword_set(make_pic) then begin
			window, xs = 700, ys = 700
			plot_simple_map, meta.latitude, meta.longitude, 6, 1, 1, map=map
			rads = [0, meta.zone_radii[0:meta.rings-1]]/100.
			secs = meta.zone_sectors[0:meta.rings-1]
			plot_zonemap_on_map, meta.latitude, meta.longitude, rads, secs, alt, $
								 180 + meta.oval_angle, meta.sky_fov_deg, map, /numberzones
			map_image = tvrd(/true)
			wdelete, !d.window

		endif else begin

			map_image = fltarr(2,2)

		endelse

		if keyword_set(get_allsky_ims) then begin
			res = execute(meta.site_code + ' = {ut:ut, vz:vz, meta:meta, winds:winds, speks:speks, lats:lat, lons:lon, zone:centers:zone_centers, ' + $
												'speks_dc:speks_dc, images:images, drift_curve:drift_curve, map:map_image, aziPlus:aziPlus}')
		endif else begin
			res = execute(meta.site_code + ' = {ut:ut, vz:vz, meta:meta, winds:winds, speks:speks, lats:lat, lons:lon, zone_centers:zone_centers, ' + $
												'speks_dc:speks_dc, drift_curve:drift_curve, map:map_image, aziPlus:aziPlus}')
		endelse
		top_level_list = [top_level_list, meta.site_code]
		real_raw_obs ++

	endfor

	;\\ RAW LAS
	real_raw_las = 0
	for k = 0, found.las - 1 do begin
		sdi3k_read_netcdf_data, las_files[k], metadata = meta, spek=speks, /close

		if size(speks, /type) eq 7 then begin
			;\\ No speks really, lets skip this.
			continue
		endif

		ut = js2ut(0.5*(speks.start_time + speks.end_time))
		res = execute(meta.site_code + '_las = {ut:ut, meta:meta, speks:speks}')
		top_level_list = [top_level_list, meta.site_code + '_las']
		real_raw_las ++
	endfor

	found.obs = real_raw_obs
	found.las = real_raw_las


	;\\ MONOSTATIC
	for k = 0, found.mono - 1 do begin
		restore, mo_files[k]
		label = monofitssub[0].station + '_Mono'
		res = execute(label + ' = monofitssub')
		monofitssub = 0
		top_level_list = [top_level_list, label]
	endfor

	;\\ BISTATIC
	for k = 0, found.bi - 1 do begin
		restore, bi_files[k]
		names = allbifits[0].stations
		names = names[sort(names)]
		label = names[0] + '_' + names[1] + '_Bi'
		res = execute(label + ' = allbifits')
		allbifits = 0
		top_level_list = [top_level_list, label]
	endfor

	;\\ BISTATIC USOLVE
	for k = 0, found.usolve - 1 do begin
		restore, biu_files[k]
		names = usolve.stations
		names = names[sort(names)]
		label = names[0] + '_' + names[1] + '_USolve'
		res = execute(label + ' = usolve')
		usolve = 0
		top_level_list = [top_level_list, label]
	endfor

	if n_elements(top_level_list) eq 1 then begin
		out = {err_code:'No Data Matching Dates/Criteria: ' + dayn}
		return
	endif else begin
		err_code = ""
		top_level_list = [top_level_list, 'err_code']
	endelse

	top_level_list = top_level_list[1:*]
	yymmdd_string = strmid(year,2,2) + '/' + month + '/' + day
	yymmdd_nosep = strmid(year,2,2) + month + day
	exec_str = 'out = {found:found, year:float(year), month:float(month), day:float(day), dayno:float(dayn), '
	exec_str += 'yymmdd_str:yymmdd_string, yymmdd_nosep:yymmdd_nosep, '
	for k = 0, n_elements(top_level_list) - 1 do begin
		exec_str += top_level_list[k] + ':' + top_level_list[k]
		if k ne n_elements(top_level_list) - 1 then exec_str += ', ' $
			else exec_str += '}'
	endfor

	res = execute(exec_str)

end