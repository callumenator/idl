;=============================================================================
;  This procedure adds variables to the netCDF logfile to store the
;  results of wind fitting.  It only adds the variables if they do not
;  already exist.
;
pro sdi3k_write_windfitpars, ncid, mm, windfit, settings, geofit=geofit

       ncnrings = mm.rings
       ncdf_control, ncid, /fill, oldfill=nc_nodata
       if keyword_set(geofit) then geo = 'GEO_' else geo = ''

       nc_desc = NCDF_INQUIRE(ncid)
        if nc_desc.ndims ge 7 then begin
            rname = 'Rings'
            radii = 'Zone_Radii'
            sectr = 'Zone_Sectors'
        endif else begin
            rname = 'Ring'
            radii = 'Ring_Radii'
            sectr = 'Sectors'
        endelse

       timeid = ncdf_dimid(ncid, 'Time')
       zoneid = ncdf_dimid(ncid, 'Zone')
       ringid = ncdf_dimid(ncid, rname)

       sdi3k_addvar, ncid, geo + 'Zonal_Wind',      [zoneid, timeid], $
                           'Horizontal m/s, mag eastward +ve',   /float
       sdi3k_addvar, ncid, geo + 'Meridional_Wind', [zoneid, timeid], $
                           'Horizontal m/s, mag northward +ve',   /float
       sdi3k_addvar, ncid, geo + 'Fitted_LOS_Wind', [zoneid, timeid], $
                           'Horizontal m/s, +ve away',   /float
       sdi3k_addvar, ncid, geo + 'Fitted_Perpendicular_Wind', [zoneid, timeid], $
                           'Horizontal m/s, +ve left seen from above',   /float
       sdi3k_addvar, ncid, geo + 'Vertical_Wind',   [timeid], $
                           'm/s, +ve up',   /float
       sdi3k_addvar, ncid, geo + 'U_0',             [ringid, timeid], $
                           'm/s, mag eastward +ve',   /float
       sdi3k_addvar, ncid, geo + 'V_0',             [ringid, timeid], $
                           'm/s, mag northward +ve',   /float

       sdi3k_addvar, ncid, geo + 'du_dx',             [ringid, timeid], $
                           'Inverse seconds',   /float
       sdi3k_addvar, ncid, geo + 'du_dy',             [ringid, timeid], $
                           'Inverse seconds',   /float
       sdi3k_addvar, ncid, geo + 'dv_dx',             [ringid, timeid], $
                           'Inverse seconds',   /float
       sdi3k_addvar, ncid, geo + 'dv_dy',             [ringid, timeid], $
                           'Inverse seconds',   /float
       sdi3k_addvar, ncid, geo + 'Wind_Chi_Squared',   [timeid], $
                           'Dimensionless',   /float
       sdi3k_addvar, ncid, geo + 'Zone_Azimuths',     [zoneid], $
                           'Degrees east from geographic north',   /float
       sdi3k_addvar, ncid, geo + 'Zone_Zenith_Angles',     [zoneid], $
                           'Degrees from geographic zenith',   /float
       sdi3k_addvar, ncid, geo + 'Zone_Latitudes',     [zoneid], $
                           'Degrees north geographic',   /float
       sdi3k_addvar, ncid, geo + 'Zone_Longitudes',     [zoneid], $
                           'Degrees east geographic',   /float
       sdi3k_addvar, ncid, geo + 'Zone_Meridional_Distances',     [zoneid], $
                           'Meters north geographic',   /float
       sdi3k_addvar, ncid, geo + 'Zone_Zonal_Distances',     [zoneid], $
                           'Meters east geographic',   /float
       sdi3k_addvar, ncid, geo + 'Time_Smoothing',    [timeid], $
                           '1/e half-width in exposure numbers',   /float
       sdi3k_addvar, ncid, geo + 'Spatial_Smoothing',    [timeid], $
                           '1/e half-width in percent of FOV',   /float

       ncdf_control, ncid, /noverbose
       attstat = ncdf_attinq(ncid, geo + 'Wind_Fitting_Time', /global)
       ncdf_control, ncid, /verbose

       trycount = 0
       outcome = 'fail'
