
pro spex_fit_tester

	path = 'C:\RSI\IDLSource\NewAlaskaCode\Routines\SDI\Monitor\'
	nc_las_file = 'HRP_2012_020_Date_01_20_CAL_6328_NZ0115.nc'
	nc_sky_file = 'HRP_2012_020_Date_01_20_SKY_6300_NZ0115.nc'


	;sdi3k_batch_spekfitz, path+nc_sky_file, path+nc_las_file


	sdi3k_read_netcdf_data, path+nc_sky_file, meta=sky_meta, spekfits=sky_fits, spex=sky_spex
	sdi3k_read_netcdf_data, path+nc_las_file, meta=las_meta, spekfits=las_fits, spex=las_spex

	sdi3k_zenav_peakpos, sky_spex, sky_meta, sky_cpos, widths=widths
	sdi3k_zenav_peakpos, las_spex, las_meta, cpos, widths=widths
    widord   = sort(widths)
    best     = widord(0.05*n_elements(widord))
    las_ips  = las_spex[best].spectra
	nz = 115
	nchan = 128
	inorm    = fltarr(nz)
    for zidx=0,nz-1 do begin
        las_ips(zidx, *) = las_ips(zidx,*) - min(mc_im_sm(las_ips(zidx,*), 7))
        las_ips(zidx, *) = shift(las_ips(zidx, *), nchan/2 - cpos)
    endfor

;    insprofs = complexarr(n_elements(las_ips(*,0)), n_elements(las_ips(0,*)))
;    inspower =     fltarr(n_elements(las_ips(*,0)), n_elements(las_ips(0,*)))
;    for zidx=0,nz-1 do begin
;        insprofs(zidx,*) = fft (las_ips(zidx,*), -1)
;        nrm              = abs(insprofs(zidx,1)) ;###
;        inorm(zidx)      = nrm
;        insprofs(zidx,*) = insprofs(zidx,*)/(nrm)
;        las_ips(zidx,*)  = las_ips(zidx,*)/(nrm)
;    endfor



	restore, path + 'HRP_Testerfile.idlsave'

	my_temps = fltarr(115, nels(sky_snaps))
	real_temps = fltarr(115, nels(sky_snaps))
	for j = 0, nels(sky_snaps) - 1 do begin

		match = (where(sky_snaps[j].sky_start eq sky_spex.start_time))[0]

		meta = {wavelength_nm:sky_snaps[j].wavelength/10., $
				scan_channels:sky_snaps[j].scan_channels, $
				gap_mm:18.6, $
				nzones:115}


		these_sky_spex = float(sky_snaps[j].spectra)
		these_sky_spex /= sky_spex[match].scans
		these_las_spex = float(sky_snaps[j].las_spectra)

		;these_las_spex = las_ips

	;\\ Crude zone 0 peak position
		spec0 = reform(these_las_spex[0,*])
		p = total(spec0 * sin((2*!pi*findgen(meta.scan_channels)/float(meta.scan_channels))))
		q = total(spec0 * cos((2*!pi*findgen(meta.scan_channels)/float(meta.scan_channels))))
		c = (atan(p, q) / (2*!pi))*float(meta.scan_channels)
		spec_shift = meta.scan_channels/2. - c

	    for zidx=0,nz-1 do begin
        	these_las_spex(zidx, *) = these_las_spex(zidx,*) - min(mc_im_sm(these_las_spex(zidx,*), 7))
    	endfor

;	    insprofs = complexarr(n_elements(las_ips(*,0)), n_elements(las_ips(0,*)))
;	    inspower =     fltarr(n_elements(las_ips(*,0)), n_elements(las_ips(0,*)))
;	    for zidx=0,nz-1 do begin
;	        insprofs(zidx,*) = fft (las_ips(zidx,*), -1)
;	        nrm              = abs(insprofs(zidx,1)) ;###
;	        inorm(zidx)      = nrm
;	        insprofs(zidx,*) = insprofs(zidx,*)/(nrm)
;	        las_ips(zidx,*)  = las_ips(zidx,*)/(nrm)
;	    endfor

	;\\ Crude zone 0 peak position
		spec0 = reform(these_sky_spex[0,*])
		p = total(spec0 * sin((2*!pi*findgen(meta.scan_channels)/float(meta.scan_channels))))
		q = total(spec0 * cos((2*!pi*findgen(meta.scan_channels)/float(meta.scan_channels))))
		c = (atan(p, q) / (2*!pi))*float(meta.scan_channels)
		spec_shift = meta.scan_channels/2. - c


	;\\ Fit
		rec = 0
		ssec = sky_snaps[j].sky_start
    	esec = ssec
    	itmp = 700.
    	sdi3k_level1_fit, rec, (ssec + esec)/2, these_sky_spex, meta, sig2noise, chi_squared, $
    	          		  sigarea, sigwid, sigpos, sigbgnd, backgrounds, areas, widths, positions, $
    	           		  these_las_spex, initial_temp=itmp, min_iters=15, shiftpos = spec_shift

		my_temps[*,j] = widths
		real_temps[*,j] = sky_fits[match].temperature
	endfor

	plot, real_temps
	oplot, my_temps, color=150
	print, median(abs(real_temps - my_temps))

	stop

end


