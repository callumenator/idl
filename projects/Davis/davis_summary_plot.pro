
pro davis_summary_plot

	png = 1
	lambda = 630
	yrange = [-200,200]
	list = file_search('f:\sdidata\davis\', '*', count = nfiles)
	plot_height = 2
	redo = 1

	for fidx = 0, nfiles - 1 do begin

		year = float(strmid(file_basename(list[fidx]),0,4))
		day = float(strmid(file_basename(list[fidx]),5,3))
		filename = 'c:\users\sdi\sdiplots\davisplots\' + string(year, f='(i04)') + '_' + string(day, f='(i03)')

		if file_test(filename + '.png') eq 1 and redo eq 0 then continue

		plot_heigth = 2

		if lambda eq 630.0 then height = 240.
		if lambda eq 557.7 then height = 120.

		dat = drta_make_time_series('f:\sdidata\davis\', year, day, 0, lambda, /useLel)

		if dat.data eq 0 then begin
			dat = drta_make_time_series('f:\sdidata\davis\', year, day, 1, lambda, /useLel)
			if dat.data eq 0 then begin
				dat = drta_make_time_series('f:\sdidata\davis\', year, day, 2, lambda, /useLel)
				if dat.data eq 0 then begin
					print, 'No Data'
					continue
				endif
			endif
		endif

		labs = dat.directions.name
		els = dat.directions.ndata
		dirs = where(els gt 0, ndirs)

		if (ndirs eq 0) then continue

		if png eq 0 then begin
			eps, filename = filename + '.eps', /open, xs = 10, ys = ndirs*plot_height
			chars = .5
		endif else begin
			window, xs = 700, ys = ndirs*plot_height*100
			chars = 1
			erase, 255
		endelse

			bounds = split_page(ndirs, 1, bounds = [.1,.05,.98,.98])

			for i = 0, ndirs - 1 do begin

				if i eq 0 then noerase = 0 else noerase = 1
				if i eq ndirs - 1 then xstyle = 9 else xstyle = 5

				label = dat.directions[dirs[i]].name

				plot, dat.time_range, yrange, xstyle=xstyle, /ystyle, noerase=noerase, /nodata, $
					  title=label, pos = bounds[i,0,*], chars=chars, $
					  xtitle='Time (UT)', ytitle = 'Speed (m/s)', color = 0, back=255

				oplot, dat.time_range, [0,0], line = 1, color = 0

				t = *dat.directions[dirs[i]].time
				w = *dat.directions[dirs[i]].wind
				e = *dat.directions[dirs[i]].wind_err

				errplot, t, w-e, w+e, noclip=1, width=.004, color=0

				if label eq 'Mawson' then begin

					zen = *dat.directions[dirs[i]].zen_ang
					uzen = get_unique(zen)
					for ii = 0, n_elements(uzen) - 1 do begin
						pts = where(zen eq uzen[ii])
						oplot, t[pts], w[pts], noclip=1, color = 0
					endfor

				endif else begin
					oplot, t, w, noclip=1, color = 0
				endelse

			endfor

		if png eq 0 then begin
			eps, /close
		endif else begin
			img = tvrd(/true)
			write_png, filename	+ '.png', img
		endelse

		heap_gc
	endfor

end