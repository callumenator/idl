; Example call:  sdi2k_batch_distiller, 'D:\USERS\sdi2000\data\SKY2001306.PF', resfile
;=======================================================================================================

@sdi2k_ncdf.pro
@sdi2kprx.pro


;---Add one note to the netCDF file:
pro sdi2k_note_distiller, ncid, thisline
    nnum = 0
    ncdf_attget, ncid, 'Note_' + string(nnum, format='(i2.2)'), note, /global
    while strpos(note, '          ') ne 0 do begin
       nnum = nnum + 1
       ncdf_attget, ncid, 'Note_' + string(nnum, format='(i2.2)'), note, /global
    endwhile
    ncdf_attput, ncid, 'Note_' + string(nnum, format='(i2.2)'), thisline, /char, /global
end

pro sdi2k_batch_distiller, skyfile, resfile, log_filter=log_filter
@sdi2kinc.pro

    set_plot, 'Z'
    device, set_colors=256
 
 ;---Initialize various data:
    load_pal, culz, proportion=0.5
    sdi2k_data_init, culz
    view = transpose(view)
    
;---Open the sky file:
    sdi2k_ncopen, skyfile, ncid, 0
    ncdf_diminq, ncid, ncdf_dimid(ncid, 'Time'),    dummy,  maxrec
    nsum = intarr(maxrec)
    ncdf_varget,  ncid, ncdf_varid(ncid, 'Number_Summed'), nsum, offset=[0], count=[maxrec]
    if n_elements(zone_map) lt 1 then sdi2k_build_zone_map

;---Get the wind results:
    sdi2k_build_windres, ncid, windfit

;---Get the peak fitting results and condition them as needed:
    if n_elements(resarr) gt 0 then undefine, resarr
    sdi2k_build_fitres, ncid, resarr
    sdi2k_drift_correct, resarr, source_file=skyfile, /force
    sdi2k_remove_radial_residual, resarr, parname='VELOCITY'
    sdi2k_remove_radial_residual, resarr, parname='INTENSITY', /multiplicative
    sdi2k_remove_radial_residual, resarr, parname='TEMPERATURE'
    pv = resarr.intensity
    pv = pv(sort(pv))
    nv = n_elements(pv)
    resarr.intensity = resarr.intensity - pv(0.02*nv)
    sdi2k_physical_units, resarr
    sdi2k_build_1dwindpars, windfit, resarr, windpars

;---Get some wind fit attributes:
    ncdf_attget, ncid, 'Wind Fitting Method',                  wind_method,     /global
    ncdf_attget, ncid, 'Wind Fitting Assumption',              wind_assumption, /global
    ncdf_attget, ncid, 'Assumed Emission Height for Wind Fit', wind_height,     /global
    
;---Close the skyfile:
    ncdf_close, ncid
    host.netcdf(0).ncid = -1
    
;---Now retrieve the log file information, if any, to determine if we should keep this file:
    logfile = 'c:\inetpub\wwwroot\conde\sdiplots\log\' + $
               strmid(dt_tm_mk(js2jd(0d)+1, resarr(0).start_time, format='Y$-n$0d$'), 2, 99) + '.txt'
    filter_by_logfile, logfile, log_filter, acceptable
    if not(acceptable) then return

;---Now do some smoothing:
    tsmooth = 1.2
    ssmooth = 0.08
    posarr = resarr.velocity
    print, 'Time smoothing winds...'
    sdi2k_timesmooth_fits,  posarr, tsmooth
    print, 'Space smoothing winds...'
    sdi2k_spacesmooth_fits, posarr, ssmooth
    resarr.velocity = posarr
    if maxrec gt 3 then resarr.velocity = resarr.velocity - total(resarr(1:maxrec-2).velocity(0))/n_elements(resarr(1:maxrec-2).velocity(0))

    tprarr = resarr.temperature
    print, 'Time smoothing temperatures...'
    sdi2k_timesmooth_fits,  tprarr, tsmooth
    print, 'Space smoothing temperatures...'
    sdi2k_spacesmooth_fits, tprarr, ssmooth
    resarr.temperature = tprarr


