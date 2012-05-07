; Example call: sdi2k_batch_spekfitz, 'd:\users\sdi2000\data\sky2001282.pf', 'd:\users\sdi2000\data\ins2001282.pf'

@sdi2kprx.pro
@sdi2k_ncdf.pro

;========================================================================
;  This routine scans the data file for fit results, looking for the
;  first record with a Chi-Squared value equal to the "no data" fill
;  value for the netCDF file.  This is presumed to be the first record
;  for which fitting needs to be done.  That is, calling this routine
;  will skip all existing fits.
pro sdi2k_skip_existing_fits, ncid, record
@sdi2kinc.pro
    record = 0
    nz = total(host.operation.zones.sectors(0:host.operation.zones.fov_rings-1))
    ncdf_diminq, ncid, ncdf_dimid(ncid, 'Time'), dummy, maxrec
    repeat begin
           ncdf_varget, ncid, ncdf_varid(ncid, 'Chi_Squared'), chisq, offset=[0, record], count=[nz, 1]
           nf = 0
           fitted = 0
           badz = where(not(finite(chisq)), nf)
           if nf ne 0 then fitted = max(chisq) ne min(chisq)
           print, record
           wait, 0.01
           record = record + 1
    endrep until (not(fitted) or record ge maxrec)
    if not(fitted) then record = record-1
end


pro sdi2k_batch_spekfitz, skyfile, insfile, skip_existing=skip_existing
@sdi2kinc.pro
    load_pal, culz, proportion=0.5
    sdi2k_data_init, culz
    sdi2k_reset_spectra
    sdi2k_load_insprofs, insfile, insprofs, insid, 1

;---Fit the instrument profiles, for drift tracking:
    sdi2k_ncopen, insfile, ncid, 1
    sdi2k_add_fitvars, ncid
    ncdf_diminq, ncid, ncdf_dimid(ncid, 'Time'),    dummy,  maxrec
    ncdf_diminq, ncid, ncdf_dimid(ncid, 'Channel'), dummy,  nchan
    record = 0
    if strupcase(getenv('sdi2k_skip_oldfits')) eq 'YES' then sdi2k_skip_existing_fits, ncid, record
;goto, NO_IPR
    sdi2k_zenav_peakpos, ncid, cpos
    for rec=record,host.netcdf(1).ncmaxrec-1 do begin
        sdi2k_read_exposure, ncid, rec
        ssec = host.programs.spectra.start_time
        esec = host.programs.spectra.start_time + host.programs.spectra.integration_seconds
        print, 'Exposure ', rec, ' of ', host.netcdf(1).ncmaxrec, ' Times: ', $
               dt_tm_mk(js2jd(0d)+1, ssec, format='d$-n$-Y$ h$:m$-'), $
               dt_tm_mk(js2jd(0d)+1, esec, format='h$:m$')
        sdi2k_level1_fit, rec, sig2noise, chi_squared, $
                       sigarea, sigwid, sigpos, sigbgnd, $
                       backgrounds, areas, widths, positions, insprofs, /no_temperature, min_iters=15, shiftpos = nchan/2 - cpos
        sdi2k_write_fitpars, ncid, rec, sig2noise, chi_squared, $
                                        sigarea, sigwid, sigpos, sigbgnd, $
                                        backgrounds, areas, widths, positions
    endfor
NO_IPR:
    ncdf_close, ncid
    host.netcdf(1).ncid = -1

;---Fit the sky profiles:
    sdi2k_ncopen, skyfile, ncid, 0
    sdi2k_add_fitvars, ncid
    ncdf_diminq, ncid, ncdf_dimid(ncid, 'Time'),    dummy,  maxrec
    ncdf_diminq, ncid, ncdf_dimid(ncid, 'Channel'), dummy,  nchan
    record = 0
    itmp = 500.
    if strupcase(getenv('sdi2k_skip_oldfits')) eq 'YES' then sdi2k_skip_existing_fits, ncid, record
    sdi2k_zenav_peakpos, ncid, cpos
    for rec=record,host.netcdf(0).ncmaxrec-1 do begin
        sdi2k_read_exposure, ncid, rec
        ssec = host.programs.spectra.start_time
        esec = host.programs.spectra.start_time + host.programs.spectra.integration_seconds
        print, 'Exposure ', rec, ' of ', host.netcdf(0).ncmaxrec, '.        Times: ', $
               dt_tm_mk(js2jd(0d)+1, ssec, format='d$-n$-Y$ h$:m$-'), $
               dt_tm_mk(js2jd(0d)+1, esec, format='h$:m$')
        sdi2k_level1_fit, rec, sig2noise, chi_squared, $
                       sigarea, sigwid, sigpos, sigbgnd, $
                       backgrounds, areas, widths, positions, insprofs, initial_temp=itmp, min_iters=25, shiftpos = nchan/2 - cpos
        sdi2k_write_fitpars, ncid, rec, sig2noise, chi_squared, $
                                        sigarea, sigwid, sigpos, sigbgnd, $
                                        backgrounds, areas, widths, positions
;###        itmp = 0.75*median(widths)+0.25*500.
        itmp = median(widths)
    endfor
    ncdf_close, ncid
    host.netcdf(0).ncid = -1
end


