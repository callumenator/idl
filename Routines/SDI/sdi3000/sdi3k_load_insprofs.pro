
pro sdi3k_load_insprofs, insfile, insprofs, norm=inorm, spekfits=spekfits
@sdi2kinc.pro
    sdi3k_read_netcdf_data, insfile, metadata=mmins, spex=spex, spekfits=spekfits
    sdi3k_zenav_peakpos, spex, mmins, cpos, widths=widths
    widord   = sort(widths)
    best     = widord(0.05*n_elements(widord))
    spectra  = spex(best).spectra
    if n_elements(spekfits) eq n_elements(spectra) then spekfits = spekfits(best)
    nz       = mmins.nzones
    nchan    = mmins.scan_channels
    inorm    = fltarr(nz)

    for zidx=0,nz-1 do begin
        spectra(zidx, *) = spectra(zidx,*) - min(mc_im_sm(spectra(zidx,*), 7))
        spectra(zidx, *) = shift(spectra(zidx, *), nchan/2 - cpos)
    endfor

    insprofs = complexarr(n_elements(spectra(*,0)), n_elements(spectra(0,*)))
    inspower =     fltarr(n_elements(spectra(*,0)), n_elements(spectra(0,*)))
    for zidx=0,nz-1 do begin
        insprofs(zidx,*) = fft (spectra(zidx,*), -1)
        nrm              = abs(insprofs(zidx,1)) ;###
        inorm(zidx)      = nrm
        insprofs(zidx,*) = insprofs(zidx,*)/(nrm)
        spectra(zidx,*)  = spectra(zidx,*)/(nrm)
    endfor
    inspower = abs(insprofs*conj(insprofs))
    insprofs = spectra
    inorm    = inorm/max(inorm)
end
