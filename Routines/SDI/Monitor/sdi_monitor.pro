
;\\ This part is for testing, it simulates an instrument creating a snapshot
pro sdi_monitor_make_snapshot, index = index

	dir = 'F:\SDIData\'

	files = ['gakona\HRP_2011_029_Elvey_630nm_Red_Sky_Date_01_29.nc', $
			 'gakona\HRP_2010_019_Elvey_Laser6328_Red_Cal_Date_01_19.nc', $
			 'poker\PKR 2010_309_Poker_630nm_Red_Sky_Date_11_05.nc', $
			 'poker\PKR 2010_046_Poker_558nm_Green_Sky_Date_02_15.nc', $
			 'poker\PKR 2010_092_Poker_Laser6328_Red_Cal_Date_04_02.pf' ]


	if not keyword_set(index) then index = 0

	for j = 0, n_elements(files) - 1 do begin

		sdi3k_read_netcdf_data, dir + files[j], spex=spex, meta=meta

		out_dir = 'C:\RSI\IDLSource\NewAlaskaCode\Routines\SDI\Monitor\'

		index = index < (meta.maxrec - 1)

		snapshot = {spectra:spex[index].spectra, $
					start_time:spex[index].start_time, $
					end_time:spex[index].end_time, $
					scans:spex[index].scans, $
					scan_channels:meta.scan_channels, $
					nzones:meta.nzones, $
					rads:[0.0, meta.zone_radii[0:meta.rings-1]]/100., $
					secs:meta.zone_sectors[0:meta.rings-1], $
					oval_angle:meta.oval_angle, $
					wavelength:meta.wavelength_nm * 10, $
					site_code:meta.site_code}

		save, filename = out_dir + meta.site_code + '_' + string(meta.wavelength_nm*10., f='(i04)') + $
				'_snapshot.idlsave', snapshot, /compress

	endfor

end

;\\ Return the status structure for a given job
function sdi_monitor_job_status, job

	common sdi_monitor_common, global, persistent

	match = (where(strlowcase(global.job_status.name) eq strlowcase(job), nmatch))[0]
	return, global.job_status[match]
end

;\\ Update the last run field of a given job
pro sdi_monitor_job_timeupdate, job

	common sdi_monitor_common, global, persistent

	match = (where(strlowcase(global.job_status.name) eq strlowcase(job), nmatch))[0]
	global.job_status[match].last_run = systime(/sec)
end

;\\ Return the time in seconds since last job run
function sdi_monitor_job_timelapse, job

	common sdi_monitor_common, global, persistent

	match = (where(strlowcase(global.job_status.name) eq strlowcase(job), nmatch))[0]
	return, systime(/sec) - global.job_status[match].last_run
end

;\\ Return the data directory for a given site code
function sdi_monitor_get_directory, site_code

	common sdi_monitor_common, global, persistent

	match = where(site_code eq global.data_directories.site_code, nmatch)
	if (nmatch eq 0) then begin
		return, 'F:\'
	endif else begin
		return, global.data_directories[match].directory
	endelse
end

;\\ Append a message string to the log
pro sdi_monitor_log_append, msg_string

	common sdi_monitor_common, global, persistent

	logName = global.home_dir + '\Log\' + 'TaskLog_' + dt_tm_fromjs(dt_tm_tojs(systime()), format='Y$_doy$') + '.txt'
	openw, hnd, logName, /get, /append
	printf, hnd, systime() + ' -> ' + msg_string
	free_lun, hnd
end

;\\ Check to see if we need to email the current log (once per day)
pro sdi_monitor_log_manage

	common sdi_monitor_common, global, persistent

	logName = global.home_dir + '\Log\' + 'TaskLog_' + dt_tm_fromjs(dt_tm_tojs(systime()), format='Y$_doy$') + '.txt'
	if file_test(logName) eq 0 then return

	if (systime(/sec) - global.log_email_sent_at)/3600. gt 24. then begin
		if file_lines(logName) gt 0 then begin
			logtext = strarr(file_lines(logName))
			openr, hnd, logName, /get
			readf, hnd, logtext
			free_lun, hnd
		  	sdi_monitor_send_email, global.email_list, 'SDI Monitor Log', strjoin(logtext, string(13B), /single)
		endif else begin
			sdi_monitor_send_email, global.email_list, 'SDI Monitor Log', 'Log file is empty'
		endelse
		global.log_email_sent_at = systime(/sec)
	endif
