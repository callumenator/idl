; Example call:  sdi3k_batch_plotz, 'd:\users\sdi2000\data\sky2001282.pf', resarr, windfit

pro time_clip, indata, timewin
    js2ymds, indata.start_time, y, m, d, s
    s = s + 86400.*(d - min(d))
    keepers = where(s ge 3600.*min(timewin) and s le 3600.*max(timewin), nn)
    if nn gt 0 then indata = indata(keepers)
end

;=======================================================================================================

pro sdi3k_batch_plotz, filename, xy_only=xy_only, stage=stage, skip_existing=skip_existing, plot_folder=plot_folder, timewin=timewin, drift_mode=drift_mode
if not(keyword_set(drift_mode)) then drift_mode = 'data'
data_based_drift = strupcase(drift_mode) eq 'DATA'

    sdi3k_read_netcdf_data, filename, metadata=mm, zonemap=zonemap, winds=winds, spekfits=spekfits, windpars=windpars, zone_centers=zone_centers
    if n_elements(spekfits) lt 3 then return
    goods = where(median(spekfits.signal2noise, dim=1) gt 150, ng)
    if ng gt 0 then begin
       spekfits = spekfits(goods)
       if n_elements(winds) ge ng    then winds = winds(goods)
       if n_elements(windpars) ge ng then windpars = windpars(goods)
    endif
    mm.maxrec = n_elements(spekfits)

    if not(keyword_set(skip_existing)) then skip_existing = 0
    if not(keyword_set(timewin)) then timewin = [-24., 48.]
    if mm.start_time eq mm.end_time then return
    if max(spekfits.start_time) - min(spekfits.start_time) gt 3D*86400D then return
    pmarg = 2
    if keyword_set(plot_folder) then begin
       if strpos(strupcase(plot_folder), 'REALTIME') ge 0 then pmarg=1
    endif

    time_clip, spekfits, timewin
    if n_elements(winds)    ge 2 then time_clip, winds,    timewin
    if n_elements(windpars) ge 2 then time_clip, windpars, timewin
    mm.maxrec = n_elements(spekfits)

;---Determine the wavelength:
    doing_sodium = 0
    doing_red    = 0
    doing_green  = 0
    if abs(mm.wavelength_nm - 589.0) lt 5. then begin
       lamda = '5890'
       doing_sodium = 1
       lamstring = '_sodium'
    endif
    if abs(mm.wavelength_nm - 557.7) lt 5. then begin
       lamda = '5577'
       doing_green = 1
       lamstring = '_green'
    endif
    if abs(mm.wavelength_nm - 630.0) lt 5. then begin
       lamda = '6300'
       doing_red = 1
       lamstring = '_red'
    endif

;---Apply any zero-velocity offset correction maps that have been selected:
    wind_offset = spekfits(0).velocity*0.
    if doing_green then sdi3k_get_wind_offset, getenv('SDI_GREEN_ZERO_VELOCITY_FILE'), wind_offset, mm
    if doing_red   then sdi3k_get_wind_offset, getenv('SDI_RED_ZERO_VELOCITY_FILE'),   wind_offset, mm
    for j=0,n_elements(spekfits) - 1 do begin
        spekfits(j).velocity = spekfits(j).velocity - wind_offset
    endfor

;---Check if plots already exist for this netCDF file. If so, and we're not forcing an update, then return:
    plot_dir = 'C:\cal\FPSData\RTPlot\'
    plots_exist = -1
    sdi3k_batch_plotsave, plot_dir, mm, 'Wind_Dial_Plot', test_exist=plots_exist, plot_folder=plot_folder
    if plots_exist and skip_existing then return

    while !d.window ge 0 do wdelete, !d.window
    xsize = 1400
    ysize = 800

;---Initialize various data:
    load_pal, culz, proportion=0.5

    year      = strcompress(string(mm.year),             /remove_all)
    doy       = strcompress(string(mm.start_day_ut, format='(i3.3)'),     /remove_all)
    sdi3k_drift_correct, spekfits, mm, /force, data_based=data_based_drift, insfile=drift_mode ;########
    spekfits.velocity = spekfits.velocity*mm.channels_to_velocity

    marg = 16 < n_elements(resarr)/2 - 1
    if not(doing_sodium) then rex = indgen(mm.maxrec) else begin
       tsbrite = fltarr(mm.maxrec)
       tsbgnd  = fltarr(mm.maxrec)
       for j=0,mm.maxrec-1 do begin
           tsbrite(j) = median(spekfits(j).intensity)
           tsbgnd(j)  = median(spekfits(j).background)
       endfor
