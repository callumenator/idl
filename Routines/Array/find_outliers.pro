
pro find_outliers, in_data, $
				   outliers, $
				   complement=complement, $			;\\ the outlier complement set
				   abs_thresh=abs_thresh, $
				   rel_thresh=rel_thresh, $
				   window_hwidth=window_hwidth, $	;\\ half-width of the window over which the mean is taken
				   replace=replace					;\\ replace the input array with the non-outlying data


	nt = n_elements(in_data)
	if nt le 3 then return

	if not keyword_set(window_hwidth) then window_hwidth = round(nt*.1)
	if not keyword_set(rel_thresh) and not keyword_set(abs_thresh) then rel_thresh = .2

	window_hwidth = window_hwidth > 3

	outliers = [0]
	for t = 0, window_hwidth - 1 do begin
	  	mn = mean(in_data[t+1:t+window_hwidth < nt-1])
	  	if keyword_set(rel_thresh) then begin
	  		if abs((in_data[t] - mn) / float(mn)) gt rel_thresh then outliers = [outliers, t]
	  	endif else begin
	  	 	if abs((in_data[t] - mn)) gt abs_thresh then outliers = [outliers, t]
		endelse
	endfor

	for t = window_hwidth, nt - window_hwidth - 1 do begin
	  	mn = mean(in_data[t-window_hwidth:t+window_hwidth])
	  	if keyword_set(rel_thresh) then begin
	  		if abs((in_data[t] - mn) / float(mn)) gt rel_thresh then outliers = [outliers, t]
	  	endif else begin
	  	 	if abs((in_data[t] - mn)) gt abs_thresh then outliers = [outliers, t]
		endelse
	endfor

	for t = nt - window_hwidth, nt - 1 do begin
	  	mn = mean(in_data[t-window_hwidth > 0:t])
	  	if keyword_set(rel_thresh) then begin
	  		if abs((in_data[t] - mn) / float(mn)) gt rel_thresh then outliers = [outliers, t]
	  	endif else begin
	  	 	if abs((in_data[t] - mn)) gt abs_thresh then outliers = [outliers, t]
		endelse
	endfor

	if n_elements(outliers) gt 1 then begin
		outliers = outliers[1:*]
		complement = indgen(nt)
		complement[outliers] = -1
		pts = where(complement ne -1, ngood)
		if ngood gt 0 then complement = complement[pts] else complement = [-1]
		if keyword_set(replace) and ngood gt 0 then in_data = in_data[complement]
		return
	endif else begin
		outliers = [-1]
		complement = indgen(nt)
		return
	endelse

end