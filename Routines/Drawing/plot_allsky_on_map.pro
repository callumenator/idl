
pro plot_allsky_on_map, map, $
						image, $
						fov, $
						azi_plus, $
						altitude, $
						latitude, $
						longitude, $
						dims, $ ;\\ window dimensions
						center=center, $
						border=border, $
						mask_radius=mask_radius, $
						true=true, $
						offset=offset, $
						alpha=alpha, $
						ctable=ctable

	COMMON Allsky_Plot, cached_map

	dim = size(image, /dimensions)

	if (n_elements(dim) gt 2) then begin
		xdim = dim[1]
		ydim = dim[2]
		nchann = dim[0]

		if keyword_set(azi_plus) then begin
			image[0,*,*] = rot(reform(image[0,*,*]), azi_plus)
			image[1,*,*] = rot(reform(image[1,*,*]), azi_plus)
			image[2,*,*] = rot(reform(image[2,*,*]), azi_plus)
		endif

	endif else begin
		xdim = dim[0]
		ydim = dim[1]
		nchann = 1

		if keyword_set(azi_plus) then image = rot(image, azi_plus)
	endelse



	if not keyword_set(offset) then offset = [0,0]
	if not keyword_set(border) then border = [0,0,xdim,ydim]

 	zang = 360.*mc_dist(xdim, ydim, $
 					    (border[0]+border[2])/2, $
 					    (border[1]+border[3])/2, $
 					    x=xx, y=yy)/(total(border))

    azi = atan(yy, xx)
    azi = 180 + rotate(reverse(azi, 1), 1)/!dtor
    rdist  = 100.*tan(!dtor*zang)
    xdist  = rdist*sin(!dtor*azi)
    ydist  = rdist*cos(!dtor*azi)
    useful = where(zang lt fov)
    useord = sort(zang(useful))
    useful = useful(reverse(useord))
    refpoints = {dims: [xdim, ydim], $
    			 horizon: [border[0], border[2], border[1], border[3]], $
    			 zang: zang, $
    			 azimuth: azi, $
    			 xdist: xdist, $
    			 ydist: ydist, $
    			 useful: useful}

	dummy   = mc_dist(dims[0], dims[1], 0., 0., x=xx, y=yy)
    data_coords = convert_coord(xx, yy, /device, /to_data)
    lonlats = map_proj_inverse(data_coords[0,*], data_coords[1,*], map=map)
    dx      = 111.12*(lonlats(0, *) - longitude)*cos(!dtor*latitude)
    dy      = 111.12*(lonlats(1, *) - latitude)
    rads    = sqrt(dx^2 + dy^2)
    use     = where(rads lt 450.)
    zang    = atan(rads(use)/105.)/!dtor
    pixrad  = 0.25*total(refpoints.horizon)*zang/(90.)
    maxrad  = max(rads(use))
    azi     = atan(dy(use), dx(use))
    radhere = sqrt((dx(use))^2 + (dy(use))^2)
    xx      = pixrad*dx(use)/radhere + (refpoints.horizon(0) + refpoints.horizon(1))/2
    yy      = pixrad*dy(use)/radhere + (refpoints.horizon(2) + refpoints.horizon(3))/2
    mapvec  = use
    ascvec  = long(yy)*refpoints.dims(0) + xx


	screen_img = tvrd(/true)
	if keyword_set(alpha) then begin
		current_image = tvrd(/true)
		screen_img *= 0
		erase, 0
	endif

	asc_gain = 1
    red        = reform(screen_img(0, *, *))
    green      = reform(screen_img(1, *, *))
    blue       = reform(screen_img(2, *, *))

	if nchann eq 3 then begin
		red[mapvec]   = (reform(image[0, *, *]))[ascvec]*asc_gain < 255
    	green[mapvec] = (reform(image[1, *, *]))[ascvec]*asc_gain < 255
    	blue[mapvec]  = (reform(image[2, *, *]))[ascvec]*asc_gain < 255
	endif else begin
    	red[mapvec]   = 0.4*image[ascvec]*asc_gain < 255
    	green[mapvec] = 0.4*image[ascvec]*asc_gain < 255
    	blue[mapvec]  = image[ascvec]*asc_gain < 255
    endelse

    screen_img[0, *, *] = red
    screen_img[1, *, *] = green
    screen_img[2, *, *] = blue

	if keyword_set(alpha) then begin
		overlay_image = tvrd(/true)
		alpha_map = float(reform(screen_img[0,*,*]))
		pts = where(total(screen_img, 1) eq 0, complement=blend, ncomp=nblend)
		if nblend ne 0 then alpha_map[blend] = alpha

		alpha3 = screen_img
		alpha3 = [[alpha_map], [alpha_map], [alpha_map]]
		blend_image = alpha_blend(current_image, screen_img, alpha3)

	endif else begin

    	blend_image = screen_img

	endelse

	device, decom=1
	tv, blend_image, /true
	device, decomp=0

end