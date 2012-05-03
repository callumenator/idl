

function read_superdarn_potentials, in_file

	fields = ['potential', 'flag', 'glat', 'glon', 'mlat', 'mlon', 'mlt']
	str_template = {year:0, month:0, day:0, ut_start:0.0, ut_end:0.0, potentials:ptr_new()}

	data_out = replicate(str_template, 1)

	;\\ Open the file
	openr, handle, in_file, /get


	while eof(handle) eq 0 do begin

		date_stamp = ''
		n_records = 0L

		readf, handle, date_stamp
		readf, handle, n_records
		data = fltarr(7, n_records)
		readf, handle, data

		ds = strsplit(date_stamp, " ", /extract)
		year = fix(ds[0])
		month = fix(ds[1])
		day = fix(ds[2])
		ut_start = float(ds[3]) + float(ds[4])/60. + float(ds[5])/3600.
		ut_end = float(ds[9]) + float(ds[10])/60. + float(ds[11])/3600.

		potentials = ptr_new(data)

		data_out = [data_out, {year:year, month:month, day:day, ut_start:ut_start, ut_end:ut_end, potentials:potentials}]

	endwhile
	free_lun, handle

	return, data_out[1:*]

end