
pro sdi_monitor_analysis

	common sdi_monitor_common, global, persistent

	cmd_str_0 = 'start /b /min c:\rsi\idl62\bin\bin.x86\idlde -IDL_WDE_SPLASHSCREEN 0 -e ' + '"' + 'sdi_analysis'
	in_files = file_search(global.in_dir + '{HRP,PKR,MAW,TLK,KTO}*SKY*.nc', count = n_in)


	;\\ First check to see if any current analysis jobs have finished
	running = where(global.analysis_jobs.free_list eq 0, nrunning)
	for i = 0, nrunning - 1 do begin
		index = running[i]
		var = shmvar(global.analysis_jobs.shmids[index])
		var = string(var)
		status = strmid(var, 10, strlen(var))
		last_time = strmid(var, 0, 10)
		task_age = long(systime(/sec)) - long(last_time)

		;\\ Get widget label id
		uname = global.analysis_jobs.site_codes[index]
		id_base = widget_info(global.status_base, find_by_uname = uname + '_base')
		id_status = widget_info(global.status_base, find_by_uname = uname + '_status')


		task_killed = 0
		;\\ If the task is too old, kill it
		if task_age/3600. gt 3 then begin ;\\ older than 3 hours, kill it
			spawn, 'taskkill /PID ' + string(global.analysis_jobs.process_ids[index], f='(i0)') + ' /T /F'
			status = 'finished'
			task_killed = 1

			;\\ Log this problem
			sdi_monitor_log_append, 'Killed process because it was too old: ' + file_basename(global.analysis_jobs.site_codes[index])
		endif

		if status eq 'finished' then begin
			;\\ Analysis job has finished running


			;\\ Unmap the shared memory
			var = 0
			shmunmap, global.analysis_jobs.shmids[index]


			;\\ Log job finished
			if task_killed eq 0 then begin
				newLine = string([13B,10B])
				sdi_monitor_log_append, 'Finished daily analysis of ' + file_basename(global.analysis_jobs.site_codes[index]) + $
										' data:' + newLine + '      Sky files processed:' + newLine + $
										strjoin('        ' + *global.analysis_jobs.file_lists[index], newLine)
			endif


			;\\ Edit the free list
			global.analysis_jobs.free_list[index] = 1
			global.analysis_jobs.shmids[index] = ''
			global.analysis_jobs.site_codes[index] = ''
			global.analysis_jobs.process_ids[index] = 0
			ptr_free, global.analysis_jobs.file_lists[index]


			;\\ Destroy the label
			widget_control, id_base, /destroy
			widget_control, id_status, /destroy


			;\\ Do other stuff here


		endif else begin

			;\\ If not finished, update the status
			widget_control, set_value = '   Status: ' + status + $
							' (Age: ' + string(task_age, f='(i0)') + ' secs)', id_status

		endelse

	endfor

	;\\ Update the jobs running label
	running = where(global.analysis_jobs.free_list eq 0, nrunning)
	widget_control, set_value = 'Analysis Processes Running: ' + string(nrunning, f='(i0)'), $
					widget_info(global.status_base, find_by_uname = 'status_analyses_running')

	;\\ Now check to see if we can start any new jobs

	;\\ Separate by site code
	for i = 0, n_in - 1 do begin
		sdi3k_read_netcdf_data, in_files[i], meta = meta
		res = execute('append, "' + in_files[i] + '", ' + meta.site_code + '_files')
		append, meta.site_code, site_codes
	endfor


	for i = 0, n_elements(site_codes) - 1 do begin

		match = where(site_codes[i] eq global.analysis_jobs.site_codes, nmatch)
		if nmatch ne 0 then continue


		;\\ List of sky files to analyze, call it 'files_arr'
		res = execute('files_arr = ' + site_codes[i] + '_files')


		;\\ Where to move files once analyzed
		 move_to_dir = sdi_monitor_get_directory(site_codes[i])


		;\\ Find the first free index
		freeidx = where(global.analysis_jobs.free_list eq 1, nfree)
		if (nfree eq 0) then continue
		freeidx = min(freeidx)


		;\\ Unset this free index
		global.analysis_jobs.free_list[freeidx] = 0


		;\\ Enter the current site code and file list
		global.analysis_jobs.site_codes[freeidx] = site_codes[i]
		global.analysis_jobs.file_lists[freeidx] = ptr_new(files_arr)


		;\\ Create a shared memory id and map it
		shmid = 'analysis_job_' + string(freeidx, f='(i0)')
		global.analysis_jobs.shmids[freeidx] = shmid
		shmmap, shmid, /byte, global.analysis_jobs.buffer_length


		;\\ Spawn the new process to analyse the files
		ipc_info_str = '{shmid:' + "'" + shmid + "'" + ', maxlength:' + string(global.analysis_jobs.buffer_length, f='(i0)') + '}'
		skylist_str = "[" + strjoin("'" + files_arr + "'", ', ') + "]"
		move_to_str = 'move_to = '  + "'" + move_to_dir + "'"
		cmd_str = cmd_str_0 + ', ' + "''" + ', skylist = ' + skylist_str + ', ipc_info = ' + ipc_info_str + ', ' + move_to_str + '"'


		;\\ Get current tasks running
		curr_tasks = get_tasklist(image = 'idlde.exe')
		spawn, cmd_str, /nowait, /hide ;, pid=pid returns wrong PID


		;\\ Compare with tasks now to find PID of new process
		now_tasks = get_tasklist(image = 'idlde.exe')
		for ii = 0, n_elements(now_tasks) - 1 do begin
			match = where(now_tasks[ii].name eq curr_tasks.name and $
						  now_tasks[ii].pid eq curr_tasks.pid, nmatch)
			if nmatch eq 0 then begin
				pid = now_tasks[ii].pid
				break
			endif
		endfor
		global.analysis_jobs.process_ids[freeidx] = pid


		;\\ Create a widget label
		uname = site_codes[i]
		name = 'Job ' + string(freeidx, f='(i0)') + ', ' + site_codes[i] + ' (PID = ' + string(pid, f='(i0)') + ')'
		label = widget_label(global.status_base, value = name, font=global.font, uname = uname + '_base')
		label = widget_label(global.status_base, value = '   Status:', font=global.font, uname = uname + '_status', xs = 500)


	endfor

end