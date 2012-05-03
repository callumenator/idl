
pro xarrow, x0, y0, x1, y1, $
			colors=colors, $
			ctables=ctables, $
			outline_colors=outline_colors, $
			outline_ctables=outline_ctables, $
			shaft=shaft, $
			head_width=head_width, $
			head_len=head_len, $
			percent=percent, $
			device=device, $
			normal=normal, $
			data=data, $
			nofill=nofill, $
			thick=thick

	;\\ Store color table
	tvlct, red, gre, blu, /get

	;\\ If position inputs are vectors, but options are scalars, replicate scalars
	if n_elements(colors) eq 1 and n_elements(x0) gt 1 then $
		colors = replicate(colors, n_elements(x0))
	if n_elements(ctables) eq 1 and n_elements(x0) gt 1 then $
		ctables = replicate(ctables, n_elements(x0))
	if n_elements(outline_colors) eq 1 and n_elements(x0) gt 1 then $
		outline_colors = replicate(outline_colors, n_elements(x0))
	if n_elements(outline_ctables) eq 1 and n_elements(x0) gt 1 then $
		outline_ctables = replicate(outline_ctables, n_elements(x0))
	if n_elements(shaft) eq 1 and n_elements(x0) gt 1 then $
		shaft = replicate(shaft, n_elements(x0))
	if n_elements(head_len) eq 1 and n_elements(x0) gt 1 then $
		head_len = replicate(head_len, n_elements(x0))
	if n_elements(head_width) eq 1 and n_elements(x0) gt 1 then $
		head_width = replicate(head_width, n_elements(x0))

	len = sqrt( (y1-y0)*(y1-y0) + (x1-x0)*(x1-x0))
	if n_elements(shaft) eq 0 then shaft = 0.1*len
	if n_elements(head_len) eq 0 then head_len = 0.4*len
	if n_elements(head_width) eq 0 then head_width = 0.2*len

	for i = 0, n_elements(x0) - 1 do begin

		genarrow, x0[i], y0[i], x1[i], y1[i], x, y, shaft=shaft[i], $
				  awid=head_width[i], alen=head_len[i], percent=percent

		if n_elements(ctables) ne 0 then loadct, ctables[i], /silent

		if keyword_set(nofill) then begin
			plots, [x,x[0]], [y,y[0]], thick=thick, $
				   color=colors[i], $
				   device=device, $
			 	   normal=normal, $
			 	   data=data
		endif else begin
			polyfill, x, y, color=colors[i], $
				      device=device, $
			 		  normal=normal, $
			 		  data=data
		endelse

		if n_elements(outline_colors) ne 0 then begin

			if n_elements(outline_ctables) ne 0 then loadct, outline_ctables[i], /silent

			plots, [x,x[0]], [y,y[0]], thick=thick, $
				   color=outline_colors[i], $
				   device=device, $
			 	   normal=normal, $
			 	   data=data
		endif

	endfor


	;\\ Restore color table
	tvlct, red, gre, blu
end