
function read_davis_specfile, file_name

;	if file_test(file_name) eq 1 then begin
;
;		filename = file_name
;
;		file_copy, filename, 'c:\specfiles\' + file_basename(filename)
;
;		spawn, 'c:\justext.exe'
;
;		file_delete, 'c:\specfiles\' + file_basename(filename)
;
;		filename = 'c:\spectext\' + strmid(file_basename(filename), 0, strlen(file_basename(filename)) - 3) + 'txt'
;
;		data = strarr(file_lines(filename))
;
;		openr, file, filename, /get_lun
;		readf, file, data
;		close, file
;		free_lun, file
;
;		file_delete, filename
;
;		time 	= float(strmid(data(700),1,strlen(data(700))-2))
;		azim 	= float(strmid(data(701),1,strlen(data(701))-2))
;		elev 	= float(strmid(data(702),1,strlen(data(702))-2))
;		tube 	= float(strmid(data(703),1,strlen(data(703))-2))
;		exptime = float(strmid(data(704),1,strlen(data(704))-2))
;		filter 	= float(strmid(data(705),1,strlen(data(705))-2))
;		xcen 	= float(strmid(data(706),1,strlen(data(706))-2))
;		ycen 	= float(strmid(data(707),1,strlen(data(707))-2))
;		title	= strmid(data(708),1,strlen(data(708))-2)
;
;		if tube eq 2 then azim = azim + 180
;		if azim gt 260 then azim = azim - 360
;		zen_ang = 90. - elev
;		time = time / 1000.
;
;		str = {time:time, azimuth:azim, zen_ang:zen_ang, tube:tube, exptime:exptime, $
;			   filter:filter, xcen:xcen, ycen:ycen, title:title}
;
;		return, str
;
;	endif else begin
;
;		return, {null:0}
;
;	endelse


;\\ This code reads a davis specfile directly, without using theo's justext program
;\\ Cal, 23 June 2008

	info = file_info(file_name)
	type = 0
	count = 0

	tstr = {hours:0, mins:0, secs:0}

	str = {spec:fltarr(700), $
		   time:tstr, $
		   azimuth:0.0, $
		   zen_ang:0.0, $
		   tube:0.0, $
		   exptime:0D, $
		   filter:0, $
		   xcen:0, $
		   ycen:0, $
		   title:'' }

	openr, f, file_name, /get_lun

		readu, f, type

		while eof(f) ne 1 do begin
			readu, f, type
			case type of
				2: val = 0
				4: val = 0.0
				5: val = 0D
				8: begin
					len = 0
					readu, f, len
					val = bytarr(len)
				end
			endcase
			readu, f, val
			if count lt 700 then begin
				str.spec(count) = float(val)
			endif else begin
				if count eq 700 then begin
					t = string(val)
					str.time.hours = fix(strmid(t,0,2))
					str.time.mins = fix(strmid(t,2,2))
					str.time.secs = fix(strmid(t,4,2))
				endif else begin
					if type eq 8 then begin
						str.(count-699) = string(val)
					endif else begin
						str.(count-699) = val
					endelse
				endelse
			endelse
			count ++
		endwhile

	close, f
	free_lun, f

	if str.tube eq 2 then str.azimuth = str.azimuth + 180
	if str.azimuth gt 360 then str.azimuth = str.azimuth - 360
	str.zen_ang = 90. - str.zen_ang

	return, str

end