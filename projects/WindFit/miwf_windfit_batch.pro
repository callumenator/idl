
@sdi3k_ncdf
@sdi3k_read_netcdf_data
@multiple_instrument_wind_fit

;\\ BATCH FIT THROUGH A GIVEN DIRECTORY
pro MIWF_WindFit_Batch, in_dirs = in_dirs, $
						file_filter = file_filter, $
						fit_mono = fit_mono, $
						fit_bi = fit_bi, $
						fit_usolve = fit_usolve, $
						force_restore = force_restore, $
						force_redo = force_redo

	common miwf_common, guiData, miscData
	@sdi3k_ncdf_inc


	;\\ Defualt to forcing a re-fit
	if not keyword_set(force_restore) and not keyword_set(force_redo) then begin
		force_redo = 0
		force_restore = 1
	endif

	;\\ Put up a progress/status panel
		stats = {file1:'', $
				 file2:'', $
				 file3:'', $
				 file4:'', $
				 file5:'', $
				 operation:'', $
				 n_groups:0, $
				 current_group:0 }

	if size(guiData, /type) eq 0 then begin
		guiData = {base:0, $
				   font:'Ariel*16'}
	endif

		base = widget_base(group_leader = guiData.base, col = 2, title = 'MIWF Batch Blend')
		table = widget_table(base, value = stats, /column_major, font=guiData.font, $
							 row_labels = tag_names(stats), column_width = 500)
		widget_control, /realize, base

	if not keyword_set(file_filter) then begin
		file_filter = ['*sky*.nc', '*.sky']
	endif

	if not keyword_set(in_dirs) then begin
		in_dirs = [where_is('poker_data'), where_is('gakona_data')]
	endif


	files = ['']
	for k = 0, n_elements(in_dirs) - 1 do begin
		files = [files, file_search(in_dirs[k] + file_filter, count = nfiles)]
	endfor
	if n_elements(files) eq 1 then goto, EXIT_WINDFITBLENDBATCH
	files = files[1:*]
	nfiles = n_elements(files)


	str = {nstations:0, files:ptr_new()}
	list = replicate(str, 1)
	while n_elements(files) gt 0 do begin

		station = strmid(file_basename(files), 0, 3)
		year = fix(strmid(file_basename(files), 4, 4))
		dayno = fix(strmid(file_basename(files), 9, 3))
		lambda = fix(strmid(file_basename(files), 19, 3))

		if lambda[0] ne '630' then begin
			files = delete_elements(files, [0])
			if size(files, /n_dimensions) eq 0 then break
			continue
		endif

		cFile = files[0]
		match = where( station ne station[0] and $
					   year eq year[0] and $
					   dayno eq dayno[0] and $
					   lambda eq lambda[0], nmatch )

		nStruc = str
		nStruc.nstations = nmatch + 1

		if nmatch gt 0 then nStruc.files = ptr_new([files[ [0, match] ]]) $
			else nStruc.files = ptr_new([files[ [0] ]])

		list = [list, nStruc]

		if nmatch gt 0 then files = delete_elements(files, [0, match]) $
			else files = delete_elements(files, [0])

		if size(files, /n_dimensions) eq 0 then break
	endwhile

	list = list[1:*]

	for k = 0, n_elements(list) - 1 do begin

			ncid_index = {filename: "bound_to_not_exist", $
                       ncid: -1, $
              write_allowed: 0, $
                       xdim: 256, $
                       ydim: 256, $
                   zone_map: intarr(1024, 1024), $
                 zmap_valid: 0}


		MIWF_ClearData

		miscData.dataFilenames[0:list[k].nstations-1] = file_basename((*list[k].files))
		miscData.dataFullpaths[0:list[k].nstations-1] = (*list[k].files)
		widget_control, guiData.dataListList, set_value = miscData.dataFilenames

		for l = 0, list[k].nstations - 1 do stats.(l) = file_basename((*list[k].files)[l])
		for l = list[k].nstations, 4 do stats.(l) = 'Empty'
		stats.n_groups = n_elements(list)
		stats.current_group = k + 1
		widget_control, set_value = stats, table

		for l = 0, list[k].nstations - 1 do begin
			miscData.nStations = l + 1
			print, 'Loading ' + miscData.dataFullpaths[l]
			MIWF_LoadData, l, return_code
			if return_code eq 'no_wind_data' then begin
				goto, MIWF_BATCH_SKIP_THIS_GROUP
			endif
		endfor


		if list[k].nstations eq 1 then begin
			if keyword_set(fit_mono) then begin
				stats.operation = 'MonoStatic Fitting...'
				widget_control, set_value = stats, table

				MIWF_FitMonoStatic, force_redo = force_redo, force_restore = force_restore
				MIWF_Refresh
			endif
			continue
		endif

		if list[k].nstations eq 2 then begin

			if keyword_set(fit_bi) then begin
				stats.operation = 'BiStatic Fitting...'
				widget_control, set_value = stats, table

				MIWF_FitBiStatic, force_redo = force_redo, force_restore = force_restore

				if keyword_set(fit_usolve) then begin
					MIWF_FitBiStatic_USolve, force_redo = 1
				endif

				MIWF_Refresh
			endif

			if keyword_set(fit_mono) then begin
				stats.operation = 'MonoStatic Fitting...'
				widget_control, set_value = stats, table

				MIWF_FitMonoStatic, force_redo = force_redo, force_restore = force_restore
				MIWF_Refresh
			endif
			continue
		endif

		if list[k].nstations ge 3 then begin

			continue
		endif

		MIWF_BATCH_SKIP_THIS_GROUP:
	endfor

EXIT_WINDFITBLENDBATCH:
	widget_control, /destroy, base

end