;---Create the results file:
    clobber = host.operation.logging.log_overwrite
    host.operation.logging.log_overwrite = 1
    resfile = host.operation.logging.log_directory + $
              'SDI_' + host.operation.header.site_code + '_L2_' + $
               dt_tm_mk(js2jd(0d)+1, resarr(0).start_time, format='Y$_n$_0d$') + '.nc'    
    sdi2k_ncdf_create, resfile, ncid, 0, /nospex, /not_now
    host.operation.logging.log_overwrite    = clobber
    
;---Get dimension info: 
    ncdf_control, ncid, /fill, oldfill=nc_nodata
    timeid = ncdf_dimid(ncid, 'Time')
    zoneid = ncdf_dimid(ncid, 'Zone')
    ncnrings = host.operation.zones.fov_rings
    ringid = ncdf_dimid(ncid, 'Ring')

;---Add variables for the the level1 fit results:
    sdi2k_addvar, ncid, 'Line_Of_Sight_Wind', [zoneid, timeid], $
			'm/s',                /float
    sdi2k_addvar, ncid, 'Temperature',        [zoneid, timeid], $
			'Kelvin',             /float
    sdi2k_addvar, ncid, 'Peak_Area',          [zoneid, timeid], $
			'Signal Counts',      /float
    sdi2k_addvar, ncid, 'Background',         [zoneid, timeid], $
			'Signal Counts per Channel',      /float
    sdi2k_addvar, ncid, 'Sigma_LOS_Wind',     [zoneid, timeid], $
			'm/s',                /float
    sdi2k_addvar, ncid, 'Sigma_Temperature',  [zoneid, timeid], $
			'Kelvin',             /float
    sdi2k_addvar, ncid, 'Sigma_Area',         [zoneid, timeid], $
			'Signal Counts',      /float
    sdi2k_addvar, ncid, 'Sigma_Bgnd',         [zoneid, timeid], $
			'Signal Counts per Channel',      /float
    sdi2k_addvar, ncid, 'Chi_Squared',        [zoneid, timeid], $
			'Dimensionless',      /float
    sdi2k_addvar, ncid, 'Signal_to_Noise',    [zoneid, timeid], $
			'Dimensionless',      /float

;---Add the level 2 variables:
       sdi2k_addvar, ncid, 'Zonal_Wind',      [zoneid, timeid], $
                           'Horizontal m/s, mag eastward +ve',   /float
       sdi2k_addvar, ncid, 'Meridional_Wind', [zoneid, timeid], $
                           'Horizontal m/s, mag northward +ve',   /float
       sdi2k_addvar, ncid, 'Fitted_LOS_Wind', [zoneid, timeid], $
                           'Horizontal m/s, +ve away',   /float
       sdi2k_addvar, ncid, 'Fitted_Perpendicular_Wind', [zoneid, timeid], $
                           'Horizontal m/s, +ve left seen from above',   /float
       sdi2k_addvar, ncid, 'Vertical_Wind',   [timeid], $
                           'm/s, +ve up',   /float
       sdi2k_addvar, ncid, 'U_0',             [ringid, timeid], $
                           'm/s, mag eastward +ve',   /float
       sdi2k_addvar, ncid, 'V_0',             [ringid, timeid], $
                           'm/s, mag northward +ve',   /float
       sdi2k_addvar, ncid, 'du/dx',             [ringid, timeid], $
                           'Inverse seconds',   /float
       sdi2k_addvar, ncid, 'du/dy',             [ringid, timeid], $
                           'Inverse seconds',   /float
       sdi2k_addvar, ncid, 'dv/dx',             [ringid, timeid], $
                           'Inverse seconds',   /float
       sdi2k_addvar, ncid, 'dv/dy',             [ringid, timeid], $
                           'Inverse seconds',   /float
       sdi2k_addvar, ncid, 'Wind_Chi_Squared',   [timeid], $
                           'Dimensionless',   /float
       sdi2k_addvar, ncid, 'Zone_Azimuths',     [zoneid], $
                           'Degrees east from geographic north',   /float
       sdi2k_addvar, ncid, 'Zone_Zenith_Angles',     [zoneid], $
                           'Degrees from geographic zenith',   /float
       sdi2k_addvar, ncid, 'Zone_Latitudes',     [zoneid], $
                           'Degrees north geographic',   /float
       sdi2k_addvar, ncid, 'Zone_Longitudes',     [zoneid], $
                           'Degrees east geographic',   /float
       sdi2k_addvar, ncid, 'Zone_Meridional_Distances',     [zoneid], $
                           'Meters north geographic',   /float
       sdi2k_addvar, ncid, 'Zone_Zonal_Distances',     [zoneid], $
                           'Meters east geographic',   /float
       sdi2k_addvar, ncid, 'Time_Smoothing',    [timeid], $
                           '1/e half-width in exposure numbers',   /float
       sdi2k_addvar, ncid, 'Spatial_Smoothing',    [timeid], $
                           '1/e half-width in percent of FOV',   /float
    ncdf_control, ncid, /sync 

