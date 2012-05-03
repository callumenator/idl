
;\\ Plot data should be an array of structures:
;\\ plot_data = [{x:ptr, $
;\\				  y:ptr, $
;\\				  location:[row, column, oplot = 0 or 1], color:[ctable, color], $
;\\ 			  titles:[xtitle, ytitle, plot title]}, ...   ]

pro eps_plotter, filename, $
				 plot_data, $
				 eps_size = eps_size, $	;\\ [xsize, ysize]
				 layout = layout, $ 	;\\ [nrows, ncols]
				 bounds = bounds, $
				 row_gap = row_gap, $
				 col_gap = col_gap

	nplots = n_elements(plot_data)
	tags = strlowcase(tag_names(plot_data))

	if not keyword_set(eps_size) then eps_size = [10, 10]
	if not keyword_set(bounds) then bounds = [.15, .1, .98, .98]
	if not keyword_set(row_gap) then row_gap = .1
	if not keyword_set(col_gap) then col_gap = .1

	if total(strmatch(tags, 'color')) eq 1 then begin
		plot_color_tables = plot_data[*].color[0]
		plot_color = plot_data[*].color[1]
	endif else begin
		plot_color_tables = replicate(0, nplots)
		plot_color = replicate(0, nplots)
	endelse

	if total(strmatch(tags, 'location')) eq 1 then begin
		plot_rows = plot_data[*].location[0]
		plot_cols = plot_data[*].location[1]
		plot_oplots = plot_data[*].location[2]
		n_unique_plots = nplots - total(plot_oplots)
	endif else begin
		plot_rows = indgen(nplots)
		plot_cols = intarr(nplots)
		plot_oplots = intarr(nplots)
		n_unique_plots = nplots
	endelse

	if total(strmatch(tags, 'titles')) eq 1 then begin
		plot_xtitles = plot_data[*].titles[0]
		plot_ytitles = plot_data[*].titles[1]
		plot_titles = plot_data[*].titles[2]
	endif else begin
		plot_xtitles = replicate('', nplots)
		plot_ytitles = replicate('', nplots)
		plot_titles = replicate('', nplots)
	endelse

	if not keyword_set(layout) then layout = [n_unique_plots, 1]
	pbounds = split_page(layout[0], layout[1], bounds=bounds, $
							row_gap = row_gap, col_gap = col_gap)

	set_plot, 'ps'
	device, filename = filename, /encaps, /color, bits = 8, $
			xsize = eps_size[0], ysize = eps_size[1]

	for k = 0, nplots - 1 do begin

		if k eq 0 then !p.noerase = 0 else !p.noerase = 1

		if plot_oplots[k] ne 1 then begin
			loadct, 0, /silent
			plot, *plot_data[k].x, *plot_data[k].y, /nodata, title = plot_titles[k], $
					xtitle = plot_xtitles[k], ytitle = plot_ytitles[k], $
					pos = pbounds[plot_rows[k], plot_cols[k],*]
		endif

		loadct, plot_color_tables[k], /silent
		oplot, *plot_data[k].x, *plot_data[k].y, color = plot_color[k]

		ptr_free, plot_data[k].x, plot_data[k].y

	endfor

	device, /close
	set_plot, 'win'

end