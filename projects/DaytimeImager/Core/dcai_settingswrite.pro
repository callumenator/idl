
@dcai_script_utilities

pro DCAI_SettingsWrite_Recurse, in, current=current, list=list, extra=extra

	tags = strlowcase(tag_names(in))

	for i = 0, n_elements(tags) - 1 do begin

		if keyword_set(extra) then current = extra.base + '[' + string(extra.index, f='(i0)') + ']'
		if current eq '' then current += tags[i] else current += '|' + tags[i]

		;\\ are we at a leaf, or still in the tree?
		leaf = 0

		var = in.(i)
		type = size(var, /type)
		nels = n_elements(var)
		if nels gt 1 then array = 1 else array = 0
		if type ne 8 then leaf = 1

		if leaf eq 1 then begin

			current += ' = '

			if type ge 1 and type le 3 or type ge 12 then fmt = '(i0)'
			if type eq 4 or type eq 5 then fmt = '(f0.4)'
			if type eq 7 then fmt = '(a0)'

			if array eq 0 then begin

				if type ne 7 then begin
				  current += string(var, f=fmt)
				endif else begin
				  current += "'" + string(var, f=fmt) + "'"
				endelse

			endif else begin

				current += '['
				for k = 0, nels - 1 do begin
				  if type ne 7 then begin
					 current += string(var[k], f=fmt)
					endif else begin
					 current += "'" + string(var[k], f=fmt) + "'"
					endelse
					if k ne nels - 1 then current += ', ' else current += ']'
				endfor

			endelse

			split = strsplit(current, '|', /extract)
			list = [list, strjoin(split, '.')]
			if n_elements(split) eq 1 then begin
				current = ''
			endif else begin
				current = strjoin(split[0:n_elements(split)-2], '|')
			endelse

		endif else begin

			if array eq 1 then begin
				extra = {array_struc:1, index:0, base:current, last_index:nels-1}
				for j = 0, nels - 1 do begin
					extra.index = j
					DCAI_SettingsWrite_Recurse, var[j], current=current, list=list, extra=extra
				endfor

			endif else begin
				DCAI_SettingsWrite_Recurse, var, current=current, list=list, extra=extra
			endelse

		endelse

	endfor

	split = strsplit(current, '|', /extract)

	reduce_depth = 0
	if size(extra, /type) eq 8 then begin
		if extra.index eq extra.last_index then begin
			reduce_depth = 1
			extra = 0
		endif
	endif else begin
		reduce_depth = 1
	endelse

	if reduce_depth eq 1 then begin
		if n_elements(split) eq 1 then begin
			current = ''
		endif else begin
			current = strjoin(split[0:n_elements(split)-2], '|')
		endelse
	endif

	list = [list, '']

end




pro DCAI_SettingsWrite, settings, filename, $
						no_write = no_write, $ 	;\\ Set if we do not want to actually write the file
						out_text = out_text 	;\\ The array of strings that were generated for output

	;\\ GENERATE THE LIST OF STRINGS
	list = ['']
	DCAI_SettingsWrite_Recurse, settings, current='settings', list=list
	list = list[1:*]

	;\\ WRITE THE TEXT OUT TO THE FILE
	if not keyword_set(no_write) then begin

		openw, f, filename, /get

		pro_name = file_basename(filename)
		spl = strsplit(pro_name, '.', /extract)
		pro_name = spl[0]

		tab = string(9B) ;\\ Horizontal tab

		printf, f ;\\ Two blank lines
		printf, f ;\\
		printf, f, ';\\ Settings file written (UT): ' + DateStringUT_YYYYMMDD()
		printf, f, 'pro ' + pro_name + ', settings = settings'
		printf, f

		for k = 0, n_elements(list) - 1 do begin
			printf, f, tab + list[k]
		endfor

		printf, f
		printf, f, 'end'
		close, f
		free_lun, f

		;\\ COMPILE IT (THIS IS A ROUNDABOUT WAY OF DOING IT, BUT SEEMS TO BE REQUIRED)
		catch, err
		if err ne 0 then begin
			catch, /cancel
			resolve_routine, pro_name, /compile_full ;\\ THIS WILL MAKE SURE OF COMPILE
		endif else begin
			call_procedure, file_dirname(filename) + '\' + pro_name ;\\ THIS WILL COMPILE BUT FAIL TO CALL
		endelse


	endif

	out_text = list

end