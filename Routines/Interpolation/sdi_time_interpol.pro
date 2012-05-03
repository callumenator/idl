
;\\ Interpolate an array of type [zones, times] to a given set of times.
;\\ The time dimension of the input data is specified by time_dim keyword.
;\\ If not set, it is assumed to be dim 2.

pro sdi_time_interpol, in_data, $
					   in_times, $
					   out_times, $
					   out_data, $
					   time_dim=time_dim

	if not keyword_set(time_dim) then time_dim = 2
	sz = size(in_data, /dimensions)
	nz = sz[abs(1 - (time_dim - 1))]
	nt = sz[time_dim - 1]
	nnt = n_elements(out_times)

	if time_dim eq 1 then begin
		out_data = fltarr(nnt, nz)
		for z = 0, nz - 1 do begin
			out_data[*, z] = interpol(in_data[*, z], in_times, out_times)
		endfor
	endif else begin
		out_data = fltarr(nz, nnt)
		for z = 0, nz - 1 do begin
			out_data[z, *] = interpol(in_data[z, *], in_times, out_times)
		endfor
	endelse
end