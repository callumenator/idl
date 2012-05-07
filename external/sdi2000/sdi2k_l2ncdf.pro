;


;========================================================================
; Create a new netCDF log file:
pro sdi2k_l2ncdf_create, file, ncid, vid
@sdi2kinc.pro

       ncdf_control, 0, /verbose

;------Open a new file:
       ncid = -1
       ncid = ncdf_create (file, clobber=host.operation.logging.log_overwrite)
       if host.netcdf(vid).ncid eq -1 then begin
          sdi2k_user_message, '>>>Error: Request to create new log file ' + file + ' failed', /beep
          return
       endif else sdi2k_user_message, 'Created new log file: ' + file

;------Create the dimensions:
       tid = ncdf_dimdef (ncid, "Time",    /unlimited)
       zid = ncdf_dimdef (ncid, "Zone",    total(host.operation.zones.sectors(0:host.operation.zones.fov_rings-1)))
       cid = ncdf_dimdef (ncid, "Channel", host.hardware.etalon.scan_channels)
       rid = ncdf_dimdef (ncid, "Ring",    host.operation.zones.fov_rings)

;------Create the variables:
       id = ncdf_vardef  (ncid, "Start_Time",      tid, /long)
       id = ncdf_vardef  (ncid, "End_Time",        tid, /long)
       id = ncdf_vardef  (ncid, "Spectra",        [zid, cid, tid], /long)
       id = ncdf_vardef  (ncid, "Number_Summed",   tid, /short)
       id = ncdf_vardef  (ncid, "FOV_Rings",            /byte)
       id = ncdf_vardef  (ncid, "Ring_Radii",      rid, /float)
       id = ncdf_vardef  (ncid, "Sectors",         rid, /byte) 
       id = ncdf_vardef  (ncid, "X_Center",             /float)
       id = ncdf_vardef  (ncid, "Y_Center",             /float)
       id = ncdf_vardef  (ncid, "Gap",                  /float)
       id = ncdf_vardef  (ncid, "Start_Spacing",        /short)
       id = ncdf_vardef  (ncid, "Channel_Spacing",      /float)
       id = ncdf_vardef  (ncid, "Nm_Per_Step",          /float)
       id = ncdf_vardef  (ncid, "Scan_Channels",        /short)
       id = ncdf_vardef  (ncid, "Gap_Refractive_Index", /float)
       id = ncdf_vardef  (ncid, "Sky_Wavelength",       /float)
       id = ncdf_vardef  (ncid, "Cal_Wavelength",       /float)
       id = ncdf_vardef  (ncid, "Cal_Temperature",      /float)
       id = ncdf_vardef  (ncid, "Sky_Mass",             /float)
       id = ncdf_vardef  (ncid, "Cal_Mass",             /float)
       id = ncdf_vardef  (ncid, "Sky_Ref_Finesse",      /float)
       id = ncdf_vardef  (ncid, "Cal_Ref_Finesse",      /float)
       id = ncdf_vardef  (ncid, "Sky_FOV",              /float)

;------Describe the units of each variable:
       ncdf_attput, ncid, ncdf_varid(ncid, "Start_Time"),           "Units", "Seconds since 00 UT on January 1, 2000", /char
       ncdf_attput, ncid, ncdf_varid(ncid, "End_Time"),             "Units", "Seconds since 00 UT on January 1, 2000", /char
       ncdf_attput, ncid, ncdf_varid(ncid, "Spectra"),              "Units", "Camera digital units", /char
       ncdf_attput, ncid, ncdf_varid(ncid, "Number_Summed"),        "Units", "Etalon scans", /char
       ncdf_attput, ncid, ncdf_varid(ncid, "FOV_Rings"),            "Units", "Number", /char
       ncdf_attput, ncid, ncdf_varid(ncid, "Ring_Radii"),           "Units", "Percent of field-of-view", /char
       ncdf_attput, ncid, ncdf_varid(ncid, "Sectors"),              "Units", "Sectors per ring", /char
       ncdf_attput, ncid, ncdf_varid(ncid, "X_Center"),             "Units", "Image pixel number", /char
       ncdf_attput, ncid, ncdf_varid(ncid, "Y_Center"),             "Units", "Image pixel number", /char
       ncdf_attput, ncid, ncdf_varid(ncid, "Gap"),                  "Units", "mm", /char
       ncdf_attput, ncid, ncdf_varid(ncid, "Start_Spacing"),        "Units", "Scan steps", /char
       ncdf_attput, ncid, ncdf_varid(ncid, "Channel_Spacing"),      "Units", "nm", /char
       ncdf_attput, ncid, ncdf_varid(ncid, "Nm_Per_Step"),          "Units", "nm", /char
       ncdf_attput, ncid, ncdf_varid(ncid, "Scan_Channels"),        "Units", "Etalon steps per interference order", /char
       ncdf_attput, ncid, ncdf_varid(ncid, "Gap_Refractive_Index"), "Units", "Dimensionless", /char
       ncdf_attput, ncid, ncdf_varid(ncid, "Sky_Wavelength"),       "Units", "nm", /char
       ncdf_attput, ncid, ncdf_varid(ncid, "Cal_Wavelength"),       "Units", "nm", /char
       ncdf_attput, ncid, ncdf_varid(ncid, "Cal_Temperature"),      "Units", "Kelvin", /char
       ncdf_attput, ncid, ncdf_varid(ncid, "Sky_Mass"),             "Units", "AMU", /char
       ncdf_attput, ncid, ncdf_varid(ncid, "Cal_Mass"),             "Units", "AMU", /char
       ncdf_attput, ncid, ncdf_varid(ncid, "Sky_Ref_Finesse"),      "Units", "Dimensionless", /char
       ncdf_attput, ncid, ncdf_varid(ncid, "Cal_Ref_Finesse"),      "Units", "Dimensionless", /char
       ncdf_attput, ncid, ncdf_varid(ncid, "Sky_FOV"),              "Units", "Degrees 1/2 angle, from zenith", /char

