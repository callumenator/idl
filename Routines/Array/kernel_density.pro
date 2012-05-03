
;\\ IN: data = input data
;\\ IN: bandwidth = width of kernel
;\\ OUT: kde, the kernel density

;\\ KEYWORD: xout = xvalues for the kde

pro kernel_density, data, bandwidth, kde, $
					xout=xout

	n = float(n_elements(data))
	bandwidth = float(bandwidth)

	sdata = data(sort(data))

	kde = fltarr(n)
	for j = 0, n - 1 do begin
		kde[j] = (1./n) * total( (1./bandwidth) * (1./(sqrt(2*!PI))) * exp(-0.5*(((sdata[j] - sdata)/bandwidth)^2.)) )
	endfor
	xout = sdata

end