;      rex = where(tsbrite gt 2. and tsbrite lt 100. and tsbgnd lt 1000.)
       rex = where(tsbrite gt 100. and tsbrite lt 5e6 and tsbgnd lt 1e7)
;       rex = [indgen(marg), indgen(marg) + n_elements(resarr) - marg - 1]
    endelse
    if n_elements(rex) lt 2 then goto, PLOTZ_DONE
    sdi3k_remove_radial_residual, mm, spekfits, parname='VELOCITY',    recsel=rex
    sdi3k_remove_radial_residual, mm, spekfits, parname='TEMPERATURE', recsel=rex, /zero_mean
    sdi3k_remove_radial_residual, mm, spekfits, parname='INTENSITY',   recsel=rex, /multiplicative
    pv = spekfits.intensity
    pv = pv(sort(pv))
    nv = n_elements(pv)
    spekfits.intensity = spekfits.intensity - pv(0.02*nv)

;---Build the time information arrays:
    tcen   = (spekfits.start_time + spekfits.end_time)/2
    tlist  = dt_tm_mk(js2jd(0d)+1, tcen, format='h$:m$')

;---Setup briteness and temperature scaling:
    britearr   = reform(spekfits.intensity)
    intord     = sort(britearr)
    britescale = [0., 1E5];1.4*britearr(intord(0.85*n_elements(intord)))]
    medtemp = median(spekfits.temperature)
    medtemp = 100*fix(medtemp/100)
;    if doing_red    then tprscale = [medtemp - 200. > 0, medtemp + 200.]
    if doing_red    then tprscale = [500., 1100.]
    if doing_green  then tprscale = [medtemp - 250. > 0, medtemp + 250.]
    if doing_sodium then tprscale = [medtemp - 350. > 0, medtemp + 350.]
    f107 = 70.
    if medtemp gt 850  then f107 = 120.
    if medtemp gt 950  then f107 = 150.
    if medtemp gt 1050 then f107 = 200.
    alt = 240.
    if abs(mm.wavelength_nm - 630.03) gt 10. then alt = 120.

    msis  = {tsplot_msis,   plot_msis: 1, $
                               f10pt7: f107, $
                                   ap: 15., $
                          msis_height: alt}
    hwm   =                 {plot_hwm: 1, $
                               f10pt7: f107, $
                                   ap: 15., $
                           hwm_height: alt}


    if not(keyword_set(stage)) then stage = 'dummy'
    if stage eq 'STAGE_SMOOTHING' then goto, STAGE_SMOOTHING
    if stage eq 'STAGE_SKYMAPS'   then goto, STAGE_SKYMAPS
    if stage eq 'STAGE_RGBMAPS'   then goto, STAGE_RGBMAPS
    if stage eq 'STAGE_WINDMAPS'  then goto, STAGE_SMOOTHING
    if stage eq 'STAGE_DIALPLOTS' then goto, STAGE_SMOOTHING

    while !d.window ge 0 do wdelete, !d.window
    window, xsize=xsize, ysize=ysize

;---Chi-squared histogram:
    scale = {xrange: [0., 3.], auto_scale: 0, nbins: 200}
    geo   = {xsize:  xsize, ysize: ysize}
    histplot_settings = {scale: scale, parameter: 'CHI_SQUARED', zones: 'All', black_bgnd: 1, geometry: geo, records: [0, mm.maxrec-pmarg]}
    sdi3k_histogram_plotter, tlist, tcen, spekfits, mm, histplot_settings, culz
    sdi3k_batch_plotsave, plot_dir, mm, 'Spectral_Fit_Chi_Squared', plot_folder=plot_folder

;---Vertical Wind time series:
    scale = {time_range: [0., 1.], yrange: [-150., 150.], auto_scale: 0}
    geo   = {xsize:  xsize, ysize: ysize}
    style =   {tsplot_style, charsize: 2, $
                            charthick: 2, $
                       line_thickness: 2, $
                       axis_thickness: 4, $
                    menu_configurable: 1, $
                        user_editable: [0,1,2,3]}
    tsplot_settings = {scale: scale, parameter: 'Velocity', zones: 'Zenith', black_bgnd: 1, geometry: geo, records: [0, mm.maxrec-pmarg], msis: msis, hwm: hwm, style: style}
    sdi3k_tseries_plotter, tlist, tcen, mm, spekfits, tsplot_settings, culz
    sdi3k_batch_plotsave, plot_dir, mm, 'Vertical_Wind', plot_folder=plot_folder