;------Save some global attributes:
       ncdf_attput, ncid, "Start_Day_UT", dt_tm_mk(js2jd(0d)+1, dt_tm_tojs(systime()), format='doy$'), /char, /global
       ncdf_attput, ncid, "Year",         dt_tm_mk(js2jd(0d)+1, dt_tm_tojs(systime()), format='Y$'), /char, /global
       ncdf_attput, ncid, "Site",      host.operation.header.site, /char, /global
       ncdf_attput, ncid, "Site_Code", host.operation.header.site_code, /char, /global
       ncdf_attput, ncid, "Operator",  host.operation.header.operator, /char, /global
       ncdf_attput, ncid, "Latitude",  host.operation.header.latitude, /float, /global
       ncdf_attput, ncid, "Longitude", host.operation.header.longitude, /float, /global
       ncdf_attput, ncid, "Comment",   host.operation.header.comment, /char, /global
       ncdf_attput, ncid, "Software",  host.operation.header.software, /char, /global

;------Enter some notes, which can be over-written with other information later, if need be:
       for i=0,n_elements(host.operation.header.notes)-1 do begin
           ncdf_attput, ncid, 'Note_' + string(i, format='(i2.2)'), host.operation.header.notes(i), /char, /global
       endfor

;------Write the static variables now:
       ncdf_control,ncid, /endef
       ncdf_varput, ncid, ncdf_varid(ncid, 'X_Center'),              host.operation.zones.x_center
       ncdf_varput, ncid, ncdf_varid(ncid, 'Y_Center'),              host.operation.zones.y_center
       ncdf_varput, ncid, ncdf_varid(ncid, 'Gap'),                   host.hardware.etalon.gap
       ncdf_varput, ncid, ncdf_varid(ncid, 'Start_Spacing'),         host.hardware.etalon.start_spacing
       ncdf_varput, ncid, ncdf_varid(ncid, 'Channel_Spacing'),       host.hardware.etalon.nm_per_step*host.hardware.etalon.scan_gain
       ncdf_varput, ncid, ncdf_varid(ncid, 'Nm_Per_Step'),           host.hardware.etalon.nm_per_step
       ncdf_varput, ncid, ncdf_varid(ncid, 'Scan_Channels'),         host.hardware.etalon.scan_channels
       ncdf_varput, ncid, ncdf_varid(ncid, 'Gap_Refractive_Index'),  host.hardware.etalon.gap_refractive_index
       ncdf_varput, ncid, ncdf_varid(ncid, 'Sky_Wavelength'),        host.operation.calibration.sky_wavelength
       ncdf_varput, ncid, ncdf_varid(ncid, 'Cal_Wavelength'),        host.operation.calibration.cal_wavelength
       ncdf_varput, ncid, ncdf_varid(ncid, 'Cal_Temperature'),       host.operation.calibration.cal_temperature
       ncdf_varput, ncid, ncdf_varid(ncid, 'Sky_Mass'),              host.operation.calibration.sky_mass
       ncdf_varput, ncid, ncdf_varid(ncid, 'Cal_Mass'),              host.operation.calibration.cal_mass
       ncdf_varput, ncid, ncdf_varid(ncid, 'Sky_Ref_Finesse'),       host.operation.calibration.sky_ref_finesse
       ncdf_varput, ncid, ncdf_varid(ncid, 'Cal_Ref_Finesse'),       host.operation.calibration.cal_ref_finesse
       ncdf_varput, ncid, ncdf_varid(ncid, 'Sky_FOV'),               host.operation.calibration.sky_fov
       ncdf_varput, ncid, ncdf_varid(ncid, 'FOV_Rings'),             host.operation.zones.fov_rings
       ncdf_varput, ncid, ncdf_varid(ncid, 'Ring_Radii'),            host.operation.zones.ring_radii(0:host.operation.zones.fov_rings-1)
       ncdf_varput, ncid, ncdf_varid(ncid, 'Sectors'),               host.operation.zones.sectors(0:host.operation.zones.fov_rings-1)

;------Force a commit to disk of the current file data:
       ncdf_control, ncid, /sync 
end


