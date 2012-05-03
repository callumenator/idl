
;\\ Return 1 if the site, year dayno and ut time fall into a good data range or 0 otherwise.
;\\ UT can be a vector, in which case a vector will be returned, same length as UT, with a
;\\ 1 at each element falling in the good data range.
function sdi_good_data, site_code, year, dayno, ut

	Common SDI_GOOD_DATA_COMMON, good_dates, site_codes, site_ids

	;\\ If first call, read in the data
	if size(good_dates, /type) eq 0 then begin
		file = where_is('good_data_list')

		openr, hnd, file, /get
		first_line = ''
		readf, hnd, first_line
		spl = strsplit(first_line, ' ', /extract)
		header_lines = fix(spl[1])
		header = strarr(header_lines)
		good_dates = intarr(7, file_lines(file)-(header_lines+1))
		readf, hnd, header
		readf, hnd, good_dates
		free_lun, hnd

		;\\ Get station ID's
		site_codes = strarr(header_lines - 1)
		site_ids = intarr(header_lines - 1)
		for k = 0, header_lines - 2 do begin
			spl = strsplit(header[k], ' ', /extract)
			site_codes[k] = strcompress(strupcase(spl[1]), /remove)
			site_ids[k] = fix(spl[2])
		endfor
	endif

	;\\ Match the site, year and dayno, and return the time ranges
	use_id = (where(strupcase(site_code) eq site_codes, nmatch))[0]
	if nmatch eq 0 then begin
		print, 'SDI_GOOD_DATA: No Matching Site Code'
		return, replicate(0, n_elements(ut))
	endif
	id = site_ids[use_id]

	line = (where(good_dates[0,*] eq id and good_dates[1,*] eq year and good_dates[2,*] eq dayno, nmatch))[0]
	if nmatch eq 0 then return, replicate(0, n_elements(ut))


	ranges = reform(good_dates[3:*, line])
	negone = where(ranges eq -1, nneg)
	if nneg ne 0 then ranges = ranges[0:negone[0]-1]
	nranges = n_elements(ranges)/2

	;\\ Convert to decimal
	ranges = ranges / 100.
	ranges = fix(ranges) + (ranges mod 1)*(100./60.)

	good = intarr(nranges, n_elements(ut))
	for k = 0, nranges - 1, 2 do begin
		in = where( (ut ge ranges[k] and ut le ranges[k+1]))
		good[k,in] = 1
	endfor

	in = total(good, 1)
	good = where(in ne 0, ngood)

	out = intarr(n_elements(ut))
	if ngood gt 0 then out[good] = 1
	return, out

end