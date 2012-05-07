
function DocGen_TypeCodeToString, code
	code_string = 'Unknown'
	case code of
		0:code_string = 'undefined'
		1:code_string = 'byte'
		2:code_string = 'int'
		3:code_string = 'long'
		4:code_string = 'float'
		5:code_string = 'double'
		6:code_string = 'complex'
		7:code_string = 'string'
		8:code_string = 'structure'
		9:code_string = 'double complex'
		10:code_string = 'ptr'
		11:code_string = 'obj'
		12:code_string = 'uint'
		13:code_string = 'ulong'
		14:code_string = 'long64'
		15:code_string = 'ulong64'
		else:code_string = 'unknown'
	endcase
	return, code_string
end

function DocGen_CharacterEscape, name, byte_val
	byte_val = byte_val(0)
	name_byte = byte(name)
	uscore = where(name_byte eq byte_val, nuscore)
	for uidx = 0, nuscore - 1 do begin
		pos = uscore(uidx) + uidx
		name_byte_new = bytarr(n_elements(name_byte) + 1)
		name_byte_new(pos+1:*) = name_byte(pos:*)
		name_byte_new(pos) = 92
		if pos ne 0 then name_byte_new(0:pos-1) = name_byte(0:pos-1)
		name_byte = name_byte_new
	endfor
	name = string(name_byte)
	return, name
end

function DocGen_CharacterReplace, name, replace, replace_with
	replace = replace(0)
	replace_with = replace_with(0)
	name_byte = byte(name)
	pts = where(name_byte eq replace, nuscore)
	name_byte(pts) = replace_with
	name = string(name_byte)
	return, name
end

