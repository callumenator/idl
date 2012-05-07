

;\\ Takes Davis Real Time Analysis files and produces wind, temperature,
;\\ intensity, exposure time, etc, time series, for the specified year, dayno, filter
;\\ and wavelength

function drta_make_time_series, data_path, year, $
										   dayno, $
										   filter, $
										   lambda, $
										   los=los, $
										   zenith_correct=zenith_correct, $
										   filename=filename, $
										   useLELdrift=useLELdrift, $
										   noDrift = noDrift, $
										   dataDrift = dataDrift, $
										   refitTemperatures=refitTemperatures

	if data_path eq '' then data_path = where_is('davis_data')

	if keyword_set(filename) then filename1 = filename else $
		filename1 = data_path + string(year, f='(i4.4)') + '_' + string(dayno, f='(i3.3)')

	if file_test(filename1) then restore, filename1, /relaxed else return, {data:0}

	if keyword_set(filename) then begin
		js2ymds, sky[0].js, year, month, day, second
		dayno = ymd2dn(year, month, day)
	endif

	if size(sky, /type) eq 0 or size(las, /type) eq 0 then return, {data:0}
	if n_elements(sky) le 5 then return, {data:0}
	if n_elements(las) lt 5 then return, {data:0}

	;sintens = sky(sort(sky.fitpars(2) / sky.data.exptime)).fitpars(2) / sky.data.exptime
	;sidx = n_elements(sintens)*0.2
	pts = where(sky.fitpars(2) / sky.data.exptime gt .01, npts)
	if npts eq 0 then return, {data:0}

	sky = sky(pts)

	if lambda eq 557.7 then lambda = ceil(lambda)
	sub = where(sky.params.lambda eq lambda and sky.data.filter eq filter, nsub)

	if nsub eq 0 then return, {data:0}

	sky = sky(sub)

	wavelength = sky[0].params.lambda

	;\\ Sort out the good fits
		sky_chisq = fltarr(n_elements(sky))
		for schsq = 0, n_elements(sky) - 1 do sky_chisq(schsq) = sky[schsq].quality.chisq[sky[schsq].quality.iters]
		s_chisq = sort(sky_chisq)
		s_chisq_max = sky_chisq(s_chisq(n_elements(s_chisq)*.99 - 1))
		good_sky = where(sky_chisq le s_chisq_max, nsgood)

		las_chisq = fltarr(n_elements(las))
		for lchsq = 0, n_elements(las) - 1 do las_chisq(lchsq) = las[lchsq].quality.chisq[las[lchsq].quality.iters]
		s_chisq = sort(las_chisq)
		s_chisq_max = las_chisq(s_chisq(n_elements(s_chisq)*.99 - 1))
		good_las = where(las_chisq le s_chisq_max, nlgood)

		if nlgood lt 5 then return, {data:0}
		if nsgood lt 5 then return, {data:0}

		las = las[good_las]
		sky = sky[good_sky]

	;\\ Zeniths
		zen = where(sky.data.zen_ang eq 0, nzen)
		if nzen lt 4 then return, {data:0}

	;\\ Peakpos
		sky_pkpos = sky.fitpars(3) * (-1.0)
		sky_pkerr = sky.sigpars(3)
		las_pkpos = las.fitpars(3) * (-1.0)

	;\\ Correct for laser drift (or use LEL pressure/temperature model)
		las_drift = las_pkpos - las_pkpos(0)
		las_drift = interpol(las_drift, las.ut, sky.ut)
		las_drift = smooth(las_drift, 5, /edge) * (632.8 / wavelength)

		if keyword_set(noDrift) then begin
			drift = 0
			goto, END_DRIFT
		endif

		if keyword_set(useLELdrift) then begin
			lelDQ = extract_lel_data(year, dayno, '"DQ"', goodValues = [800,1500])
			lelTemp = extract_lel_data(year, dayno, '"EC7"', goodValues = [-100,100])
			if size(lelDQ, /type) ne 8 or size(lelDQ, /type) ne 8 then begin
				;\\ No lel data, use laser drift
					sky_pkpos = sky_pkpos - las_drift
					drift = las_drift
			endif else begin
				;\\ Lel data found, use lel model
					p = double(interpol(lelDQ.data, lelDQ.ut, sky.ut)) * 100.
					t = double(interpol(lelTemp.data, lelTemp.ut, sky.ut))
					t = smooth(t, nsgood/2. < 30, /edge)

					sigma = double(1./(632.8E-3))
					nchann = 64D
					ns = 0.0472326D*((173.3D - sigma^2.)^(-1))
					n = ns*[(p * [ 1 + p*(60.1 - .972*t)*10^(-10)]) / (96095.43*(1 + 0.003661*t))] + 1D
					m = nchann*(2*n*(12.948E-3))/(wavelength * 1E-9)
					lel_drift = -1*(m-m[0])
					sky_pkpos = sky_pkpos - lel_drift
					drift = lel_drift
			endelse
			goto, END_DRIFT
		endif

		if keyword_set(datadrift) then begin
			zt  = sky(zen).ut
            zd = sky_pkpos[zen]
            zf = poly_fit(zt, zd, 2, yfit=drift_curve, measure_errors = sky_pkerr(zen))
            drift_curve = drift_curve - drift_curve[0]
            drift_curve = interpol(drift_curve, zt, sky.ut)
            sky_pkpos = sky_pkpos - drift_curve
            drift = drift_curve
            ;stop
            goto, END_DRIFT
		endif

		;\\ Else do normal drift correct
		sky_pkpos = sky_pkpos - las_drift
		drift = las_drift

	END_DRIFT:

	;\\ Temp
		if keyword_set(refitTemperatures) then begin
			;\\ Re-do temperatures
			redoneTemperatures = refit_davis_temperatures(year, dayno)
			sky_temp = redoneTemperatures(*,0)
			sky_temperr = redoneTemperatures(*,1)
		endif else begin
			sky_temp = sky.fitpars(4)
			sky_temperr = sky.sigpars(4)
		endelse

	;\\ Rel Intensity
		sky_intens = sky.fitpars(2) / sky.data.exptime
		sky_intenserr = sky.sigpars(2) / sky.data.exptime

	;\\ Zero velocity reference
		zen_peaks = sky_pkpos(zen)
		zen_errs  = sky_pkerr(zen)
		zen_time  = sky(zen).ut

		zen_sort = sort(zen_errs)
		n = n_elements(zen_sort)
		zen_sort = zen_sort(0.05*n - 1:0.95*n - 1)
		zero_wind = median(zen_peaks(zen_sort))

	;\\ Zero the sky peaks
		sky_pkpos = sky_pkpos - zero_wind

	;\\ Sort into directions:
	;\\ north, south, east, west, zenith, mawson cv
		ndirections = 6
		template = {ndata:0, $
					zen_ang:ptr_new(/alloc), $
					azimuth:ptr_new(/alloc), $
					name:'', $
					time:ptr_new(/alloc), $
					jstime:ptr_new(/alloc), $
					wind:ptr_new(/alloc), $
					wind_err:ptr_new(/alloc), $
					temp:ptr_new(/alloc), $
					temp_err:ptr_new(/alloc), $
					intens:ptr_new(/alloc), $
					intens_err:ptr_new(/alloc), $
					exptime:ptr_new(/alloc) , $
					chisq:ptr_new(/alloc), $
					snr:ptr_new(/alloc)}

		directions = replicate(template, ndirections)

		names = ['Zenith', 'North', 'South', 'East', 'West', 'Mawson']
		directions(*).name = names

		Lambdafsr = (632.8e-9)^2/(2*12.948e-3)
		Vfsr = ((3.e8)*Lambdafsr)/632.8e-9
		cnv = Vfsr/64.

		for n = 0, ndirections - 1 do begin


			pts = where(strmatch(sky.data.title, '*'+directions(n).name+'*', /fold) eq 1, npts)

			for z = 4, 14 do directions(n).(z) = ptr_new(/alloc)
			for z = 1, 2 do directions(n).(z) = ptr_new(/alloc)

			directions(n).ndata 	= npts

			if npts eq 0 then goto, DRTA_PLOTTER_NEXT_DIR

			if n eq 0 then begin
				mint = min(sky(pts).ut)
				maxt = max(sky(pts).ut)
			endif else begin
				if min(sky(pts).ut) < mint then mint = min(sky(pts).ut)
				if max(sky(pts).ut) > maxt then maxt = max(sky(pts).ut)
			endelse

			if directions(n).name ne 'Zenith' then begin
				;\\ This part subtracts the zenith component, assuming zenith wind covers the field of view
					m = moment(sky_pkpos(zen))
					good_zens = where(sky_intens(zen) gt .01)
					int_zen = interpol(sky_pkpos(zen(good_zens)), sky(zen(good_zens)).ut, sky(pts).ut)*cnv

				  	if not keyword_set(los) then begin
				  		if keyword_set(zenith_correct) then begin
				  			*directions(n).wind = (sky_pkpos(pts)*cnv - int_zen*cos(sky(pts(0)).data.zen_ang*!dtor)) / sin(sky(pts(0)).data.zen_ang*!dtor)
				  		endif else begin
				  			*directions(n).wind = (sky_pkpos(pts)*cnv) / sin(sky(pts(0)).data.zen_ang*!dtor)
						endelse
				  	endif else begin
				  		*directions(n).wind	= sky_pkpos(pts)*cnv
				  	endelse
			endif else begin
					*directions(n).wind	= sky_pkpos(pts)*cnv
			endelse

			*directions(n).zen_ang 	= sky(pts).data.zen_ang
			*directions(n).azimuth 	= sky(pts).data.azimuth
			*directions(n).time		= sky(pts).ut
			*directions(n).jstime	= sky(pts).js
			*directions(n).wind_err	= sky_pkerr(pts)*cnv
			*directions(n).temp		= sky_temp(pts)
			*directions(n).temp_err	= sky_temperr(pts)
			*directions(n).intens	= sky_intens(pts)
			*directions(n).intens_err = sky_intenserr(pts)
			*directions(n).exptime 	= sky(pts).data.exptime
			*directions(n).chisq 	= sky_chisq(pts)
			*directions(n).snr 		= sky(pts).quality.snr

		DRTA_PLOTTER_NEXT_DIR:
		endfor

		drift_ut = sky.ut
		return, {data:1, $
				 directions:directions, $
				 time_range:[mint,maxt], $
				 drift_ut:drift_ut, $
				 drift:drift, $
				 chan_to_vel:cnv, $
				 goodSky:good_sky}

end