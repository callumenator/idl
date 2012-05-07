;=============================================================================
;  This procedure adds variables to the netCDF logfile to store the
;  results of peak fitting.  It only adds the variables if they do not
;  already exist.
;
pro sdi3k_add_spekfitvars, ncid

       ncdf_control, ncid, /fill, oldfill=nc_nodata
       timeid = ncdf_dimid(ncid, 'Time')
       zoneid = ncdf_dimid(ncid, 'Zone')

;------First check if there's an old variable called "Peak_Width". If so, we'll
;      try to rename it to "Temperature", rather than add a new variable.
       ncdf_control, ncid, /noverbose
       wid = ncdf_varid(ncid, 'Peak_Width')
       tid = ncdf_varid(ncid, 'Temperature')
       if wid ge 0 and tid lt 0 then begin
          ncdf_control, ncid, /verbose
          ncdf_control, ncid, /redef
          print, "Renaming Peak_Width variables to Temperature..."
          ncdf_varrename, ncid, ncdf_varid(ncid, 'Peak_Width'),        'Temperature'
          ncdf_varrename, ncid, ncdf_varid(ncid, 'Sigma_Width'),       'Sigma_Temperature'
          ncdf_attput,    ncid, ncdf_varid(ncid, 'Temperature'),       'Units', 'Kelvins'
          ncdf_attput,    ncid, ncdf_varid(ncid, 'Sigma_Temperature'), 'Units', 'Kelvins'
          ncdf_control,   ncid, /endef
          ncdf_control,   ncid, /sync
   endif else begin
       sdi3k_addvar, ncid, 'Temperature',      [zoneid, timeid], $
                           'Kelvin',           /float
       sdi3k_addvar, ncid, 'Sigma_Temperature',[zoneid, timeid], $
                           'Kelvin',           /float
   endelse

       sdi3k_addvar, ncid, 'Peak_Position',    [zoneid, timeid], $
                           'Scan Channels',    /float
       sdi3k_addvar, ncid, 'Peak_Area',        [zoneid, timeid], $
                           'Signal Counts',    /float
       sdi3k_addvar, ncid, 'Background',       [zoneid, timeid], $
                           'Signal Counts per Channel',      /float
       sdi3k_addvar, ncid, 'Sigma_Position',   [zoneid, timeid], $
                           'Scan Channels',    /float
       sdi3k_addvar, ncid, 'Sigma_Area',       [zoneid, timeid], $
                           'Signal Counts',    /float
       sdi3k_addvar, ncid, 'Sigma_Bgnd',       [zoneid, timeid], $
                           'Signal Counts per Channel',      /float
       sdi3k_addvar, ncid, 'Chi_Squared',      [zoneid, timeid], $
                           'Dimensionless',    /float
       sdi3k_addvar, ncid, 'Signal_to_Noise',  [zoneid, timeid], $
                           'Dimensionless',    /float

       ncdf_control, ncid, /noverbose
       attstat = ncdf_attinq(ncid, 'Peak Fitting Time', /global)
       ncdf_control, ncid, /verbose

       trycount = 0
       outcome = 'fail'
ATTRIB_ADDER:
       if attstat.datatype eq 'UNKNOWN' then begin
          trycount = trycount + 1
          on_error, 3
          on_ioerror, ATTRIB_TRUBBLE
          ncdf_control, ncid, /redef
          outcome = 'ok'
          nowtime = dt_tm_mk(js2jd(0d)+1, dt_tm_tojs(systime()), format='0d$ n$ Y$, h$:m$')
          ncdf_attput, ncid, 'Peak Fitting Time', nowtime, /global
          ncdf_attput, ncid, 'Peak Fitting Routine', $
                             'IDL sdi3000 suite, Author=Conde', /global
          ncdf_control, ncid, /fill, oldfill=nc_nodata
          ncdf_control, ncid, /endef
          ncdf_control, ncid, /sync
       endif else return
ATTRIB_TRUBBLE:
        if outcome ne 'ok' and trycount lt 50 then goto, ATTRIB_ADDER

end

