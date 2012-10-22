
function import_IPS_magnetometer, filename

	if file_test(filename) eq 0 then return, {ut:0.0, x:0.0, y:0.0}


	lines = file_lines(filename)
	data = fltarr(lines, 5)

	header = ''
	openr, hnd, filename, /get
	readf, hnd, header
	readf, hnd, data
	free_lun, hnd

	data = {ut:data[*,0] + data[*,1]/60. + data[*,2]/3600., $
			x:data[*,3], $
			y:data[*,4] }

	return, data
end