
pro sdi_monitor_intensity_normalize, altitude, $
									 metaArr, $ ;\\ array of meta data structs in order of scaling
									 intensArr, $ ;\\ flat vector of intensities, in same order as meta arr
									 timesArr, $ ;\\ flat vector of times, in same order as meta arr
									 numArr ;\\ number of obs for each site

	numArr = [0, numArr]
	ntimesArr = numArr / [1, metaArr.nzones]
	n = n_elements(metaArr)

	for ia = 0, n - 2 do begin
		ib = ia + 1

		zone_overlaps, altitude, metaArr[[ia,ib]], olaps, /bistatic
		pts = where(max(olaps.overlaps, dim=2) gt .5, no)
		if no eq 0 then continue

		ia_intens = reform(intensArr[numArr[ia]:numArr[ia]+numArr[ia+1]-1], metaArr[ia].nzones, numArr[ia+1]/metaArr[ia].nzones)
		ib_intens = reform(intensArr[numArr[ib]:numArr[ib]+numArr[ib+1]-1], metaArr[ib].nzones, numArr[ib+1]/metaArr[ib].nzones)

		;\\ Indexes into pairs/overlaps arrays
		a_idx = where(olaps.stationnames eq metaArr[ia].site_code)
		b_idx = where(olaps.stationnames eq metaArr[ib].site_code)

		scale = 0
		for pair_idx = 0, no - 1 do begin

			a_zn = reform(olaps.pairs[pts[pair_idx], a_idx])
			b_zn = reform(olaps.pairs[pts[pair_idx], b_idx])
			ts_a = reform(ia_intens[a_zn, *])
			ts_b = reform(ib_intens[b_zn, *])

			;\\ Common time range
			t_a = timesArr[ntimesArr[ia]:ntimesArr[ia]+ntimesArr[ia+1]-1]
			t_b = timesArr[ntimesArr[ib]:ntimesArr[ib]+ntimesArr[ib+1]-1]
			range = [max(min([t_a,t_b])), min(max([t_a,t_b]))]
			n_els = max([ntimesArr[ia+1], ntimesArr[ib+1]])
			times = ((findgen(n_els)/float(n_els-1)) * (range[1]-range[0])) + range[0]

			ts_a = interpol(ts_a, t_a, times)
			ts_b = interpol(ts_b, t_b, times)

			scale += median(ts_a / ts_b)
		endfor

		scale /= float(no)
		intensArr[numArr[ib]:numArr[ib]+numArr[ib+1]-1] *= scale

	endfor
end
