@sdi2kprx.pro
@sdi2k_ncdf.pro

pro sdi2k_batch_windfitz, skyfile, resarr, windfit, skip_existing=skip_existing
@sdi2kinc.pro
    load_pal, culz, proportion=0.5
    sdi2k_data_init, culz
    view = transpose(view)
    
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
    height = 120.    
    if doing_red    then height = 240.
    if doing_green  then height = 120.
    if doing_sodium then height = 90.
    
    wind_settings = {time_smoothing: 0.8, $
                    space_smoothing: 0.03, $
                    dvdx_assumption: 'dv/dx = 0', $
                          algorithm: 'Fourier Fit', $
                     assumed_height: height, $
                           geometry: 'none'}
    dvdx_zero = wind_settings.dvdx_assumption ne 'dv/dx = 1/epsilon x dv/dt'
    dvdx_zero = 0 ; ###################################
    sdi2k_ncopen, skyfile, ncid, 0
    

    sdi2k_build_zone_map
    if n_elements(resarr) gt 0 then undefine, resarr
    sdi2k_build_fitres, ncid, resarr
    ncdf_close, host.netcdf(0).ncid
    host.netcdf(0).ncid = -1
    sdi2k_drift_correct, resarr, source_file=skyfile, /force, /data_based ;########3

    if getenv('SDI_ZERO_VELOCITY_FILE') ne '' then begin
       restore, getenv('SDI_ZERO_VELOCITY_FILE') 
       print, 'Using vzero map: ', getenv('SDI_ZERO_VELOCITY_FILE')
       for j=0,n_elements(resarr) - 1 do begin
           resarr(j).velocity = resarr(j).velocity - vzero
       endfor
    endif

    sdi2k_remove_radial_residual, resarr, parname='VELOCITY'
    sdi2k_physical_units, resarr
    posarr = resarr.velocity
    sdi2k_timesmooth_fits,  posarr, wind_settings.time_smoothing
    sdi2k_spacesmooth_fits, posarr, wind_settings.space_smoothing
    resarr.velocity(1:*) = posarr(1:*,*)

    nobs = n_elements(resarr)
    if nobs gt 2 then resarr.velocity = resarr.velocity - total(resarr(1:nobs-2).velocity(0))/n_elements(resarr(1:nobs-2).velocity(0))
    sdi2k_fit_wind, resarr, dvdx_zero=dvdx_zero, windfit, wind_settings.assumed_height
    sdi2k_ncopen, skyfile, ncid, 0
    sdi2k_add_windvars, ncid, windfit, wind_settings
    ncdf_close, host.netcdf(0).ncid
    host.netcdf(0).ncid = -1
 end





