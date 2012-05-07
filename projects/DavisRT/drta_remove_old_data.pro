
;\\ Checks to see if a specified file is not going to be analysed,
;\\ and so is just taking up space. If it is older than min_time
;\\ (in hours) then remove the file to move_path

pro drta_remove_old_data, filename, saves_path, move_path, min_time = min_time

	if not keyword_set(min_time) then min_time = 4.

	year = 2000 + float(strmid(file_basename(filename),0,2))
	mnth = float(strmid(file_basename(filename),2,2))
	day  = float(strmid(file_basename(filename),4,2))
	hour = float(strmid(file_basename(filename),6,2))
	mins = float(strmid(file_basename(filename),8,2))
	secs = float(strmid(file_basename(filename),10,2))

	file_js = ymds2js(year, mnth, day, hour*3600. + mins*60. + secs)
	file_dayno = ymd2dn(year, mnth, day)

	now_js = dt_tm_tojs(systime())

	;\\ Get the name of analysis results file, and test for existence
		analysed_filename = saves_path + string(year, f='(i0)') + '_' + string(file_dayno, f='(i3.3)')
		analysed = file_test(analysed_filename)

	;\\ Need to know if the picture file is there too, and remove that also
		pic_filename = strmid(filename, 0, strlen(filename) - 3) + 'tif'
		pic_file_there = file_test(pic_filename)

	if analysed eq 1 then begin

		restore, analysed_filename
		if size(sky, /type) ne 0 then begin
			last_skytime_js = sky[n_elements(sky)-1].time_done
			hours_diff = abs(last_skytime_js - now_js)/3600.

			if hours_diff gt min_time then begin
				file_move, filename, move_path + file_basename(filename), /verbose
				if pic_file_there then file_move, pic_filename, move_path + file_basename(pic_filename), /verbose
			endif
		endif
	endif

end