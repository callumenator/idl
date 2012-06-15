
function extract_lel_data, year, dayno, field, lelpath=lelpath, $
											   goodValues=goodValues, $
											   no_next_day = no_next_day

	if not keyword_set(lelpath) then lelpath = where_is('davis_lel')

	;\\ FOR THIS DAY...
		ydn2md, year, dayno, mnth, day
		day = string(day, f='(i02)')
		mnth = string(mnth, f='(i02)')
		lelfile = lelpath + string(year, f='(i04)') + mnth + day + '.lel'

	;\\ AND FOR THE NEXT DAY
		ydn2md, year, dayno+1, mnth, day
		day = string(day, f='(i02)')
		mnth = string(mnth, f='(i02)')
		lelfile_nextday = lelpath + string(year, f='(i04)') + mnth + day + '.lel'


	if file_test(lelfile) and file_test(lelfile_nextday) and not keyword_set(no_next_day) then begin

		data_thisday = strarr(file_lines(lelfile))
		openr, handle, lelfile, /get_lun
			readf, handle, data_thisday
		close, handle
		free_lun, handle
		if n_elements(data_thisday) eq 1 then return, -1
		data_thisday = data_thisday[1:n_elements(data_thisday)-1]

		data_nextday = strarr(file_lines(lelfile_nextday))
		openr, handle, lelfile_nextday, /get_lun
			readf, handle, data_nextday
		close, handle
		free_lun, handle
		data_nextday = data_nextday[1:n_elements(data_nextday)-1]

		data = [data_thisday, data_nextday]
		whichday = intarr(n_elements(data))
		whichday[0:n_elements(data_thisday)-1] = 0
		whichday[n_elements(data_thisday):n_elements(data_thisday)+n_elements(data_nextday)-1] = 1

		;\\ GET LEL DATA AND PLOT
			hour = fltarr(n_elements(data))
			mins = fltarr(n_elements(data))
			allSubData = fltarr(n_elements(data))
			for j = 0L, n_elements(data) - 1 do begin
				split = strcompress(strsplit(data(j), ',', /extract), /remove)
				match = where(split eq field, npts)
					if npts gt 0 then allSubData(j) = float(split(match(0)+1)) $
						else print, 'No Match for ' + field
				if whichday(j) eq 0 then hour(j) = float(split(0)) $
					else hour(j) = float(split(0)) + 24.
				mins(j) = float(split(1))
			endfor

			ut = hour + mins/60.

			if keyword_set(goodValues) then begin
				good = where(allsubData ge goodValues(0) and allsubData le goodValues(1), ngood)
				if ngood gt 0 then begin
					allsubData = allsubData(good)
					ut = ut(good)
				endif
			endif

			return, {ut:ut, data:allSubData}
	endif

	if file_test(lelfile) and (file_test(lelfile_nextday) eq 0 or keyword_set(no_next_day)) then begin

		data_thisday = strarr(file_lines(lelfile))
		openr, handle, lelfile, /get_lun
			readf, handle, data_thisday
		close, handle
		free_lun, handle
		if n_elements(data_thisday) eq 1 then return, -1
		data_thisday = data_thisday[1:n_elements(data_thisday)-1]

		data = data_thisday
		whichday = intarr(n_elements(data))
		whichday[0:n_elements(data_thisday)-1] = 0

		;\\ GET LEL DATA AND PLOT
			hour = fltarr(n_elements(data))
			mins = fltarr(n_elements(data))
			allSubData = fltarr(n_elements(data))
			for j = 0L, n_elements(data) - 1 do begin
				split = strcompress(strsplit(data(j), ',', /extract), /remove)
				match = where(split eq field, npts)
					if npts gt 0 then allSubData(j) = float(split(match(0)+1)) $
						else print, 'No Match for ' + field
				if whichday(j) eq 0 then hour(j) = float(split(0)) $
					else hour(j) = float(split(0)) + 24.
				mins(j) = float(split(1))
			endfor

			ut = hour + mins/60.

			if keyword_set(goodValues) then begin
				good = where(allsubData ge goodValues(0) and allsubData le goodValues(1), ngood)
				if ngood gt 0 then begin
					allsubData = allsubData(good)
					ut = ut(good)
				endif
			endif

			return, {ut:ut, data:allSubData}
	endif


	return, -1

end