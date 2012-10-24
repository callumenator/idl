
;\\ The find_outliers procedure relies on differences between consectutive values. Where consectutive
;\\ data are not dissimilar, but still outliers (i.e. outlier "plateau's") a recursive call to find_outliers
;\\ is needed. This procedure supplies that, recursively calling find_outliers and building up the outlier list.
pro find_outliers_recursive, in_data, $
				   			 outliers, $
				   			 complement=complement, $		;\\ the outlier complement set (the non-outliers)
				   			 abs_thresh=abs_thresh, $
				   			 rel_thresh=rel_thresh, $
				   			 window_hwidth=window_hwidth, $	;\\ half-width of the window over which the mean is taken
				   			 replace=replace				;\\ replace the input array with the non-outlying data

	recurse = 1
	all_outliers = [-1]
	total_outliers = 0
	indices = indgen(nels(in_data))
	in_data_copy = in_data

	set_abs_thresh = 0
	if keyword_set(abs_thresh) then set_abs_thresh = abs_thresh
	if keyword_set(rel_thresh) then set_rel_thresh = rel_thresh
	if not keyword_set(window_hwidth) then set_window_hwidth = round(nels(in_data)*.05) else set_window_hwidth = window_hwidth
	if not keyword_set(rel_thresh) and not keyword_set(abs_thresh) then set_rel_thresh = 2.0

	while (recurse eq 1) do begin

		outliers = 0

		if set_abs_thresh ne 0 then begin
			find_outliers, in_data, outliers, abs_thresh = set_abs_thresh, $
											  window_hwidth = set_window_hwidth < round(nels(in_data)/2.), $
											  complement = complement
		endif else begin
			find_outliers, in_data, outliers, rel_thresh = set_rel_thresh, $
											  window_hwidth = set_window_hwidth < round(nels(in_data)/2.), $
											  complement = complement
		endelse

		if nels(outliers) eq 1 then begin
			if outliers[0] eq -1 then recurse = 0
		endif

		if n_elements(complement) eq 0 then return

		if recurse ne 0 then begin
			total_outliers += nels(outliers)
			all_outliers = [all_outliers, indices[outliers]] ;\\ need to keep track indices, since we replace in_data each pass
			indices = indices[complement] ;\\ only retain indices of non-outliers from this pass
			in_data = in_data[complement]
		endif

		if nels(in_data) lt 5 then recurse = 0

	endwhile


	if not keyword_set(replace) then begin
		 in_data = in_data_copy
	endif

	outliers = all_outliers
	if total_outliers ne 0 then outliers = outliers[1:*]

	complement = indgen(nels(in_data_copy))
	if total_outliers ne 0 then complement[outliers] = -1
	pts = where(complement ne -1, ngood)
	if ngood gt 0 then complement = complement[pts] else complement = [-1]

end