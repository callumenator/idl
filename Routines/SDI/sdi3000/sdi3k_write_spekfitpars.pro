;========================================================================
;  This routine appends the results of the latest fit to the netCDF data
;  file:

pro sdi3k_write_spekfitpars, ncid, record, sig2noise, chi_squared, sigarea, sigwid, sigpos, sigbgnd, $
                             backgrounds,  areas,     widths,      positions
       ncdf_control, ncid, /sync

       if n_elements(positions) lt 1 then return

       ncdf_varput, ncid, ncdf_varid(ncid, 'Peak_Position'),     positions,   offset=[0,  record]
       ncdf_varput, ncid, ncdf_varid(ncid, 'Sigma_Position'),    sigpos,      offset=[0,  record]
       ncdf_varput, ncid, ncdf_varid(ncid, 'Temperature'),       widths,      offset=[0,  record]
       ncdf_varput, ncid, ncdf_varid(ncid, 'Sigma_Temperature'), sigwid,      offset=[0,  record]
       ncdf_varput, ncid, ncdf_varid(ncid, 'Peak_Area'),         areas,       offset=[0,  record]
       ncdf_varput, ncid, ncdf_varid(ncid, 'Sigma_Area'),        sigarea,     offset=[0,  record]
       ncdf_varput, ncid, ncdf_varid(ncid, 'Background'),        backgrounds, offset=[0,  record]
       ncdf_varput, ncid, ncdf_varid(ncid, 'Sigma_Bgnd'),        sigbgnd,     offset=[0,  record]
       ncdf_varput, ncid, ncdf_varid(ncid, 'Signal_to_Noise'),   sig2noise,   offset=[0,  record]
       ncdf_varput, ncid, ncdf_varid(ncid, 'Chi_Squared'),       chi_squared, offset=[0,  record]
       ncdf_control, ncid, /sync
end
