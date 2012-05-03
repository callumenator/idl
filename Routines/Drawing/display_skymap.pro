
pro display_skymap, data, $			;\\ Data array [nzones]
					scale=scale, $  ;\\ [min, max]
					zmap=zmap, $
					rads=rads, $
					secs=secs, $
					metadata=metadata, $
					ctable=ctable, $
					symmetric=symmetric, $
					outline_zones=outline_zones, $
					smoothing=smoothing, $
					skymap_out=skymap_out, $
					skymap_truecolor=skymap_truecolor, $	;\\ Used when winds are plotted, returns a [3,N,N] true color image
					nodisplay=nodisplay, $
					background=background, $
					winds=winds, $					;\\ Inlcude wind arrows over the top - winds = {meridional_wind:, zonal_wind:}
					wind_scale=wind_scale, $ 		;\\ Multiply components by this scale before plotting arrows
					wind_color=wind_color, $		;\\ [ctable, color]
					wind_thick=wind_thick, $
					wind_hsize=wind_hsize, $
					number_zones=number_zones

	if not keyword_set(background) then background = 0

	if keyword_set(winds) and not keyword_set(wind_scale) then wind_scale = .7
	if keyword_set(winds) and not keyword_set(wind_color) then wind_color = [39, 255]
	if keyword_set(winds) and not keyword_set(wind_thick) then wind_thick = 1
	if keyword_set(winds) and not keyword_set(wind_hsize) then wind_hsize = 10

	if not keyword_set(zmap) then begin
		if keyword_set(metadata) then begin
			rads = [0., metadata.zone_radii[0:metadata.rings-1]]/100.
			secs = metadata.zone_sectors[0:metadata.rings-1]
		endif else begin
			if not keyword_set(rads) and not keyword_set(secs) then return
		endelse
		zmap = zonemapper(400,400,[200,200],rads,secs,0)
	endif

	if keyword_set(smoothing) then begin
		data = space_smooth( data, rads, secs, /show_progress, spacewin = smoothing)
	endif

	if keyword_set(outline_zones) then begin
		bounds = get_zone_bounds(zmap)
	endif

	if not keyword_set(scale) then begin
		scale = float([min(data), max(data)])
		print, 'Data Range: ' + string(scale[0], f='(i0)') + '-' + string(scale[1], f='(i0)')
	endif else begin
		scale = float(scale)
	endelse

	if size(ctable, /type) ne 0 then begin
		tvlct, red, gre, blu, /get
		loadct, ctable, /silent
	endif

	skymap = zmap
	skymap[*] = background
	centers = fltarr(n_elements(data), 2)
	for z = 0, n_elements(data) - 1 do begin
		pts = where(zmap eq z, npts)
		if npts eq 0 then continue

		if data[z] lt scale[0] then begin
			skymap[pts] = 0
			continue
		endif

		if data[z] gt scale[1] then begin
			skymap[pts] = 255
			continue
		endif

		if keyword_set(symmetric) then begin
			frac = ((data[z] - scale[0]) / (scale[1] - scale[0]))
			frac = 2*(frac - .5)
			skymap[pts] = 127 + frac*127

		endif else begin
			skymap[pts] = 255 * ((data[z] - scale[0]) / (scale[1] - scale[0]))
		endelse

		if keyword_set(number_zones) then begin
			indices = array_indices(skymap, pts)
			xbar = mean(indices[0,*])
			ybar = mean(indices[1,*])
			centers[z,*] = [xbar, ybar]
		endif

	endfor

	if keyword_set(outline_zones) then begin
		skymap[where(bounds eq 1)] = 255
	endif

	if keyword_set(symmetric) then begin
		skymap[where(zmap eq -1)] = 127
	endif else begin
		skymap[where(zmap eq -1)] = 0
	endelse

	if not keyword_set(nodisplay) or (keyword_set(winds)) then begin
		window, xs = 400, ys = 400, /free
		tv, skymap

		loadct, 39, /silent
		if keyword_set(number_zones) then begin
			for z = 0, n_elements(data) - 1 do $
				xyouts, centers[z,0], centers[z,1], string(z, f='(i0)'), color = 250, /device, align=.5
		endif
	endif
	skymap_out = skymap

	if keyword_set(winds) then begin
		loadct, wind_color[0], /silent
		zc = get_zone_centers(zmap)
		angle = metadata.rotation_from_oval*!DTOR
		rzn = (winds.zonal_wind*cos(angle) - winds.meridional_wind*sin(angle))*wind_scale
		rmr = (winds.zonal_wind*sin(angle) + winds.meridional_wind*cos(angle))*wind_scale
		arrow, zc[*,0] - .5*rzn, $
			   zc[*,1] - .5*rmr, $
			   zc[*,0] + .5*rzn, $
			   zc[*,1] + .5*rmr, $
			   color = wind_color[1], hsize = wind_hsize, thick = wind_thick
		skymap_truecolor = tvrd(/true)
		wdelete, !d.window

	endif


	;\\ Reload original colours
	if keyword_set(ctable) then begin
		tvlct, red, gre, blu
	endif

end