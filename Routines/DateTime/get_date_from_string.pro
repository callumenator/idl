
;\\ Returns a 6 character date string from input string, like
;\\ a filename with a yymmdd date in it somewhere: it finds the first
;\\ occurrence of date_length consecutive digits

function get_date_from_string, str, date_length

	dig_cnt = 0
	date_str = ''


	if n_elements(str) gt 1 then begin

		date_array = strarr(n_elements(str))

		for indx = 0, n_elements(str) - 1 do begin

			this_str = str(indx)

			dig_cnt = 0
			date_str = ''

			for pos = 0, strlen(this_str) do begin

			char = strmid(this_str, pos, 1)

			if byte(char) ge 48 and byte(char) le 57 then begin
				if dig_cnt lt date_length then begin
					dig_cnt = dig_cnt + 1
					date_str = date_str + char
				endif
			endif else begin
				if dig_cnt gt 0 and dig_cnt lt date_length then begin
					dig_cnt = 0
					date_str = ''
				endif
			endelse

			endfor

			date_array(indx) = date_str

		endfor

		return, date_array

	endif else begin

		str = str(0)

		for pos = 0, strlen(str) do begin

			char = strmid(str, pos, 1)

			if byte(char) ge 48 and byte(char) le 57 then begin
				if dig_cnt lt date_length then begin
					dig_cnt = dig_cnt + 1
					date_str = date_str + char
				endif
			endif else begin
				if dig_cnt gt 0 and dig_cnt lt date_length then begin
					dig_cnt = 0
					date_str = ''
				endif
			endelse

		endfor

		return, date_str

	endelse


end