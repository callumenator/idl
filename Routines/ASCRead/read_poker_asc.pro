
;\\ Date and time are strings, date: 'yymmdd', time: 'hhmmss'

pro read_poker_asc, image, $
					latlon=latlon, $
					file=file, $
					date=date, $
					time=time, $
					meta=meta

	load = 0
	if keyword_set(file) then begin
		img = readfits(file)
		load = 1
	endif

	if keyword_set(date) and keyword_set(time) then begin
		path = where_is('poker_asc')
		files = file_search(path + '*' + date + '*' + time + '*.fits', count = nfiles)
		if nfiles ge 1 then begin
			file = files[0]
			img = readfits(file)
			load = 1
		endif
	endif

	edges = [10,29,477,503]
	image = img[edges[0]:edges[2], edges[1]:edges[3]]
	dims = size(image, /dimensions)

	if keyword_set(meta) then begin
		dd = mc_dist(dims[0], dims[1], dims[0]/2., dims[1]/2., x=xx, y=yy)
		;dist_circle, imdist, dims, dims[0]/2., dims[1]/2.
		imzen = 90.*dd/(mean(dims)/2.)
		imazi = atan(yy,xx)/!dtor
		imazi = 180 + rot( reverse(imazi, 1), 90 ) + meta.oval_angle

		latlon = fltarr(dims[0], dims[1], 2)
		latlon[*,*,*] = -999
		for xx = 0, dims[0] - 1 do begin
		for yy = 0, dims[1] - 1 do begin
			if imzen[xx,yy] gt 77 then continue
			ll = reform(get_end_lat_lon(meta.latitude, meta.longitude, get_great_circle_length(imzen[xx,yy], 105.), imazi[xx,yy]))
			latlon[xx,yy,0] = ll[0]
			latlon[xx,yy,1] = ll[1]
		endfor
		endfor

	endif

end