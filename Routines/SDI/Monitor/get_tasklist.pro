
function get_tasklist, image_name = image_name

	command = 'tasklist /FO "CSV" '
	if keyword_set(image_name) then begin
		command += '/FI "IMAGENAME eq ' + image_name + '"'
	endif

	spawn, command, result, /hide
	if n_elements(result) eq 1 then return, {name:'', pid:0L}

	out = replicate({name:'', pid:0L}, n_elements(result)-1)

	for i = 1, n_elements(result) - 1 do begin
		fields = strsplit(result[i], ',', /extract)
		out[i-1].name = (strsplit(fields[0], '"', /extract))[0]
		out[i-1].pid = long((strsplit(fields[1], '"', /extract))[0])
	endfor

	return, out

end