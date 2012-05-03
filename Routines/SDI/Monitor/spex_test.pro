
pro spex_test

	dir = 'C:\cal\IDLSource\NewAlaskaCode\Routines\SDI\Monitor\spectra\'
	odir = 'C:\cal\IDLSource\NewAlaskaCode\Routines\SDI\Monitor\spectra_orig\'

	skyfile = 'PKR_2012_019_Poker_630nm_Red_Sky_Date_01_19.nc'
	insfile = 'PKR_2012_019_Poker_Laser6328_Red_Cal_Date_01_19.pf'

	skyfile = 'PKR_2011_053_Date_02_22_SKY_6300_NZ0115.nc'
	insfile = 'PKR_2011_053_Date_02_22_CAL_6328_NZ0115.nc'

	sdi3k_read_netcdf_data, odir + skyfile, spekfits=spekfits, meta=meta, spex=spex
	sdi3k_read_netcdf_data, odir + insfile, spex=ispex, meta=imeta




	sdi3k_zenav_peakpos, ispex, imeta, cpos, widths=widths
    widord   = sort(widths)
    best     = widord(0.05*n_elements(widord))
    insprofs = ispex(best).spectra


	;\\ Insprof background and subtraction and normalization
		spec0 = reform(insprofs[0,*])
		p = total(spec0 * sin((2*!pi*findgen(meta.scan_channels)/float(meta.scan_channels))))
		q = total(spec0 * cos((2*!pi*findgen(meta.scan_channels)/float(meta.scan_channels))))
		c = (atan(p, q) / (2*!pi))*float(meta.scan_channels)
		spec_shift = meta.scan_channels/2. - c

    	for zidx = 0, meta.nzones - 1 do begin
    		insprofs[zidx, *] = insprofs[zidx,*] - min(mc_im_sm(insprofs[zidx,*], 7))
    		insprofs[zidx, *] = shift(insprofs[zidx, *], spec_shift)
        	insprof = fft(reform(insprofs[zidx,*]), -1)
        	nrm = abs(insprof[1]) ;###
        	insprofs[zidx,*] = insprofs[zidx,*]/(nrm)
	    endfor


	sdi3k_zenav_peakpos, spex, meta, cpos, widths=widths
	spec_shift = meta.scan_channels/2. - cpos

	;\\ Crude zone 0 peak position
		spec0 = reform(spex[0].spectra[0,*])
		p = total(spec0 * sin((2*!pi*findgen(meta.scan_channels)/float(meta.scan_channels))))
		q = total(spec0 * cos((2*!pi*findgen(meta.scan_channels)/float(meta.scan_channels))))
		c = (atan(p, q) / (2*!pi))*float(meta.scan_channels)
		spec_shift = meta.scan_channels/2. - c


	meta.maxrec = 20
	temps = fltarr(meta.nzones, meta.maxrec)
	peaks = fltarr(meta.nzones, meta.maxrec)
	itmp = 700.
	for k = 0, meta.maxrec-1 do begin

		spectra = spex[k].spectra





		;\\ Fit
			rec = 0
			ssec = meta.start_time
	    	esec = meta.end_time

	    	sdi3k_level1_fit, rec, (ssec + esec)/2, spectra, meta, sig2noise, chi_squared, $
	    	          		  sigarea, sigwid, sigpos, sigbgnd, backgrounds, areas, widths, positions, $
	    	           		  insprofs, initial_temp=itmp, min_iters=15, shiftpos = spec_shift

			temps[*,k] = widths
			peaks[*,k] = positions

			if k gt 0 then begin
				plot, peaks[0,0:k]
				oplot, spekfits[0:k].velocity[0]
			endif

			itmp = median(widths)
	endfor


	stop


end
