

pro sdi3k_batch_windfitz, skyfile, drift_mode=drift_mode

if not(keyword_set(drift_mode)) then drift_mode = 'data'

sdi3k_read_netcdf_data, skyfile, metadata=mmsky, zonemap=zonemap, zone_centers=zone_centers, zone_edges=zone_edges, spekfits=spekfits
if mmsky.start_time eq mmsky.end_time then return

;---Determine the wavelength:
    doing_sodium = 0
    doing_red    = 0
    doing_green  = 0
    if abs(mmsky.wavelength_nm - 589.0) lt 5. then begin
       lamda = '5890'
       doing_sodium = 1
    endif
    if abs(mmsky.wavelength_nm - 557.7) lt 5. then begin
       lamda = '5577'
       doing_green = 1
    endif
    if abs(mmsky.wavelength_nm - 630.03) lt 5. then begin
       lamda = '6300'
       doing_red = 1
    endif
    height = 120.
    if doing_red    then height = 240.
    if doing_green  then height = 120.
    if doing_sodium then height = 90.

    wind_settings = {time_smoothing: 1.4, $
                    space_smoothing: 0.08, $
                    dvdx_assumption: 'dv_dx=0', $
                          algorithm: 'Fourier_Fit', $
                     assumed_height: height, $
                           geometry: 'none'}
    dvdx_zero = wind_settings.dvdx_assumption ne 'dv_dx=1_over_epsilon_times_dv_dt'
;    dvdx_zero = 0

;---Reduced smoothing for 2008 data!
    if mmsky.year gt 2007 then begin
       wind_settings.time_smoothing  = 0.9
       wind_settings.space_smoothing = 0.06
    endif
;---Extra smoothing for pre-1998 data!
    if mmsky.year lt 1998 then begin
       wind_settings.time_smoothing  = 1.6
       wind_settings.space_smoothing = 0.1
    endif
;---Less smoothing for HAARP winds:
    if mmsky.site_code eq 'HRP' then begin
       if doing_red then begin
          wind_settings.time_smoothing  = 0.6
          wind_settings.space_smoothing = 0.05
       endif
       if doing_green then begin
          wind_settings.time_smoothing  = 0.5
          wind_settings.space_smoothing = 0.04
       endif
    endif
	if mmsky.site_code eq 'MAW' then begin
		if mmsky.nzones gt 200 then wind_settings.space_smoothing = 0.001
		if mmsky.nzones gt 200 then wind_settings.time_smoothing = 0.5
	endif

    if doing_green and getenv('SDI_GREEN_ZERO_VELOCITY_FILE') ne '' then begin
       restore, getenv('SDI_GREEN_ZERO_VELOCITY_FILE')
       print, 'Using vzero map: ', getenv('SDI_GREEN_ZERO_VELOCITY_FILE')
       for j=0,n_elements(spekfits) - 1 do begin
           spekfits(j).velocity = spekfits(j).velocity - wind_offset
       endfor
    endif
    if doing_red and getenv('SDI_RED_ZERO_VELOCITY_FILE') ne '' then begin
       restore, getenv('SDI_RED_ZERO_VELOCITY_FILE')
       print, 'Using vzero map: ', getenv('SDI_RED_ZERO_VELOCITY_FILE')
       for j=0,n_elements(spekfits) - 1 do begin
           spekfits(j).velocity = spekfits(j).velocity - wind_offset
       endfor
    endif

    data_based_drift = strupcase(drift_mode) eq 'DATA'
    sdi3k_drift_correct, spekfits, mmsky, /force, data_based=data_based_drift, insfile=drift_mode ;########
    sdi3k_remove_radial_residual, mmsky, spekfits, parname='VELOCITY'
    spekfits.velocity = mmsky.channels_to_velocity*spekfits.velocity
    posarr = spekfits.velocity
    sdi3k_timesmooth_fits,  posarr, wind_settings.time_smoothing, mmsky
    sdi3k_spacesmooth_fits, posarr, wind_settings.space_smoothing, mmsky, zone_centers
    spekfits.velocity = posarr

    nobs = n_elements(spekfits)
    if nobs gt 2 then spekfits.velocity = spekfits.velocity - total(spekfits(1:nobs-2).velocity(0))/n_elements(spekfits(1:nobs-2).velocity(0))
    sdi3k_fit_wind, spekfits, mmsky, dvdx_zero=dvdx_zero, windfit, wind_settings, zone_centers
    ncid = sdi3k_nc_get_ncid(skyfile, write_allowed=1)
    sdi3k_write_windfitpars, ncid, mmsky, windfit, wind_settings
    ncid = sdi3k_nc_get_ncid(skyfile, write_allowed=0)

;---The following line forces the winds to be calculated relative to GEOGRAPHIC north:
;    mmsky.rotation_from_oval = mmsky.rotation_from_oval + mmsky.oval_angle
;    sdi3k_fit_wind, spekfits, mmsky, dvdx_zero=dvdx_zero, windfit, wind_settings, zone_centers
;    ncid = sdi3k_nc_get_ncid(skyfile, write_allowed=1)
;    sdi3k_write_windfitpars, ncid, mmsky, windfit, wind_settings, /geofit
;    ncid = sdi3k_nc_get_ncid(skyfile, write_allowed=0)

 end





