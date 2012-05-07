;==================================================================
; This is a batch-mode program to generate real-time analysis and
; real-time plots of Poker SDI data. It was written to support
; the 2002 CODA rocket experiment, which was interested in
; launching into a pre-dawn thermospheric heating event.
; Mark Conde, Poker Flat, January 2002.


@sdi2kprx.pro
@sdi2k_ncdf.pro

;-------------------------------------------------------------------
;   This routine returns a data structure containing all the various
;   filenames that will be needed:
pro coda_build_filenames, filez
    gmt_offset = 0
    jsnow   = dt_tm_tojs(systime()) + gmt_offset
    yyyyddd = dt_tm_mk(js2jd(0d)+1, jsnow, format='Y$doy$')
    srcpath = '\\sdi2000\sdi_data\'
    dstpath = 'c:\users\sdi2000\data\'
    pngpath = 'c:\inetpub\wwwroot\'

    filez   = {remote_sky:   srcpath + 'sky' + yyyyddd + '.pf', $
               remote_laser: srcpath + 'ins' + yyyyddd + '.pf', $
               local_sky:    dstpath + 'sky' + yyyyddd + '.pf', $
               local_laser:  dstpath + 'ins' + yyyyddd + '.pf', $
               xytplot:      pngpath + 'poker_sdi_temperatures.gif', $
               vz_plot:      pngpath + 'poker_sdi_vertical_wind.gif', $
               xyiplot:      pngpath + 'poker_sdi_intensity_tseries.gif', $
               losplot:      pngpath + 'poker_sdi_los_wind.gif', $
               intplot:      pngpath + 'poker_sdi_intensity.gif', $
               tprplot:      pngpath + 'poker_sdi_skytemp.gif', $
               semaphore:    dstpath + 'Nobody_but_CODA_would_make_this.I_hope'}
end

;-------------------------------------------------------------------
;   This routine checks if another instance of codaplot is already
;   running. If so, it exits IDL immediately.
pro coda_check_semaphore, filez
    xx = findfile(filez.semaphore, count=cc)
    if cc gt 0 then print, filez.semaphore else begin
       whoami, dir, file
       spawn, 'copy ' + dir + file + ' ' + filez.semaphore
    endelse
end

;-------------------------------------------------------------------
;   This routine checks if we have local copies of the current SDI
;   sky and ins data files. If not, it copies these files from the
;   sdi machine.
pro coda_establish_local_files, filez
    xx = findfile(filez.local_sky, count=cc)
    if cc lt 1 then spawn, 'copy ' + filez.remote_sky + ' ' + filez.local_sky
    xx = findfile(filez.local_laser, count=cc)
    if cc lt 1 then spawn, 'copy ' + filez.remote_laser + ' ' + filez.local_laser
;---Test if we actually got any files; if not, then exit.
    xx = findfile(filez.local_sky, count=cc)
    if cc lt 1 then exit

end

;-------------------------------------------------------------------
;   This routine appends the most recent data to the local copies
;   of the current SDI2000 data files:
pro coda_update_local_files, remfile, locfile
    rem = ncdf_open (remfile)
    loc = ncdf_open (locfile, /write)

    ncdf_diminq, rem, ncdf_dimid(rem, 'Time'), dummy, maxrem
    ncdf_diminq, loc, ncdf_dimid(loc, 'Time'), dummy, maxloc

    if maxrem gt maxloc then begin
       ncdf_diminq, rem, ncdf_dimid(rem, 'Zone'),    dummy,  nz
       ncdf_diminq, rem, ncdf_dimid(rem, 'Channel'), dummy,  nchan
       spectra = ulonarr(nz, nchan)
       for record=maxloc, maxrem-1 do begin
           print, 'Appending record ' + strcompress(string(record), /remove_all) + ' to ' + locfile
;----------Read the exposure data from the SDI2000 machine's source file:
           ncdf_varget,  rem, ncdf_varid(rem, 'Spectra'),       spectra, offset=[0,0,record], $
                         count=[n_elements(spectra(*,0)), n_elements(spectra(0,*)), 1]
           ncdf_varget,  rem, ncdf_varid(rem, 'Start_Time'),    stime, offset=[record], count=[1]
           ncdf_varget,  rem, ncdf_varid(rem, 'End_Time'),      etime, offset=[record], count=[1]
           ncdf_varget,  rem, ncdf_varid(rem, 'Number_Summed'), scanz, offset=[record], count=[1]
