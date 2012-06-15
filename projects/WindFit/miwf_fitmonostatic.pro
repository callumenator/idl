
;\\ blendFit = {timeIndex, lats (yout), lons (xout), vertGrid[gridx,gridy]}

;\\ Fit monostatic winds
pro MIWF_FitMonoStatic, blendFitData = blendFitData, $
						outFits = outFits, $
						force_restore = force_restore, $
						force_redo = force_redo

	common miwf_common, guiData, miscData

	if miscData.nstations eq 0 then return

	;\\ Make an array of station names
		stationName = strarr(miscData.nStations)
		stationPos = fltarr(miscData.nStations, 2)
		for s = 0, miscData.nStations - 1 do stationName[s] = (*miscData.metaData[s]).site_code

	monoFitStruc = {station:'', $
					stnTime:0D, $
					time:0D, $
					windCoords:'', $
					lat:0.0, $
					lon:0.0, $
					zonal:0.0, $
					merid:0.0, $
					vertical:0.0, $
					alt:0.0, $
					dudx:0.0, $
					dudy:0.0, $
					dvdx:0.0, $
					dvdy:0.0, $
					bistatic_datafrac:0.0, $
					bistatic_medMerr:0.0, $
					bistatic_medLerr:0.0 }

	nZones = 0
	for s = 0, miscData.nStations - 1 do nZones = nZones + (*miscData.metadata[s]).nzones

	if size(blendFitData, /type) ne 8 then begin
		monoFitsAll = replicate(monoFitStruc, n_elements(*miscData.allTimes), nzones)
	endif else begin
		;\\ If called by the blend fitting algorithm, only fit the given exposure
		monoFitsAll = replicate(monoFitStruc, 1, nzones)
	endelse


	sidx = 0
	for s = 0, miscData.nStations - 1 do begin

		;\\ Generate a save name for each station's monofit data (this stuff doesn't actually get
		;\\ restored like it does for bistatic fits, I just like to save it for easy access later...)
			dateStr = date_str_from_js((*miscData.windData[0])[0].start_time[0], /forfile)
			stnName = stationName[s]
			fitSaveName = miscData.savedDataPath + 'MonoStaticFits_' + stnName + '_' + dateStr + '.saved'

			if not keyword_set(force_redo) then begin
				if file_test(fitSaveName) eq 1 then begin
					if not keyword_set(force_restore) then begin
						yn = dialog_message('Restore Saved Fit Data: ' + file_basename(fitSaveName) + '?', /question)
						if yn eq 'Yes' then begin
							restore, fitSaveName

							if size(*miscData.monoFits, /type) eq 2 or $
								size(*miscData.monoFits, /type) eq 0 then begin
								*miscData.monoFits = monoFitsSub
							endif else begin
								*miscData.monoFits = [[*miscData.monoFits], [monoFitsSub]]
							endelse
							continue
						endif
					endif
					if keyword_set(force_restore) then begin
						restore, fitSaveName
						if size(*miscData.monoFits, /type) eq 2 then begin
							*miscData.monoFits = monoFitsSub
						endif else begin
							*miscData.monoFits = [[*miscData.monoFits], [monoFitsSub]]
						endelse
						continue
					endif
				endif
			endif


		meta = (*miscData.metaData[s])
		wind = (*miscData.windData[s])
		spek = (*miscData.spekDataX[s])
		zcen = (*miscData.zoneCenters[s])

		zenithWind = spek.velocity
		sdi3k_timesmooth_fits,  zenithWind, 3, meta
		zenithWind = zenithWind[0,*]

		diff = 180 - (wind[0].azimuths[2] - meta.oval_angle)
		rads = [0,meta.zone_radii[0:meta.rings-1]]/100.
		secs = meta.zone_sectors[0:meta.rings-1]
		azis = wind[0].azimuths + diff - meta.oval_angle 		;\\ these are in magnetic now
		zens = wind[0].zeniths
		ring = get_zone_rings(zens)

		med_sig_intens = median(spek[*].sigma_intensities[*], dimension = 1)
		sigma_intens = fltarr(meta.nzones, n_elements(*miscData.allTimes))
		for k = 0, meta.nzones - 1 do sigma_intens[k,*] = $
			interpol(abs(spek[*].sigma_intensities[k] - med_sig_intens) / stddev(med_sig_intens), $
				js2ut(0.5*(wind.start_time + wind.end_time)), *miscData.allTimes)

		;\\ Determine an emission altitude
		case meta.wavelength_nm of
			557.7: alt = 120.
			589.0: alt = 92.
			630.0: alt = 240.
			else: alt = 0.
		endcase

		;\\ Determine start-end times/exposures
		if size(blendFitData, /type) ne 8 then begin
			monoFitsSub = replicate(monoFitStruc, n_elements(*miscData.allTimes), meta.nzones)
			minT = 0
			maxT = n_elements(*miscData.allTimes) - 1
		endif else begin
			monoFitsSub = replicate(monoFitStruc, 1, meta.nzones)
			minT = blendFitData.timeIndex
			maxT = blendFitData.timeIndex
		endelse



		;\\ Fit each exposure
		for t = minT, maxT do begin
			zidx = 0

			expIndex = (*miscData.stnIndices[s])[t]
			MIWF_GetInterpolates, s, t, interps

			if size(blendFitData, /type) ne 8 then begin
				;\\ For normal fits, zenith wind is measured in the central zone...
				verticalWind = float(interpol(zenithWind, js2ut(0.5*(wind.start_time + wind.end_time)), (*miscData.allTimes)[t]))
				verticalWind = replicate(verticalWind, meta.nzones)
			endif else begin
				;\\ For blending fits, zenith wind is supplied on a lon/lat grid, so find nearest...
				vz = fltarr(meta.nzones)
				for bfz = 0, meta.nzones - 1 do begin
					dist = get_great_circle_length(zens[bfz], alt)
					diff = 180 - (winds[0].azimuths[2] - meta.oval_angle)
					endpt = get_end_lat_lon(meta.latitude, meta.longitude, dist, azis[bfz] + diff)
					latDiff  = (endpt[0] - blendFitData.lats)*(endpt[0] - blendFitData.lats)
					lonDiff  = (endpt[1] - blendFitData.lons)*(endpt[1] - blendFitData.lons)
					latPt = (where(latDiff eq min(latDiff)))[0]
					lonPt = (where(lonDiff eq min(lonDiff)))[0]
					vz[bfz] = blendFitData.verticalWind[lonPt, latPt]
				endfor
				verticalWind = vz
			endelse

			;goodZones = indgen((*miscData.metaData[s]).nzones)
			;goodZones = where(spek[expIndex].intensity gt 0 and $
			;				  spek[expIndex].sigma_velocity*meta.channels_to_velocity lt 40 and $
			;				  sigma_intens[*,expIndex] le 4)

			;goodZones = where(interps.intensity gt 0 and $
			;				  interps.sigma_los*meta.channels_to_velocity lt 40 and $
			;				  sigma_intens[*,t] le 4)

			;windfit = field_fit( reform(interps.los - verticalWind*cos(zens*!dtor))/sin(zens*!dtor), $
			;					 azis, zens, 240*tan(zens*!dtor), $
			;					 ring, secs, goodZones, /fourier)
			;zonalWind = windfit.hx
			;meridWind = windfit.hy

			dvdx_assumption = 'dv/dx=zero'
			wind_settings = {time_smoothing: 1.4, $
                    		 space_smoothing: 0.08, $
                    		 dvdx_assumption: dvdx_assumption, $
                          	 algorithm: 'Fourier_Fit', $
                     		 assumed_height: alt, $
                             geometry: 'none'}
    		dvdx_zero = 1


			tmp = spek[expIndex]
			tmp.velocity = interps.los - verticalWind*cos(zens*!dtor)

			windfit_modified, tmp, meta, dvdx_zero=dvdx_zero, windfit, wind_settings, zcen, $
							  /no_vz_correction

			;zonalWind = windfit.zonal_fitted
			;meridWind = windfit.merid_fitted
			zonalWind = windfit.zonal_wind
			meridWind = windfit.meridional_wind

			angle = (-1.0)*meta.oval_angle*!dtor
			geoZonalWind = zonalWind*cos(angle) - meridWind*sin(angle)
			geoMeridWind = zonalWind*sin(angle) + meridWind*cos(angle)



			for z = 0, meta.nzones - 1 do begin
				dist = get_great_circle_length(zens[z], alt)
				diff = 180 - (wind[0].azimuths[2] - meta.oval_angle)
				endpt = get_end_lat_lon(meta.latitude, meta.longitude, dist, wind[0].azimuths[z] + diff)

				bistatic_datafrac = 0.0
				bistatic_medMerr = 0.0
				bistatic_medLerr = 0.0

				fitStr = {station:meta.site_code, $
						  stnTime:(*miscData.stnTimes[s])[t], $
						  time:(*miscData.allTimes)[t], $
						  windCoords:'Geo', $
						  lat:endpt[0], $
						  lon:endpt[1], $
						  zonal:geoZonalWind[z], $
						  merid:geoMeridWind[z], $
						  vertical:verticalWind[z], $
						  alt:alt, $
						  dudx:windfit.dudx[ring[z]], $  ;\\ These are still in magnetic coords
						  dudy:windfit.dudy[ring[z]], $
						  dvdx:windfit.dvdx[ring[z]], $
						  dvdy:windfit.dvdy[ring[z]], $
						  bistatic_datafrac:bistatic_datafrac, $
						  bistatic_medMerr:bistatic_medMerr, $
						  bistatic_medLerr:bistatic_medLerr}

				monoFitsSub[t - minT, zidx] = fitStr
				zidx ++
			endfor

			if size(blendFitData, /type) ne 8 then begin
				;\\ Update progress bar
				MIWF_UpdateProgress, float(t*(s+1))/ (n_elements(*miscData.allTimes)*float(miscData.nStations)), $
									 'Station ' + string(s, f='(i0)') + ', Time Index: ' + string(t, f='(i0)')
			endif

		endfor ;\\ exposure loop

			;\\ Save mono-static fits to the savedDataPath
				save, filename = fitSaveName, monoFitsSub, /compress

		monoFitsAll[*, sidx:sidx+meta.nzones-1] = monoFitsSub
		sidx += zidx
	endfor

	if size(blendFitData, /type) ne 8 then begin
		*miscData.monoFits = monoFitsAll
		;\\ Clear the progress bar
			MIWF_UpdateProgress, /reset
	endif else begin
		outFits = reform(monoFitsAll)
	endelse

end