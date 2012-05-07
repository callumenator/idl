
pro potentials_plotter

	list = file_search('c:\cal\idlsource\mawsoncode\latest spex\', '*.sky', count = nfiles)

	for fidx = 4, nfiles - 1 do begin

		sky = get_ncdf_data(list(fidx))
		yymmdd = js_to_yymmdd(sky.start_time(0))

		cloud = get_cloud_level(yymmdd, /day)
		if cloud gt 4 or cloud eq -1 then goto, SKIP_THIS_FILE

		mag = get_geomag_conditions(yymmdd)
		imf = get_imf(yymmdd)

		if mag.mag.match eq 0 then begin
			f107 = 75.
			ap = 10.
		endif else begin
			f107 = mag.mag.f107
			ap = mag.mag.apmean
		endelse

		seconds = fltarr(sky.nexps)
		for q = 0, sky.nexps - 1 do begin
			js2ymds, double(sky.start_time(q)), y, m, d, s
			seconds(q) = s
		endfor
		flags = fltarr(25)
		flags(*) = 1
		hwm = get_hwm_wind(07208L, seconds, 240., -67.6, 62.87, f107, f107, [ap,ap], flags)
		hwmx = hwm(*,1)
		hwmy = hwm(*,0)
		rhwmx = hwmx
		rhwmy = hwmy
		rhwmx = hwmx*cos(-66.*!dtor) - hwmy*sin(-66.*!dtor)
		rhwmy = hwmx*sin(-66.*!dtor) + hwmy*cos(-66.*!dtor)

		ReadCoef


		;bz = imf.bz
		;by = imf.by
		;bx = imf.bx
		bx = 1.
		by = 2.
		bz = -3.
		tilt = 0.0
		vel = 340.

	    Theta=ATAN(By,Bz)
	    angle=Theta*180./!PI
	    IF angle LT 0. THEN angle=angle+360.
	    Bt=SQRT(BY^2 + BZ^2 + bx^2)

	    SetModel,angle,Bt,tilt,vel

		max_lat = -55.
		xs = 400.
		pot = fltarr(xs,xs)

		xarr = fltarr(xs,xs)
		for z = 0, xs - 1 do xarr(*,z) = findgen(xs) - xs/2.
		yarr = transpose(xarr)

		distarr = sqrt(xarr^2 + yarr^2)
		anglarr = reverse(rot(atan(yarr, xarr)+ !pi, 270))
		anglarr = (anglarr/(2.*!pi))*24.

		lat_ext = 90 - abs(max_lat)
		lat_rad = xs / 2.
		lat_scl = lat_ext / lat_rad

		latarr = -(90 - distarr * lat_scl)

		pts = where(distarr lt lat_rad, npts, complement = opts)
		pot(opts) = 0
		pot(pts) = epotval(latarr(pts), anglarr(pts))


		fxs = 1000
		fys = 1000

		window, 0, xs = fxs, ys = fys
		contour, pot, /nodata, color = 0, position = [.05, .05, .95, .95]
		coords = convert_coord([0,xs], [0,xs], /data, /to_device)
		xlen = coords(0,1) - coords(0,0)
		ylen = coords(1,1) - coords(1,0)


		loadct, 13

		;potcpy = pot + abs(min(pot))
		;potcpy = (potcpy / max(potcpy))*255.
		;potcpy(opts) = 0
		tv, congrid(abs(pot), xlen, ylen), coords(0,0), coords(1,0)
		loadct, 39
		levels = (indgen(50) - 25)*10
		slevels = levels(where(levels ne 0))
		;contour, pot, /noerase, xticklen = 0.001, yticklen = 0.001, xstyle = 4, ystyle = 4, color = 50, thick = 2, levels=slevels, $
					  position = [.05, .05, .95, .95]
		contour, latarr, /noerase, xticklen = 0.001, yticklen = 0.001, xstyle = 4, ystyle = 4, color = 100, thick = 1, c_line = 1, levels=[-80,-70,-60], $
					  position = [.05, .05, .95, .95], c_labels = [1,1,1]
		plots, /data	, [xs/2., xs/2.], [0, xs], line=1, color = 100
		plots, /data, [0., xs], [xs/2., xs/2.], line=1, color = 100


	;\\ Read in a sky file


		js2ymds, double(sky.start_time(0)), y, m, d, s
		xvals = ((sky.start_time - sky.start_time(0)) / 3600.) + ((s/3600.) + 1.3)

		;glat = -67.6
		glat = -70.
		rad = (90. + glat) / lat_scl

		npts = 5.
	 	timez = findgen(npts)/npts
		timez = (timez*(xvals(sky.nexps-1)-xvals(0))) + xvals(0)

		hx = interpol(-sky.hx(0,*), xvals, timez)
		hy = interpol(sky.hy(0,*), xvals, timez)
		mhx = interpol(rhwmx, xvals, timez)
		mhy = interpol(rhwmy, xvals, timez)

		ghx = hx
		ghy = hy
		ghx = hx*cos(66.*!dtor) - hy*sin(66.*!dtor)
		ghy = hx*sin(66.*!dtor) + hy*cos(66.*!dtor)

		for idx = 0, npts - 1 do begin

			time = timez(idx)

		 	time = time - 12.
		 	if time lt 0 then time = time + 24.
			ang = ((time/6.)*90.)*!dtor

			hang = ang ;+ 1.5*!pi/180.

			xpos = xs / 2. + rad*sin(ang)
			ypos = xs / 2. + rad*cos(ang)
			hxpos = xs / 2. + rad*sin(hang)
			hypos = xs / 2. + rad*cos(hang)
			xcomp = (hx(idx)*cos(-ang) - hy(idx)*sin(-ang))/1.5
			ycomp = (hx(idx)*sin(-ang) + hy(idx)*cos(-ang))/1.5
			mxcomp = (mhx(idx)*cos(-hang) - mhy(idx)*sin(-hang))/1.5
			mycomp = (mhx(idx)*sin(-hang) + mhy(idx)*cos(-hang))/1.5

			;\\ Convection direction
			angs = findgen(360)*!dtor
			diffs = fltarr(360)
			crad = 5.
			diffs = abs(pot(xpos,ypos) - pot(xpos+crad*cos(angs),ypos+crad*sin(angs)))
			cangle = median(where(diffs eq min(diffs)))
			cxcomp = 15.*cos(cangle*!dtor)
			cycomp = 15.*sin(cangle*!dtor)

			arrow, /data, hxpos, hypos, hxpos + mxcomp, hypos + mycomp, color =150, thick=2, hsize = 7
			arrow, /data, xpos, ypos, xpos + xcomp, ypos + ycomp, color = 254, thick=2, hsize = 7
			arrow, /data, xpos, ypos, xpos + cxcomp, ypos + cycomp, color = 200, thick=2, hsize = .01
			arrow, /data, xpos, ypos, xpos - cxcomp, ypos - cycomp, color = 200, thick=2, hsize = .01

		endfor

		;\\ Do some annotating
		date = date_str_from_js(sky.start_time(0))
		xyouts, /normal, .05, .15, date, chart=1.5, chars=1.5
		xyouts, /normal, .05, .12, 'Mean Ap: ' + string(ap,f='(f0.1)'), chart=1.5, chars=1.5
		xyouts, /normal, .05, .09, 'F107: ' + string(f107,f='(f0.1)'), chart=1.5, chars=1.5
		xyouts, /normal, .05, .06, 'Cld: ' + string(cloud,f='(i0)'), chart=1.5, chars=1.5

		xyouts, /data, xs/2 - 5, 0, '00', chart=1.5, chars=1.5
		xyouts, /data, xs - 15, xs/2 - 2, '18', chart=1.5, chars=1.5
		xyouts, /data, xs/2 - 5, xs-5, '12', chart=1.5, chars=1.5
		xyouts, /data, 5, xs/2 - 2, '06', chart=1.5, chars=1.5

		pic = tvrd(/true)
		save_name = 'c:\cal\idlsource\visualcode\image capture\convection\Plot ' + yymmdd + '.png'
		write_png, save_name, pic

		wait, 0.001

	SKIP_THIS_FILE:
	endfor
	stop

end