;---Add the level 2 attributes:
    now = dt_tm_mak(js2jd(0d)+1, dt_tm_tojs(systime()), format='Y$-n$-0d$ h$:m$')
    
    
    tries = 0
bdf1:
    tries = tries + 1
    on_error, 3
    on_ioerror, bdf1x

    ncdf_control, ncid, /redef
    goto, bdf1y
bdf1x:
    ncdf_control, ncid, /abort
    wait, 0.01
    ncid = ncdf_open (resfile, /write)
    if tries gt 200 then begin
       ncid = -1
       return
    endif
    goto, bdf1
bdf1y:  

    ncdf_attput,  ncid, 'Wind Fitting Method',                  wind_method,     /global
    ncdf_attput,  ncid, 'Wind Fitting Assumption',              wind_assumption, /global
    ncdf_attput,  ncid, 'Assumed Emission Height for Wind Fit', wind_height,     /global
    ncdf_attput,  ncid, 'Geographic azimuth of magnetic north', '28.5 degrees',  /global
    ncdf_attput,  ncid, 'Export file creation date',            now,             /global
    ncdf_attput,  ncid, 'Principal Investigator',               'Mark Conde, Geophysical Institute University of Alaska',    /global
    ncdf_attput,  ncid, 'PI contact email',                     'mark.conde@gi.alaska.edu', /global
    ncdf_control, ncid, /fill, oldfill=nc_nodata
    ncdf_control, ncid, /endef
    ncdf_control, ncid, /sync 


;---Add the level1 fit data:
    for rec=0,maxrec-1 do begin
	ncdf_varput, ncid, ncdf_varid(ncid, 'Start_Time'),         resarr(rec).start_time,        offset=[rec]
	ncdf_varput, ncid, ncdf_varid(ncid, 'End_Time'),           resarr(rec).end_time,          offset=[rec]
	ncdf_varput, ncid, ncdf_varid(ncid, 'Line_Of_Sight_Wind'), resarr(rec).velocity,          offset=[0,  rec]
	ncdf_varput, ncid, ncdf_varid(ncid, 'Sigma_LOS_Wind'),     resarr(rec).sigma_velocity,    offset=[0,  rec]
	ncdf_varput, ncid, ncdf_varid(ncid, 'Temperature'),        resarr(rec).temperature,       offset=[0,  rec]
	ncdf_varput, ncid, ncdf_varid(ncid, 'Sigma_Temperature'),  resarr(rec).sigma_temperature, offset=[0,  rec]
	ncdf_varput, ncid, ncdf_varid(ncid, 'Peak_Area'),          resarr(rec).intensity,         offset=[0,  rec]
	ncdf_varput, ncid, ncdf_varid(ncid, 'Sigma_Area'),         resarr(rec).sigma_intensities, offset=[0,  rec]
	ncdf_varput, ncid, ncdf_varid(ncid, 'Background'),         resarr(rec).background,        offset=[0,  rec]
	ncdf_varput, ncid, ncdf_varid(ncid, 'Sigma_Bgnd'),         resarr(rec).sigma_background,  offset=[0,  rec]
	ncdf_varput, ncid, ncdf_varid(ncid, 'Signal_to_Noise'),    resarr(rec).signal2noise,      offset=[0,  rec]
	ncdf_varput, ncid, ncdf_varid(ncid, 'Chi_Squared'),        resarr(rec).chi_squared,       offset=[0,  rec]
        ncdf_varput, ncid, ncdf_varid(ncid, 'Number_Summed'),      nsum(rec),                     offset=[rec]
	ncdf_varput, ncid, ncdf_varid(ncid, 'Time_Smoothing'),     tsmooth,                       offset=[rec]
	ncdf_varput, ncid, ncdf_varid(ncid, 'Spatial_Smoothing'),  ssmooth,                       offset=[rec]
    endfor

