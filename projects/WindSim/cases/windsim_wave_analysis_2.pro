
@resolve_nstatic_wind
@windsim_sample_fields


function windsim_wave_analysis_func, a

	common windsim_wave_analysis_common, fit

	;a = [k_hor, freq, ampl, prop_angle, phase]


	k_hor = a[0]
	frequency = a[1]
	ampl = a[2]
	prop_angle = a[3]
	phase = a[4]

	r_zonal = fit.r_zonal
	r_merid = fit.r_merid

	gamma = 1.5
	grav = 9.8
	sound_speed = 700. ;\\ meters / second
	wg_squared = (gamma-1)*(grav*grav) / (sound_speed*sound_speed)
	wa_squared = (gamma*grav / (2*sound_speed))^2.


	k_zonal = k_hor*sin(prop_angle)
	k_merid = k_hor*cos(prop_angle)
	w_squared = frequency*frequency
	phase_lag = phase

	k_ver_real = sqrt((k_hor*k_hor)*((wg_squared/w_squared) - 1) + $
				 ((w_squared - wa_squared)/(sound_speed*sound_speed)))


	k_ver_im = (gamma*grav)/(2*sound_speed*sound_speed)

	magnitude = ampl
	wpert = exp( complex( replicate(0, nels(fit.mo_fits)), (phase_lag - k_zonal*r_zonal - k_merid*r_merid)) )


	wind = 0

	dopp_freq = (frequency - wind*k_hor)
	z_phase = complex( (dopp_freq^3.) - (sound_speed^2.)*(k_hor^2.)*dopp_freq, 0)
	x_phase = complex( dopp_freq*(sound_speed^2.)*k_hor*k_ver_real, dopp_freq*k_hor*( (sound_speed^2.)*k_ver_im - grav ))

	scl = abs(z_phase)

	hor_pert = real_part(magnitude * x_phase * wpert)/scl
	zonal_pert = hor_pert*sin(prop_angle)
	merid_pert = hor_pert*cos(prop_angle)
	ver_pert = real_part(magnitude * z_phase * wpert)/scl

	wave_pert = zonal_pert*fit.los_vecs.u + merid_pert*fit.los_vecs.v + ver_pert*fit.los_vecs.w
	if finite(k_ver_real) eq 0 then wave_pert = replicate(0, nels(fit.mo_fits))

	return, total(abs(fit.pert - wave_pert))

end


pro windsim_wave_analysis_2

	common windsim_wave_analysis_common, fit

	noise_dir = 'Noise10\'
	case_dir = where_is('windsim') + 'cases\waves\' + noise_dir
	data = file_search(case_dir + 'Data_*.idlsave', count=nfiles)
	restore, data[0]


	bi_use = where(bi_fits.obsdot lt .83 and max(bi_fits.overlap, dim=1) gt .1 and $
					bi_fits.mangle gt 30, nbi_use)


	tri_use = where(tri_fits.obsdot lt .83 and max(tri_fits.overlap, dim=1) gt .1 and $
				total(strmatch(tri_fits.stations, 'PKR') + $
					  strmatch(tri_fits.stations, 'HRP') + $
					  strmatch(tri_fits.stations, 'TLK'), 1) ne 3 , ntri_use)


	;\\ Zone viewing vectors
	los_vecs = [{u:0.0, v:0.0, w:0.0}]
	zn_azis = [0.]
	for m = 0, nels(meta) - 1 do begin
		get_zone_locations, meta[m], altitude=240, zones=zones
		u = sin(zones.mid_zen*!DTOR)*sin(zones.mid_azi*!DTOR)
		v = sin(zones.mid_zen*!DTOR)*cos(zones.mid_azi*!DTOR)
		w = cos(zones.mid_zen*!DTOR)
		lvs = replicate({u:0.0, v:0.0, w:0.0}, meta[m].nzones)
		lvs.u = u
		lvs.v = v
		lvs.w = w
		los_vecs = [los_vecs, [lvs]]
		zn_azis = [zn_azis, zones.mid_azi]
	endfor
	los_vecs = los_vecs[1:*]
	zn_azis = zn_azis[1:*]



	if file_test(case_dir + 'PertSave.idlsave') eq 0 then begin

		pert = fltarr(nfiles, nels(los_vecs))

		;\\ First, estimate the background wind field
		bg_wind = fltarr(nfiles, nels(mo_fits), 2)
		ls_wind = fltarr(nfiles, nels(mo_fits))
		for j = 0, nfiles - 1 do begin

			restore, data[j]

			m_wind = mo_fits

			b_wind = replicate({u:0.0, v:0.0, lat:0.0, lon:0.0}, nbi_use)
			for k = 0, nbi_use - 1 do begin
				wind = project_bistatic_fit(bi_fits[bi_use[k]], 0)
				b_wind[k].u = wind[0]
				b_wind[k].v = wind[1]
			endfor
			b_wind.lat = bi_fits[bi_use].lat
			b_wind.lon = bi_fits[bi_use].lon

			t_wind = tri_fits[tri_use]


			;\\ Do a third-order polynomial fit to the winds
			degree = 3
			m_fit_u = sfit(transpose([[m_wind.lon], [m_wind.lat], [m_wind.u]]), degree, kx=m_coeffs_u, /irregular)
			m_fit_v = sfit(transpose([[m_wind.lon], [m_wind.lat], [m_wind.v]]), degree, kx=m_coeffs_v, /irregular)

			;b_fit_u = sfit(transpose([[b_wind.lon], [b_wind.lat], [b_wind.u]]), degree, kx=b_coeffs_u)
			;b_fit_v = sfit(transpose([[b_wind.lon], [b_wind.lat], [b_wind.v]]), degree, kx=b_coeffs_v)

			;t_fit_u = sfit(transpose([[t_wind.lon], [t_wind.lat], [t_wind.u]]), degree, kx=t_coeffs_u)
			;t_fit_v = sfit(transpose([[t_wind.lon], [t_wind.lat], [t_wind.v]]), degree, kx=t_coeffs_v)


			;\\ Then evaluate them at the monostatic locations (since we will be perturbing los winds there)
			x = m_wind.lon
			y = m_wind.lat

			m_u = fltarr(nels(m_wind))
			m_v = fltarr(nels(m_wind))

			for ix = 0., degree do begin
			for iy = 0., degree do begin
				m_u += m_coeffs_u[iy,ix]*(x^ix)*(y^iy)
				m_v += m_coeffs_v[iy,ix]*(x^ix)*(y^iy)
			endfor
			endfor


			;\\ Resolve the background onto the monostatic viewing directions
			bg_los = m_u*los_vecs.u + m_v*los_vecs.v
			bg_zonal = m_u
			bg_merid = m_v

			los = ''
			for m = 0, nels(meta) - 1 do begin
				append, samples[m].zones.los, los
			endfor

			pert[j,*] = los - bg_los

			print, j
			wait, 0.01
		endfor

		for j = 0, nels(pert[0,*]) - 1 do begin
			pert[*,j] -= median(pert[*,j])
		endfor

		save, filename=case_dir + 'PertSave.idlsave', pert, bg_zonal, bg_merid
	endif else begin
		restore, case_dir + 'PertSave.idlsave'
	endelse


