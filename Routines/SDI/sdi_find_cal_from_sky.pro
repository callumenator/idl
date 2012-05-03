
function sdi_find_cal_from_sky, skyfile, las_dir = las_dir

	if not keyword_set(las_dir) then las_dir = file_dirname(skyfile)

	;\\ Format the laser names
	sky_split = strsplit(skyfile, '_', /extract)
	zone_id = sky_split[n_elements(sky_split)-1]
	zone_id = (strsplit(zone_id, '.', /extract))[0]

	las_list = file_search(las_dir + '\*CAL*' + zone_id + '.nc', count = nlas)
	las_names = file_basename(las_list)

	fname = file_basename(skyfile)

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
		if n_best gt 1 then return, ''

		use_laser = las_list[best_match[0]]

		return, use_laser

end