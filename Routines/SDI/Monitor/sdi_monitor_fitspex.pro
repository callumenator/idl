

function sdi_monitor_fitspex, snapshot, ip_snapshot, calibration=calibration

	;\\ Create a metadata structure
		case snapshot.site_code of
			'PKR': gap = 20.02
			'HRP': gap = 18.6
			'MAW': gap = 25.
			else: gap = 20.
		endcase

		meta = {wavelength_nm:snapshot.wavelength/10., $
				scan_channels:snapshot.scan_channels, $
				gap_mm:gap, $
				nzones:snapshot.nzones}

		sky_spex = float(*snapshot.spectra)
		las_spex = float(*ip_snapshot.spectra)


		negz = where(sky_spex lt 0., nneg)
        while nneg gt 0 do begin
            incr = 4096
        	drop = mean(abs(sky_spex[negz]))
            if drop gt 1e6 then begin
            	pwr = fix(alog(drop)/alog(2)) - 1
                incr = (2L^pwr) > 4096
        	endif
            sky_spex[negz] = sky_spex[negz] + incr
            negz = where(sky_spex lt 0., nneg)
            wait, 0.0001
        endwhile

		negz = where(las_spex lt 0., nneg)
        while nneg gt 0 do begin
            incr = 4096
        	drop = mean(abs(las_spex[negz]))
            if drop gt 1e6 then begin
            	pwr = fix(alog(drop)/alog(2)) - 1
                incr = (2L^pwr) > 4096
        	endif
            las_spex[negz] = las_spex[negz] + incr
            negz = where(las_spex lt 0., nneg)
            wait, 0.0001
        endwhile

		sky_spex /= float(snapshot.scans)
		las_spex /= float(ip_snapshot.scans)



	;\\ Insprof background and subtraction and normalization
		spec0 = reform(las_spex[0,*])
		p = total(spec0 * sin((2*!pi*findgen(snapshot.scan_channels)/float(snapshot.scan_channels))))
		q = total(spec0 * cos((2*!pi*findgen(snapshot.scan_channels)/float(snapshot.scan_channels))))
		c = (atan(p, q) / (2*!pi))*float(snapshot.scan_channels)
		spec_shift = snapshot.scan_channels/2. - c

    	for zidx = 0, meta.nzones - 1 do begin
    		las_spex[zidx, *] = las_spex[zidx,*] - min(mc_im_sm(las_spex[zidx,*], 7))
    		las_spex[zidx, *] = shift(las_spex[zidx, *], spec_shift)
        	insprof = fft(reform(las_spex[zidx,*]), -1)
        	nrm = abs(insprof[1]) ;###
        	las_spex[zidx,*] = las_spex[zidx,*]/(nrm)
	    endfor


	;\\ Crude zone 0 peak position
		spec0 = reform(sky_spex[0,*])
		p = total(spec0 * sin((2*!pi*findgen(snapshot.scan_channels)/float(snapshot.scan_channels))))
		q = total(spec0 * cos((2*!pi*findgen(snapshot.scan_channels)/float(snapshot.scan_channels))))
		c = (atan(p, q) / (2*!pi))*float(snapshot.scan_channels)
		spec_shift = snapshot.scan_channels/2. - c

	;\\ Fit
		rec = 0
		ssec = snapshot.start_time
    	esec = snapshot.end_time
    	itmp = 700.

    	if keyword_set(calibration) then begin
    		sdi3k_level1_fit, rec, (ssec + esec)/2, sky_spex, meta, sig2noise, chi_squared, $
    		          		  sigarea, sigwid, sigpos, sigbgnd, backgrounds, areas, widths, positions, $
    		           		  las_spex, initial_temp=itmp, min_iters=15, shiftpos = spec_shift, /no_temperature
    	endif else begin
    		sdi3k_level1_fit, rec, (ssec + esec)/2, sky_spex, meta, sig2noise, chi_squared, $
    		          		  sigarea, sigwid, sigpos, sigbgnd, backgrounds, areas, widths, positions, $
    		           		  las_spex, initial_temp=itmp, min_iters=15, shiftpos = spec_shift
		endelse

	positions = (positions + 2.25*meta.scan_channels) mod meta.scan_channels

	return, {area:areas, $
			 width:widths, $
			 position:positions, $
			 background:backgrounds, $
			 sigma_area:sigarea, $
			 sigma_width:sigwid, $
			 sigma_position:sigpos, $
			 sigma_background:sigbgnd, $
			 snr:sig2noise, $
			 chi:chi_squared, $
			 shft:spec_shift, $
			 gap_mm:gap}

end

