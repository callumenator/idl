
;\\ Get the value of the fields at lat, lon, alt. These can be vectors of locations.
function windsim_field_at, fields, lat, lon, alt
	dims = size(fields.wind_u, /dimensions)
	xx_subs = interpol(findgen(dims[0]), fields.lon, lon)
	yy_subs = interpol(findgen(dims[1]), fields.lat, lat)
	zz_subs = interpol(findgen(dims[2]), fields.alt, alt)
	u = interpolate(fields.wind_u, xx_subs, yy_subs, zz_subs)
	v = interpolate(fields.wind_v, xx_subs, yy_subs, zz_subs)
	w = interpolate(fields.wind_w, xx_subs, yy_subs, zz_subs)
	i = interpolate(fields.emission, xx_subs, yy_subs, zz_subs)
	return, {u:u, v:v, w:w, i:i}
end


;\\ Sample the fields, given a single meta data structure
pro windsim_sample_fields, meta, $
						   fields, $
						   samples=samples, $
						   noise=noise, $
						   sample_azi=sample_azi, $
						   sample_zen=sample_zen

	if not keyword_set(sample_azi) then sample_azi = [.5]
	if not keyword_set(sample_zen) then sample_zen = [.5]


	get_zone_locations, meta, zones=zn, altitude =240

	zones = replicate({min_az:0., max_az:0., min_zen:0., max_zen:0., $
					   mid_az:0., mid_zen:0., los_unit_vec:[0.,0.,0.], $
					   lat:0., lon:0., $
					   u:0., v:0., w:0., intensity:0., los:0., sigma_los:0.}, meta.nzones)

	zones.mid_az = zn.mid_azi
	zones.min_az = zn.min_azi
	zones.max_az = zn.max_azi
	zones.mid_zen = zn.mid_zen
	zones.min_zen = zn.min_zen
	zones.max_zen = zn.max_zen
	zones.lat = zn.lat
	zones.lon = zn.lon

	n_zones = nels(zn)


	if keyword_set(noise) then begin
		rnoise = randomn(systime(/sec), n_zones, /normal)*noise
	endif else begin
		rnoise = fltarr(n_zones)
	endelse

	;\\ For each zone, fire a given number of rays through the fields, and calculate
	;\\ the intensity weighted average along each ray. Then average over all rays.
	dims = size(fields.wind_u, /dimensions)
	rays_azi = sample_azi
	rays_zen = sample_zen
	zenith_rays_zen = [0, .7]
	zenith_rays_azi = [0, .25, .5, .75]
	for z = 0, n_zones - 1 do begin

		if z eq 0 then begin
			del_azi = zones[z].min_az + zenith_rays_azi*(zones[z].max_az - zones[z].min_az)
			del_zen = zones[z].min_zen + zenith_rays_zen*(zones[z].max_zen - zones[z].min_zen)
		endif else begin
			del_azi = zones[z].min_az + rays_azi*(zones[z].max_az - zones[z].min_az)
			del_zen = zones[z].min_zen + rays_zen*(zones[z].max_zen - zones[z].min_zen)
		endelse

		ray_u = fltarr(nels(rays_azi)*nels(rays_zen))
		ray_v = ray_u
		ray_w = ray_u
		ray_i = ray_u	;\\ emission intensity
		ray_l = ray_u	;\\ line-of-sight wind
		ray_count = 0
		for azi_i = 0, nels(rays_azi) - 1 do begin
			for zen_i = 0, nels(rays_zen) - 1 do begin

				alt = fields.alt
				az = replicate(del_azi[azi_i], nels(alt))
				zn = replicate(del_zen[zen_i], nels(alt))
				los_unit_vec = [ sin(zn[0]*!DTOR)*sin(az[0]*!DTOR), sin(zn[0]*!DTOR)*cos(az[0]*!DTOR), cos(zn[0]*!DTOR) ]

				;\\ At each altitude of the field, find the x and y location of the ray
				latlon = get_end_lat_lon(meta.latitude, meta.longitude, get_great_circle_length(zn, alt), az)
				yy_subs = interpol(findgen(dims[1]), fields.lat, latlon[*,0])
				xx_subs = interpol(findgen(dims[0]), fields.lon, latlon[*,1])
				zz_subs = indgen(nels(alt))
				zz_ray_u = interpolate(fields.wind_u, xx_subs, yy_subs, zz_subs )
				zz_ray_v = interpolate(fields.wind_v, xx_subs, yy_subs, zz_subs )
				zz_ray_w = interpolate(fields.wind_w, xx_subs, yy_subs, zz_subs )
				zz_ray_i = interpolate(fields.emission, xx_subs, yy_subs, zz_subs )

				zz_ray_l = zz_ray_u
				for zz = 0, nels(alt) - 1 do $
					zz_ray_l[zz] = dotp(los_unit_vec, [zz_ray_u[zz], 0, 0]) + $
							   	   dotp(los_unit_vec, [0, zz_ray_v[zz], 0]) + $
							   	   dotp(los_unit_vec, [0, 0, zz_ray_w[zz]])


				;\\ Calculate the emission weighted integrals
				ray_u[ray_count] = int_tabulated(alt, zz_ray_u * zz_ray_i) / int_tabulated(alt, zz_ray_i)
				ray_v[ray_count] = int_tabulated(alt, zz_ray_v * zz_ray_i) / int_tabulated(alt, zz_ray_i)
				ray_w[ray_count] = int_tabulated(alt, zz_ray_w * zz_ray_i) / int_tabulated(alt, zz_ray_i)
				ray_i[ray_count] = int_tabulated(alt, zz_ray_i)
				ray_l[ray_count] = int_tabulated(alt, zz_ray_l * zz_ray_i) / int_tabulated(alt, zz_ray_i)
				ray_count ++
			endfor ;\\ zenith angle loop
		endfor ;\\ azimuth loop

		zones[z].u = mean(ray_u)
		zones[z].v = mean(ray_v)
		zones[z].w = mean(ray_w)
		zones[z].intensity = mean(ray_i)
		zones[z].los = mean(ray_l) + rnoise[z]
		zones[z].sigma_los = rnoise[z]
		zones[z].los_unit_vec = [ sin(zones[z].mid_zen*!DTOR)*sin(zones[z].mid_az*!DTOR), $
								  sin(zones[z].mid_zen*!DTOR)*cos(zones[z].mid_az*!DTOR), $
								  cos(zones[z].mid_zen*!DTOR) ]

		wait, 0.0001
		;print, 'Sampling in Zone: ', z
	endfor ;\\ zone loop

	samples = {meta:meta, $
			   zones:zones, $
			   sample_azi:sample_azi, $
			   sample_zen:sample_zen, $
			   noise:noise}

end
