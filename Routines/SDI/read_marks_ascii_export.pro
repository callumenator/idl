
pro read_marks_ascii_export_parse_skymap, text, section_start, nrecs, nzones, $
										  skymap=skymap, time=time

	str0 = ''
	line = section_start + 1
	rec_idx = 0
	ut = fltarr(nrecs)
	skymap = fltarr(nrecs, nzones)
	while str0 ne '>' do begin

		time = strsplit(text[line], ' ', /extract)
		t0 = fix(strsplit(time[1], ':', /extract))
		t1 = fix(strsplit(time[3], ':', /extract))
		t0_dec = total(t0*[1., 1./60., 1/3600.])
		t1_dec = total(t1*[1., 1./60., 1/3600.])

		ut[rec_idx] = (t0_dec + t1_dec) / 2.

		zones = 0
		for j = 0, 7 do begin
			line ++
			vals = float(strsplit(text[line], ' ', /extract))
			append, vals, zones
		endfor
		skymap[rec_idx, *] = zones

		rec_idx ++
		line ++
		str0 = strmid(text[line], 0, 1)
	endwhile

	time=ut

end


pro read_marks_ascii_export, filename

	filename = 'C:\Users\callum\Downloads\pkr 2010_066_poker_630nm_red_sky_date_03_07.txt'

	openr, hnd, filename, /get

	strtext = strarr(file_lines(filename))
	readf, hnd, strtext
	free_lun, hnd

	recs = strsplit(strtext[5], ':', /extract)
	nrecs = fix(recs[1])

	start = (where(strmatch(strtext, '*Section*GEO_ZONAL_WIND_SKYMAP*') eq 1))[0]
	read_marks_ascii_export_parse_skymap, strtext, start, nrecs, 115, $
										  skymap=skymap, time=time
	ut = time
	geo_zonal = skymap

	start = (where(strmatch(strtext, '*Section*GEO_MERID_WIND_SKYMAP*') eq 1))[0]
	read_marks_ascii_export_parse_skymap, strtext, start, nrecs, 115, $
										  skymap=skymap, time=time
	geo_merid = skymap


	start = (where(strmatch(strtext, '*Section*TEMP_SKYMAP*') eq 1))[0]
	read_marks_ascii_export_parse_skymap, strtext, start, nrecs, 115, $
										  skymap=skymap, time=time
	temp = skymap


	restore, 'Z:\WindsForHWM\2010_066_PKR_6300.idlsave'

	loadct, 39, /silent
	window, 0
	plot, ut,  geo_merid[*,50]
	oplot, data.time_ut, data.meridional[50,*], color = 100, psym=1

	window, 1
	plot, ut,  geo_zonal[*,50]
	oplot, data.time_ut, data.zonal[50,*], color = 100, psym=1

	window, 2
	plot, ut,  temp[*,50]
	oplot, data.time_ut, data.temperature[50,*], color = 100, psym=1

	stop

end