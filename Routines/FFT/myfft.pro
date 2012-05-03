
pro myfft, in_times, in_data, out_fft, out_frequency, out_period, abs=abs

	n = n_elements(in_times)
	dt = mean((in_times - shift(in_times, 1))[1:*])

	freq = findgen(n)

	if n mod 2 eq 0 then sub = 1 else sub = .5

	freq = freq - (n/2. - sub)
	freq = shift(freq, -(n/2. - sub)) / (n*dt)

	out_frequency = freq
	out_period = 1./freq

	out_fft = fft(in_data)
	if keyword_set(abs) then out_fft = abs(out_fft)


end