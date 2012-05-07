;========================================================================
;
;  This procedure returns a crude estimate of peak position of the
;  cummulative zenith sky spectrum summed over the whole night.
;  Mark Conde, Fairbanks, October 2001.

pro sdi2k_zenav_peakpos, ncid, cpos
@sdi2kinc.pro

    ncdf_diminq, ncid, ncdf_dimid(ncid, 'Time'),    dummy,  maxrec
    ncdf_diminq, ncid, ncdf_dimid(ncid, 'Channel'), dummy,  nchan
    record = 0
    cumspec = fltarr(nchan)
    for rec=0,maxrec-1 do begin
        sdi2k_read_exposure, ncid, rec
        cumspec = cumspec + reform(spectra(0,*))
    endfor
    cumspec = mc_im_sm(cumspec, 5)
    phse_x  = cos(findgen(nchan)*2.*!pi/nchan)
    phse_y  = sin(findgen(nchan)*2.*!pi/nchan)
    
    cpos    = atan(total(phse_y*cumspec), total(phse_x*cumspec))*nchan/(2*!pi) 
end