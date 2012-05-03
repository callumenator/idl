
;\\ The plot part assumes a data coordinate system, which has time as the x-axis and
;\\ pixel number as the y-axis
pro sdi_keogram_plotit, keogram, start_times, end_times, ctable = ctable, clip_times=clip_times

	if not keyword_set(ctable) then ctable = 4
	dims = size(keogram, /dimensions)

	tvlct, r, g, b, /get
	loadct, ctable, /silent

	s_times = start_times
	e_times = end_times
	t_range = max(e_times) - min(s_times)

	if not keyword_set(clip_times) then clip_times = [min(s_times), max(e_times)]

	for t = 0, dims[0] - 2 do begin
		if s_times[t] gt clip_times[0] and s_times[t+1] lt clip_times[1] then begin
			for k = 0, dims[1] - 1 do plots, /data, [s_times[t], s_times[t+1]], [k,k], color = keogram[t,k]
		endif
	endfor
	if s_times[t] gt clip_times[0] and e_times[t] lt clip_times[1] then begin
		for k = 0, dims[1] - 1 do plots, /data, [s_times[t], e_times[t]], [k,k], color = keogram[t,k]
	endif

	tvlct, r, g, b
end


pro sdi_keogram, images_structure, keogram, $
				 color_top = color_top, $
				 scale_to = scale_to, $			;\\ percentile
				 scale_to_abs = scale_to_abs, $	;\\ absolute number to scale tp
				 smoothing = smoothing, $
				 image_rotate = image_rotate

	if not keyword_set(smoothing) then smoothing = [1,1]
	if not keyword_set(color_top) then color_top = 255
	if not keyword_set(scale_to) then scale_to = .98

	dims = size(images_structure[0].scene, /dimensions)
	ims = images_structure
	exptime = ims.end_time - ims.start_time
	exptime = exptime
	factor = 1.0 / exptime
	factor = factor / total(factor)
	cut = fltarr(n_elements(ims), 512)
	for k = 0, n_elements(ims) - 1 do begin
		if keyword_set(image_rotate) then begin
			cut[k,*] = (rot(ims[k].scene, image_rotate))[dims[0]/2.,*] * factor[k]
		endif else begin
			cut[k,*] = (ims[k].scene)[dims[0]/2.,*]	* factor[k]
		endelse
	endfor

	scut = smooth(cut, smoothing, /edge)
	sorted = scut[sort(scut)]
	if keyword_set(scale_to_abs) then begin
		color = bytscl(scut, max = sorted[scale_to*n_elements(sorted) - 1], top = color_top)
	endif else begin
		color = bytscl(scut, max = scale_to_abs, top = color_top)
	endelse
	keogram = color
end
