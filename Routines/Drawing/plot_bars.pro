
pro plot_bars, x, y, width=width, $
					 color=color, $		;[ctable, color]
					 indiv_colors=indiv_colors		;[# elements x, 2]	- [ctable,color]

	if not keyword_set(color) then color = [0,255]
	if not keyword_set(width) then begin
		diff = min((x - shift(x, 1))[1:*])
		width = diff*(0.75)
	endif

	loadct, color[0], /silent
	for k = 0, n_elements(x) - 1 do begin
		if keyword_set(indiv_colors) then begin
			loadct, indiv_colors[k,0], /silent
			this_color = indiv_colors[k,1]
		endif else this_color = color[1]

		polyfill, x[k] + [-.5,-.5,.5,.5]*width, [0,y[k],y[k],0], color=this_color, /data, noclip=0, thick = .01
	endfor

end