WINDATT_ADDER:

       trycount = trycount + 1
       if attstat.datatype eq 'UNKNOWN' then begin
          on_error, 3
          on_ioerror, WINDATT_ERR
          ncdf_control, ncid, /redef
          outcome = 'ok'
          nowtime = dt_tm_mk(js2jd(0d)+1, dt_tm_tojs(systime()), format='0d$ n$ Y$, h$:m$')
          ncdf_attput, ncid, geo + 'Wind_Fitting_Time', nowtime, /global
          ncdf_attput, ncid, geo + 'Wind_Fitting_Routine', $
                             'IDL_sdi3000_suite', /global
          ncdf_attput, ncid, geo + 'Wind_Fitting_Method', $
                             settings.algorithm, /global
          ncdf_attput, ncid, geo + 'Wind_Fitting_Assumption', $
                             settings.dvdx_assumption, /global
          ncdf_attput, ncid, geo + 'Assumed_Emission_Height_for_Wind_Fit', $
                             settings.assumed_height, /global
          ncdf_attput, ncid, 'Geographic_azimuth_of_magnetic_north', $
                             strcompress(string(mm.oval_angle, format='(f12.1)'), /remove_all) + ' degrees', /global
          ncdf_control, ncid, /fill, oldfill=nc_nodata
          ncdf_control, ncid, /endef
       endif
WINDATT_ERR:
        if outcome ne 'ok' and trycount lt 50 then goto, WINDATT_ADDER

on_ioerror, NULL
       ncdf_varput, ncid, ncdf_varid(ncid, geo + 'Zonal_Wind'),                windfit.zonal_wind
       ncdf_varput, ncid, ncdf_varid(ncid, geo + 'Meridional_Wind'),           windfit.meridional_wind
       ncdf_varput, ncid, ncdf_varid(ncid, geo + 'Vertical_Wind'),             windfit.vertical_wind
       ncdf_varput, ncid, ncdf_varid(ncid, geo + 'Fitted_LOS_Wind'),           windfit.fitted_los_wind
       ncdf_varput, ncid, ncdf_varid(ncid, geo + 'Fitted_Perpendicular_Wind'), windfit.fitted_perpendicular_wind
       ncdf_varput, ncid, ncdf_varid(ncid, geo + 'U_0'),                       transpose(windfit.u_zero)
       ncdf_varput, ncid, ncdf_varid(ncid, geo + 'V_0'),                       transpose(windfit.v_zero)
       ncdf_varput, ncid, ncdf_varid(ncid, geo + 'du_dx'),             transpose(windfit.dudx)
       ncdf_varput, ncid, ncdf_varid(ncid, geo + 'du_dy'),             transpose(windfit.dudy)
       ncdf_varput, ncid, ncdf_varid(ncid, geo + 'dv_dx'),             transpose(windfit.dvdx)
       ncdf_varput, ncid, ncdf_varid(ncid, geo + 'dv_dy'),             transpose(windfit.dvdy)
       ncdf_varput, ncid, ncdf_varid(ncid, geo + 'Zone_Azimuths'),             windfit.azimuths
       ncdf_varput, ncid, ncdf_varid(ncid, geo + 'Zone_Zenith_Angles'),        windfit.zeniths
       ncdf_varput, ncid, ncdf_varid(ncid, geo + 'Zone_Latitudes'),            windfit.zone_latitudes
       ncdf_varput, ncid, ncdf_varid(ncid, geo + 'Zone_Longitudes'),           windfit.zone_longitudes
       ncdf_varput, ncid, ncdf_varid(ncid, geo + 'Zone_Meridional_Distances'), windfit.meridional_distances
       ncdf_varput, ncid, ncdf_varid(ncid, geo + 'Zone_Zonal_Distances'),      windfit.zonal_distances
       ncdf_varput, ncid, ncdf_varid(ncid, geo + 'Wind_Chi_Squared'),          windfit.reduced_chi_squared
       ncdf_varput, ncid, ncdf_varid(ncid, geo + 'Time_Smoothing'),            replicate(settings.time_smoothing,  n_elements(windfit.reduced_chi_squared))
       ncdf_varput, ncid, ncdf_varid(ncid, geo + 'Spatial_Smoothing'),         replicate(settings.space_smoothing, n_elements(windfit.reduced_chi_squared))
end

