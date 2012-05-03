;\\ Wrapper for EPS creation

pro eps, filename=filename, $
		 xsize=xsize, $
		 ysize=ysize, $
		 open=open, $
		 close=close

	if keyword_set(open) and size(filename, /type) eq 7 then begin
		set_plot, 'ps'
		device, filename = filename, xs=xsize, ys=ysize, /encaps, /color, bits=8
	endif

	if keyword_set(close) then begin
		empty
		device, /close
		set_plot, 'win'
	endif

end