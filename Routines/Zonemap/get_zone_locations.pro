
pro get_zone_locations, meta, $
						altitude=altitude, $
						magnetic=magnetic, $
						zones=zones	;\\ Data is returned in this structure

	;\\ Figure out zone angles
		if meta.zone_radii[0] eq 0 then begin
			radii = meta.zone_radii[0:meta.rings]/100.
		endif else begin
			radii = [0.0, meta.zone_radii[0:meta.rings-1]]/100.
		endelse
		sectors = meta.zone_sectors[0:meta.rings-1]

		zones = replicate({min_azi:0., $
						   max_azi:0., $
						   min_zen:0., $
						   max_zen:0., $
						   mid_azi:0., $
						   mid_zen:0., $
						   x:0.0, $
						   y:0.0, $
						   lat:0., $
						   lon:0.}, meta.nzones)

		count = 0
		for r = 0, meta.rings - 1 do begin

			ang_width = 360./sectors[r]

			base_ang = 0
			for s = 0, sectors[r] - 1 do begin
				zones[count].min_zen = radii[r]*meta.sky_fov_deg
				zones[count].max_zen = radii[r+1]*meta.sky_fov_deg
				zones[count].min_azi = base_ang
				zones[count].max_azi = base_ang + ang_width
				base_ang += ang_width
				count++
			endfor
		endfor

		zones.mid_zen = (zones.min_zen + zones.max_zen)/2.
		zones[0].mid_zen = 0

		norm_rad = (zones.mid_zen/meta.sky_fov_deg)/2.
		mid_azi = ((zones.min_azi + zones.max_azi)/2.)
		zones.x = .5 + norm_rad*cos(mid_azi*!DTOR)
		zones.y = .5 + norm_rad*sin(mid_azi*!DTOR)

		;\\ Convert to actual azimuths (east of 'north')
		;zones.min_azi = (450 - zones.min_azi)
		;zones.max_azi = (450 - zones.max_azi)

		zones.min_azi += 90
		zones.max_azi += 90

		;\\ Flip azimuths left-to-right
		;zones.min_azi = (360 - zones.min_azi)
		;zones.max_azi = (360 - zones.max_azi)

		if strlowcase(meta.site_code) eq 'maw' then begin
			add_angle = 0
		endif else begin
			add_angle = 180
		endelse

		if not keyword_set(magnetic) then begin
			;\\ Rotate into geographic (assumed to be in magnetic currently)
			zones.min_azi += meta.oval_angle + meta.rotation_from_oval
			zones.max_azi += meta.oval_angle + meta.rotation_from_oval
		endif else begin
			zones.min_azi += meta.rotation_from_oval
			zones.max_azi += meta.rotation_from_oval
		endelse

		zones.mid_azi = ((zones.min_azi + zones.max_azi)/2.) mod 360

		n_zones = count

		if keyword_set(altitude) then begin

			if not keyword_set(magnetic) then begin
				ll = get_end_lat_lon(meta.latitude, $
									 meta.longitude, $
									 get_great_circle_length(zones.mid_zen, altitude), $
									 zones.mid_azi)
			endif else begin
				aacgmidl
				cnv_aacgm, meta.latitude, meta.longitude, altitude, mag_lat, mag_lon, r, error
				ll = get_end_lat_lon(mag_lat, $
									 mag_lon, $
									 get_great_circle_length(zones.mid_zen, altitude), $
									 zones.mid_azi)
			endelse
			zones.lat = ll[*,0]
			zones.lon = ll[*,1]
		endif

		zones = zones
end