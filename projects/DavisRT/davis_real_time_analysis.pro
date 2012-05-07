
;\\ 21 June 2008
;\\ Updated version of the real time analysis software
;\\ This takes into account different filters


;!!! MAKE SURE FORMAT SPECIFIER i2.2 WORKS ON DAVIS COMPUTER  !!!

@drta_frngprox

pro Davis_Real_Time_Analysis


	;\\ Widget Display
		drta_base = widget_base(xo=800,xs=600,ys=300, title='Davis Analysis')
		drta_nfiles = widget_label(drta_base, xs=600, ys=20, value = 'Files: ' + string(0,f='(i0)'), font = 'Ariel*20*Bold')
		drta_file 	= widget_label(drta_base, xs=600, ys=20, yo = 30, value = 'Current File:', font = 'Ariel*20*Bold')
		drta_type 	= widget_label(drta_base, xs=600, ys=20, yo = 60, value = 'File Type:', font = 'Ariel*20*Bold')
		drta_status = widget_label(drta_base, xs=600, ys=20, yo = 90, value = 'Status:', font = 'Ariel*20*Bold')
		widget_control, /realize, drta_base


	;\\ Log File
		date = js_to_yymmdd(dt_tm_tojs(systime(/ut)))
		log_filename = 'c:\cal\idlsource\davisrtnew\drta\logs\drta_log_file_' + date + '.txt'

	;\\ Make a new log file if needed
		if file_test(log_filename) ne 1 then res = drta_write_to_log_file(log_filename, '', write_header = 'Davis Real-Time Analysis Log - ' + systime(/ut), drta_status)

	;\\ Set up a display widget
		;base = widget_base(xo=800,xs=400,ys=300, title='Davis Real-Time Analysis Log')
		;cfile = widget_label(base, xs=400, ys=20, yo = 10, value = '
		;ctype = widget_label(base, xs=400, ys=20, yo = 40, value = 'File Type:', font = 'Ariel*20*Bold')
		;cstatus = widget_label(base, xs=400, ys=20, yo = 70, value = 'Status:', font = 'Ariel*20*Bold')
		;widget_control, /realize, base


	;\\ ----------------------------MAP THE NETWORK DRIVE---------------------------------------
		computername = '\\Fpswin98'
		sharename = '\FPSDATA\newdata'
		localname = 'z:'
		user = ''
		password = ''

		map_unmap = 0
		map_network_drive, computername, sharename, localname, user, password, map_unmap, drive_mapped
		drive_mapped = 1

		if drive_mapped eq 0 then begin
		 res = drta_write_to_log_file(log_filename, 'Failed to map network drive. Ending...', drta_status)
		 goto, DRTA_END_ANALYSIS
		endif else begin
		 res = drta_write_to_log_file(log_filename, 'Network drive (' + computername + sharename + ') mapped to ' + localname, drta_status)
		endelse
	;\\ -----------------------------------------------------------------------------------------

	;\\ ------------------------- SETUP VARIABLES -----------------------------------------------
		;image_path = localname
		;spec_path  = localname
		;plot_path  = 'd:\drta\drta_plots\'
		;save_path  = 'd:\drta\drta_saves\'
		;misc_path  = 'd:\drta\'
		;\\ FOR TESTING
		image_path = 'c:\cal\idlsource\davisrtnew\drta\newdata\'
		spec_path  = 'c:\cal\idlsource\davisrtnew\drta\newdata\'
		plot_path  = 'c:\cal\idlsource\davisrtnew\drta\plots\'
		save_path  = 'c:\cal\idlsource\davisrtnew\drta\saves\'
		misc_path  = 'c:\cal\idlsource\davisrtnew\drta\drta\'

		break_time = 6.8D     	;\\ The time for which obs before are from day before, in UT
		npts = 64.				;\\ Points in the spectrum
		plt_period = 24.		;\\ Time period for real-time plot
		move_done_files = 1		;\\ Move files out of newdata once analysed
		;move_to_base = 'c:\data\'
		move_to_base = 'c:\cal\idlsource\davisrtnew\drta\'
		old_files_moveto = 'c:\cal\idlsource\davisrtnew\drta\OldFiles_Not_Analysed\'
		skip_rough = 1
		noplot = 1
		diagz = ['main_print_status']

		load_pal, culz, idl=[3,1]
	;\\ ---------------------------------------------------------------------------------------

	skipped = 0

	DRTA_GET_FILE_LIST:

	;\\ ----------------------- GET NEW FILES -----------------------------------------------------------------------------------------------------------------------
		red_newdata = file_search(spec_path, '*.630', count = nred)
		gre_newdata = file_search(spec_path, '*.557', count = ngre)
		all_newdata = [red_newdata, gre_newdata]
		nfiles = nred + ngre
			if nfiles eq 0 then begin &	res = drta_write_to_log_file(log_filename, 'No new data found. Ending...', drta_status)
			endif else begin & res = drta_write_to_log_file(log_filename, 'New data found - ' + string(nred,f='(i0)') + ' Red, ' + string(ngre,f='(i0)') + ' Green', drta_status)
			endelse
		widget_control, set_value = 'Files: ' + string(nfiles,f='(i0)'), drta_nfiles
	;\\ -------------------------------------------------------------------------------------------------------------------------------------------------------------


		common frng_ideal, circles
		circles = 1

	;\\ ------------------------- BEGIN MAIN LOOP ----------------------------------------------
		for ix = 0, nfiles - 1 do begin


			if skipped eq 0 then res = drta_write_to_log_file(log_filename, ' ', drta_status)

			sname = file_basename(all_newdata(ix))
			pname = strmid(sname,0,strlen(sname)-4) + '.tif'

			data = read_davis_specfile(all_newdata(ix))
			fyear =  float(strmid(sname, 0, 2)) & if fyear lt 50 then fyear = fyear + 2000 else fyear = fyear + 1900
			fmnth =  float(strmid(sname, 2, 2))
			fday  =  float(strmid(sname, 4, 2))
			fdayno = ymd2dn(fyear, fmnth, fday)

			dtime = (data.time.hours + (float(data.time.mins))/60. + (float(data.time.secs))/3600.)

			;\\ The file date depends on the date and time - before breaktime = from day before
				if dtime lt break_time then begin
					fdayno = fdayno - 1
					file_utime = dtime + 24.0
					file_jtime = ydns2js(fyear, fdayno, file_utime*3600.)
				endif else begin
					file_utime = dtime
					file_jtime = ydns2js(fyear, fdayno, file_utime*3600.)
				endelse

			;\\ Check for previously analysed data for this dayno
				savename = save_path + string(fyear, f='(i0)') + '_' + string(fdayno,f='(i3.3)')
				if file_test(savename) eq 1 then begin
					restore, savename
					restored_data = 1
					done = where(files_done eq sname, ndone)
					if ndone eq 1 then begin
						;res = drta_write_to_log_file(log_filename, 'File has already been analysed. Skipping...', drta_status)
						goto, DRTA_SKIP_THIS_FILE
					endif
				endif else begin
					restored_data = 0
					nlas = 0
					nsky = 0
				endelse

				res = drta_write_to_log_file(log_filename, 'Analysing file: ' + sname + ', Dayno = ' + string(fdayno,f='(i0)'), drta_status)

			;\\ Make sure there is a picture for the specfile
				if file_test(image_path + pname) eq 1 then begin
					res = drta_write_to_log_file(log_filename, 'Image file: ' + image_path + pname + ' found', drta_status)
				endif else begin
					res = drta_write_to_log_file(log_filename, 'Image file: ' + image_path + pname + ' NOT found. Skipping...', drta_status)
					goto, DRTA_SKIP_THIS_FILE
				endelse

				widget_control, set_value = 'Current File: ' + sname, drta_file
				widget_control, set_value = 'File Type: ' + data.title, drta_type


			;\\ Distinguish between calibration or sky file
				if strmatch(data.title, '*calibration*', /fold) eq 1 then begin

					;\\ Linearise and clean the image file
						image = linearise_davis_fringe(image_path + pname, spec_path + sname)
						res = drta_write_to_log_file(log_filename, 'Image linearised', drta_status)
						cleaned_pic = imageclean(image)
						res = drta_write_to_log_file(log_filename, 'Image cleaned', drta_status)

						nx = n_elements(cleaned_pic(*,0))
						ny = n_elements(cleaned_pic(0,*))

						Lambdafsr = (632.8e-9)^2/(2*12.948e-3)
						Vfsr = ((3.e8)*Lambdafsr)/632.8e-9
						cnvrsnfctr = Vfsr/npts
						gap    = 12.948e-3
						lambda = 632.8e-9
						fsr    = lambda^2/(2*gap)
						cal    = {s_cal, delta_lambda: fsr/npts, nominal_lambda: 632.8e-9}
						species = {s_spec, name: 'O', mass:  16., relint: 1.}



					;\\ File is a calibration image - analyse
						if nlas eq 0 then begin

							res = drta_write_to_log_file(log_filename, 'File is the first laser. Performing detailed fit...', drta_status)


							frnginit, php, nx, ny, mag=[0.35e-010, 0.35e-010,  0.65e-05], $
	                          			warp = [  0.0, 0.00], $
	                          			center=[471, 298], $
	                          			ordwin=[0.0,1.0], $
	                          			phisq = 1.0, $
	                          			zerph = 0.2, $
	                          			R=0.9, $
	                          			xcpsave='NO'

							;frnginit, php, nx, ny, mag=[6e-006,  6e-006,  1e-008], $
			                ;          warp 		= [  0.0, 0.00], $
			                ;          center	= [471.995, 298.007], $
			                ;          ordwin	= [0.0,1.0], $
			                ;          phisq 	= 1.0, $
			                ;          zerph 	= 0.354925, $
			                ;          R			= 0.98, $
			                ;          xcpsave	= 'NO'

						   	if noplot eq 1 then php.fplot = 0 else php.fplot = 1

						   	php.xcstp = .1*php.xcen & php.ycstp = .1*php.ycen
						   	php.zerstp = 0.01 & php.xmstp = 0 & php.ymstp = 0 & php.xymstp = 0
						   	php.xwstp = 0 & php.ywstp = 0 & php.phistp = 0

						   	frng_fit, cleaned_pic, php, culz, skip_rough = skip_rough, /progress
						   	wait, .1

						   	php.minord = 0 & php.delord = 1
						   	php.zerstp = 0 & php.xcstp = .1*php.xcen
						   	php.ycstp = .1*php.ycen & php.xmstp = 1e-6 & php.ymstp = 1e-6
						   	php.xymstp = 2e-8 & php.xwstp = 0.1 & php.ywstp = 0.1 & php.phistp = 0

						   	frng_fit, cleaned_pic, php, culz, skip_rough = skip_rough, /progress
						   	wait, .1

							php.minord = 0    & php.delord = 3
						   	php.zerstp = 0.05 & php.xcstp =  0
						   	php.ycstp =  0    & php.xmstp =  0 & php.ymstp = 0
						   	php.xymstp = 0    & php.xwstp =  0 & php.ywstp = 0 & php.phistp = 0.5

						   	frng_fit, cleaned_pic, php, culz, skip_rough = skip_rough, /progress
						   	wait, .1

						endif else begin

							res = drta_write_to_log_file(log_filename, 'File is laser number ' + string(nlas+1,f='(i0)') + ', performing reduced fit...', drta_status)

							php = las(0).params

						   	if noplot eq 1 then php.fplot = 0 else php.fplot = 1

							php.minord = 0    & php.delord = 2
						   	php.zerstp = 0.05 & php.xcstp =  0
						   	php.ycstp =  0    & php.xmstp =  0 & php.ymstp = 0
						   	php.xymstp = 0    & php.xwstp =  0 & php.ywstp = 0 & php.phistp = 0.5

						   	frng_fit, cleaned_pic, php, culz, skip_rough = skip_rough, /progress
						   	wait, .1

						endelse

							res = drta_write_to_log_file(log_filename, 'Scanning laser spectrum...', drta_status)

						;\\ Scan the laser spectrum
							if nlas eq 0 then zerph = php.zerph else zerph = las(0).params.zerph
							php.zerph = zerph
							frng_newspex, cleaned_pic, php, npts, las_spec, [0.0,2.0], culz
							;frng_spx, cleaned_pic, cleaned_pic, php, npts, [0.0, 2.0], 0.98, culz, las_spec, zerph=zerph

							peak = where(las_spec eq max(las_spec))
					   		fitpars   = [0., 0., 0., peak(0), 0.5]
					   		fix_mask  = [0, 1, 0, 0, 1]


						;\\ Make an Airy function to use as an "instrument function":
					   		x       = (findgen(npts) - npts/2.)*!pi/npts
					   		fringes = sin(x)
					   		fringes = 1./(1 + ( (4*.95) / ((1. - .95)^2) )*fringes*fringes)
					   		fringes = fringes - min(fringes)
					   		las_ip  = fringes/max(fringes)

							res = drta_write_to_log_file(log_filename, 'Fitting laser spectrum...', drta_status)


							load_pal, culz, idl=[3,1]
						;\\ Now fit an emission spectrum to the laser spectrum, using the instrument profile obtained from the laser fringes:
					   		spek_fit, las_spec, las_ip, species, cal, fix_mask, diagz, fitpars, sigpars, quality, /passive, max_iters=100


							;plot, las_spec, color = culz.yellow
					   		;oplot, quality.fitfunc, color = culz.yellow



						;\\ Save the fit
							struc = {ut:file_utime, $
								   	js:file_jtime, $
								   	data:data, $
								   	fitpars:fitpars, $
								   	sigpars:sigpars, $
								   	quality:quality, $
								   	spec:las_spec, $
								   	insprof:las_ip, $
								   	params:php, $
								   	time_done:dt_tm_tojs(systime())}

							if nlas eq 0 then begin
								las = struc
							endif else begin
								las = [las, struc]
							endelse
							nlas ++

				endif else begin

					;\\ File is a sky image
						res = drta_write_to_log_file(log_filename, 'File is a sky image', drta_status)

						if nlas lt 2 then begin
							res = drta_write_to_log_file(log_filename, 'Not enough laser files fitted. Skipping...', drta_status)
							skipped = 1
							goto, DRTA_SKIP_THIS_FILE
						endif

						max_las_time = max(las.ut)
						min_las_time = min(las.ut)
						if (not (file_utime gt min_las_time and file_utime lt max_las_time)) then begin
							if file_utime gt min_las_time then begin
								res = drta_write_to_log_file(log_filename, "File doesn't sit between two lasers. Skipping...", drta_status)
								skipped = 1
								goto, DRTA_SKIP_THIS_FILE
							endif
						endif

					;\\ Linearise and clean the image file
						image = linearise_davis_fringe(image_path + pname, spec_path + sname)
						res = drta_write_to_log_file(log_filename, 'Image linearised', drta_status)
						cleaned_pic = imageclean(image)
						res = drta_write_to_log_file(log_filename, 'Image cleaned', drta_status)

						nx = n_elements(cleaned_pic(*,0))
						ny = n_elements(cleaned_pic(0,*))

					;\\ Interpolate laser params to sky time
						las_times = las.ut
						sky_time  = file_utime
						tparams = las(0).params
						for tag = 0, n_tags(php) - 1 do begin
							if size(las(*).params.(tag), /type) ne 7 then begin
								tparams.(tag) = interpol(las(*).params.(tag), las_times, sky_time)
							endif else begin
								tparams.(tag) = las(0).params.(tag)
							endelse
						endfor

						lambda = float(strmid(sname,strlen(sname)-3, strlen(sname)))
						tparams.lambda = lambda

						Lambdafsr = (lambda*1e-9)^2/(2*12.948e-3)
						Vfsr = ((3.e8)*Lambdafsr)/(lambda*1e-9)
						cnvrsnfctr = Vfsr/npts
						gap    = 12.948e-3
						fsr    = (lambda*1e-9)^2/(2*gap)
						cal    = {s_cal, delta_lambda: fsr/npts, nominal_lambda: lambda*1e-9}
						species = {s_spec, name: 'O', mass:  16., relint: 1.}

						res = drta_write_to_log_file(log_filename, 'Scanning sky spectrum...', drta_status)

					;\\ Scan the sky spectrum
						zerph = las(0).params.zerph
						frng_newspex, cleaned_pic, tparams, npts, sky_spec, [0.0,2.0], culz
						;frng_spx, cleaned_pic, cleaned_pic, php, npts, [0.0, 2.0], 0.98, culz, sky_spec, zerph=zerph

			   			fitpars   = [0., 0., 0., 0., 800.]
			   			fix_mask  = [0, 1, 0, 0, 0]

						las_ip = las(0).spec

						res = drta_write_to_log_file(log_filename, 'Fitting sky spectrum...', drta_status)


						load_pal, culz, idl=[3,1]
					;\\ Now fit an emission spectrum to the laser spectrum, using the instrument profile obtained from the laser fringes:
			   			spek_fit, sky_spec, las_ip, species, cal, fix_mask, diagz, fitpars, sigpars, quality, /passive, max_iters=300
			   			wait, .1

					;\\ Save the fit
						struc = {ut:file_utime, $
							   	js:file_jtime, $
							   	data:data, $
							   	fitpars:fitpars, $
							   	sigpars:sigpars, $
							   	quality:quality, $
							   	spec:sky_spec, $
							   	insprof:las_ip, $
							   	params:tparams, $
							   	time_done:dt_tm_tojs(systime())}

						if nsky eq 0 then begin
							sky = struc
						endif else begin
							sky = [sky, struc]
						endelse
						nsky ++

				endelse

				if restored_data eq 0 then begin
					files_done = sname
				endif else begin
					files_done = [files_done, sname]
				endelse

				save, filename = savename, las, sky, nlas, nsky, files_done, /compress
				res = drta_write_to_log_file(log_filename, 'Data saved', drta_status)


				;\\-------------------------------- MOVE FILES OUT OF NEWDATA ------------------------------
					if move_done_files eq 1 then begin
						res = drta_write_to_log_file(log_filename, 'Moving files out of ' + spec_path, drta_status)

						ydn2md, fyear, fdayno, mnth, day
						current_date = strmid(sname,0,2) + string(mnth,f='(i2.2)') + string(day,f='(i2.2)')

						pic_folder_name = current_date + 'PICS'
						spc_folder_name = current_date + 'SPECS'

						there_pic = file_test(move_to_base + pic_folder_name, /directory)
						there_spc = file_test(move_to_base + spc_folder_name, /directory)

						if there_pic ne 1 then file_mkdir, move_to_base + pic_folder_name
						if there_spc ne 1 then file_mkdir, move_to_base + spc_folder_name

						file_copy, image_path + pname, move_to_base + pic_folder_name + '\' + pname
						file_delete, image_path + pname
						file_copy, spec_path  + sname, move_to_base + spc_folder_name + '\' + sname
						file_delete, spec_path + sname
					endif else begin
						res = drta_write_to_log_file(log_filename, 'File-move option turned off, leaving files in ' + spec_path, drta_status)
					endelse

					res = drta_write_to_log_file(log_filename, 'Real-time plotting..', drta_status)

					davis_real_time_analysis_plotter, save_path, plot_path, 630.0, 2, 20.0, 2

					res = drta_write_to_log_file(log_filename, 'Finished with file ' + sname, drta_status)

					if skipped eq 1 then goto, DRTA_GET_FILE_LIST

		DRTA_SKIP_THIS_FILE:
			drta_remove_old_data, all_newdata(ix), save_path, old_files_moveto, min_time = 5.
		endfor






DRTA_END_ANALYSIS:
widget_control, drta_base, /destroy
end