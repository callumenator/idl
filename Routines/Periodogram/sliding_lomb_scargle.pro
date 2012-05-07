

;\\ Frequency is given in units of in_tt, absolute frequency
;\\ window_hwidth is half-width of the sliding window, in units of in_tt
pro sliding_lomb_scargle, in_tt, in_yy, freq, window_hwidth, $
						  power=power, $
						  time_axis=time_axis, $
						  signif=signif

	use_tt = where(in_tt ge min(in_tt) + window_hwidth and $
				   in_tt le max(in_tt) - window_hwidth, n_tt)

	period = 1./freq
	out_pwr = fltarr(n_tt, n_elements(freq))
	out_signif = fltarr(n_tt)

	for tx = 0, n_tt - 1 do begin

		this_tt = in_tt[use_tt[tx]]
		sub_pts = where(in_tt ge this_tt - window_hwidth and $
						in_tt le this_tt + window_hwidth, n_sub)

		if n_sub lt 2 then continue

		sub_tt = in_tt[sub_pts]
		sub_yy = in_yy[sub_pts]
		this_pwr = generalised_lomb_scargle(sub_tt, sub_yy, freq, signi=signi, /fap)

		tt_range = max(sub_tt) - min(sub_tt)
		pt = interpol(findgen(n_elements(period)), period, tt_range)
		this_pwr[pt:*] = 0

		out_pwr[tx, *] = this_pwr
		out_signif[tx] = signi
	endfor

	power = out_pwr
	signif= out_signif
	time_axis = in_tt[use_tt]

end