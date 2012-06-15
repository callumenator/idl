
pro cv_plot_quick

	data = file_search(where_is('mawson_davis_cv') + 'Data\110619.idlsave', count = nfiles)
	loadct, 39, /silent

	for d = 0, nfiles - 1 do begin

		restore, data[d]


		if size(all_cv.green, /type) eq 2 then continue
		if size(all_cv.red, /type) eq 2 then continue

		red = all_cv.red
		tags = tag_names(red)
		cvs = where(strmid(tags, 0, 2) eq 'CV', ncv)

		lat = fltarr(ncv)
		for k = 0, ncv - 1 do lat[k] = red.(cvs[k])[0].lat
		cvs = cvs[sort(lat)]

		trange = [min([red.maw_ut, red.dav_ut]), max([red.maw_ut, red.dav_ut])]
		yrange = [-80,80]

		!p.charthick = 2

		eps, filename=where_is('mawson_davis_cv') + 'Pics\' + all_cv.date.yymmdd_string + '.eps', /open, $
			 xs = 10, ys =15

			bnds = split_page(2+ncv, 1, bounds=[.14,.08,.98,.98], row_gap = .03)

			plot, trange, trange, /nodata, pos = bnds[0,0,*], yrange=yrange, xstyle=5, /ystyle
			oplot, trange, [0,0], line=1
			oplot, red.maw_ut, red.maw_zenith, noclip=1, thick = .5
			oplot, red.maw_ut, smooth_in_time(red.maw_ut, red.maw_zenith, 500, .5), thick = 2, noclip=1, color = 250
			xyouts, trange[0], 80, /data, 'Mawson', align=-.2

			for k = 0, ncv - 1 do begin
				good = where(red.(cvs[k]).dav_missing ne 1, ngood)

				if ngood eq 0 then continue

				ut = red.(cvs[k])[good].ut
				vz = red.(cvs[k])[good].mcomp
				vze = red.(cvs[k])[good].merr
				vz = vz - median(vz)

				fit = linfit(ut, vz, yfit=curve)
				vz = vz-curve

				plot, trange, trange, /nodata, pos = bnds[1+k,0,*], yrange=yrange, xstyle=5, /ystyle, $
					  /noerase
				oplot, trange, [0,0], line=1
				oplot, ut, vz, noclip=1, thick = .5
				oplot, ut, smooth_in_time(ut, vz, 500, .5), thick = 2, noclip=1, color = 250

				xyouts, trange[0], 80, /data, 'CV'+string(k,f='(i0)'), align=-.4
			endfor

			plot, trange, trange, /nodata, pos = bnds[1+k,0,*], yrange=yrange, xstyle=9, /ystyle, /noerase, $
				  xtitle = 'Time (UT)'
			oplot, trange, [0,0], line=1
			oplot, red.dav_ut, red.dav_zenith, noclip=1, thick = .5
			oplot, red.dav_ut, smooth_in_time(red.dav_ut, red.dav_zenith, 500, .5), thick = 2, noclip=1, color = 250
			xyouts, trange[0], 80, /data, 'Davis', align=-.2

			xyouts, .04, .5*(bnds[0,0,3] + bnds[4,0,1]), align=.5, orientation=90, 'Vz (ms!U-1!N)', /normal

		eps, /close

		clear_p


		print, d, nfiles
		wait, .01

	endfor





end