; Example call:  sdi2k_batch_plotz, 'd:\users\sdi2000\data\sky2001282.pf', resarr, windfit

@sdi2kprx.pro
@sdi2k_ncdf.pro

pro sdi2k_batch_plotsave, gif_path, year, doy, ptype, palette=palette
    md_err = 0
    catch, md_err
    if md_err ne 0 then goto, keep_going
    folder = gif_path + year + '\' + ptype + '\'
    file_mkdir, folder
keep_going:
    fname  = folder + ptype + year + doy + '.gif'
    img    = tvrd()
    if keyword_set(palette) then begin
       r = palette.r
       g = palette.g
       b = palette.b
    endif else tvlct, r, g, b, /get
    write_gif, fname, img, r, g, b
end

;=======================================================================================================

pro sdi2k_batch_plotz, skyfile, resarr, windfit
@sdi2kinc.pro

    set_plot, 'Z'
    device, set_colors=256
    xsize = 1000
    ysize = 600
    gif_path = 'c:\inetpub\wwwroot\conde\sdiplots\'
;    window, xsize=xsize, ysize=ysize

;---Initialize various data:
    load_pal, culz, proportion=0.5
    sdi2k_data_init, culz
    view = transpose(view)

;---Open the sky file:
    sdi2k_ncopen, skyfile, ncid, 0
    if n_elements(zone_map) lt 1 then sdi2k_build_zone_map
    ncdf_diminq, ncid, ncdf_dimid(ncid, 'Time'),    dummy,  maxrec
    sdi2k_read_exposure, host.netcdf(0).ncid, 0
    ctime = host.programs.spectra.start_time + host.programs.spectra.integration_seconds/2
    year = dt_tm_mk(js2jd(0d)+1, ctime, format='Y$')
    doy  = dt_tm_mk(js2jd(0d)+1, ctime, format='doy$')

;---Get the wind results:
    sdi2k_build_windres, ncid, windfit

;---Get the peak fitting results and condition them as needed:
    if n_elements(resarr) gt 0 then undefine, resarr
    sdi2k_build_fitres, ncid, resarr

    sdi2k_drift_correct, resarr, source_file=skyfile, /force, /data_based ;#####
    
;---Determine the wavelength:
    doing_sodium = 0
    doing_red    = 0
    doing_green  = 0
    if abs(host.operation.calibration.sky_wavelength - 589.0) lt 5. then begin
       lamda = '5890'
       doing_sodium = 1
    endif
    if abs(host.operation.calibration.sky_wavelength - 557.7) lt 5. then begin
       lamda = '5577'
       doing_green = 1
    endif
    if abs(host.operation.calibration.sky_wavelength - 630.0) lt 5. then begin
       lamda = '6300'
       doing_red = 1
    endif

    marg = 16 < n_elements(resarr)/2 - 1
    if not(doing_sodium) then rex = indgen(n_elements(resarr)) else begin
       tsbrite = fltarr(n_elements(resarr))
       tsbgnd  = fltarr(n_elements(resarr))
       for j=0,n_elements(resarr)-1 do begin
           tsbrite(j) = median(resarr(j).intensity)
           tsbgnd(j)  = median(resarr(j).background)
       endfor
       rex = where(tsbrite gt 2. and tsbrite lt 100. and tsbgnd lt 1000.) 
;       rex = [indgen(marg), indgen(marg) + n_elements(resarr) - marg - 1]
    endelse

    sdi2k_remove_radial_residual, resarr, parname='VELOCITY', recsel=rex
    sdi2k_remove_radial_residual, resarr, parname='TEMPERATURE', recsel=rex
    sdi2k_remove_radial_residual, resarr, parname='INTENSITY', /multiplicative, recsel=rex
    pv = resarr.intensity
    pv = pv(sort(pv))
    nv = n_elements(pv)
    resarr.intensity = resarr.intensity - pv(0.02*nv)
    sdi2k_physical_units, resarr
    sdi2k_build_1dwindpars, windfit, resarr, windpars

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
; goto, RES_TS ;####