;----------Write the exposure to the local destination file:
           ncdf_varput,  loc, ncdf_varid(loc, 'Spectra'),       spectra, offset=[0,0,record]
           ncdf_varput,  loc, ncdf_varid(loc, 'Start_Time'),    stime,   offset=[record]
           ncdf_varput,  loc, ncdf_varid(loc, 'End_Time'),      etime,   offset=[record]
           ncdf_varput,  loc, ncdf_varid(loc, 'Number_Summed'), scanz,   offset=[record]
       endfor
    endif

    ncdf_close, rem
    ncdf_close, loc

end


pro coda_plot_temps, filez
@sdi2kinc.pro

    set_plot, 'Z'
    device, set_colors=256
    xsize = 1000
    ysize = 600

;---Initialize various data:
    load_pal, culz, proportion=0.5
    sdi2k_data_init, culz
    view = transpose(view)

;---Open the sky file:
    sdi2k_ncopen, filez.local_sky, ncid, 0
    sdi2k_build_zone_map
    ncdf_diminq, ncid, ncdf_dimid(ncid, 'Time'),    dummy,  maxrec
    sdi2k_read_exposure, host.netcdf(0).ncid, 0
    ctime = host.programs.spectra.start_time + host.programs.spectra.integration_seconds/2
    year = dt_tm_mk(js2jd(0d)+1, ctime, format='Y$')
    doy  = dt_tm_mk(js2jd(0d)+1, ctime, format='doy$')

;---Get the peak fitting results and condition them as needed:
    if n_elements(resarr) gt 0 then undefine, resarr
    sdi2k_build_fitres, ncid, resarr

    sdi2k_drift_correct, resarr, source_file=filez.local_sky, /force, /data
    sdi2k_remove_radial_residual, resarr, parname='VELOCITY'
    sdi2k_remove_radial_residual, resarr, parname='INTENSITY', /multiplicative
    sdi2k_remove_radial_residual, resarr, parname='TEMPERATURE'
    pv = resarr.intensity
    pv = pv(sort(pv))
    nv = n_elements(pv)
    resarr.intensity = resarr.intensity - pv(0.02*nv)
    sdi2k_physical_units, resarr


;---Build the time information arrays:
    record = 0
    tlist = strarr(maxrec)
    tcen  = dblarr(maxrec)
    for rec=record,maxrec-1 do begin
        sdi2k_read_exposure, ncid, rec
        tcen(rec) = host.programs.spectra.start_time + host.programs.spectra.integration_seconds/2
        hhmm = dt_tm_mk(js2jd(0d)+1, tcen(rec), format='h$:m$')
        tlist(rec) =  hhmm
    endfor
    sdi2k_read_exposure, host.netcdf(0).ncid, 0
    ctime = host.programs.spectra.start_time + host.programs.spectra.integration_seconds/2
    datestr = dt_tm_mk(js2jd(0d)+1, ctime, format='0d$ n$ Y$')

;---Close the skyfile:
    ncdf_close, host.netcdf(0).ncid
    host.netcdf(0).ncid = -1

    device, set_resolution=[xsize,ysize]

    scale = {time_range: [0., 1.], yrange: [-180., 180.], auto_scale: 0}
    geo   = {xsize:  xsize, ysize: ysize}
    msis  = {tsplot_msis,   plot_msis: 1, $
                               f10pt7: 180., $
                                   ap: 15., $
                          msis_height: 120.}
    tsplot_settings = {scale: scale, parameter: 4, zones: 'Zenith', black_bgnd: 1, geometry: geo, records: [0, maxrec-2], msis: msis}

;---Vertical Wind time series:
;    if maxrec gt 3 then resarr.velocity = resarr.velocity - total(resarr(1:maxrec-2).velocity(0))/n_elements(resarr(1:maxrec-2).velocity(0))
    sdi2k_tseries_plotter, tlist, tcen, datestr, resarr, tsplot_settings
    gmt_offset = 0
    jsnow   = dt_tm_tojs(systime()) + gmt_offset
    tstamp  = dt_tm_mk(js2jd(0d)+1, jsnow, format='Plotted at h$m$ UT.')
    xyouts, 0.2, 0.08, tstamp, charsize=1.2, color=host.colors.blue, align=0, /normal
    img    = tvrd()
    tvlct, r, g, b, /get
    write_gif, filez.vz_plot, img, r, g, b

