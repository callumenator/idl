
function get_allsky_image, filename, index

	id = ncdf_open(filename)

		vid = ncdf_varid(id, 'Accumulated_Image')
		if vid ne -1 then begin
			ncdf_varget, id, vid, image, offset = [0,0,index], count = [512,512,1]
		endif else begin
			image = bytarr(10,10)
		endelse

	ncdf_close, id

	return, image

end