;---Chi-squared histogram:
    scale = {xrange: [0., 4.], auto_scale: 0, nbins: 200}
    geo   = {xsize:  xsize, ysize: ysize}
    histplot_settings = {scale: scale, parameter: 15, zones: 'All', black_bgnd: 1, geometry: geo, records: [0, maxrec-2]}
    sdi2k_histogram_plotter, tlist, tcen, datestr, resarr, histplot_settings
    sdi2k_batch_plotsave, gif_path, year, doy, 'chi'

;---Wind Chi-squared:
    scale = {yrange: [0., 20.], auto_scale: 0}
    geo   = {xsize:  xsize, ysize: ysize}
    hwm   = {plot_hwm: 1, f10pt7: 150., ap: 15., hwm_height: 240.}
    windparplot_settings = {scale: scale, parameter: 11, black_bgnd: 1, geometry: geo, records: [0, maxrec-2], hwm: hwm}
    if doing_red    then windparplot_settings.scale.yrange = [-300., 300]
    if doing_green  then windparplot_settings.scale.yrange = [-200., 200]
    if doing_sodium then windparplot_settings.scale.yrange = [-180., 180]
    
    if doing_red    then windparplot_settings.hwm.hwm_height = 240.
    if doing_green  then windparplot_settings.hwm.hwm_height = 120.
    if doing_sodium then windparplot_settings.hwm.hwm_height = 90.

    sdi2k_wpar_plotter, tlist, tcen, datestr, windpars, windparplot_settings
    sdi2k_batch_plotsave, gif_path, year, doy, 'wx2'
    
;---Zonal Wind Time series:

    windparplot_settings.parameter = 3
    sdi2k_wpar_plotter, tlist, tcen, datestr, windpars, windparplot_settings
    sdi2k_batch_plotsave, gif_path, year, doy, 'zon'

;---Meridional Wind Time series:
    windparplot_settings.parameter = 4
    sdi2k_wpar_plotter, tlist, tcen, datestr, windpars, windparplot_settings
    sdi2k_batch_plotsave, gif_path, year, doy, 'mer'

;---Vorticity Time series:
    windparplot_settings.parameter = 9
    windparplot_settings.scale.yrange = [-1.5, 1.5]
    sdi2k_wpar_plotter, tlist, tcen, datestr, windpars, windparplot_settings
    sdi2k_batch_plotsave, gif_path, year, doy, 'vor'

;---Divergence Time series:
    windparplot_settings.parameter = 10
    windparplot_settings.scale.yrange = [-1.5, 1.5]
    sdi2k_wpar_plotter, tlist, tcen, datestr, windpars, windparplot_settings
    sdi2k_batch_plotsave, gif_path, year, doy, 'div'

RES_TS:
;---Vertical Wind time series:
    scale = {time_range: [0., 1.], yrange: [-180., 180.], auto_scale: 0}
    geo   = {xsize:  xsize, ysize: ysize}
    msis  = {tsplot_msis,   plot_msis: 1, $
                               f10pt7: 120., $
                                   ap: 15., $
                          msis_height: 120.}
    tsplot_settings = {scale: scale, parameter: 4, zones: 'Zenith', black_bgnd: 1, geometry: geo, records: [0, maxrec-2], msis: msis}
    sdi2k_tseries_plotter, tlist, tcen, datestr, resarr, tsplot_settings
    sdi2k_batch_plotsave, gif_path, year, doy, 'Vz_'

;---Median Temperature Time Series:
    if doing_red    then tsplot_settings.scale.yrange = [500., 1500.]
    if doing_green  then tsplot_settings.scale.yrange = [200., 700.]
    if doing_sodium then tsplot_settings.scale.yrange = [800., 1500.]
    if doing_red    then tsplot_settings.msis.msis_height = 240.
    if doing_green  then tsplot_settings.msis.msis_height = 120.
    if doing_sodium then tsplot_settings.msis.msis_height = 90.

    tsplot_settings.zones = 'Median'
    tsplot_settings.parameter = 5
    sdi2k_tseries_plotter, tlist, tcen, datestr, resarr, tsplot_settings
    sdi2k_batch_plotsave, gif_path, year, doy, 'xyT'
    
