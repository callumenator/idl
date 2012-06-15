
;\\ Generate a 3D wind field
pro windsim_generate_fields, fields=fields, $
							 wind_params=wind_params, $
							 airglow_peak_height=airglow_peak_height, $
							 auroral_peak_height=auroral_peak_height, $
							 auroral_brightness=auroral_brightness ;\\ 1.0 means no aurora = default

	if not keyword_set(airglow_peak_height) then airglow_peak_height = 240.
	if not keyword_set(auroral_peak_height) then auroral_peak_height = 240.
	if not keyword_set(auroral_brightness) then auroral_brightness = 1.0

	;\\ Magnetic coordinates
		x0 = -100.	;\\ mag longitude
		y0 = 67.	;\\ mag latitude
		z0 = 240.	;\\ kilometers


	;\\ Geographic grid boundaries
		lat_bounds = [50., 82.]
		lon_bounds = [-180., -100.]
		alt_bounds = [100., 500.]


	;\\ Grid resolutions
		nx = 200.
		ny = 200.
		nz = 100.


	;\\ Calculate grid coordinates, first geographic...
		grid_lat = fltarr(nx, ny, nz)
		grid_lon = grid_lat
		grid_alt = grid_lat

		for zz = 0, nz - 1 do begin
			grid_alt[*,*,zz] = (zz/(nz-1))*(alt_bounds[1] - alt_bounds[0]) + alt_bounds[0]
			for xx = 0, nx - 1 do begin
				grid_lat[xx, *, zz] = (findgen(ny)/(ny-1))*(lat_bounds[1] - lat_bounds[0]) + lat_bounds[0]
			endfor
			for yy = 0, ny - 1 do begin
				grid_lon[*, yy, zz] = ((findgen(nx)/(nx-1))*(lon_bounds[1] - lon_bounds[0]) + lon_bounds[0])
			endfor
		endfor


	;\\ Then magnetic, do this at lower resolution and then interpolate to speed things up...
		aacgmidl
		res = 5.
		grid_mlat = fltarr(nx/res, ny/res, nz)
		grid_mlon = grid_mlat
		for xx = 0, nx - 1, res do begin
		for yy = 0, ny - 1, res do begin
			cnv_aacgm, grid_lat[xx,yy,0], grid_lon[xx,yy,0], 240, xlat, xlon, r, error
			grid_mlat[xx/res,yy/res,*] = xlat
			grid_mlon[xx/res,yy/res,*] = xlon
		endfor
		endfor
		grid_mlat = congrid(grid_mlat, nx, ny, nz, /interp)
		grid_mlon = congrid(grid_mlon, nx, ny, nz, /interp)


	;\\ Converters from angle to kilometers - crude
		lon_cnv = !DTOR * cos(grid_lat*!DTOR)*6371.
		lat_cnv = !DTOR * 6371.


	;\\ Wind model
		u0 = 40.
		xdist = abs(grid_lat[0,*,0] - y0)
		xdist = xdist - min(xdist)
		xdist = xdist / max(xdist)
		if keyword_set(wind_params) then u0 = wind_params.u0
		dudx = 0.
		dudy = -.5
		dudz = 0.

		v0 = 0.
		if keyword_set(wind_params) then v0 = wind_params.v0
		dvdx = 0.
		dvdy = 0.
		dvdz = 0.

		w0 = 0.
		dwdx = 0.
		dwdy = 0.
		dwdz = 0.


	;\\ Altitude gradient - a multiplier function
		alt_mult = atan(10*!PI*(grid_alt-100)/max(grid_alt[0,0,*]))


	;\\ Calculate the winds in magnetic coords
		wind_u = u0 + (grid_mlon - x0)*lon_cnv*dudx + (grid_mlat - y0)*lat_cnv*dudy + (grid_alt - z0)*dudz
		wind_v = v0 + (grid_mlon - x0)*lon_cnv*dvdx + (grid_mlat - y0)*lat_cnv*dvdy + (grid_alt - z0)*dvdz
		wind_w = w0 + (grid_mlon - x0)*lon_cnv*dwdx + (grid_mlat - y0)*lat_cnv*dwdy + (grid_alt - z0)*dwdz


	;\\ Modulate the zonal velocity
		;for kx = 0, nx - 1 do begin
		;for kz = 0, nz - 1 do begin
		;	wind_u[kx,*,kz] *= (1 - .5*xdist)
		;endfor
		;endfor



	;\\ Modulate the altitude profile of the wind by an inverse tangent function, so they taper to zero at 100km
		wind_u = wind_u*alt_mult
		wind_v = wind_v*alt_mult
		wind_w = wind_w*alt_mult


	;\\ Rotate the winds into geographic coordinates. Note the angle of rotation depends on
	;\\ geographic lat and lon, so we use an interpolation scheme to figure out what the
	;\\ angle is at each point on the grid, from known values (from DGRF).
		glat = [55., 	55., 	80., 	80., 	55., 	80., 	65., 	65., 	65.]
		glon = [-180., 	-120., 	-180., 	-120., 	-150, 	-150., 	-180., 	-150., 	-120.]
		mrot = [10.21, 	20.47, 25.90,	57.21, 	18.66,	42.28, 	12.18, 	22.95, 	26.29]

		triangulate, glon, glat, tr, b
		mrot = trigrid(glon, glat, mrot, tr, extrap=b, $
					   xout=grid_lon[*,0,0], yout=grid_lat[0,*,0], /quintic)

		angle = fltarr(nx, ny, nz)
		for zz = 0, nz - 1 do angle[*,*,zz] = mrot*(-!DTOR)

		ru = wind_u*cos(angle) - wind_v*sin(angle)
		rv = wind_u*sin(angle) + wind_v*cos(angle)
		wind_u = ru
		wind_v = rv


	;\\ Define a 2-D airglow map using the magnetic coordinate grid
		airglow = (auroral_brightness - 1.0)*exp( -((67 - grid_mlat[*,*,0])^2.)/1.5) + 1


	;\\ Calculate emission height profiles for each grid point based on the airglow map
		scale_height = 30.
		emission = findgen(nx,ny,nz)
		peak_height = airglow_peak_height
		for zz = 0, nz - 1 do begin
			g = (grid_alt[*,*,zz] - peak_height)/scale_height
			f = exp(-g)
			func = exp(1 - g - f)
			emission[*,*,zz] = func > .0001
		endfor

		scale_height = 30.
		peak_height = airglow_peak_height - (airglow/max(airglow))*(airglow_peak_height - auroral_peak_height)
		for zz = 0, nz - 1 do begin
			g = (grid_alt[*,*,zz] - peak_height)/scale_height
			f = exp(-g)
			func = 5*(airglow+1)*exp(1 - g - f)
			emission[*,*,zz] += func > .0001
		endfor


		contour, total(emission, 3), reform(grid_lon[*,0,0]), reform(grid_lat[0,*,0]), /path_data, $
			 		path_xy=xy, path_info=info, closed=0
		if size(xy, /type) eq 0 then begin
			xy = 0
			info = 0
		endif


	;\\ Store the data in a single structure
		fields = {lat:reform(grid_lat[0,*,0]), $ ;\\ geographic latitude
				  lon:reform(grid_lon[*,0,0]), $ ;\\ geographic longitude
				  alt:reform(grid_alt[0,0,*]), $
				  wind_u:wind_u, $
				  wind_v:wind_v, $
				  wind_w:wind_w, $
				  emission:emission, $
				  emission_ctr:xy, $
				  emission_ifo:info, $
				  airglow_peak_height:airglow_peak_height, $
				  auroral_peak_height:auroral_peak_height, $
				  auroral_brightness:auroral_brightness, $
				  peak_height:peak_height }

	return

end