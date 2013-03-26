
;\\ This assumes .jpeg 3 channel images

pro asc_keogram, path, $
				 keogram, $
				 time_axis, $
				 time_range=time_range, $
				 interpolate_to=interpolate_to, $ ;\\ a vector of times to interpolate to
				 cut=cut ;\\ where to take slice in pixels

	if not keyword_set(cut) then cut = 256

	list = file_search(path, '*.jpeg', count=nfiles)

	hr = float(strmid(file_basename(list), 23, 2))
	mn = float(strmid(file_basename(list), 25, 2))
	sc = float( strmid(file_basename(list), 27, 2))
	dsc = float( strmid(file_basename(list), 30, 3))

	dec_ut = hr + mn/60. + (sc + dsc/100.)/3600.

	if keyword_set(time_range) then begin
		pts = where(dec_ut ge time_range[0] and dec_ut le time_range[1], npts)
		if npts eq 0 then begin
			print, 'No data in time range'
			return
		endif else begin
			dec_ut = dec_ut[pts]
			list = list[pts]
		endelse
	endif

	time_axis = dec_ut
	keo = bytarr(n_elements(list), 512, 3)
	for i = 0, n_elements(list) - 1 do begin
		read_jpeg, list[i], image
		keo[i,*,*] = transpose(image[*,*,256])
		print, i + 1, n_elements(list)
		wait, .001
	endfor
	keo = reverse(keo, 2)
	keogram = keo

	if keyword_set(interpolate_to) then begin
		new_time_axis = interpolate_to
		new_keo = fltarr(n_elements(new_time_axis), 512, 3)
		for i = 0, 511 do begin
			new_keo[*,i,0] = interpol(float(keo[*,i,0]), time_axis, new_time_axis)
			new_keo[*,i,1] = interpol(float(keo[*,i,1]), time_axis, new_time_axis)
			new_keo[*,i,2] = interpol(float(keo[*,i,2]), time_axis, new_time_axis)
		endfor
		keogram = bytscl(new_keo)
		time_axis = new_time_axis
	endif
end