;========================================================================
;  This routine adds a new note to the log file:
pro sdi2k_ncdf_putnote, note=note
@sdi2kinc.pro
    if not(keyword_set(note)) then begin
       wid_pool, 'sdi2k_widget_note', widget_note, /get
       widget_control, widget_note, get_value=user_note
       widget_control, widget_note, set_value=' '
    endif else user_note=note
    vid  = strupcase(strcompress(host.programs.spectra.observation_type, /remove_all)) eq 'INS'

    if host.netcdf(vid).ncid eq -1 then begin
       sdi2k_user_message, 'No NetCDF file. Failed to add note: ' + user_note
       return
    endif 

    nnum = 0
    ncdf_attget, host.netcdf(vid).ncid, 'Note_' + string(nnum, format='(i2.2)'), note, /global
    while strpos(note, '          ') ne 0 do begin
       nnum = nnum + 1
       ncdf_attget, host.netcdf(vid).ncid, 'Note_' + string(nnum, format='(i2.2)'), note, /global
    endwhile
    tstr = dt_tm_mk(js2jd(0d)+1, dt_tm_tojs(systime()), format='0d$ n$ Y$, h$:m$')
    ncdf_attput, host.netcdf(vid).ncid, 'Note_' + string(nnum, format='(i2.2)'), tstr + ' - ' + user_note, /char, /global    
    sdi2k_user_message, 'Added Note ' +  strcompress(string(nnum+1), /remove_all) + ': ' + user_note
    host.operation.header.notes(nnum) = tstr + ' - ' + user_note
end


pro sdi2k_read_fitpars, ncid, record, sig2noise, chi_squared, sigarea, sigwid, sigpos, sigbgnd, $
                                      backgrounds, areas, widths, positions
@sdi2kinc.pro
    ncdf_control, ncid, /sync

    nz       = total(host.operation.zones.sectors(0:host.operation.zones.fov_rings-1))
    ncdf_varget, ncid, ncdf_varid(ncid, 'Peak_Position'),     positions,   offset=[0,  record], count=[nz, 1]
    ncdf_varget, ncid, ncdf_varid(ncid, 'Sigma_Position'),    sigpos,      offset=[0,  record], count=[nz, 1]
    ncdf_varget, ncid, ncdf_varid(ncid, 'Peak_Width'),        widths,      offset=[0,  record], count=[nz, 1]
    ncdf_varget, ncid, ncdf_varid(ncid, 'Sigma_Width'),       sigwid,      offset=[0,  record], count=[nz, 1]
    ncdf_varget, ncid, ncdf_varid(ncid, 'Peak_Area'),         areas,       offset=[0,  record], count=[nz, 1]
    ncdf_varget, ncid, ncdf_varid(ncid, 'Sigma_Area'),        sigarea,     offset=[0,  record], count=[nz, 1]
    ncdf_varget, ncid, ncdf_varid(ncid, 'Background'),        backgrounds, offset=[0,  record], count=[nz, 1]
    ncdf_varget, ncid, ncdf_varid(ncid, 'Sigma_Bgnd'),        sigbgnd,     offset=[0,  record], count=[nz, 1]
    ncdf_varget, ncid, ncdf_varid(ncid, 'Signal_to_Noise'),   sig2noise,   offset=[0,  record], count=[nz, 1]
    ncdf_varget, ncid, ncdf_varid(ncid, 'Chi_Squared'),       chi_squared, offset=[0,  record], count=[nz, 1]
    ncdf_control, ncid, /sync
end

pro sdi2k_build_fitres, ncid, resarr
@sdi2kinc.pro
    ncdf_control, ncid, /sync
    ncdf_diminq, ncid, ncdf_dimid(ncid, 'Time'),    dummy,  maxrec
    record = 0
    nz     = total(host.operation.zones.sectors(0:host.operation.zones.fov_rings-1))
    for rec=record,maxrec-1 do begin
        sdi2k_read_fitpars, ncid, rec, sig2noise, chi_squared, sigarea, sigwid, sigpos, sigbgnd, $
                            backgrounds, areas, widths, positions
        ncdf_varget,  ncid, ncdf_varid(ncid, 'Start_Time'),    stime, offset=[rec], count=[1]
        ncdf_varget,  ncid, ncdf_varid(ncid, 'End_Time'),      etime, offset=[rec], count=[1]
        ncdf_varget,  ncid, ncdf_varid(ncid, 'Number_Summed'), scanz, offset=[rec], count=[1]
        resrec = {s_fitres, record: rec, $
                        start_time: stime, $
                          end_time: etime, $
                     number_summed: scanz, $
                          velocity: positions, $
                       temperature: widths, $
                         intensity: areas, $
                        background: backgrounds, $
                    sigma_velocity: sigpos, $
                 sigma_temperature: sigwid, $
                 sigma_intensities: sigarea, $
                  sigma_background: sigbgnd, $
                      signal2noise: sig2noise, $
                       chi_squared: chi_squared, $
                        zonal_wind: fltarr(nz), $
                   meridional_wind: fltarr(nz), $
                 wind_coefficients: fltarr(6), $
                 units_temperature: 'K', $
                    units_velocity: 'm/s'}
       if n_elements(resarr) eq 0 then resarr = resrec else resarr = [resarr, resrec]
    endfor
end