;---Scatter plot temperature against signal2noise:
    if doing_red    then scale = {auto_scale: 0, xrange: [100., 1e5], yrange: [0., 1500.]}
    if doing_green  then scale = {auto_scale: 0, xrange: [100., 1e5], yrange: [0., 1000.]}
    if doing_sodium then scale = {auto_scale: 0, xrange: [100., 1e5], yrange: [0., 1500.]}

    scatplot_settings = {scale: scale, parameter: [14, 5], zones: 'All', black_bgnd: 1, geometry: geo, records: [0, maxrec-2]}
    sdi2k_scatter_plotter, tlist, tcen, datestr, resarr, scatplot_settings
    sdi2k_batch_plotsave, gif_path, year, doy, 'snr'

 ;goto, PLOTZ_DONE  ; ####
; goto, SKIP_SMOOTHING  ; ####

;---Now do some smoothing prior to making the maps:

    if doing_red    then tsm = 0.9
    if doing_green  then tsm = 0.8
    if doing_sodium then tsm = 1.2
    if doing_red    then ssm = 0.06
    if doing_green  then ssm = 0.06
    if doing_sodium then ssm = 0.05

    posarr = resarr.velocity
    print, 'Time smoothing winds...'
    sdi2k_timesmooth_fits,  posarr, tsm
    print, 'Space smoothing winds...'
    sdi2k_spacesmooth_fits, posarr, ssm
    resarr.velocity = posarr
    if maxrec gt 3 then resarr.velocity = resarr.velocity - total(resarr(1:maxrec-2).velocity(0))/n_elements(resarr(1:maxrec-2).velocity(0))

    if doing_red    then tsm = 1.2
    if doing_green  then tsm = 1.0
    if doing_sodium then tsm = 1.2
    if doing_red    then ssm = 0.06
    if doing_green  then ssm = 0.06
    if doing_sodium then ssm = 0.05

    tprarr = resarr.temperature
    print, 'Time smoothing temperatures...'
    sdi2k_timesmooth_fits,  tprarr, tsm
    print, 'Space smoothing temperatures...'
    sdi2k_spacesmooth_fits, tprarr, ssm
    resarr.temperature = tprarr

;---For SODIUM work only, do a little intensity smoothing too...
    if doing_sodium then begin
       print, 'Time smoothing intensities...'
       intenarr = resarr.intensity
       sdi2k_timesmooth_fits,  intenarr, 1.0
       print, 'Space smoothing intensities...'
       sdi2k_spacesmooth_fits, intenarr, 0.05
       resarr.intensity = intenarr
    endif
    
SKIP_SMOOTHING:
;---Set the bitmap size for skymaps:
    ysize = 2*85 + 85*maxrec/10.
    device, set_resolution=[xsize,ysize]

;---Map LOS winds:
    scale = {yrange: [-150., 150.], auto_scale: 0}
    if doing_red    then scale = {yrange: [-400., 400.], auto_scale: 0}
    if doing_sodium then scale = {yrange: [-150., 150.], auto_scale: 0}
    if doing_green  then scale = {yrange: [-150., 150.], auto_scale: 0}
    geo   = {xsize:  xsize, ysize: ysize}
    skymap_settings = {scale: scale, parameter: 4, black_bgnd: 1, geometry: geo, records: [0, maxrec-2]}
    sdi2k_sky_mapper, tlist, tcen, datestr, resarr, skymap_settings, palette=palette
    sdi2k_batch_plotsave, gif_path, year, doy, 'los', palette=palette

