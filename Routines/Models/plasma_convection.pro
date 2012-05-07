
@w96

pro plasma_convection

	s = 800.

	;\\ Get potentials
		readcoef
		tilt = 0.0
		vel = 400.

		by = -.5
		bz = -1.
		bx = .03
    	Theta=ATAN(by, bz)
    	angle=Theta*180./!PI
    	IF angle LT 0. THEN angle=angle+360.
   		Bt=SQRT(BY^2 + BZ^2 + bx^2)

    	SetModel,angle,Bt,tilt,vel

		lat_range = [-90, -55]
		dim = 100.
		pot = fltarr(dim,dim)
		latarr = fltarr(dim,dim)
		cen = ((dim)/2.) - .1

		for xx = 0., dim - 1 do begin
		for yy = 0., dim - 1 do begin
			rad = (sqrt((xx - cen)^2 + (yy - cen)^2))
			ang = atan(yy - cen,xx - cen) - !pi/2.
			if ang lt 0 then ang = ang + 2*!pi
			mlt = (ang/(2*!pi))*24.0
			mlat = lat_range(0) + ((lat_range(1) - lat_range(0))/(cen))*rad
			latarr(xx,yy) = mlat
			pot(xx,yy) = epotval(mlat, mlt)
		endfor
		endfor
		spot_cpy = pot
		lat = congrid(latarr, s, s, /interp)
		phi = reverse(congrid(pot, s, s, /interp),2)
		r = [intarr(128), indgen(128)]
		b = [255 - indgen(128)*2, intarr(128)]
		g = intarr(256)
		;window, xs = s, ys = s
		;erase, 255

		set_plot, 'ps'
		device, filename = 'c:\cal\phd\plasma_convection.eps', /color, bits=8, /encaps, xs = 10, ys = 10
		;tvlct, r, g, b
		;tvscl, phi

		loadct, 0, /silent
		contour, phi, pos = [0,0,1,1], xstyle=5, ystyle=5, /noerase, thick = 4, color = 120, levels = [-40,-30,-20,-10,10,20,30]

		loadct, 39, /silent
		scl = 10000./s
		latfac=35.
		get_feldstein_oval, mlt, pole, equator, level = 2, res = 700.
		ang = (mlt-12)*(90./6.)*!dtor
		prad = ((pole + 90)/latfac)*(s/2.)*scl
		erad = ((equator + 90)/latfac)*(s/2.)*scl
		sx = .05
		for j = 0, n_elements(ang) - 1 do begin
			polyfill, [ s*scl/2. + prad(j)*sin(ang(j)+sx), $
					    s*scl/2. + prad(j)*sin(ang(j)-sx), $
					    s*scl/2. + erad(j)*sin(ang(j)-sx), $
					    s*scl/2. + erad(j)*sin(ang(j)+sx)  ], $
					  [ s*scl/2. + prad(j)*cos(ang(j)+sx), $
					    s*scl/2. + prad(j)*cos(ang(j)-sx), $
					    s*scl/2. + erad(j)*cos(ang(j)-sx), $
					    s*scl/2. + erad(j)*cos(ang(j)+sx)  ], color = 50, /device
		endfor

		davrad = ((-74.65 + 90)/latfac)*(s/2.)*scl
		mawrad = ((-70.37 + 90)/latfac)*(s/2.)*scl
		ang = findgen(361)*!dtor
		plots, s*scl/2. + davrad*sin(ang), s*scl/2. + davrad*cos(ang), /device, thick = 6, color = 250, line=0
		plots, s*scl/2. + mawrad*sin(ang), s*scl/2. + mawrad*cos(ang), /device, thick = 6, color = 250, line=0


		loadct, 0, /silent
		contour, lat, pos = [0,0,1,1], xstyle=5, ystyle=5, /noerase, thick = 1, color = 0, $
				 levels = [-80,-70,-60], c_labels=[1,1,1], c_annotation=['80!9%!3S','70!9%!3S','60!9%!3S']

		loadct, 39, /silent
		step = 35.
		for xx = step/2., s - step/2. - 1, step do begin
		for yy = step/2., s - step/2. - 1, step do begin
			gradx = (phi(xx + step/2., yy) - phi(xx - step/2., yy))/step
			grady = (phi(xx, yy + step/2.) - phi(xx, yy - step/2.))/step
			vecx = -250.*grady
			vecy = 250.*gradx
			if sqrt(vecx^2 + vecy^2) gt 15 and lat(xx,yy) lt -58 then begin
				arrow, xx*scl - vecx*scl/2., yy*scl - vecy*scl/2., xx*scl + vecx*scl/2., yy*scl + vecy*scl/2., $
					   color = 0, hsize = 120, thick = 2, /solid
			endif
		endfor
		endfor

		r = .48
		acirc = [[cos((findgen(71)+10)*!dtor)],[sin((findgen(71)+10)*!dtor)]]
		bcirc = [[cos((findgen(71)+100)*!dtor)],[sin((findgen(71)+100)*!dtor)]]
		ccirc = [[cos((findgen(71)+190)*!dtor)],[sin((findgen(71)+190)*!dtor)]]
		dcirc = [[cos((findgen(71)+280)*!dtor)],[sin((findgen(71)+280)*!dtor)]]

		plots, /normal, .5 + r*acirc(*,0), .5 + r*acirc(*,1), color = 0, thick = 3
		plots, /normal, .5 + r*bcirc(*,0), .5 + r*bcirc(*,1), color = 0, thick = 3
		plots, /normal, .5 + r*ccirc(*,0), .5 + r*ccirc(*,1), color = 0, thick = 3
		plots, /normal, .5 + r*dcirc(*,0), .5 + r*dcirc(*,1), color = 0, thick = 3

		ticks = [14,16,20,22,26,28,32,34]
		for t = 0, n_elements(ticks) - 1 do begin
			ang = (ticks(t)-12)*(90./6.)*!dtor
			plots, /normal, [.5 + (r-.01)*sin(ang), .5 + r*sin(ang)], $
							[.5 + (r-.01)*cos(ang), .5 + r*cos(ang)], thick=3, color = 0
		endfor


		xyouts, /normal, .45, .97, chars = .8, chart = 2, '12 MLT', color = 0
		xyouts, /normal, .95, .48, chars = .8, chart = 2, '18', color = 0
		xyouts, /normal, .01, .48, chars = .8, chart = 2, '06', color = 0
		xyouts, /normal, .48, .01, chars = .8, chart = 2, '00', color = 0
		empty
		set_plot, 'win'

stop
end