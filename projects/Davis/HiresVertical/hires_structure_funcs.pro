
pro hires_structure_funcs

	days = file_search(where_is('davis_data') + '2010_*', count = nfiles)

	window, 0, xs = 1000, ys = 500
	loadct, 39, /silent
	periods = (findgen(99) + 1)/60.

	residual = [[0.], [0.], [0.], [0.]]

	all_power = [0.]
	all_period = [0.]
	all_time = [0.]

	for k = 50, nfiles - 1 do begin
		dat = drta_make_time_series('', 0, 0, 2, 630, filename = days[k], /uselel)
		ymd = ydn_to_yymmdd( float( strmid( file_basename(days[k]),0,4)), $
							 float( strmid( file_basename(days[k]),5,3)))
		geo = get_geomag_conditions(ymd, /quick)
		if dat.data eq 1 then begin

			ut = *dat.directions(0).time
			temp = *dat.directions(0).temp
			zen = *dat.directions(0).wind
			zenErr = *dat.directions(0).wind_err
			int = *dat.directions(0).intens
			intErr = *dat.directions(0).intens_err

			pts = where(int gt .5, npts)
			if npts eq 0 then continue

			find_gaps, pts, blocks, nblocks
			for j = 0, nblocks - 1 do begin
				if (ut(blocks[j,1]) - ut(blocks[j,0])) lt 3 then continue

				tt = ut[blocks[j,0]:blocks[j,1]]
				zz = zen[blocks[j,0]:blocks[j,1]]
				tm = temp[blocks[j,0]:blocks[j,1]]
				ze = zenerr[blocks[j,0]:blocks[j,1]]
				ii = int[blocks[j,0]:blocks[j,1]]
				ie = intErr[blocks[j,0]:blocks[j,1]]


				wind = .5
				for tx = 0, n_elements(tt) - 1 do begin
					in = where(tt ge tt[tx]-wind and tt le tt[tx]+wind, nin)

					in_tt = tt[in]
					in_zz = zz[in]
					freqs = (max(in_tt) - min(in_tt))/periods
					zen_power = generalised_lomb_scargle(in_tt, in_zz, freqs)

					all_power = [all_power, zen_power]
					all_period = [all_period, periods]
					all_time = [all_time, replicate(tt[tx], n_elements(periods))]

				endfor

			endfor

		endif
		wait, 0.001
		print, k, nfiles
	endfor



	stop

end