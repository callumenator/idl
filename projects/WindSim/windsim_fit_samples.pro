
pro windsim_fit_samples, meta, $
						 samples, $
						 fits=fits, $
						 monostatic=monostatic, $
						 bistatic=bistatic, $
						 tristatic=tristatic


	if keyword_set(monostatic) then begin
		;\\ Fit monostatics
		dvdx_assumption = 'dv/dx=zero'
		wind_settings = {time_smoothing: 1.4, space_smoothing: 0.08, $
	               		 dvdx_assumption:dvdx_assumption, algorithm: 'Fourier_Fit', $
	               		 assumed_height: 240., geometry: 'none'}
	    dvdx_zero = 1
		mono_fits = 0
		for stn = 0, nels(meta) - 1 do begin
			spek_fits = {velocity:samples[stn].zones.los, start_time:0., end_time:0., scans:1, $
						 sigma_velocity:samples[stn].zones.sigma_los, $
						 signal2noise:1./samples[stn].zones.sigma_los}

			get_zone_locations, meta[stn], altitude=240, zones=zone_locs
			zcen = [[zone_locs.x], [zone_locs.y]]


			windfit_modified, spek_fits, meta[stn], dvdx_zero=dvdx_zero, windfit, wind_settings, zcen, /no_vz
			angle= -meta[stn].oval_angle*!DTOR
			u = windfit.zonal_wind*cos(angle) - windfit.meridional_wind*sin(angle)
			v = windfit.zonal_wind*sin(angle) + windfit.meridional_wind*cos(angle)
			stn_mono_fits = replicate({u:0., v:0., lat:0., lon:0.}, nels(windfit.zonal_wind))
			stn_mono_fits.u = u
			stn_mono_fits.v = v
			stn_mono_fits.lat = samples[stn].zones.lat
			stn_mono_fits.lon = samples[stn].zones.lon
			append, stn_mono_fits, mono_fits
		endfor
		fits = mono_fits
		return
	endif


	if keyword_set(bistatic) then begin
		;\\ Fit bistatics
		bi_fits = 0
		counter = 0
		for stn1 = 0, nels(meta) - 2 do begin
		for stn2 = stn1 + 1, nels(meta) - 1 do begin

			fit_bistatic, meta[stn1], meta[stn2], $
						  samples[stn1].zones.los, $
						  samples[stn2].zones.los, $
					  	  samples[stn1].zones.sigma_los, $
					  	  samples[stn2].zones.sigma_los, 240., $
					  	  fit = stn_bifit
			append, stn_bifit, bi_fits
			counter++
		endfor
		endfor
		fits = bi_fits
		return
	endif


	if keyword_set(tristatic) then begin
		;\\ Fit tristatics
		tri_fits = 0
		counter = 0
		for stn1 = 0, nels(meta) - 3 do begin
		for stn2 = stn1 + 1, nels(meta) - 2 do begin
		for stn3 = stn2 + 1, nels(meta) - 1 do begin
			fit_tristatic, meta[stn1], meta[stn2], meta[stn3], $
						   samples[stn1].zones.los, $
						   samples[stn2].zones.los, $
						   samples[stn3].zones.los, $
					  	   samples[stn1].zones.sigma_los, $
					  	   samples[stn2].zones.sigma_los, $
					  	   samples[stn3].zones.sigma_los, $
					  	   240., $
					  	   fit = stn_trifit
			append, stn_trifit, tri_fits
			counter++
		endfor
		endfor
		endfor
		fits = tri_fits
		return
	endif


end