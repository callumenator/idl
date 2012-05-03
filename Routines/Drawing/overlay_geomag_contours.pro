
;\\ Overlay geomagnetic latitude or longitude circles onto a map
pro overlay_geomag_contours, map, $	;\\ map structure
							 longitude=longitude, $ ;\\ show longitude at given increment
							 latitude=latitude, $ ;\\ show latitude at given increment
							 color=color, $ ;\\ [ctable, color index]
							 thick=thick, $ ;\\ line thickness
							 linestyle=linestyle, $ ;\\ linestyle
							 label_locations=label_locations, $ ;\\ [2,n] array of mag lat/lon pairs to label
							 label_names=label_names, $ ;\\ [n-elements] array of strings to use for names
							 label_charsize=label_charsize, $ ;\\ char size for labels
							 label_charthick=label_charthick, $ ;\\ char thick for labels
							 label_color=label_color, $ ;\\ [ctable, index] color for labels
							 label_align=label_align, $ n-element array of char alignments
							 label_orient=label_orient ;\\ n-element array of char orientations


	if not keyword_set(thick) then thick = 1
	if not keyword_set(linestyle) then linestyle = 0
	if not keyword_set(color) then color = [0,0]

	aacgmidl
	tvlct, red, gre, blu, /get
	loadct, color[0], /silent

	if keyword_set(longitude) then begin

		increment = longitude

		for mlon = 0, 360, increment do begin

			glat = fltarr(91)
			glon = fltarr(91)
			i = 0
			for mlat = -90, 90, 2 do begin
				cnv_aacgm, mlat, mlon, 240, xlat, xlon, r, error, /geo
				glat[i] = xlat
				glon[i] = xlon
				i++
			endfor

			pts = where(glon ne 0 and glat ne 0 and finite(glon) eq 1 and finite(glat) eq 1, npts)

			if npts gt 0 then plots, map_proj_forward(glon[pts], glat[pts], map=map), thick=thick, linestyle=linestyle, $
					color = color[1], noclip=0, /data

		endfor

	endif


	if keyword_set(latitude) then begin

		increment = latitude

		for mlat = -90, 90, increment do begin

			glat = fltarr(73)
			glon = fltarr(73)
			i = 0
			for mlon = 0, 360, 5 do begin
				cnv_aacgm, mlat, mlon, 240, xlat, xlon, r, error, /geo
				glat[i] = xlat
				glon[i] = xlon
				i++
			endfor

			pts = where(glon ne 0 and glat ne 0 and finite(glon) eq 1 and finite(glat) eq 1, npts)

			if npts gt 0 then plots, map_proj_forward(glon[pts], glat[pts], map=map), thick=thick, linestyle=linestyle, $
					color = color[1], noclip=0, /data

		endfor

	endif


	if keyword_set(label_locations) then begin

		n_labs = n_elements(label_locations[0,*])
		if not keyword_set(label_charsize) then label_charsize = 1
		if not keyword_set(label_charthick) then label_charthick = 1
		if not keyword_set(label_color) then label_color = [0,0]
		if not keyword_set(label_align) then label_align = replicate(.5, n_labs)
		if not keyword_set(label_orient) then label_orient = replicate(0, n_labs)

		for i = 0, n_labs-1 do begin
			cnv_aacgm, label_locations[0,i], label_locations[1,i], 240, xlat, xlon, r, error, /geo
			pos = map_proj_forward(xlon, xlat, map=map)
			loadct, label_color[0], /silent
			xyouts, pos[0], pos[1], label_names[i], color=label_color[1], chart = label_charthick, $
					chars = label_charsize, /data, align=label_align[i], orient=label_orient[i]
		endfor

	endif



	;\\ Restore previous color table
	tvlct, red, gre, blu

end