;---Median Temperature Time Series:
    tsplot_settings.scale.yrange = tprscale
    if doing_red    then tsplot_settings.msis.msis_height = 240.
    if doing_green  then tsplot_settings.msis.msis_height = 120.
    if doing_sodium then tsplot_settings.msis.msis_height = 90.

    tsplot_settings.zones = 'Median'
    tsplot_settings.parameter = 'Temperature'
    sdi3k_tseries_plotter, tlist, tcen, mm, spekfits, tsplot_settings, culz
    sdi3k_batch_plotsave, plot_dir, mm, 'Median_Temperature', plot_folder=plot_folder

;---Time Series Plot intensities:
    tsplot_settings.zones = 'All'
    tsplot_settings.parameter = 'INTENSITY'
    tsplot_settings.scale.yrange = britescale
    sdi3k_tseries_plotter, tlist, tcen, mm, spekfits, tsplot_settings, culz
    sdi3k_batch_plotsave, plot_dir, mm, 'Intensity_Vs_Time', plot_folder=plot_folder

;---Wind Chi-squared: reduced_chi_squared
    tsplot_settings.zones = ' '
    tsplot_settings.parameter = 'reduced_chi_squared'
    tsplot_settings.scale.yrange = [0, 8]
    if n_elements (winds) gt 2 then begin
       sdi3k_tseries_plotter, tlist, tcen, mm, winds, tsplot_settings, culz
       sdi3k_batch_plotsave, plot_dir, mm, 'Wind_Chi_Squared', plot_folder=plot_folder
    endif

;---Scatter plot temperature against signal2noise:
    if doing_red    then scale = {auto_scale: 0, xrange: [100., 5e4], yrange: [300., 1500.]}
    if doing_green  then scale = {auto_scale: 0, xrange: [100., 5e4], yrange: [100., 1000.]}
    if doing_sodium then scale = {auto_scale: 0, xrange: [100., 5e4], yrange: [0., 1500.]}

    scatplot_settings = {scale: scale, xpar: 'signal2noise', ypar: 'temperature', zones: 'All', black_bgnd: 1, geometry: geo, records: [0, mm.maxrec-pmarg], style: style}
    sdi3k_scatter_plotter, mm, spekfits, spekfits, scatplot_settings, culz, yunits='K'
    sdi3k_batch_plotsave, plot_dir, mm, 'Temp_vs_SNR', plot_folder=plot_folder

;---Scatter plot vertical wind against divergence:
    scale = {auto_scale: 0, xrange: [-0.7, 0.7], yrange: [-150., 150.]}
    scatplot_settings = {scale: scale, xpar: 'Divergence', ypar: 'Vertical_Wind', zones: ' ', black_bgnd: 1, geometry: geo, records: [0, mm.maxrec-pmarg], style: style}
    if n_elements(winds) gt 2 then begin
       sdi3k_scatter_plotter, mm, windpars, winds, scatplot_settings, culz, xunits='1000*s!u-1!N', yunits='m/s'
       sdi3k_batch_plotsave, plot_dir, mm, 'Vz_vs_Divergence', plot_folder=plot_folder
    endif

    if keyword_set(xy_only) then return

STAGE_SMOOTHING:
;---Now do some smoothing prior to making the maps:

    if doing_red    then tsm = 1.
    if doing_green  then tsm = 0.6
    if doing_sodium then tsm = 1.5
    if doing_red    then ssm = 0.07
    if doing_green  then ssm = 0.03
    if doing_sodium then ssm = 0.03
    if doing_green and mm.site_code eq 'HRP' then begin
       tsm = 0.4
       ssm = 0.02
    endif
    if doing_red and mm.year lt 2007   then tsm = 1.5

    posarr = spekfits.velocity
    print, 'Time smoothing winds...'
    sdi3k_timesmooth_fits,  posarr, tsm, mm
    print, 'Space smoothing winds...'
    sdi3k_spacesmooth_fits, posarr, ssm, mm, zone_centers
    spekfits.velocity = posarr
    if mm.maxrec gt 3 then spekfits.velocity = spekfits.velocity - total(spekfits(1:mm.maxrec-2).velocity(0))/n_elements(spekfits(1:mm.maxrec-2).velocity(0))

    if doing_red    then tsm = 1.2
    if doing_green  then tsm = 0.8
    if doing_sodium then tsm = 1.2
    if doing_red    then ssm = 0.07
    if doing_green  then ssm = 0.05
    if doing_sodium then ssm = 0.07
    if doing_green and mm.site_code eq 'HRP' then begin
       tsm = 0.6
       ssm = 0.05
    endif
    if doing_red and mm.year lt 2007   then tsm = 1.8
    if doing_red and mm.year lt 2007   then ssm = 0.1

    tprarr = spekfits.temperature
    print, 'Time smoothing temperatures...'
    sdi3k_timesmooth_fits,  tprarr, tsm, mm
    print, 'Space smoothing temperatures...'
    sdi3k_spacesmooth_fits, tprarr, ssm, mm, zone_centers
    spekfits.temperature = tprarr

