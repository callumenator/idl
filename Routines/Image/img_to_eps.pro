
pro img_to_eps, filename

	filetype = strlowcase(strmid(filename, strlen(filename) - 3, strlen(filename)))

	case filetype of
		'jpg': read_jpeg, filename, image, /true
		'png': read_png, filename, image
		'bmp': image = read_bmp(filename, /rgb)
		else: stop
	endcase

	nx = float(n_elements(image(0,*,0)))
	ny = float(n_elements(image(0,0,*)))

	epsname = strmid(filename, 0, strlen(filename) - 4) + '.eps'



	set_plot, 'ps'
	device, filename = epsname, /encaps, /color, bits = 8, xs = 10, ys = 10.*(ny/nx)

	TVLCT, INDGEN(256), INDGEN(256), INDGEN(256)

	tv, image, /true

	device, /close
	set_plot, 'win'



end