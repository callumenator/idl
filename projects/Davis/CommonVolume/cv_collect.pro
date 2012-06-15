
pro cv_collect

	topdir = 'C:\RSI\IDLSource\NewAlaskaCode\Davis\CommonVolume\'
	redo = 1
	list = file_search(topdir + '\data\clear\*', count=nfiles)


	if redo eq 1 or file_test(topdir + 'Data.idlsave') eq 0 then begin
		for j = 0, nfiles - 1 do begin

			restore, list[j]

			tmin = max([min(all_cv.red.maw_ut), min(all_cv.green.maw_ut), min(all_cv.red.dav_ut), min(all_cv.green.dav_ut)])
			tmax = min([max(all_cv.red.maw_ut), max(all_cv.green.maw_ut), max(all_cv.red.dav_ut), max(all_cv.green.dav_ut)])

			dt = 5./60.
			nt = round((tmax - tmin)/dt)
			ctime = findgen(nt)*dt + tmin
			max_err = 10
			max_mag = 300
			smoothing = 20./60.

			twid = 1
			slide_correlate, all_cv.red.maw_ut, all_cv.green.maw_ut, $
							 all_cv.red.maw_zenith, all_cv.green.maw_zenith, $
							 twid, corr, time, signi
			pts = where(signi gt 0, n_pts)
			if n_pts gt 0 then begin
				append, corr, vz0_corr
				append, signi, vz0_signi
				gtmp = interpol(all_cv.green.maw_zenith_temps, all_cv.green.maw_ut, time)
				gtmp = smooth_in_time(time, gtmp, 1000, smoothing, /gconvol)

				heights = infer_height_from_temp(all_cv.date.year, all_cv.date.dayno, $
												 (station_info('maw')).glat, (station_info('maw')).glon, $
												 time, gtmp)
				append, heights, alt0
				append, gtmp, gtmp0
				append, interpol(all_cv.red.maw_zenith, all_cv.red.maw_ut, time), rvz0
				append, interpol(all_cv.green.maw_zenith, all_cv.green.maw_ut, time), gvz0
			endif


			kp = where(all_cv.red.cv02.ut ge tmin and all_cv.red.cv02.ut le tmax)
			cvrut = all_cv.red.cv02[kp].ut
			cvrvz = all_cv.red.cv02[kp].mcomp
			cvrvz -= median(cvrvz)
			kp = where(all_cv.green.cv01.ut ge tmin and all_cv.green.cv01.ut le tmax)
			cvgut = all_cv.red.cv01[kp].ut
			cvgvz = all_cv.red.cv01[kp].mcomp
			cvgvz -= median(cvgvz)
			slide_correlate, cvrut, cvgut, $
							 cvrvz, cvgvz, $
							 twid, corr, time, signi
			pts = where(signi gt 0, n_pts)
			if n_pts gt 0 then begin
				append, corr, vz1_corr
				append, signi, vz1_signi
				gtmp = interpol(all_cv.green.cv01.temperature, all_cv.green.cv01.ut, time)
				gtmp = smooth_in_time(time, gtmp, 1000, smoothing, /gconvol)

				heights = infer_height_from_temp(all_cv.date.year, all_cv.date.dayno, $
												 all_cv.green.cv01[0].lat, all_cv.green.cv01[0].lon, $
												 time, gtmp)
				append, heights, alt1
				append, gtmp, gtmp1
				append, interpol(cvrvz, cvrut, time), rvz1
				append, interpol(cvgvz, cvgut, time), gvz1
			endif

			kp = where(all_cv.red.cv01.ut ge tmin and all_cv.red.cv01.ut le tmax)
			cvrut = all_cv.red.cv01[kp].ut
			cvrvz = all_cv.red.cv01[kp].mcomp
			cvrvz -= median(cvrvz)
			kp = where(all_cv.green.cv00.ut ge tmin and all_cv.green.cv00.ut le tmax)
			cvgut = all_cv.red.cv00[kp].ut
			cvgvz = all_cv.red.cv00[kp].mcomp
			cvgvz -= median(cvgvz)
			slide_correlate, cvrut, cvgut, $
							 cvrvz, cvgvz, $
							 twid, corr, time, signi
			pts = where(signi gt 0, n_pts)
			if n_pts gt 0 then begin
				append, corr, vz2_corr
				append, signi, vz2_signi
				gtmp = interpol(all_cv.green.cv00.temperature, all_cv.green.cv00.ut, time)
				gtmp = smooth_in_time(time, gtmp, 1000, smoothing, /gconvol)

				heights = infer_height_from_temp(all_cv.date.year, all_cv.date.dayno, $
												 all_cv.green.cv00[0].lat, all_cv.green.cv00[0].lon, $
												 time, gtmp)
				append, heights, alt2
				append, gtmp, gtmp2
				append, interpol(cvrvz, cvrut, time), rvz2
				append, interpol(cvgvz, cvgut, time), gvz2
			endif

			slide_correlate, all_cv.red.dav_ut, all_cv.green.dav_ut, $
							 all_cv.red.dav_zenith, all_cv.green.dav_zenith, $
							 twid, corr, time, signi
			pts = where(signi gt 0, n_pts)
			if n_pts gt 0 then begin
				append, corr, vz3_corr
				append, signi, vz3_signi
				gtmp = interpol(all_cv.green.cv00.temperature, all_cv.green.cv00.ut, time)
				gtmp = smooth_in_time(time, gtmp, 1000, smoothing, /gconvol)

				heights = infer_height_from_temp(all_cv.date.year, all_cv.date.dayno, $
												 (station_info('dav')).glat, (station_info('dav')).glon, $
												 time, gtmp)
				append, heights, alt3
				append, gtmp, gtmp3
				append, interpol(all_cv.red.dav_zenith, all_cv.red.dav_ut, time), rvz3
				append, interpol(all_cv.green.dav_zenith, all_cv.green.dav_ut, time), gvz3
			endif


			print, j, nfiles
			wait, 0.001
		endfor


		save, filename=topdir + 'Data.idlsave', $
				vz0_corr, alt0, vz0_signi, rvz0, gvz0, $
				vz1_corr, alt1, vz1_signi, rvz1, gvz1,  $
				vz2_corr, alt2, vz2_signi, rvz2, gvz2,  $
				vz3_corr, alt3, vz3_signi, rvz3, gvz3,  $
				gtmp0, gtmp1, gtmp2, gtmp3

	endif else begin

		restore, topdir + 'Data.idlsave'
	endelse





	min_sig = 0.90
	min_num = 10
	twid = 5

	loadct, 39, /silent
	plot, [100, 190], [0, 1], /xstyle, /ystyle, /nodata	;\\ btemp
	plot, [.1, 1], [0, 1], /xstyle, /ystyle, /nodata	;\\ bratio

	for i = 0, 3 do begin

		case i of
			0: begin & x = alt0 & y = vz0_signi & z = rvz0/gvz0 & c = vz0_corr & end
			1: begin & x = alt1 & y = vz1_signi & z = rvz1/gvz1 & c = vz1_corr & end
			2: begin & x = alt2 & y = vz2_signi & z = rvz2/gvz2 & c = vz2_corr & end
			3: begin & x = alt3 & y = vz3_signi & z = rvz3/gvz3 & c = vz3_corr & end
		endcase

		keep = where(finite(x) eq 1 and x gt 0 and x lt 200)
		x = x[keep]
		y = y[keep]

		rng = [min(x), max(x)]
		nbins = ceil((rng[1]-rng[0]) / float(twid))
		bfrac = fltarr(nbins)
		bcorr = fltarr(nbins)
		btemp = fltarr(nbins)
		bratio = fltarr(nbins)
		bnels = fltarr(nbins)
		for b = 0., nbins - 1 do begin
			pts = where(x ge rng[0] + b*twid and $
						x lt rng[0] + (b+1)*twid, npts)

			if npts gt 3 then begin
				sig = y[pts]
				sig_pts = where(sig gt min_sig, n_sig)
				bfrac[b] = float(n_sig)/float(npts)
				bcorr[b] = mean(c[pts])
				btemp[b] = median(x[pts])
				bratio[b] = median(z[pts])
				bnels[b] = npts
			endif else begin
				bfrac[b] = -1
			endelse

			wait, 0.001

		endfor
		keep = where(bfrac ne -1, nkeep)
		bfrac = bfrac[keep]
		btemp = btemp[keep]
		bnels = bnels[keep]
		bratio = bratio[keep]

		use = where(bnels gt min_num)
		oplot, bratio[use], bcorr[use], psym=-6, color = 90 + i*50
		print, 90 + i*50

	endfor








	stop

end