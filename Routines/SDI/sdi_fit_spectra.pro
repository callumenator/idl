
@sdi3k_ncdf
@sdi3k_read_netcdf_data

pro sdi_fit_spectra_ipc_message, ipc_info, sharedVar, msg_string
	time = string(long(systime(/sec)), f='(i10)')
	msg_string = byte(time + msg_string)
	sharedVar[0] = bytarr(ipc_info.maxlength)
	sharedVar[0] = msg_string[0: n_elements(msg_string) - 1 < (ipc_info.maxlength - 1)]
end

pro sdi_fit_spectra, fit_skyfile = fit_skyfile, $
					 fit_insfile = fit_insfile, $
					 use_insfile = use_insfile, $
					 force_refit = force_refit, $	;\\ Force fitted spectra to be refit
					 start_record = start_record, $	;\\ Start fitting at this record number
					 recent_fits = recent_fits, $	;\\ Return the recently fitted spectra in this variable
					 only_zones = only_zones, $
					 ipc_info = ipc_info

	if not keyword_set(start_record) then start_record = 0

	if keyword_set(fit_insfile) then begin
		insfile = fit_insfile
		ncid = sdi3k_nc_get_ncid(insfile, write_allowed=1)
		laser_ncid = ncid
		sdi3k_add_spekfitvars, ncid
		sdi3k_read_netcdf_data, insfile, metadata=meta, spex=spex, spekfits=fits, /close
		file = insfile
		log_leader = 'Insprof exposure '
	endif


	if keyword_set(fit_skyfile) then begin

		if keyword_set(use_insfile) then begin
			insfile = use_insfile
			sdi3k_read_netcdf_data, insfile, metadata=mmins, spex=inspex, spekfits=insfits, /close
		endif else begin
			insfile = 'bad'
		endelse

		skyfile = fit_skyfile
		ncid = sdi3k_nc_get_ncid(skyfile, write_allowed=1)
		sdi3k_add_spekfitvars, ncid
		sdi3k_read_netcdf_data, skyfile, metadata=meta, spex=spex, spekfits=fits, /close
		file = skyfile
		log_leader = 'Sky exposure '
	endif

	if not keyword_set(fit_skyfile) and not keyword_set(fit_insfile) then return

	sdi3k_load_insprofs, insfile, insprofs
	sdi3k_zenav_peakpos, spex, meta, cpos, widths=widths
	ncid = sdi3k_nc_get_ncid(file, write_allowed=1)

    for rec = start_record, (meta.maxrec - 1) do begin

        ssec = spex(rec).start_time
        esec = spex(rec).end_time
        print, log_leader, rec, ' of ', meta.maxrec, ' Times: ', $
               dt_tm_mk(js2jd(0d)+1, ssec, format='d$-n$-Y$ h$:m$-'), $
               dt_tm_mk(js2jd(0d)+1, esec, format='h$:m$')

		if keyword_set(ipc_info) then begin
			sharedVar = shmvar(ipc_info.shmid)
			sdi_fit_spectra_ipc_message, ipc_info, sharedVar, log_leader + ' ' + string(rec, f='(i0)') + ' of ' + string(meta.maxrec, f='(i0)')
		endif

        badz = where(~(finite(fits(rec).chi_squared)), nf)
        fit_this = (nf ne 0) or (max(fits(rec).chi_squared) eq min(fits(rec).chi_squared)) or min(fits(rec).chi_squared) gt 1000.

        if (fit_this)  or (keyword_set(force_refit)) then begin

			if keyword_set(fit_insfile) then begin
           		sdi3k_level1_fit, rec, (ssec + esec)/2, spex(rec).spectra, meta, sig2noise, chi_squared, $
            	              	  sigarea, sigwid, sigpos, sigbgnd, backgrounds, areas, widths, positions, $
                	          	  insprofs, /no_temperature, min_iters=15, shiftpos = meta.scan_channels/2 - cpos, $
                	          	  only_zones = only_zones
            endif else begin
            	itmp = 700.
            	sdi3k_level1_fit, rec, (ssec + esec)/2, spex(rec).spectra, meta, sig2noise, chi_squared, $
                          		  sigarea, sigwid, sigpos, sigbgnd, backgrounds, areas, widths, positions, $
                          		  insprofs, initial_temp=itmp, min_iters=15, shiftpos = meta.scan_channels/2 - cpos, $
                          		  only_zones = only_zones
			endelse

           	sdi3k_write_spekfitpars, ncid, rec, sig2noise, chi_squared, sigarea, sigwid, sigpos, sigbgnd, $
            	            		 backgrounds, areas, widths, positions


			;\\ Store the latest fits to return to the caller, save them re-opening the netCDF
			if keyword_set(recent_fits) then begin

				recent_record = {positions:positions, sigma_positions:sigpos, $
								 areas:areas, sigma_areas:sigarea, $
								 widths:widths, sigma_widths:sigwid, $
								 backgrounds:backgrounds, sigma_backgrounds:sigbgnd, $
								 snr:sig2noise, chisq:chi_squared}

				if size(store_recent_fits, /type) eq 0 then begin
					store_recent_fits = recent_record
				endif else begin
					store_recent_fits = [store_recent_fits, recent_record]
				endelse
			endif

        endif

    endfor

    sdi3k_ncdf_close, ncid

	;\\ Return the new fits
	if keyword_set(recent_fits) then recent_fits = store_recent_fits

end