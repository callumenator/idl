
pro slide_correlate, in_t1, in_t2, $	;\\ Data times (in)
					 in_d1, in_d2, $	;\\ Data (in)
					 time_hwidth, $		;\\ Half-width of the time window (in)
					 out_corr, $		;\\ Sliding correlation (out)
					 out_time, $		;\\ Sliding time (out)
					 out_signi 			;\\ Sliding significance (out) Higher significance is higher confidence

	;\\ Generate a new time grid
	time_res = mean([mean((in_t1 - shift(in_t1, 1))[1:*]), mean((in_t2 - shift(in_t2, 1))[1:*])])
	trange = [min([in_t1, in_t2]), max([in_t1, in_t2])]
	n_times = floor((trange[1] - trange[0])/time_res)
	itimes = (findgen(n_times)/(n_times-1))*(trange[1] - trange[0]) + trange[0]

	;\\ Interpolate to common time grid
	i_d1 = interpol(in_d1, in_t1, itimes)
	i_d2 = interpol(in_d2, in_t2, itimes)

	dt = itimes[1] - itimes[0]
	wind_wid = ceil(time_hwidth / dt)

	slide_corr = [0.]
	slide_time = [0.]
	slide_signif = [0.]

	for tt = wind_wid, n_elements(itimes) - wind_wid - 1 do begin

		this_corr = correlate(i_d1[tt-wind_wid:tt+wind_wid], i_d2[tt-wind_wid:tt+wind_wid])
		slide_corr = [slide_corr, this_corr]
		slide_time = [slide_time, itimes[tt]]

		in_pts_1 = where(in_t1 ge itimes[tt]-time_hwidth and in_t1 le itimes[tt]+time_hwidth, n_pts_1)
		in_pts_2 = where(in_t2 ge itimes[tt]-time_hwidth and in_t2 le itimes[tt]+time_hwidth, n_pts_2)
		n_pts = n_pts_1 > n_pts_2
		if n_pts le 2 then n_pts = 3

		t = this_corr / sqrt( (1-(this_corr*this_corr)) / (n_pts-2) )
		signif = 1 - (1 - 2*(1 - t_pdf(abs(t), (n_pts-2))))
		slide_signif = [slide_signif, signif]
	endfor

	out_corr = float(slide_corr[1:*])
	out_time = float(slide_time[1:*])
	out_signi = float((1 - slide_signif[1:*]))

end