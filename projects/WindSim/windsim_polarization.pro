
;\\ prop_azimuth should be in degrees, angular frequency in radians/seconds, wavelength in meters,
;\\ time in seconds, wind is the wind speed (meters/second) in the direction of propagation
;\\ amplitude is the desired amplitude at 240 km
pro windsim_polarization, amplitude, frequency, wavelength, prop_azimuth, time, wind, fields, $
						  u_pert=u_pert, v_pert=v_pert, w_pert=w_pert, properties=properties

	gamma = 1.5
	grav = 9.8
	sound_speed = 700. ;\\ meters / second
	wg_squared = (gamma-1)*(grav*grav) / (sound_speed*sound_speed)
	wa_squared = (gamma*grav / (2*sound_speed))^2.
	w_squared = frequency*frequency

	k_hor = 2*!PI / float(wavelength)

	k_zonal = k_hor*sin(prop_azimuth*!DTOR)
	k_merid = k_hor*cos(prop_azimuth*!DTOR)

	k_ver_real = sqrt((k_hor*k_hor)*((wg_squared/w_squared) - 1) + $
				 ((w_squared - wa_squared)/(sound_speed*sound_speed)))

	k_ver_im = (gamma*grav)/(2*sound_speed*sound_speed)

	dims = size(fields.wind_u, /dimensions)
	lat = findgen(dims[0], dims[1], dims[2])
	lon = lat
	alt = lat

	for zz = 0, dims[2] - 1 do begin
		for xx = 0, dims[0]-1 do begin
			lat[xx,*,zz] = fields.lat
			alt[xx,*,zz] = fields.alt[zz]
		endfor

		for yy = 0, dims[1]-1 do begin
			lon[*,yy,zz] = fields.lon
			alt[*,yy,zz] = fields.alt[zz]
		endfor
	endfor

	lon_cnv = !DTOR * cos(lat*!DTOR)*6371.E3
	lat_cnv = !DTOR * 6371.E3
	alt_cnv = 1E3

	r_zonal = (lon-min(lon))*lon_cnv
	r_merid = (lat-min(lat))*lat_cnv
	r_vert =  (alt-min(alt))*alt_cnv

	magnitude = amplitude * exp(k_ver_im*r_vert)
	pert = exp( complex( replicate(0, dims[0], dims[1], dims[2]), (frequency*time - k_zonal*r_zonal - k_merid*r_merid - k_ver_real*r_vert)) )

	dopp_freq = (frequency - wind*k_hor)
	z_phase = complex( (dopp_freq^3.) - (sound_speed^2.)*(k_hor^2.)*dopp_freq, 0)
	x_phase = complex( dopp_freq*(sound_speed^2.)*k_hor*k_ver_real, dopp_freq*k_hor*( (sound_speed^2.)*k_ver_im - grav ))

	scale = abs(z_phase)
	z_phase /= scale
	x_phase /= scale

	mag_240 = interpol(reform(magnitude[0,0,*]), fields.alt, 240)
	magnitude = magnitude * (amplitude/mag_240)

	hor_pert = real_part(magnitude * x_phase * pert)
	ver_pert = real_part(magnitude * z_phase * pert)



	w_pert = ver_pert
	u_pert = hor_pert*sin(prop_azimuth*!DTOR)
	v_pert = hor_pert*cos(prop_azimuth*!DTOR)

	properties = {z_phase:z_phase, $
				  x_phase:x_phase, $
				  z_phase_angle:atan(z_phase, /phase)/!DTOR, $
				  x_phase_angle:atan(x_phase, /phase)/!DTOR, $
				  slant_angle:atan(k_ver_real, k_hor)/!DTOR, $
				  mag_x_pert:reform(magnitude[0,0,*]), $
				  mag_z_pert:reform(magnitude[0,0,*]), $
				  x_wavelength:(2*!PI/k_hor)/1E3, $
				  z_wavelength:(2*!PI/k_ver_real)/1E3, $
				  wg_ratio:(frequency/2*!PI)/sqrt(wg_squared), $
				  wa_ratio:(frequency/2*!PI)/sqrt(wa_squared) }

end