;---Median Temperature Time Series:
    tsplot_settings.zones = 'Median'
    tsplot_settings.parameter = 5
    tsplot_settings.scale.yrange = [100., 800]
    sdi2k_tseries_plotter, tlist, tcen, datestr, resarr, tsplot_settings
    gmt_offset = 0
    jsnow   = dt_tm_tojs(systime()) + gmt_offset
    tstamp  = dt_tm_mk(js2jd(0d)+1, jsnow, format='Plotted at h$m$ UT.')
    xyouts, 0.2, 0.08, tstamp, charsize=1.2, color=host.colors.blue, align=0, /normal
    img    = tvrd()
    tvlct, r, g, b, /get
    write_gif, filez.xytplot, img, r, g, b

;---Intensity Time Series:
    tsplot_settings.zones = 'All'
    tsplot_settings.parameter = 6
    tsplot_settings.scale.yrange = [0., 2000]
    sdi2k_tseries_plotter, tlist, tcen, datestr, resarr, tsplot_settings
    gmt_offset = 0
    jsnow   = dt_tm_tojs(systime()) + gmt_offset
    tstamp  = dt_tm_mk(js2jd(0d)+1, jsnow, format='Plotted at h$m$ UT.')
    xyouts, 0.2, 0.08, tstamp, charsize=1.2, color=host.colors.blue, align=0, /normal
    img    = tvrd()
    tvlct, r, g, b, /get
    write_gif, filez.xyiplot, img, r, g, b

;---Set the bitmap size for skymaps:
    ysize = 2*85 + 85*maxrec/10.
    device, set_resolution=[xsize,ysize]

;---Map LOS winds:
    scale = {yrange: [-200., 200.], auto_scale: 0}
    geo   = {xsize:  xsize, ysize: ysize}
    skymap_settings = {scale: scale, parameter: 4, black_bgnd: 1, geometry: geo, records: [0, maxrec-2]}
    sdi2k_sky_mapper, tlist, tcen, datestr, resarr, skymap_settings, palette=palette
    gmt_offset = 0
    jsnow   = dt_tm_tojs(systime()) + gmt_offset
    tstamp  = dt_tm_mk(js2jd(0d)+1, jsnow, format='h$m$ UT.')
    xyouts, 10, 10, tstamp, charsize=1.2, color=host.colors.blue, align=0, /device
    img    = tvrd()
;    tvlct, r, g, b, /get
    write_gif, filez.losplot, img, palette.r, palette.g, palette.b

;---Map temperatures:
    skymap_settings.parameter = 5
    skymap_settings.scale.yrange = [100., 900]
    sdi2k_sky_mapper, tlist, tcen, datestr, resarr, skymap_settings
    gmt_offset = 0
    jsnow   = dt_tm_tojs(systime()) + gmt_offset
    tstamp  = dt_tm_mk(js2jd(0d)+1, jsnow, format='h$m$ UT.')
    xyouts, 10, 10, tstamp, charsize=1.2, color=host.colors.blue, align=0, /device
    img    = tvrd()
    tvlct, r, g, b, /get
    write_gif, filez.tprplot, img, r, g, b

;---Map intensities:
    skymap_settings.parameter = 6
    skymap_settings.scale.yrange = [0., 1500]
    sdi2k_sky_mapper, tlist, tcen, datestr, resarr, skymap_settings, palette=palette
    gmt_offset = 0
    jsnow   = dt_tm_tojs(systime()) + gmt_offset
    tstamp  = dt_tm_mk(js2jd(0d)+1, jsnow, format='h$m$ UT.')
    xyouts, 10, 10, tstamp, charsize=1.2, color=host.colors.blue, align=0, /device
    img    = tvrd()
    tvlct, r, g, b, /get
    write_gif, filez.intplot, img, r, g, b

end

;-------------------------------------------------------------------
;   This is the main program:

    setenv, 'sdi2k_skip_oldfits=YES'
    coda_build_filenames, filez
    print, 'establish'
    ;coda_check_semaphore, filez
    coda_establish_local_files, filez
    print, 'files'
    coda_update_local_files, filez.remote_sky,   filez.local_sky
    coda_update_local_files, filez.remote_laser, filez.local_laser
    print, 'fits'
    sdi2k_batch_spekfitz, filez.local_sky, filez.local_laser
    print, 'plots'
    coda_plot_temps, filez
    spawn, 'del ' + filez.semaphore
end