;---Map temperatures:
    skymap_settings.parameter = 5
    skymap_settings.scale.yrange = [200., 700.]
    if doing_green  then skymap_settings.scale.yrange = [200., 700.]
    if doing_sodium then skymap_settings.scale.yrange = [700., 1500.]
    if doing_red    then skymap_settings.scale.yrange = [600., 1600.]
    sdi2k_sky_mapper, tlist, tcen, datestr, resarr, skymap_settings
    sdi2k_batch_plotsave, gif_path, year, doy, 'tpr'

;---Map intensities:
    skymap_settings.parameter = 6
    skymap_settings.scale.yrange = [0., 80]
    if doing_green  then skymap_settings.scale.yrange = [0., 1500.]
    if doing_sodium then skymap_settings.scale.yrange = [0., 100.]
    if doing_red    then skymap_settings.scale.yrange = [0., 1000.]
    sdi2k_sky_mapper, tlist, tcen, datestr, resarr, skymap_settings, palette=palette
    sdi2k_batch_plotsave, gif_path, year, doy, 'int', palette=palette

;---Make temperature/Intensity RGB skymaps:
    if doing_green  then yrange = [[200., 700.],  [ 0., 1500.], [0., 4e15]]
    if doing_sodium then yrange = [[700., 1500.], [0., 80.],    [0., 4e15]]
    if doing_red    then yrange = [[600., 1400.], [0., 1000.],  [0., 4e15]]
    
    rgbmap_scale = {rgbmap_scale, auto_scale: 0, $
                                      yrange: yrange, $
                           menu_configurable: 1, $
                               user_editable: [0,1]}
    rgbmap_geom  = {rgbmap_geom, viewing_from_above: 0, $
                              radius_maps_to_distance: 0, $
                                       north_rotation: 0, $
                                    menu_configurable: 1, $
                                        user_editable: [0,1,2]}
    rgbmap_settings = {scale: rgbmap_scale, parameter: [5, 6, 4], black_bgnd: 1, map_view: rgbmap_geom, geometry: geo, records: [0, maxrec-2]}

    sdi2k_sky_rgbmap, tlist, tcen, datestr, resarr, rgbmap_settings, /no_purple, palette=palette
    sdi2k_batch_plotsave, gif_path, year, doy, 'tbr', palette=palette
    
    
;---Setup the wind mapping:
    if doing_green  then scale = {yrange: 200., auto_scale: 0}
    if doing_sodium then scale = {yrange: 200., auto_scale: 0}
    if doing_red    then scale = {yrange: 400., auto_scale: 0}
    ysize = ysize*2
    device, set_resolution=[xsize,ysize]
    geo   = {xsize:  xsize, ysize: ysize}
    pp  = 'Map'
    oo  = 'Magnetic Noon at Top'
    windmap_settings = {scale: scale, perspective: pp, orientation: oo, black_bgnd: 1, geometry: geo, records: [0, maxrec-2]}
    sdi2k_wind_mapper, tlist, tcen, datestr, windfit, windmap_settings
    sdi2k_batch_plotsave, gif_path, year, doy, 'vec', palette=palette

;---Setup dial plotting:
    if doing_green  then scale = {yrange: 200., auto_scale: 0, minute_step: 35., magnetic_midnight: 11.3}
    if doing_sodium then scale = {yrange: 200., auto_scale: 0, minute_step: 35., magnetic_midnight: 11.3}
    if doing_red    then scale = {yrange: 400., auto_scale: 0, minute_step: 35., magnetic_midnight: 11.3}
    ysize = 1000
    ysize = 900
    device, set_resolution=[xsize,ysize]
    geo   = {xsize:  xsize, ysize: ysize}
    cirplot_settings = {scale: scale, black_bgnd: 1, geometry: geo, records: [0, maxrec-2]}
    sdi2k_dial_mapper, tlist, tcen, datestr, windfit, cirplot_settings
    sdi2k_batch_plotsave, gif_path, year, doy, 'cir'

PLOTZ_DONE:
    set_plot, 'WIN'
 end





