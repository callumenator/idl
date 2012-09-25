
pro sdi_analysis, directory, filter = filter, plot_to = plot_to, only_zones = only_zones

	if keyword_set(plot_to) then plot_dir = plot_to

	if not keyword_set(filter) then begin
		las_list = file_search(directory + '*CAL*', count = nlas)
		sky_list = file_search(directory + '*SKY*', count = nsky)
	endif else begin
		las_list = file_search(directory + filter + '*CAL*', count = nlas)
		sky_list = file_search(directory + filter + '*SKY*', count = nsky)
	endelse


	;\\ Format the laser names
	las_names = strarr(nlas)
	for k = 0, nlas - 1 do begin

		fname = file_basename(las_list[k])

		;\\ Replace spaces with underscores
			byte_name = byte(fname)
			pts = where(byte_name eq byte(' '), npts)
			if npts gt 0 then byte_name[pts] = byte('_')
			fname = string(byte_name)

		las_names[k] = fname
	endfor


	;\\ If there are no skies, just fit the lasers
	if nsky eq 0 then begin
		for k = 0, nlas - 1 do begin
			fname = las_list[k]
			sdi_fit_spectra, fit_insfile = fname, only_zones = only_zones
		endfor
	endif


	;\\ Else fit the lasers when we fit the corresponding skies
	for k = 0, nsky - 1 do begin

		fname = file_basename(sky_list[k])

		;\\ Replace spaces with underscores
			byte_name = byte(fname)
			pts = where(byte_name eq byte(' '), npts)
			if npts gt 0 then byte_name[pts] = byte('_')
			fname = string(byte_name)

		;\\ Match up a laser calibration file for this sky file
			split = strsplit(fname, '_', /extract)

		;\\ Find best laser match
			match = intarr(nlas)
			for j = 0, nlas - 1 do begin
				cmp = las_names[j]
				for n = 0, n_elements(split) - 1 do begin
					match[j] += strmatch(cmp, '*_' + split[n] + '_*', /fold)
				endfor
			endfor
			best_match = where(match eq max(match), n_best)
			if n_best gt 1 then stop	;\\ HMMM?

			use_laser = las_list[best_match[0]]

			print, fname, las_names[best_match[0]]

			print
			print, 'LASER FIT: ' + las_names[best_match[0]]
			sdi_fit_spectra, fit_insfile = use_laser, only_zones = only_zones

			print
			print, 'SKY FIT: ' + fname
			sdi_fit_spectra, fit_skyfile = sky_list[k], use_insfile = use_laser, only_zones = only_zones

			print
			print, 'WIND FIT: ' + fname
			sdi3k_batch_windfitz, sky_list[k]

			if keyword_set(plot_to) then plot_skymap_series, ['temperature'], plot_dir=plot_dir, filename=sky_list[k]

			wait, 0.01

	endfor

end