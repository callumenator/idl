

;\\ Routine to correct the non-linearity in a Davis FPS fringe

function linearise_davis_fringe, picname, specname

	orig_pic = float(read_tiff(picname))

	data = read_davis_specfile(specname)

	;\\ Get the integration time (not the same as exposure time)
		if strmatch(data.title, '*IS*', /fold) then begin
			pos = strpos(data.title, 'IS')
			int_time = float(strmid(data.title, pos+4, strlen(data.title)))
		endif else begin
			int_time = data.exptime
		endelse

	;\\ Get the dark count
		dark_count = (int_time * 0.1373) + 11.4

	;\\ Linearise the picture
		lin_pic = double(orig_pic) - dark_count
		lin_pic = 22.9449079323489D * ((-0.0000000040542D * (lin_pic^4.0)) + $
				  (0.0000026321D * (lin_pic^3.0)) - $
				  (0.00030518D * (lin_pic^2.0)) + $
				  (0.017385D * lin_pic) + $
				  0.023068D)
		lin_pic = lin_pic + dark_count


	return, lin_pic

end
