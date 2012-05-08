;\\ Code formatted by DocGen


;\D\<Function/method/pro documentation here>
function zonemapper, nx, $          ;\A\<Arg0>
                     ny, $          ;\A\<Arg1>
                     cent, $        ;\A\<Arg2>
                     rads, $        ;\A\<Arg3>
                     secs, $        ;\A\<Arg4>
                     nums, $        ;\A\<Arg5>
                     show=show, $      ;\A\<Arg6>
                     outang=outang, $
                     outrad=outrad

nums = secs
nums(0) = 0
for n = 1, n_elements(secs) - 1 do nums(n) = total(secs(0:n-1))

zone = intarr(nx,ny)
zone(*) = -1

;\\ NEW ZONEMAPPER CODE, SPEED UP THE OLD VERSION (BELOW) - CAL 28/10/2009

	;\\ Make a distance map from [cent(0),cent(1)]
		calidx = findgen(n_elements(zone))
		calxx = (calidx mod nx) - cent(0)
		calyy = fix(calidx / nx) - cent(1)
		calx = fltarr(nx,ny)
		calx(*) = calxx
		caly = calx
		caly(*) = calyy
		caldist = sqrt(calx*calx + caly*caly)
		caldist = caldist / float(nx/2.)
		outrad = caldist

	;\\ Make an angle map
		calang = atan(caly,calx)
		pts = where(calang lt 0, npts)
		if npts gt 0 then calang(pts) = calang(pts) + (2*!PI)
		outang = calang

	zcount = 0
	for ridx = 0, n_elements(rads) - 2 do begin
		lower_dist = rads(ridx)
		upper_dist = rads(ridx+1)
		circ = where(caldist ge lower_dist and caldist lt upper_dist, ncirc)

		if ncirc gt 0 then begin
			nsecs = secs(ridx)
			angles = findgen(nsecs+1) * (360./nsecs) * !dtor
			for sidx = 0, nsecs - 1 do begin
				;if ridx eq 2 and sidx eq 6 then stop
				lower_ang = angles(sidx)
				upper_ang = angles(sidx+1)
				seg = where(calang(circ) ge lower_ang and calang(circ) lt upper_ang, nseg)
				if nseg gt 0 then begin
					zone(circ(seg)) = zcount
					zcount ++
				endif
			endfor
		endif
	endfor

;\\ THE OLD VERSION OF ZONEMAPPER -- TOO SLOW
		;for x = 0, nx-1 do begin
		;for y = 0, ny-1 do begin
		;
		;	dist = sqrt((float(x)-float(cent(0)))^2 + (float(y)-float(cent(1)))^2)
		;	ang = atan(float(y)-float(cent(1)),float(x)-float(cent(0)))
		;	if ang lt 0 then ang = ang + (2*!Pi)
		;
		;	dist = float(dist) / float(nx/2)
		;
		;	hi = where(rads gt dist, nhigh)
		;	low = where(rads le dist, nlow)
		;
		;	if nhigh ne 0 then begin
		;
		;		hi = hi(0)
		;		low = low(0)
		;
		;		ring = hi - low - 1
		;
		;		sectors = secs(ring)
		;
		;		sec_ang = 2*!PI/float(sectors)
		;
		;		zone(x,y) = nums(ring) + fix(ang/sec_ang)			;fix((ang-0.0001*!pi) /(2*!pi/float(sectors)))
		;
		;	endif else begin
		;
		;		zone(x,y) = -1
		;
		;	endelse
		;
		;
		;endfor
		;endfor

	if keyword_set(show) then begin
		loadct, 1, /silent
		window, /free, xsize = nx, ysize = ny
		tvscl, zone
		zcen = get_zone_centers(zone)
		plot_zone_bounds, nx, rads, secs
		loadct, 39, /silent
		for z = 0, max(zone) do begin
			xyouts, zcen(z,0), zcen(z,1), string(z,f='(i0)'), color = 240, /device
		endfor
	endif

	return, zone

end
