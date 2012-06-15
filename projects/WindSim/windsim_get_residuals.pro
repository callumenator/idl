
@resolve_nstatic_wind
@windsim_sample_fields

pro windsim_get_residuals, fields, fits, $
						   resid=resid, $
						   monostatic=monostatic, $
						   bistatic=bistatic, $
						   tristatic=tristatic


	if keyword_set(monostatic) then begin
		;\\ Monostatic residuals
		mono_resid = fltarr(nels(fits))
		for i = 0, nels(fits) - 1 do begin
			fld = windsim_field_at(fields, fits[i].lat, fits[i].lon, 240.)
			mono_resid[i] = sqrt( (fits[i].u-fld.u)^2. + (fits[i].v-fld.v)^2.)
			wait, 0.001
			print, 'Mono, ', i, ' ', nels(fits)
		endfor
		resid = mono_resid
		return
	endif


	if keyword_set(bistatic) then begin
		;\\ Bistatic residuals
		use = where(fits.obsdot lt .8 and max(fits.overlap, dim=1) gt .1, nuse)
		bi_resid = fltarr(nuse)
		for ii = 0, nuse - 1 do begin
			i = use[ii]
			fld = windsim_field_at(fields, fits[i].lat, fits[i].lon, 240.)
			;\\ Resolve the real wind along the bistatic axes
			units = get_unit_spherical(fits[i].lat, fits[i].lon)
			wind_cartesian = fld.u * units.zonal + $
							 fld.v * units.merid + $
							 fld.w * units.zenith
			wind_plane = [dotp(wind_cartesian, fits[i].laxis), $
						  dotp(wind_cartesian, fits[i].maxis) ]
			bi_resid[ii] = sqrt( (fits[i].lcomp-wind_plane[0])^2. + (fits[i].mcomp-wind_plane[1])^2.)
			wait, 0.001
			print, 'Bi, ', ii, ' ', nuse
		endfor
		resid = bi_resid
		return
	endif


	if keyword_set(tristatic) then begin
		;\\ Tristatic residuals
		use = where(fits.obsdot lt .8 and max(fits.overlap, dim=1) gt .1, nuse)
		flag = intarr(nuse)
		tri_resid = fltarr(nuse)
		for ii = 0, nuse - 1 do begin
			i = use[ii]

			if total(strmatch(fits[ii].stations, 'PKR')) eq 1 and $
			   total(strmatch(fits[ii].stations, 'HRP')) eq 1 and $
			   total(strmatch(fits[ii].stations, 'TLK')) eq 1 then flag[ii] = 1

			fld = windsim_field_at(fields, fits[i].lat, fits[i].lon, 240.)
			tri_resid[ii] = sqrt( (fits[i].u-fld.u)^2. + (fits[i].v-fld.v)^2. + $
							 (fits[i].w-fld.w)^2.)
			wait, 0.001
			print, 'Tri, ', ii, ' ', nuse
		endfor
		keep = where(flag eq 0, nkeep)
		if nkeep gt 0 then tri_resid = tri_resid[keep] else tri_resid = [0]
		resid = tri_resid
		return
	endif

end