;---For SODIUM work only, do a little intensity smoothing too...
    if doing_sodium then begin
       print, 'Time smoothing intensities...'
       intenarr = spekfits.intensity
       sdi3k_timesmooth_fits,  intenarr, 1.5, mm
       print, 'Space smoothing intensities...'
       sdi3k_spacesmooth_fits, intenarr, 0.08, mm, zone_centers
       spekfits.intensity = intenarr
    endif
    if stage eq 'STAGE_WINDMAPS'  then goto, STAGE_WINDMAPS
    if stage eq 'STAGE_DIALPLOTS' then goto, STAGE_DIALPLOTS


STAGE_SKYMAPS:

;---Set the bitmap size for skymaps:
    thumsize = 85
    xsize    = 1200
    ysize    = 2*thumsize + thumsize*mm.maxrec/(1 + xsize/thumsize)
    while !d.window ge 0 do wdelete, !d.window
    window, xsize=xsize, ysize=ysize

;---Map LOS winds:
    scale = {yrange: [-150., 150.], auto_scale: 0}
    if doing_red    then scale = {yrange: [-300., 300.], auto_scale: 0}
    if doing_sodium then scale = {yrange: [-150., 150.], auto_scale: 0}
    if doing_green  then scale = {yrange: [-150., 150.], auto_scale: 0}
    geo   = {xsize:  xsize, ysize: ysize}
    skymap_settings = {scale: scale, parameter: 'Velocity', black_bgnd: 1, geometry: geo, records: [0, mm.maxrec-pmarg]}
    sdi3k_sky_mapper, tlist, tcen, mm, spekfits, skymap_settings, culz, zonemap
    sdi3k_batch_plotsave, plot_dir, mm, 'Skymap_LOS_Wind', plot_folder=plot_folder
    load_pal, culz

;---Map temperatures:
    if doing_green and mm.site_code eq 'HRP' then tprscale = [150, 550.]
    skymap_settings.parameter = 'Temperature'
    skymap_settings.scale.yrange = tprscale
    sdi3k_sky_mapper, tlist, tcen, mm, spekfits, skymap_settings, culz, zonemap
    sdi3k_batch_plotsave, plot_dir, mm, 'Skymap_Temperature', plot_folder=plot_folder

;---Map intensities:
    skymap_settings.parameter = 'Intensity'
    skymap_settings.scale.yrange = britescale
    sdi3k_sky_mapper, tlist, tcen, mm, spekfits, skymap_settings, culz, zonemap
    sdi3k_batch_plotsave, plot_dir, mm, 'Skymap_Intensity', plot_folder=plot_folder

STAGE_RGBMAPS:
;---Set the bitmap size for RGB skymaps:
    thumsize = 85
    xsize    = 1200
    ysize    = 2*thumsize + thumsize*mm.maxrec/(1 + xsize/thumsize)
    while !d.window ge 0 do wdelete, !d.window
    window, xsize=xsize, ysize=ysize
    geo   = {xsize:  xsize, ysize: ysize}

;---Make temperature/Intensity RGB skymaps:
    yrange = [[tprscale], [britescale], [0., 4e15]]
    rgbmap_scale = {rgbmap_scale, auto_scale: 0, $
                                      yrange: yrange, $
                           menu_configurable: 1, $
                               user_editable: [0,1]}
    rgbmap_geom  = {rgbmap_geom, viewing_from_above: 0, $
                              radius_maps_to_distance: 0, $
                                       north_rotation: 0, $
                                    menu_configurable: 1, $
                                        user_editable: [0,1,2]}
    rgbmap_settings = {scale: rgbmap_scale, parameter: ['Temperature', 'Intensity', 'Background'], black_bgnd: 1, map_view: rgbmap_geom, geometry: geo, records: [0, mm.maxrec-pmarg]}

    sdi3k_sky_rgbmap, tlist, tcen, mm, spekfits, rgbmap_settings, zonemap, culz, /no_purple
    sdi3k_batch_plotsave, plot_dir, mm, 'Temperature_Brightness_RGB_Skymap', plot_folder=plot_folder