end

pro sdi_monitor_send_email, addresses, subject, body

	common sdi_monitor_common, global, persistent

	for k = 0, n_elements(addresses) - 1 do begin
  		cmd = 'cd ' + global.home_dir + ' &'
    	cmd += ' bmail.exe -s fuzz.gi.alaska.edu -t ' + addresses[k]
    	cmd += ' -f sdimonitor@gi.alaska.edu '
    	cmd += '-a "' + subject + '"'
    	cmd += ' -b "' + body + '"'
    	spawn, cmd, /nowait
  	endfor

end


pro sdi_monitor_event, event

	common sdi_monitor_common, global, persistent


	;\\ persistent = {snapshots:ptr([snapshot struc]), $
	;\\				  zonemaps:ptr([zonemap struc]), $
	;\\				  calibrations:ptr([snapshot struc]) }
	;\\ snapshots = {site id, spectra:ptr, fits:ptr, start/end, scans, site, wavelength, zonemap_index}
	;\\ zonemaps = {zmap id, zonemap, centers:ptr, rads:ptr, secs:ptr}
	;\\ calibrations = {site id, spectra:ptr, fits:ptr, start/end, scans, site, wavelength, zonemap_index}


	widget_control, get_uval = uval, event.id


	;\\ Widget events from uval-containing widgets
	if size(uval, /type) eq 8 then begin

		case uval.tag of

			'file_background': begin
				pick_base = widget_base(title = 'Select Background Parameter', /floating, group=global.base_id, col=1)
				list = ['Temperature', 'Intensity', 'SNR/Scan', 'Chi Squared']
				for j = 0, n_elements(list) - 1 do begin
					btn = widget_button(pick_base, value=list[j], uval={tag:'pick_background', $
										select:list[j], base:pick_base}, font='Ariel*15*Bold')
				endfor
				widget_control, /realize, pick_base
				xmanager, 'sdi_monitor', pick_base, event = 'sdi_monitor_event'
			end

			'file_jobs': begin
				pick_base = widget_base(title = 'Set Job Status', /floating, group=global.base_id, col=1, /nonexclusive)
				list = global.job_status.name
				for j = 0, n_elements(list) - 1 do begin
					btn = widget_button(pick_base, value=list[j], uval={tag:'toggle_job', $
										select:list[j], base:pick_base}, font='Ariel*15*Bold')
					widget_control, btn, set_button = global.job_status[j].active
				endfor
				widget_control, /realize, pick_base
				xmanager, 'sdi_monitor', pick_base, event = 'sdi_monitor_event'
			end

			'pick_background': begin
				global.background_parameter = uval.select
				widget_control, /destroy, uval.base
			end

   			'toggle_job': begin
				widget_control, get_uval = uval, event.id
				match = (where(global.job_status.name eq uval.select, nmatch))[0]
				global.job_status[match].active = event.select

				monitor_jobs = where(global.job_status.active eq 1, njobs)
				if (njobs gt 0) then begin
					monitor_jobs_label = string(njobs, f='(i0)') + string([13b,10b]) + $
										 strjoin('     ' + global.job_status[monitor_jobs].name, string([13b,10b]))
				endif else begin
					monitor_jobs_label = 'None'
				endelse
				id = widget_info(global.base_id, find = 'status_jobs_running')
				widget_control, set_value = 'Monitor Jobs Running: ' + monitor_jobs_label , ysize = 15*(njobs+1), id
			end

			else:
		endcase

		return
	endif


	;\\ Base widget resize event
	if tag_names(event, /structure_name) eq 'WIDGET_BASE' then begin

		base_geom = widget_info(global.base_id, /geom)
		for k = 0, n_elements(global.draw_id) - 1 do begin
			draw_geom = widget_info(global.draw_id[k], /geom)
			new_x = draw_geom.scr_xsize + (base_geom.scr_xsize - global.base_geom.scr_xsize)
			new_y = draw_geom.scr_ysize + (base_geom.scr_ysize - global.base_geom.scr_ysize)
			widget_control, scr_xsize=new_x, scr_ysize=new_y, global.draw_id[k]
		endfor

		global.base_geom = base_geom

	endif



	if tag_names(event, /structure_name) eq 'WIDGET_TIMER' then begin

		global.free_index_0 ++


		;\\ Queue next timer event
			widget_control, timer = global.timer_interval, global.base_id


		;\\ Check on running daily analysis jobs, and start new analysis tasks
			sdi_monitor_analysis


		;\\ Manage the log (check if we need to open a new one, email the current one, etc)
			sdi_monitor_log_manage


		;\\ Read snapshot files in in_dir
			in_files = file_search(global.in_dir + '*snapshot*idlsave', count = n_in, /test_regular)
			if n_in eq 0 then goto, MONITOR_FILE_LOOP_END


		;\\ Only take the ones that are more than N seconds old, to (try to) prevent read errors
			file_age = systime(/sec) - (file_info(in_files)).mtime
			keep = where(file_age gt global.min_file_age, n_keep)

			if n_keep gt 0 then begin
				in_files = in_files[keep]
				n_in = n_keep
			endif else begin
				goto, MONITOR_FILE_LOOP_END
			endelse


			for k = 0, n_in - 1 do begin


				;\\ Handle read errors (these do occur)
				catch, error_status
				if error_status ne 0 then begin
					print, 'Error index: ', error_status
					print, 'Error message: ', !ERROR_STATE.MSG
					catch, /cancel
					;\\ If restoring failed, log the error, and go on to the next file
					eof_error = strpos(!ERROR_STATE.MSG, 'RESTORE: End of file encountered.') ne -1
					if eof_error eq 1 then begin
						openw, hnd, global.home_dir + '\Log\EOF_ErrLog.txt', /get, /append
						printf, hnd, systime(/ut) + ' - Failed with: ' + !ERROR_STATE.MSG
						free_lun, hnd
						continue
					endif
				endif

				restore, in_files[k]

				catch, /cancel


				;\\ Build up unique id's for this snapshot site, wavelength, and zonemap type
					site_lambda_id = strupcase(snapshot.site_code) + '_' + $
						 			 string(snapshot.wavelength, f='(i04)')
					zmap_type_id = strjoin(string(snapshot.rads*100, f='(i0)')) + '_' + $
						 		   strjoin(string(snapshot.secs, f='(i0)'))

					have_zmap_type = -1
					have_site_lambda = -1
					is_new_snapshot = 0


				;\\ Do we have previous data for this zonemap type?
					if ptr_valid(persistent.zonemaps) ne 0 then begin
						ids = (*persistent.zonemaps).id
						match = where(strmatch(ids, zmap_type_id) eq 1, n_matching)
						if n_matching eq 1 then have_zmap_type = match[0]
					endif


				;\\ If we have the zmap type, do we have site and lambda?
					if have_zmap_type ne -1 then begin
						ids = (*persistent.snapshots).id
						match = where(strmatch(ids, site_lambda_id) eq 1 and $
								  	  (*persistent.snapshots).zonemap_index eq have_zmap_type, n_matching)
						if n_matching eq 1 then have_site_lambda = match[0]
					endif


				;\\ If we have both zmap type and site lambda, is this a new snapshot?
					if have_zmap_type ne -1 and have_site_lambda ne -1 then begin
						curr_snapshot = (*persistent.snapshots)[have_site_lambda]
						if curr_snapshot.start_time ne snapshot.start_time and $
						   curr_snapshot.end_time ne snapshot.end_time then is_new_snapshot = 1
					endif


				;\\ If the snapshot is not a new one, we are done with this file
					if have_zmap_type ne -1 and $
					   have_site_lambda ne -1 and $
					   is_new_snapshot eq 0 then continue


				;\\ If this is a new zonemap type, make the zonemap, get zone centers, and add entry
					if have_zmap_type eq -1 then begin
						zonemap = zonemapper(global.zmap_size, global.zmap_size, $
											[global.zmap_size, global.zmap_size]/2., $
											 snapshot.rads, snapshot.secs, 0)
						zone_centers = get_zone_centers(zonemap)

						pix_per_zone = pixels_per_zone( 0, /relative, zonemap=zonemap)

						zmap_entry = {id:zmap_type_id, $
									  zonemap:zonemap, $
									  centers:ptr_new(zone_centers), $
									  rads:ptr_new(snapshot.rads), $
									  secs:ptr_new(snapshot.secs), $
									  pix_per_zone:ptr_new(pix_per_zone) }

						if ptr_valid(persistent.zonemaps) eq 0 then begin
							persistent.zonemaps = ptr_new([zmap_entry])
						endif else begin
							*persistent.zonemaps = [*persistent.zonemaps, zmap_entry]
						endelse
						have_zmap_type = n_elements(*persistent.zonemaps) - 1
					endif


				;\\ Create the new snapshot data entry
					snapshot_entry = {id:site_lambda_id, $
									  zonemap_index:have_zmap_type, $
									  spectra:ptr_new(snapshot.spectra), $
									  fits:ptr_new(), $
									  start_time:snapshot.start_time, $
								 	  end_time:snapshot.end_time, $
									  scans:snapshot.scans, $
									  scan_channels:snapshot.scan_channels, $
									  nzones:snapshot.nzones, $
									  wavelength:snapshot.wavelength, $
							  		  site_code:snapshot.site_code }

					if snapshot.wavelength eq 6328 then begin
						calibration_entry = {id:site_lambda_id, $
										  zonemap_index:have_zmap_type, $
										  spectra:ptr_new(snapshot.spectra), $
										  fits:ptr_new(), $
										  start_time:snapshot.start_time, $
									 	  end_time:snapshot.end_time, $
										  scans:snapshot.scans, $
										  scan_channels:snapshot.scan_channels, $
										  nzones:snapshot.nzones, $
										  wavelength:snapshot.wavelength, $
								  		  site_code:snapshot.site_code }
					endif

				;\\ If we dont have site and lambda, append to the snapshots array
					if have_zmap_type ne -1 and have_site_lambda eq -1 then begin
						if ptr_valid(persistent.snapshots) eq 0 then begin
							persistent.snapshots = ptr_new([snapshot_entry])
						endif else begin
							*persistent.snapshots = [*persistent.snapshots, snapshot_entry]
						endelse

						;\\ If it is a calibration wavelength, put it in the calibrations tag as well
						if snapshot.wavelength eq 6328 then begin
							if ptr_valid(persistent.calibrations) eq 0 then begin
								persistent.calibrations = ptr_new([calibration_entry])
							endif else begin
								*persistent.calibrations = [*persistent.calibrations, calibration_entry]
							endelse
						endif
					endif


				;\\ If we do have site and lambda, replace the existing info with new snapshot
					if have_zmap_type ne -1 and have_site_lambda ne -1 then begin
						;\\ Free the pointer to the previous spectra and fits
						ptr_free, (*persistent.snapshots)[have_site_lambda].spectra
						ptr_free, (*persistent.snapshots)[have_site_lambda].fits
						(*persistent.snapshots)[have_site_lambda] = snapshot_entry

						;\\ If it is a calibration wavelength, check to see if it is the first one for the night
						if snapshot.wavelength eq 6328 then begin

							if ptr_valid(persistent.calibrations) eq 0 then begin
								persistent.calibrations = ptr_new([calibration_entry])
							endif else begin
								match = where((*persistent.calibrations).site_code eq snapshot_entry.site_code and $
											  (*persistent.calibrations).zonemap_index eq have_zmap_type, n_match)
								if n_match eq 1 then begin
									idx = match[0]
									if (snapshot.start_time - curr_snapshot.start_time) gt 4*3600. then begin
										ptr_free, (*persistent.calibrations)[idx].spectra
										ptr_free, (*persistent.calibrations)[idx].fits
										(*persistent.calibrations)[idx] = calibration_entry
									endif
								endif
							endelse
						endif
					endif


				;\\ Save the current persistent data
					save, filename = global.persistent_file, persistent

			endfor


	MONITOR_FILE_LOOP_END:

		;\\ Check to see if any of the snapshots need spectral fits
		if size(persistent, /type) eq 0 then return
		if ptr_valid(persistent.snapshots) eq 0 then return
		if ptr_valid(persistent.calibrations) eq 0 then return


		;\\ First look for any calibrations that need fitting (why fit them?)
		calibrations = *persistent.calibrations
		fit_these = where(ptr_valid(calibrations.fits) eq 0 and $
						  calibrations.wavelength eq 6328, n_fit)

		for k = 0, n_fit - 1 do begin
			fits = sdi_monitor_fitspex(calibrations[fit_these[k]], calibrations[fit_these[k]], /calibration)
			ptr_free, (*persistent.calibrations)[fit_these[k]].fits  ;\\ this should be redundant
			(*persistent.calibrations)[fit_these[k]].fits = ptr_new(fits)
		endfor

		;\\ Now fit the snapshots
		snapshots = *persistent.snapshots
		fit_these = where(ptr_valid(snapshots.fits) eq 0 and $
						  snapshots.wavelength ne 6328 and $
						  snapshots.wavelength ne 5435 and $
						  snapshots.wavelength ne 7320 and $
						  snapshots.wavelength ne 5890, n_fit)

		for k = 0, n_fit - 1 do begin

			;\\ Find the corresponding instrument profiles for this snapshot (if we have them)
			ip_id = strupcase(snapshots[fit_these[k]].site_code) + '_6328'
			match = where(calibrations.id eq ip_id and $
						  calibrations.zonemap_index eq snapshots[fit_these[k]].zonemap_index, n_matching)

			if n_matching eq 1 then begin
				ip_snapshot = calibrations[match[0]]
				fits = sdi_monitor_fitspex(snapshots[fit_these[k]], ip_snapshot)
				ptr_free, (*persistent.snapshots)[fit_these[k]].fits ;\\ this should be redundant
				(*persistent.snapshots)[fit_these[k]].fits = ptr_new(fits)

				;\\ Once they have been fit, new snapshots can be added to the timeseries
				if (snapshots[fit_these[k]].wavelength eq 5577 or $
				    snapshots[fit_these[k]].wavelength eq 6300) then begin

					save_name = global.home_dir + '\Timeseries\' + snapshots[fit_these[k]].id + '_timeseries.idlsave'
					if file_test(save_name) eq 1 then begin
						restore, save_name
						restored = 1
					endif else begin
						restored = 0
					endelse

					snap = (*persistent.snapshots)[fit_these[k]]
					zone_dims = snap.nzones
					chann_dims = snap.scan_channels

					new_entry = {fits:*snap.fits, $
								 start_time:snap.start_time, $
								 end_time:snap.end_time, $
								 scans:snap.scans }

					if restored eq 0 then begin
						series = new_entry
						zmap = (*persistent.zonemaps)[snap.zonemap_index]
						zonemap_info = {zonemap:zmap.zonemap, $
										centers:*zmap.centers, $
										rads:*zmap.rads, $
										secs:*zmap.secs }
						meta = {zonemap_info:zonemap_info, $
								scan_channels:snap.scan_channels, $
								wavelength:snap.wavelength, $
								site_code:snap.site_code, $
								gap_mm:(*snap.fits).gap_mm}
					endif else begin
						series = [series, new_entry]
					endelse

					if n_elements(series) gt global.max_timeseries_length then begin
						series = series[global.timeseries_chop:*]
					endif

					save, filename = save_name, series, meta

				endif ;\\ matching wavelengths for time series
			endif ;\\ found insprofs
		endfor ;\\ loop over snapshots

		ftp = 0
		image_names = 0
		draw_ids = ''
		;\\ Plot the current snapshots
		status = sdi_monitor_job_status('snapshots')
		if (status.active eq 1) and (sdi_monitor_job_timelapse('snapshots') gt 60) then begin
			sdi_monitor_job_timeupdate, 'snapshots'
			sdi_monitor_snapshots, oldest_snapshot = global.oldest_snapshot
			append, 'sdi_monitor', image_names
			append, global.draw_id[0], draw_ids
			ftp = 1
		endif
		;\\ Plot the current timeseries
		status = sdi_monitor_job_status('timeseries')
		if (status.active eq 1) and (sdi_monitor_job_timelapse('timeseries') gt 120) then begin
			sdi_monitor_job_timeupdate, 'timeseries'
			sdi_monitor_timeseries
			append, 'sdi_timeseries', image_names
			append, global.draw_id[1], draw_ids
			append, 'sdi_temp_series', image_names
			append, global.draw_id[2], draw_ids
			ftp = 1
		endif
		;\\ Plot the current windfields
		status = sdi_monitor_job_status('windfields')
		if (status.active eq 1) and (sdi_monitor_job_timelapse('windfields') gt 120) then begin
			sdi_monitor_job_timeupdate, 'windfields'
			sdi_monitor_windfields
			append, 'sdi_windfields', image_names
			append, global.draw_id[3], draw_ids
			ftp = 1
		endif
		;\\ Run multistatic analyses
		status = sdi_monitor_job_status('multistatic')
		if (status.active eq 1) and (sdi_monitor_job_timelapse('multistatic') gt 120) then begin
			sdi_monitor_job_timeupdate, 'multistatic'
			sdi_monitor_multistatic
			;append, 'sdi_windfields', image_names
			;append, global.draw_id[3], draw_ids
			;ftp = 1
		endif




		;\\ FTP images
		if ftp eq 1 then begin
			for j = 0, n_elements(draw_ids) - 1 do begin

				;\\ Here we get the actual image from the widget draw window
				widget_control, get_value = wind_id, draw_ids[j]
				wset, wind_id
				image = tvrd(/true)

				;\\ Write out the file
				crtime = convert_js(dt_tm_tojs(systime(/ut)))
				tstamp = string(crtime.sec, f='(i05)')
				image_name = global.out_dir + '\' + image_names[j] + '_' + tstamp + '.png'
				write_png, image_name, image

				;\\ FTP it
				openw, hnd, global.home_dir + 'ftp_batch.bat', /get
				for k = 0, n_elements(global.ftp_batch) - 1 do printf, hnd, global.ftp_batch[k]
				printf, hnd, 'put ' + image_name + ' ' + image_names[j] + '.png'
				printf, hnd, 'quit'
				free_lun, hnd

				openw, hnd, global.home_dir + 'command_batch.bat', /get
				printf, hnd, 'ftp -s:' + global.home_dir + 'ftp_batch.bat'
				printf, hnd, 'del ' + image_name
				free_lun, hnd

				spawn, global.home_dir + '\command_batch.bat', /hide
			endfor
		endif

	endif ;\\ widget timer events

	heap_gc
