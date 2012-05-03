
pro drift_correct, spekfits, sky_meta, force=fdc, data_based=dbase, insfile=insfile

	sdi3k_read_netcdf_data, insfile, metadata=las_meta, spekfits=driftarr, /close


	dp = driftarr.velocity
	sp = spekfits.velocity
	dt = driftarr.start_time
	st = spekfits.start_time

	las_dims = size(dp, /dimensions)
	sky_dims = size(sp, /dimensions)

	dut = js2ut(dt)
	dt_range = max(dut) - min(dut)
	dp_interpol = fltarr(sky_dims[0], sky_dims[1])


	;\\ For each zone, replace any outliers in the laser positions
		for z = 0, las_dims[0] - 1 do begin
			dp_z = reform(dp[z,*])
			find_outliers_recursive, dp_z, outs, complement=ins, abs_thresh = 3

			if n_elements(outs) gt las_dims[1]/5. then begin
				;\\ Too many outliers, replace the whole timeseries with either..
				if z ne 0 then begin
					;\\ The previous zone, or...
					dp_z = dp[z-1,*]
				endif else begin
					;\\ The median over all zones
					dp_z = median(dp, dim=1)
				endelse
			endif else begin
				;\\ Interpolate the non-outlying positions to the original times
				dp_z = interpol(dp_z[ins], dt[ins], dt)
			endelse

			;\\ Relative to first laser
				dp_z -= dp_z[0]

			;\\ Scale to the sky wavelength
				dp_z *= las_meta.wavelength_nm / sky_meta.wavelength_nm

			;\\ Smooth in time
				dp_z = smooth_in_time(dut, dp_z, las_dims[1]*2, 5./60.) ;\\ 5 minute smoothing

				dp[z,*] = dp_z

			;\\ Interpolate to skies
				dp_interpol[z, *] = interpol(dp_z, dt, st, /lsquad)


		endfor


	;\\ Correct the sky positions, and replace the input sky positions
		sp -= dp_interpol

	;\\ Remove significant frequencies
;		del_t = median((dut - shift(dut,1))[1:*])
;		for z = 0, sky_dims[0] - 1 do begin
;
;			sp_z = reform(sp[z,*])
;
;			sp_fft = fft(sp_z, -1)
;			dp_fft = (abs(fft(reform(dp_interpol[z,*]), -1)))[5:las_dims[1]/2]
;
;			threshold = median(dp_fft) + 0.1*meanabsdev(dp_fft, /median)
;			pts = where(dp_fft gt threshold, npts)
;
;			if npts gt 0 then begin
;				sp_fft[pts+5] = 0
;				sp_z = fft(sp_fft, 1)
;			endif
;
;			sp[z,*] = sp_z
;		endfor


	;\\ Remove the zenith median
		zen_med = median(sp[0,*])
		sp -= zen_med
		spekfits.velocity = sp

end