
pro post_image_temporal_smooth, dir = dir

	if not keyword_set(dir) then dir = dp(/directory)

	files = file_search(dir + ['*.png'], count=nfiles)

	for z = 0, nfiles - 2 do begin

		read_png, files[z], img1
		read_png, files[z+1], img2

		out_img = byte(0.5*img1 + 0.5*img2)

		name = file_basename(files[z])
		name = strmid(name, 0, strlen(name)-4) + '_a.png'

		write_png, dir + '\' + name, out_img

	endfor

end