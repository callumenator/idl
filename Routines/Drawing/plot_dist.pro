
pro plot_dist, data, binsize=binsize, psym=psym, normal=normal

	hh=histogram(data,binsize=binsize, loc = xx)
	if keyword_set(normal) then hh = float(hh)/max(hh)
	plot, xx, hh, psym=psym

end