pro DocGen_Format, docgen_path, $
				   source_path, $
				   format_path, $
				   output_path, $
				   file_list, $
				   docgen_suffix=docgen_suffix, $
				   format_only=format_only, $
				   latex_only=latex_only, $
				   force_format=force_format

	nfiles = n_elements(file_list)
	flist = file_list
	alldefs = 0

	if not keyword_set(docgen_suffix) then begin
		suffix = '.docgen'
	endif else begin
		if docgen_suffix eq 'none' then suffix = '' else $
			suffix = docgen_suffix
	endelse

	for idx = 0, nfiles-1 do begin

		;\\ Read in the file
			fpath = file_dirname(flist(idx))
			;\\ Keep the directory structure in the format_path
				fpath_sep = strsplit(fpath, path_sep(), /extract)
				source = file_basename(source_path)
				pt = where(strlowcase(fpath_sep) eq strlowcase(source))
				if pt ne n_elements(fpath_sep)-1 then begin
					dir_struc_path = fpath_sep(pt+1:*)
				endif else begin
					dir_struc_path = ''
				endelse

			fname = file_basename(flist(idx))
			fname = strmid(fname, 0, strlen(fname) - 4)
			fname_with_ext = file_basename(flist(idx))
			nlines = file_lines(flist(idx))
			content = strarr(nlines)
			openr, handle, flist(idx), /get
				readf, handle, content
			close, handle
			free_lun, handle

		;\\ Check to see if code already formatted
			formatted = 0
			if content(0) eq ';\\ Code formatted by DocGen' then formatted = 1

		;\\ Loop through content
			struc = {def_line_range:[0,0], $
					 end_line:-1, $
					 type:'', $
					 name:'', $
					 args_ptr:ptr_new(), $
					 arg_text_ptr:ptr_new(), $
					 def_text_ptr:ptr_new(), $
					 nargs:0L, $
					 method:0, $
					 class:'null', $
					 define:0, $
					 fname:'', $
					 fpath:'', $
					 super_class_ptr:ptr_new(), $
					 class_tags_ptr:ptr_new(), $
					 class_type_ptr:ptr_new()}

			defs = replicate(struc, 1)
			def_idx = 0
			includes = 0
			for line = 0, nlines - 1 do begin

				str = strcompress(strtrim(content(line), 2))
				recheck = 0

				DOCGEN_RECHECK_POINT:
				cmnt_match = strpos(str, ';')
				func_match = strpos(strlowcase(str), 'function')
				proc_match = strpos(strlowcase(str), 'pro')
				end_match  = strpos(strlowcase(str), 'end')
				include_match  = strpos(strlowcase(str), '@')

				check = 0
				if (func_match ne -1) or (proc_match ne -1) or (end_match ne -1) then check = 1

				if include_match eq 0 then begin
					if size(includes, /type) eq 2 then begin
						includes = str
					endif else begin
						includes = [includes, str]
					endelse
				endif

				if check then begin

					has_a_func = 0
					has_a_proc = 0
					has_an_end = 0
					if (func_match ne -1) then begin
							has_a_func = 1
							pos = func_match
							if pos ne 0 and strlen(strmid(str, pos-1, 1)) gt 0 and strmid(str, pos-1, 1) ne ' ' then has_a_func = 0
							if pos ne strlen(str) and strlen(strmid(str, pos+8, 1)) gt 0 and strmid(str, pos+8, 1) ne ' ' then has_a_func = 0
					endif
					if (proc_match ne -1) then begin
							has_a_proc = 1
							pos = proc_match
							if pos ne 0 and strlen(strmid(str, pos-1, 1)) gt 0 and strmid(str, pos-1, 1) ne ' ' then has_a_proc = 0
							if pos ne strlen(str) and strlen(strmid(str, pos+3, 1)) gt 0 and strmid(str, pos+3, 1) ne ' ' then has_a_proc = 0
					endif
					if (end_match ne -1) then begin
							has_an_end = 1
							pos = end_match
							if pos ne 0 and strlen(strmid(str, pos-1, 1)) gt 0 and strmid(str, pos-1, 1) ne ' ' then has_an_end = 0
							if pos ne strlen(str) and strlen(strmid(str, pos+3, 1)) gt 0 and strmid(str, pos+3, 1) ne ' ' then has_an_end = 0
					endif

					if ((proc_match ne -1) and (func_match ne -1)) then begin
						if (has_a_func eq 0 and has_a_proc eq 0) then continue
					endif
					if ((proc_match ne -1) and (func_match eq -1)) then begin
						if (has_a_proc eq 0) then continue
					endif
					if ((proc_match eq -1) and (func_match ne -1)) then begin
						if (has_a_func eq 0) then continue
					endif
					if (end_match ne -1) then begin
						if (has_a_proc eq 0) and (has_a_func eq 0) and (has_an_end eq 0) then continue
					endif

					;\\ Remove anything after a comment (; character), unless file is formatted,
					;\\ In which case extract documentation
						if (cmnt_match ne -1) then begin
								if (cmnt_match eq 0) then continue
								sub_str = strsplit(str, ';', /extract)
								str = sub_str(0)
						endif

					;\\ Join together continued lines ($ character)
						dollar_match = strpos(str, '$')
						line_inc = 1
						if dollar_match ne -1 then begin
							while (dollar_match ne -1) do begin
								sub_str = strcompress(strmid(str, 0, dollar_match) + ' ' + content(line+line_inc))
								sub_str = strsplit(sub_str, ';', /extract)
								sub_str = sub_str(0)
								str = sub_str
								line_inc ++
								dollar_match = strpos(str, '$')
								def_line_range = [line, line+line_inc-1]		;\\ lines over which the function is defined
							endwhile
						endif else begin
							if not recheck then def_line_range = [line, line]		;\\ lines over which the function is defined
						endelse

						if recheck eq 0 then begin
							recheck ++
							goto, DOCGEN_RECHECK_POINT
						endif

					;\\ If an 'END', then update the previous def
						if (end_match ne -1) and (has_an_end eq 1) then begin
							defs(def_idx-1).end_line = line
							continue
						endif

					;\\ Extract func, pro, obj or method, along with args
						sub_str = strsplit(str, ',', /extract)
						sub_type = strsplit(sub_str(0), ' ', /extract)
							class = 'null'
							method = 0
							define = 0
							type = strcompress(sub_type(0), /remove)
							name = strcompress(sub_type(1), /remove)
							;\\ See if this is an object method, and get method and object
								colon_match = strpos(name, '::')
								if colon_match ne -1 then begin
									class_sub = strsplit(name, '::', /extract)
									class = strcompress(class_sub(0), /remove)
									name = strcompress(class_sub(1), /remove)
									method = 1
								endif
							;\\ See if this is an object __define
								define_match = strpos(name, '__define')
								if define_match ne -1 then begin
									define = 1
									class_sub = strsplit(name, '__', /extract)
									class = strcompress(class_sub(0), /remove)
								endif

						nargs = n_elements(sub_str) - 1
						if nargs gt 1 then args = strcompress(sub_str(1:*), /remove)
						if nargs eq 1 then args = [strcompress(sub_str(1:*), /remove)]

						this_def = {def_line_range:def_line_range, $
					 				end_line:-1, $
					 				type:type, $
					 				name:name, $
					 				args_ptr:ptr_new(args), $
					 				arg_text_ptr:defs(def_idx).arg_text_ptr, $
					 				def_text_ptr:defs(def_idx).def_text_ptr, $
					 				nargs:nargs, $
					 				method:method, $
					 				class:class, $
					 				define:define, $
					 				fname:fname_with_ext, $
					 				fpath:fpath, $
					 				super_class_ptr:defs(def_idx).super_class_ptr, $
					 				class_tags_ptr:defs(def_idx).class_tags_ptr, $
					 				class_type_ptr:defs(def_idx).class_type_ptr}

						defs(def_idx) = this_def
						def_idx ++
						tmp = defs
						defs = replicate(struc, def_idx + 1)
						defs(0:def_idx-1) = tmp

				endif
			endfor	;\\ Line loop within a file

		;\\ If formatted, extract documentation info
		if formatted then begin
			;\\ Loop through defs
			for dx = 0, def_idx - 1 do begin
				;\\ If this is the object define method, do some stuff...
					if defs(dx).define eq 1 then begin
						super_classes = obj_class(defs(dx).class, count = nsupers, /superclass)
						res = execute('class_data = {' + defs(dx).class + '}')
						;res = execute('class_tags = tag_names({' + defs(dx).class + '})')
						class_tags = tag_names(class_data)
						if nsupers gt 0 then defs(dx).super_class_ptr = ptr_new(super_classes)
						if n_elements(class_tags) gt 0 then begin
							class_tags_str = strarr(n_elements(class_tags))
							class_type_str = strarr(n_elements(class_tags))
							for ccx = 0, n_elements(class_tags) - 1 do begin
								type_str = DocGen_TypeCodeToString(size(class_data.(ccx), /type))
								class_tags_str(ccx) = class_tags(ccx)
								class_type_str(ccx) = type_str
							endfor
							defs(dx).class_tags_ptr = ptr_new(class_tags_str)
							defs(dx).class_type_ptr = ptr_new(class_type_str)
						endif
					endif

				;\\ Get argument documentation
					nargs = defs(dx).nargs
					if nargs gt 0 then begin
						arg_info_str = strarr(nargs)
						arg_line_range = defs(dx).def_line_range(0) + $
										 indgen(defs(dx).def_line_range(1) - defs(dx).def_line_range(0) + 1)
						for ln = arg_line_range(0), arg_line_range(nargs-1) do begin
							cmnt = strsplit(content(ln), ';', /extract)
							if n_elements(cmnt) gt 1 then begin
								cmnt = cmnt(1)
								cmnt = strtrim(strmid(cmnt, 4, strlen(cmnt)-5), 2)
								arg_info_str(ln - arg_line_range(0)) = cmnt
							endif else begin
								arg_info_str(ln - arg_line_range(0)) = 'No Arg Doc'
							endelse
						endfor
						defs(dx).arg_text_ptr = ptr_new(arg_info_str)
						endif
				;\\ Get function documentation - start at def_line_range(0)-1 and work upward
					ln = defs(dx).def_line_range(0) - 1
					cmnt_match = strpos(strtrim(content(ln), 2), ';')
					def_info_str = 0
					while cmnt_match ne -1 do begin
						cmnt = strsplit(content(ln), ';', /extract)
						cmnt = cmnt(0)
						cmnt = strtrim(strmid(cmnt, 4, strlen(cmnt) - 5), 2)
						if size(def_info_str, /type) eq 2 then def_info_str = cmnt else $
							def_info_str = [def_info_str, cmnt]
						ln --
						cmnt_match = strpos(strtrim(content(ln), 2), ';')
					endwhile
					if size(def_info_str, /type) ne 2 then begin
						if n_elements(def_info_str) eq 1 then begin
							def_info_str = [def_info_str]
						endif else begin
							def_info_str = reverse(def_info_str)
						endelse
					endif else begin
						def_info_str = ['No Def Doc']
					endelse
					defs(dx).def_text_ptr = ptr_new(def_info_str)

			endfor ;\\ defs loop
		endif else begin
			for dx = 0, def_idx - 1 do begin
				nargs = defs(dx).nargs
				if nargs gt 0 then begin
					arg_info_str = strarr(nargs)
					arg_info_str(*) = 'No Doc'
				endif
				def_info_str = ['No Doc']
				defs(dx).arg_text_ptr = ptr_new(arg_info_str)
				defs(dx).def_text_ptr = ptr_new(def_info_str)
			endfor
		endelse	;\\ formatted conditional



		;\\ Loop through defs, create formatted file
		do_format = 0
		if (not formatted) then do_format = 1
		if (formatted) and keyword_set(force_format) then do_format = 1
		if keyword_set(latex_only) then do_format = 0
		if do_format then begin
			if not file_test(format_path + dir_struc_path, /dir) then $
				file_mkdir, format_path + dir_struc_path

			openw, handle, format_path + dir_struc_path + path_sep() + fname + suffix, /get
			printf, handle, ';\\ Code formatted by DocGen'
			printf, handle
			if size(includes,/type) ne 2 then begin
				for incx = 0, n_elements(includes) - 1 do printf, handle, includes(incx)
			endif

			for fidx = 0, def_idx - 1 do begin
				printf, handle

				if ptr_valid(defs(fidx).def_text_ptr) then begin
					;\\ Put docced info back in
					def_text = *defs(fidx).def_text_ptr
					def_text = ';\D\<' + def_text + '>'
					for ddx = 0, n_elements(def_text) - 1 do printf, handle, def_text(ddx)
				endif else begin
					;\\ Create doc placeholder, since no docs found
					if defs(fidx).define ne 1 then $
						doc_char = ';\D\< Function/method/pro documentation here >' $
					else $
						doc_char = ';\D\< Class/object documentation here >'
					printf, handle, doc_char
				endelse


				if defs(fidx).method eq 0 then $
					first_str = defs(fidx).type + ' ' + defs(fidx).name $
				else $
					first_str = defs(fidx).type + ' ' + defs(fidx).class + '::' + defs(fidx).name

				if defs(fidx).nargs eq 0 then begin
					str = first_str
				endif else begin
					args = *defs(fidx).args_ptr
					str = first_str +  ', ' + args(0)
				endelse

				args_max_width = max(strlen(args))
				args_docced = 0

				if ptr_valid(defs(fidx).arg_text_ptr) then begin
					;\\ Put docced arg info back in
					args_docced = 1
					arg_text = *defs(fidx).arg_text_ptr
					arg_text = ';\A\<' + arg_text + '>'
				endif

				if defs(fidx).nargs gt 1 then begin
					wht_spc = bytarr(args_max_width - strlen(args(0)) + 3)
					wht_spc(*) = 32B
					wht_spc = string(wht_spc)
					if args_docced then str = str + ', $'  + wht_spc + arg_text(0) $
						else str = str + ', $'  + wht_spc + ';\A\< Arg0 >'
					printf, handle, str
					for kidx = 1, defs(fidx).nargs - 1 do begin
						wht_spc = bytarr(strlen(first_str) + 2)
						wht_spc(*) = 32B
						wht_spc = string(wht_spc)
						astr = wht_spc + args(kidx)
						if kidx ne defs(fidx).nargs - 1 then astr = astr + ', $' $
							else astr = astr + '   '
						wht_spc = bytarr(args_max_width - strlen(args(kidx)) + 3)
						wht_spc(*) = 32B
						wht_spc = string(wht_spc)
						if args_docced then astr = astr + wht_spc + arg_text(kidx) $
							else astr = astr + wht_spc + ';\A\< Arg' + string(kidx, f='(i0)') + ' >'
						printf, handle, astr
					endfor
				endif else begin
					if defs(fidx).nargs ne 0 then begin
						if args_docced then str = str + '  ' + arg_text(0) $
							else str = str + '  ;\A\< Arg0 >'
					endif
					printf, handle, str
				endelse

				for jidx = defs(fidx).def_line_range(1) + 1, defs(fidx).end_line do begin
					printf, handle, content(jidx)
				endfor

			endfor
			close, handle
			free_lun, handle
		endif else begin
			print, 'Code already formatted'
		endelse


		print, fname
		wait, 0.05

		if def_idx gt 0 then begin
			if size(alldefs, /type) eq 2 then begin
				alldefs = defs(0:def_idx-1)
			endif else begin
				alldefs = [alldefs, defs(0:def_idx-1)]
			endelse
		endif

	endfor	;\\ File list loop

	defs = alldefs
	ndefs = n_elements(defs)
	defs = defs(sort(defs.name))

	;\\ Once formatted, loop through defs, produce latex output
	if not keyword_set(format_only) then begin
		;\\ Get a list of any eps files in the output path, to include where appropriate
			pic_list = strlowcase(file_basename(file_search(output_path, '*.png')))
			openw, handle, output_path + 'out.tex', /get

		;\\ Read-in and write-out Write the latex preamble
			preamble = strarr(file_lines(docgen_path + 'docgen_preamble.txt'))
			openr, handle2, docgen_path + 'docgen_preamble.txt', /get
			readf, handle2, preamble
			close, handle2
			free_lun, handle2
			for kidx = 0, n_elements(preamble) - 1 do printf, handle, preamble(kidx)

				;\\ Loop through classes (defines) and methods
				defines = where(defs.define eq 1, ndefines)
				if ndefines gt 0 then begin

					printf, handle, '\chapter*{Classes}'
					printf, handle, '\addcontentsline{toc}{chapter}{Classes}'

					for didx = 0, ndefines - 1 do begin

						ix = defines(didx)

						;\\ Need to escape underscores and backslashes in latex...
							class_name = DocGen_CharacterEscape(defs(ix).class, byte('_'))
							file_name = DocGen_CharacterEscape(defs(ix).fname, byte('_'))
							file_path = DocGen_CharacterReplace(defs(ix).fpath, byte('\'), byte('/'))
							file_path = DocGen_CharacterEscape(file_path, byte('_'))

						;\\ See if there is a matching picture
							pic_match = where(pic_list eq strlowcase(class_name)+'.png', npic)

						if didx gt 0 then printf, handle, '\newpage'
						printf, handle, '\section*{' + class_name + $
										' \label{' + defs(ix).name + '_lab}}'
						printf, handle, '\addcontentsline{toc}{section}{'+class_name+'}'

						if ptr_valid(defs(ix).super_class_ptr) then begin
							super_classes = strjoin(*defs(ix).super_class_ptr, ', ', /single)
							super_classes = DocGen_CharacterEscape(super_classes, byte('_'))
						endif else begin
							super_classes = 'None'
						endelse
							printf, handle, 'Inherits from: \textbf{' + super_classes + '} \newline'

						if ptr_valid(defs(ix).class_tags_ptr) then begin
							class_tags = strlowcase(*defs(ix).class_tags_ptr)
							class_types = strlowcase(*defs(ix).class_type_ptr)
							printf, handle, 'Class Data: '
							printf, handle, '\begin{table}[!h]
							printf, handle, '\begin{small}\vspace{-.1cm}\begin{center}'
							printf, handle, '\begin{tabular}{rl|rl|rl}'
							printf, handle, '\hline'
							for ctx = 0, n_elements(class_tags) - 3, 3 do begin
										printf, handle, '(\textit{' + class_types(ctx) + '})' $
												+ ' & ' + DocGen_CharacterEscape(class_tags(ctx), byte('_')) + $
												'& (\textit{' + class_types(ctx+1) + '})' $
												+ ' & ' + DocGen_CharacterEscape(class_tags(ctx+1), byte('_')) + $
												'& (\textit{' + class_types(ctx+2) + '})' $
												+ ' & ' + DocGen_CharacterEscape(class_tags(ctx+2), byte('_')) + ' \\'
							endfor
							printf, handle, '\hline'
							printf, handle, '\end{tabular}\end{center}\end{small}\end{table}\vspace{-.5cm} \\'

						endif else begin
							class_tags = 'None'
						endelse


						printf, handle, '\textbf{Defined in file:} \newline'
						printf, handle, '\small{' + file_path + '/' + file_name + '}'

						if npic ne 0 then begin
							pic_match = pic_match(0)
							printf, handle, '\begin{figure*}[!h]\centering\includegraphics[width=.5\textwidth]{' + $
											pic_list(pic_match) + '}\end{figure*}'
						endif

						printf, handle, '\begin{center}\rule{1\textwidth}{.02cm}\end{center}'

						methods = where(defs.class eq defs(ix).class and defs.define ne 1, nmethods)
						if nmethods gt 0 then begin
							printf, handle, '\subsection*{METHODS:}'
							methods = defs(methods)
							methods = methods(sort(strlowcase(methods.name)))
							;\\ Put the INIT method first if there is one
							mpt = where(strlowcase(methods.name) eq 'init', nmpt, complement=cmpt)
							if nmpt eq 1 then begin
								methods = methods([mpt,cmpt])
							endif
							for method_idx = 0, nmethods -1 do begin

								type = methods(method_idx).type
								mth_name = DocGen_CharacterEscape(methods(method_idx).name, byte('_'))
								printf, handle, '\subsubsection*{' + '(' + type + ') ' + strupcase(mth_name) + $
										' \label{' + methods(method_idx).class + '::' + methods(method_idx).name + '_lab}}'
										;printf, handle, '\addcontentsline{toc}{subsection}{'+mth_name+'}'

								printf, handle, '\textbf{Method Documentation:} \\'
								if ptr_valid(methods(method_idx).def_text_ptr) then begin
									meth_doc = *methods(method_idx).def_text_ptr
									meth_doc = strjoin(meth_doc, ' ', /single)
									printf, handle, meth_doc + '\newline'
								endif
								;for mx = 0, n_elements(meth_doc) - 1 do begin
								;	printf, handle, meth_doc(mx) + '\newline'
								;endfor


								nargs = methods(method_idx).nargs
								if nargs gt 0 then begin
									args = *methods(method_idx).args_ptr
									args_str = args
									for nx = 0, nargs - 1 do args_str(nx) = DocGen_CharacterEscape(args(nx), byte('_'))
								endif

								if nargs gt 0 then begin
									arg_info = *methods(method_idx).arg_text_ptr
									printf, handle, '\textbf{Arguments:}'
									printf, handle, '\begin{description}'
									for nx = 0, nargs - 1 do begin
										printf, handle, '\vspace{-.15cm}'
										printf, handle, '\item[] \hspace{.5cm} \textit{' + args_str(nx) + $
														'}: ' + arg_info(nx)
									endfor
									printf, handle, '\end{description}'
								endif else begin
									printf, handle, 'Takes no arguments \\'
								endelse

								printf, handle, 'Example Call:'
								printf, handle, '\begin{align*}'
									if type eq 'function' then begin
										call_str = 'result = \mathbf{'+class_name+'}-\hspace{-.15cm}>\mathbf{'+mth_name+'}(&'
									endif else begin
									  	call_str = '\mathbf{'+class_name+'}-\hspace{-.15cm}>\mathbf{'+mth_name+'}'
									endelse
									if nargs gt 0 then begin
										for argidx = 0, nargs - 1 do begin
											arg = args_str(argidx)
											if type eq 'function' and argidx eq 0 then call_str = call_str + arg
											if type eq 'pro' and argidx eq 0 then call_str = call_str + ', \ &' + arg
											if argidx gt 0 and argidx lt nargs - 1 then call_str = call_str + ',\\ \ &' + arg
											if argidx gt 0 and argidx eq nargs - 1 then call_str = call_str + ',\\ \ &' + arg
										endfor
									endif
									if type eq 'function' then call_str = call_str + ')'
									printf, handle, call_str
									printf, handle, '\end{align*}'
									printf, handle, '\begin{center}\rule{.85\textwidth}{.01cm}\end{center}'
							endfor
						endif
					endfor
				endif

					;\\ Loop through functions and procs
					funcs = where(defs.type eq 'function' and defs.method eq 0 and defs.define eq 0, nfuncs)
					procs = where(defs.type eq 'pro' and defs.method eq 0 and defs.define eq 0, nprocs)
					if nfuncs gt 0 then begin
						funcs = defs(funcs)
						printf, handle, '\chapter*{Functions}'
						printf, handle, '\addcontentsline{toc}{chapter}{Functions}'

						for didx = 0, nfuncs - 1 do begin
							fnc_name = DocGen_CharacterEscape(funcs(didx).name, byte('_'))
							file_name = DocGen_CharacterEscape(funcs(didx).fname, byte('_'))
							file_path = DocGen_CharacterReplace(funcs(didx).fpath, byte('\'), byte('/'))
							file_path = DocGen_CharacterEscape(file_path, byte('_'))

								printf, handle, '\section*{'+'('+funcs(didx).type+') '+strupcase(fnc_name) + $
										' \label{' + funcs(didx).name + '_lab}}'
								printf, handle, '\addcontentsline{toc}{section}{'+fnc_name+'}'

								printf, handle, '\textbf{Defined in file:} \newline'
								printf, handle, '\small{' + file_path + '/' + file_name + '} \newline'

								printf, handle, '\textbf{Function Documentation:} \\'
								func_doc = *funcs(didx).def_text_ptr
								for mx = 0, n_elements(func_doc) - 1 do begin
									printf, handle, func_doc(mx) + '\newline'
								endfor

								type = funcs(didx).type
								nargs = funcs(didx).nargs
								if nargs gt 0 then begin
									args = *funcs(didx).args_ptr
									args_str = args
									for nx = 0, nargs - 1 do args_str(nx) = DocGen_CharacterEscape(args(nx), byte('_'))
								endif

								if nargs gt 0 then begin
									arg_info = *funcs(didx).arg_text_ptr
									printf, handle, '\textbf{Arguments:}'
									printf, handle, '\begin{description}'
									for nx = 0, nargs - 1 do begin
										printf, handle, '\vspace{-.15cm}'
										printf, handle, '\item[] \hspace{.5cm} \textit{' + args_str(nx) + $
														'}: ' + arg_info(nx)
									endfor
									printf, handle, '\end{description}'
								endif else begin
									printf, handle, 'Takes no arguments \\'
								endelse
								printf, handle, '\begin{center}\rule{.85\textwidth}{.01cm}\end{center}'
						endfor
					endif

					if nprocs gt 0 then begin
						procs = defs(procs)
						printf, handle, '\chapter*{Procedures}'
						printf, handle, '\addcontentsline{toc}{chapter}{Procedures}'

						for didx = 0, nprocs - 1 do begin
							fnc_name = DocGen_CharacterEscape(procs(didx).name, byte('_'))
							file_name = DocGen_CharacterEscape(procs(didx).fname, byte('_'))
							file_path = DocGen_CharacterReplace(procs(didx).fpath, byte('\'), byte('/'))
							file_path = DocGen_CharacterEscape(file_path, byte('_'))

								printf, handle, '\section*{'+'('+procs(didx).type+') '+strupcase(fnc_name) + $
										' \label{' + procs(didx).name + '_lab}}'
								printf, handle, '\addcontentsline{toc}{section}{'+fnc_name+'}'

								printf, handle, '\textbf{Defined in file:} \newline'
								printf, handle, '\small{' + file_path + '/' + file_name + '} \newline'

								printf, handle, '\textbf{Procedure Documentation:} \\'
								pro_doc = *procs(didx).def_text_ptr
								for mx = 0, n_elements(proc_doc) - 1 do begin
									printf, handle, proc_doc(mx) + '\newline'
								endfor

								type = procs(didx).type
								nargs = procs(didx).nargs
								if nargs gt 0 then begin
									args = *procs(didx).args_ptr
									args_str = args
									for nx = 0, nargs - 1 do args_str(nx) = DocGen_CharacterEscape(args(nx), byte('_'))
								endif

								if nargs gt 0 then begin
									arg_info = *procs(didx).arg_text_ptr
									printf, handle, '\textbf{Arguments:}'
									printf, handle, '\begin{description}'
									for nx = 0, nargs - 1 do begin
										printf, handle, '\vspace{-.15cm}'
										printf, handle, '\item[] \hspace{.5cm} \textit{' + args_str(nx) + $
														'}: ' + arg_info(nx)
									endfor
									printf, handle, '\end{description}'
								endif else begin
									printf, handle, 'Takes no arguments \\'
								endelse
								printf, handle, '\begin{center}\rule{.85\textwidth}{.01cm}\end{center}'
						endfor
					endif
					printf, handle, '\end{document}'
			close, handle
			free_lun, handle
			;\\ Run pdflatex on the file
				cd, output_path, current=old_dir
				spawn, 'pdflatex out.tex'
				spawn, 'pdflatex out.tex'
				spawn, 'pdflatex out.tex'
				spawn, output_path + 'out.pdf', /hide, /nowait
				cd, old_dir
		endif

end


pro DocGen

	docgen_path = 'c:\cal\idlsource\docgen\'
	source_path = 'c:\cal\idlsource\objects\utility\'

	format_path = 'c:\cal\idlsource\objects\'
	output_path = 'c:\cal\idlsource\objects\'

	docgen_suffix = '.pro'

	flist = file_search(source_path, '*.pro', count = nfiles)
	;pts = where(file_basename(flist) ne 'include_source.pro', npts)
	;flist = flist(pts)

	DocGen_Format, docgen_path, source_path, $
				   format_path, output_path, $
				   flist, $
				   docgen_suffix=docgen_suffix, $
				   /latex_only

	;flist = file_search(format_path, '*.pro')
	;DocGen_Format, docgen_path, source_path, format_path, output_path, flist

end