;---Add the level 2 data:
    ncdf_varput, ncid, ncdf_varid(ncid, 'Zonal_Wind'),                windfit.zonal_wind
    ncdf_varput, ncid, ncdf_varid(ncid, 'Meridional_Wind'),           windfit.meridional_wind
    ncdf_varput, ncid, ncdf_varid(ncid, 'Vertical_Wind'),             windfit.vertical_wind
    ncdf_varput, ncid, ncdf_varid(ncid, 'Fitted_LOS_Wind'),           windfit.fitted_los_wind
    ncdf_varput, ncid, ncdf_varid(ncid, 'Fitted_Perpendicular_Wind'), windfit.fitted_perpendicular_wind
    ncdf_varput, ncid, ncdf_varid(ncid, 'U_0'),                       transpose(windfit.u_zero)
    ncdf_varput, ncid, ncdf_varid(ncid, 'V_0'),                       transpose(windfit.v_zero)
    ncdf_varput, ncid, ncdf_varid(ncid, 'du/dx'), 		      transpose(windfit.dudx)
    ncdf_varput, ncid, ncdf_varid(ncid, 'du/dy'), 		      transpose(windfit.dudy)
    ncdf_varput, ncid, ncdf_varid(ncid, 'dv/dx'), 		      transpose(windfit.dvdx)
    ncdf_varput, ncid, ncdf_varid(ncid, 'dv/dy'), 	              transpose(windfit.dvdy)
    ncdf_varput, ncid, ncdf_varid(ncid, 'Zone_Azimuths'),             windfit.azimuths
    ncdf_varput, ncid, ncdf_varid(ncid, 'Zone_Zenith_Angles'),        windfit.zeniths
    ncdf_varput, ncid, ncdf_varid(ncid, 'Zone_Latitudes'),            windfit.zone_latitudes
    ncdf_varput, ncid, ncdf_varid(ncid, 'Zone_Longitudes'),           windfit.zone_longitudes
    ncdf_varput, ncid, ncdf_varid(ncid, 'Zone_Meridional_Distances'), windfit.meridional_distances
    ncdf_varput, ncid, ncdf_varid(ncid, 'Zone_Zonal_Distances'),      windfit.zonal_distances
    ncdf_varput, ncid, ncdf_varid(ncid, 'Wind_Chi_Squared'),          windfit.reduced_chi_squared
    ncdf_control,ncid, /sync 

;---Attempt to copy logbook entries, if any, into the netCDF export file.
;---Look for a log file:
    oneline = 'dummy'
    logfile = 'c:\inetpub\wwwroot\conde\sdiplots\log\' + $
               strmid(dt_tm_mk(js2jd(0d)+1, resarr(0).start_time, format='Y$-n$0d$'), 2, 99) + '.txt'
;---If we have a logfile, copy the relevant entries to the note fields of the netCDF output file:
    if file_test(logfile) then begin
       openr, logun, logfile, /get_lun
;------Skip the first 5 lines of the logfile; we already have this info.
       for j=0,4 do readf, logun, oneline
       while not eof(logun) do begin
             readf, logun, oneline
;------------Only keep lines with useful info entered.             
             if strpos(strupcase(oneline), ' = UNKNOWN') lt 0 then begin
                charpos  = 0 
                thisline = strmid(oneline, charpos, 78)
                sdi2k_note_distiller, ncid, thisline
                charpos = charpos + strlen(thisline)
                while charpos lt strlen(oneline) do begin
                      thisline = strmid(oneline, charpos, 78)
                      sdi2k_note_distiller, ncid, thisline
                      charpos = charpos + strlen(thisline)
                      wait, 0.01
                endwhile
             endif
       endwhile
       close, logun
       free_lun, logun
    endif
    
    ncdf_close, ncid
    host.netcdf(0).ncid = -1
 end
 