stop

	gamma = 1.5
	grav = 9.8
	sound_speed = 700. ;\\ meters / second
	wg_squared = (gamma-1)*(grav*grav) / (sound_speed*sound_speed)
	wa_squared = (gamma*grav / (2*sound_speed))^2.


	lat = mo_fits.lat - min(mo_fits.lat)
	lon = mo_fits.lon - min(mo_fits.lon)

	lon_cnv = !DTOR * cos(lat*!DTOR)*6371.E3
	lat_cnv = !DTOR * 6371.E3

	r_merid = lon*lon_cnv
	r_zonal = lat*lat_cnv


	time = 0
	fit = {r_merid:r_merid, $
		   r_zonal:r_zonal, $
		   los_vecs:los_vecs, $
		   mo_fits:mo_fits, $
		   pert:pert[time,*] }



	scale = [200E3, 2*!PI/(1.*60.), 30, 360*!DTOR, 360*!DTOR]

	fmins = fltarr(11,11,11,11)
	for i0 = 0, 10 do begin
	for i1 = 0, 10 do begin
	for i2 = 0, 10 do begin
	for i3 = 0, 10 do begin

		a = [10E3 + i0*50E3, $
			 2*!PI/((14 + i1)*60.), $
			 2*i2 + 1., $
			 i3*36*!DTOR, 0]

		R = AMOEBA(1.0e-5, SCALE=scale, P0 = a, FUNCTION_VALUE=fval, function_name = 'windsim_wave_analysis_func')
		fmins[i0,i1,i2,i3] = fval[0]

		wait, 0.001
		print, i0, i1, i2, i3
	endfor
	endfor
	endfor
	endfor




	frequency = 2*!PI*1./(14*60.)

	resid = fltarr(20,20,20,20)
	ix = 0
	time = 0
	for lambda = 0., 19 do begin
	for angle = 0., 19 do begin
	for ampl = 0., 19 do begin
	for lag = 0., 19 do begin


		k_hor = 2*!PI/((lambda + 2)*10E3)
		prop_angle = (angle/20.)*360.*!DTOR
		k_zonal = k_hor*sin(prop_angle)
		k_merid = k_hor*cos(prop_angle)
		w_squared = frequency*frequency
		phase_lag = (lag/20.)*!PI

		k_ver_real = sqrt((k_hor*k_hor)*((wg_squared/w_squared) - 1) + $
				 ((w_squared - wa_squared)/(sound_speed*sound_speed)))

		k_ver_im = (gamma*grav)/(2*sound_speed*sound_speed)

		magnitude = ampl + 1.
		wpert = exp( complex( replicate(0, nels(mo_fits)), (phase_lag - k_zonal*r_zonal - k_merid*r_merid)) )

		wind = bg_zonal*sin(prop_angle) + bg_merid*cos(prop_angle)
		wind = 0

		dopp_freq = (frequency - wind*k_hor)
		z_phase = complex( (dopp_freq^3.) - (sound_speed^2.)*(k_hor^2.)*dopp_freq, 0)
		x_phase = complex( dopp_freq*(sound_speed^2.)*k_hor*k_ver_real, dopp_freq*k_hor*( (sound_speed^2.)*k_ver_im - grav ))

		scl = abs(z_phase)

		hor_pert = real_part(magnitude * x_phase * wpert)/scl
		zonal_pert = hor_pert*sin(prop_angle)
		merid_pert = hor_pert*cos(prop_angle)
		ver_pert = real_part(magnitude * z_phase * wpert)/scl

		fin = where(finite(hor_pert) eq 1, n_fin)
		if n_fin eq 0 then stop

		;\\ Resolve onto monostatic los
		wave_pert = zonal_pert*los_vecs.u + merid_pert*los_vecs.v + ver_pert*los_vecs.w

		resid[lambda, angle, ampl, lag] = total(abs(reform(pert[time,fin]) -  wave_pert[fin]))/float(n_fin)

		print, lambda, angle, ampl, lag
		wait, 0.001

	endfor
	endfor
	endfor
	endfor

	stop





end