end



;\\ Cleanup
pro sdi_monitor_cleanup, arg

	common sdi_monitor_common, global, persistent

	persistent = 0
	heap_gc, /ptr, /verbose
	print, ptr_valid()

end



;\\ Main routine
pro sdi_monitor

	common sdi_monitor_common, global, persistent

	in_dir = 'C:\FTP\'
	home_dir = 'C:\RSI\IDLSource\NewAlaskaCode\Routines\SDI\Monitor\'
	out_dir = home_dir


	;\\ Recipient list for email updates
	email_list = ['callumenator@gmail.com']


	;\\ Control where analyzed data are moved to
	data_directories = [{site_code:'MAW', directory:'F:\SDIData\Mawson\'}, $
						{site_code:'PKR', directory:'F:\SDIData\Poker\'}, $
						{site_code:'HRP', directory:'F:\SDIData\Gakona\'}, $
						{site_code:'TLK', directory:'F:\SDIData\Toolik\'}, $
						{site_code:'KTO', directory:'F:\SDIData\Kaktovik\'} ]


	;\\ Control which jobs will be run
	job_status = [{name:'snapshots', active:1, last_run:0D}, $
				  {name:'timeseries', active:1, last_run:0D}, $
				  {name:'windfields', active:1, last_run:0D}, $
				  {name:'multistatic', active:1, last_run:0D} ]


	ftp_batch = ['o fulcrum.gi.alaska.edu', 'callum', 'B1_static', 'cd ../Downrange_SDI/sdi_monitor']

	zmap_size = 200.
	min_file_age = 5 ;\\ age in seconds
	timer_interval = 2
	max_timeseries_length = 1000
	timeseries_chop = 100
	oldest_snapshot = 10 ;\\ in days, snapshots older than this are greyed out

	;\\ Restore persistent data if any
		persistent_file = home_dir + 'persistent.idlsave'
		if file_test(persistent_file) then begin
			restore, persistent_file
		endif else begin
			persistent = {snapshots:ptr_new(), $
					  	  zonemaps:ptr_new(), $
					  	  calibrations:ptr_new() }
		endelse


	font = 'Ariel*Bold*15'
	base = widget_base(col = 1, title='SDI Monitor', /TLB_SIZE_EVENTS, mbar=menu )
	tab = widget_tab(base)
	tab_status_base = widget_base(tab, title = 'Status', col = 1, /base_align_left)
	tab_0_base = widget_base(tab, title = 'Spnashots', col = 1)
	tab_1_base = widget_base(tab, title = 'Timeseries', col = 1)
	tab_2_base = widget_base(tab, title = 'ForMark', col = 1)
	tab_3_base = widget_base(tab, title = 'Windfields', col = 1)
	file_menu = widget_button(menu, value = 'File')
	file_plugin_status = widget_button(file_menu, value = 'Set Job Status ', uval={tag:'file_jobs'})
	file_background_menu = widget_button(file_menu, value = 'Select Background Parameter', uval={tag:'file_background'})

	monitor_jobs = where(job_status.active eq 1, njobs)
	if (njobs gt 0) then begin
		monitor_jobs_label = string(njobs, f='(i0)') + string([13b,10b]) + $
									strjoin('     ' + job_status[monitor_jobs].name, string([13b,10b]))
	endif else begin
		monitor_jobs_label = 'None'
	endelse
	label = widget_label(tab_status_base, value = 'Monitor Jobs Running: ' + monitor_jobs_label, font=font, uname='status_jobs_running', ysize = 15*(njobs+1))
	label = widget_label(tab_status_base, value = 'Analysis Processes Running: 0', font=font, uname='status_analyses_running')

	draw0 = widget_draw(tab_0_base, xs = 500, ys=500, x_scroll_size=500, y_scroll_size=500)
	draw1 = widget_draw(tab_1_base, xs = 500, ys=500, x_scroll_size=500, y_scroll_size=500)
	draw2 = widget_draw(tab_2_base, xs = 500, ys=500, x_scroll_size=500, y_scroll_size=500)
	draw3 = widget_draw(tab_3_base, xs = 500, ys=500, x_scroll_size=500, y_scroll_size=500)

	widget_control, /realize, base
	widget_control, timer = timer_interval, base

	analysis_jobs = {site_codes:strarr(20), $
					 file_lists:ptrarr(20), $
					 shmids:strarr(20), $
				     process_ids:lonarr(20), $
				     buffer_length:500, $
					 free_list:replicate(1, 20) }

	global = {persistent_file:persistent_file, $
			  in_dir:in_dir, $
			  out_dir:out_dir, $
			  home_dir:home_dir, $
			  zmap_size:zmap_size, $
			  min_file_age:min_file_age, $
			  background_parameter:'Temperature', $
			  max_timeseries_length:max_timeseries_length, $
			  timeseries_chop:timeseries_chop, $
			  timer_interval:timer_interval, $
			  oldest_snapshot:oldest_snapshot, $
			  ftp_batch:ftp_batch, $
			  base_id:base, $
			  base_geom:widget_info(base, /geom), $
			  draw_id:[draw0, draw1, draw2, draw3], $
			  tab_id:[tab_0_base, tab_1_base, tab_2_base, tab_3_base], $
			  status_base:tab_status_base, $
			  label_id:label, $
			  free_index_0:0L, $
			  analysis_jobs:analysis_jobs, $
			  font:font, $
			  email_list:email_list, $
			  log_email_sent_at:0D, $
			  data_directories:data_directories, $
			  job_status:job_status}

	xmanager, 'sdi_monitor', base, event = 'sdi_monitor_event', $
			  cleanup = 'sdi_monitor_cleanup', /no_block

end