STAGE_WINDMAPS:
    if n_elements(winds) lt 3 then return

;---Wind Summary Plot:
    if doing_red    then sdi3k_batch_wind_summary, filename, culz, 300, hwm, drift_mode=drift_mode
    if doing_green  then sdi3k_batch_wind_summary, filename, culz, 150, hwm, drift_mode=drift_mode
    if doing_sodium then sdi3k_batch_wind_summary, filename, culz, 300, hwm, drift_mode=drift_mode
    sdi3k_batch_plotsave, plot_dir, mm, 'Wind_Summary', plot_folder=plot_folder
    while !d.window ge 0 do wdelete, !d.window
    window, xsize=xsize, ysize=ysize

;---Setup the wind mapping:

    if doing_green  then scale = {yrange: 150., auto_scale: 0, rbscale: tprscale, gscale: britescale, pscale: [0, 9e9]}
    if doing_sodium then scale = {yrange: 200., auto_scale: 0, rbscale: tprscale, gscale: britescale, pscale: [0, 9e9]}
    if doing_red    then scale = {yrange: 250., auto_scale: 0, rbscale: tprscale, gscale: britescale, pscale: [0, 9e9]}
    if doing_green  then load_pal, culz, idl=[8,  0]
    if doing_sodium then load_pal, culz, idl=[14, 0]
    if doing_red    then load_pal, culz, idl=[3,  0]

    cadence  = fix(mm.maxrec/100) > 1
    thumsize = 200
    xsize    = 1500
    ysize    = 2*thumsize + (thumsize*mm.maxrec/(1 + xsize/thumsize))/cadence
    while !d.window ge 0 do wdelete, !d.window
    window, xsize=xsize, ysize=ysize
    geo   = {xsize:  xsize, ysize: ysize}
    pp  = 'Map'
    oo  = 'Magnetic Noon at Top'
    windmap_settings = {scale: scale, perspective: pp, orientation: oo, black_bgnd: 1, geometry: geo, records: [0, mm.maxrec-pmarg]}
    sdi3k_read_netcdf_data, filename, metadata=mm_dummy, images=images, cadence=cadence
    if n_elements(images) gt 2 then time_clip, images, timewin
    sdi3k_wind_mapper, tlist, tcen, mm, winds, windmap_settings, culz, spekfits, zonemap, images=images, cadence=cadence
    sdi3k_batch_plotsave, plot_dir, mm, 'Wind_Vector_Maps', plot_folder=plot_folder

STAGE_DIALPLOTS:
;---Setup dial plotting:
    if n_elements(winds) lt 3 then return
    if doing_green  then scale = {yrange: 150., auto_scale: 0, minute_step: 40., magnetic_midnight: mm.magnetic_midnight, rbscale: tprscale, gscale: britescale, pscale: [0, 9e9]}
    if doing_sodium then scale = {yrange: 200., auto_scale: 0, minute_step: 40., magnetic_midnight: mm.magnetic_midnight, rbscale: tprscale, gscale: britescale, pscale: [0, 9e9]}
    if doing_red    then scale = {yrange: 250., auto_scale: 0, minute_step: 40., magnetic_midnight: mm.magnetic_midnight, rbscale: tprscale, gscale: britescale, pscale: [0, 9e9]}
    if doing_green  then load_pal, culz, idl=[8,  0]
    if doing_sodium then load_pal, culz, idl=[14, 0]
    if doing_red    then load_pal, culz, idl=[3,  0]
    ysize = 1500
    while !d.window ge 0 do wdelete, !d.window
    window, xsize=xsize, ysize=ysize
    if n_elements(images) lt 2 then sdi3k_read_netcdf_data, filename, metadata=mm_dummy, images=images, cadence=2
    geo   = {xsize:  xsize, ysize: ysize}
    cirplot_settings = {scale: scale, black_bgnd: 1, geometry: geo, records: [0, mm.maxrec-pmarg]}
    sdi3k_dial_mapper, tlist, tcen, mm, winds, cirplot_settings, culz, spekfits, zonemap, images=images
    sdi3k_batch_plotsave, plot_dir, mm, 'Wind_Dial_Plot', plot_folder=plot_folder

PLOTZ_DONE:
end





