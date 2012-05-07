;========================================================================
;
;  This procedure returns crude estimates of peak position of the
;  cummulative zenith sky spectrum summed over the whole night, and
;  of the average widths of zenith spectra at each observation time.
;  Mark Conde, Fern Tree, July 2008.

pro sdi3k_zenav_peakpos, spex, mm, cpos, widths=widths
    widths  = fltarr(n_elements(spex))
    record  = 0
    cumspec = fltarr(mm.scan_channels)
    xvec    = findgen(mm.scan_channels)
    for rec=0,mm.maxrec-1 do begin
        zspx = reform(spex(rec).spectra(0,*))
        zspx = zspx - min(smooth(zspx, 5))
        cumspec = cumspec + zspx
        mean = total(zspx*xvec)/total(zspx)
        var = total(zspx*(xvec - mean)^2)/total(zspx)
        widths(rec) = sqrt(var)
    endfor
    cumspec = mc_im_sm(cumspec, 5)
    phse_x  = cos(findgen(mm.scan_channels)*2.*!pi/mm.scan_channels)
    phse_y  = sin(findgen(mm.scan_channels)*2.*!pi/mm.scan_channels)
    cpos    = atan(total(phse_y*cumspec), total(phse_x*cumspec))*mm.scan_channels/(2*!pi)
end
