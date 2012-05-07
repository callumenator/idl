;======================================================================
;  This procedure checks if a variable is already defined in a netCDF
;  file and, if not, adds it to the file.

pro sdi2k_addvar, ncid, vname, dimids, units, status, byte=bt, char=ch, short=sh, $
                  long=lg, float=fl, double=db

       trycount = 0                  
addvar_entry:
       trycount = trycount + 1
       on_ioerror, addvar_trubble
       status = "Failure"
	   
       ncdf_control, ncid, /noverbose
       id = ncdf_varid(ncid, vname)
       ncdf_control, ncid, /verbose

       if id ge 0 then return

       ncdf_control, ncid, /redef
       if (keyword_set(bt)) then $
           id = ncdf_vardef(ncid, vname, dimids, /byte)
       if (keyword_set(ch)) then $
           id = ncdf_vardef(ncid, vname, dimids, /char)
       if (keyword_set(sh)) then $
           id = ncdf_vardef(ncid, vname, dimids, /short)
       if (keyword_set(lg)) then $
           id = ncdf_vardef(ncid, vname, dimids, /long)
       if (keyword_set(fl)) then $
           id = ncdf_vardef(ncid, vname, dimids, /float)
       if (keyword_set(db)) then $
           id = ncdf_vardef(ncid, vname, dimids, /double)
       ncdf_attput, ncid, id, 'Units', units
       ncdf_control, ncid, /endef
	   status = "Success"
addvar_trubble:
       if status ne "Success" then help, !ERROR_STATE, /struc
       if status ne "Success" and trycount lt 5 then goto, addvar_entry
end

;=============================================================================
;  This procedure adds variables to the netCDF logfile to store the
;  results of peak fitting.  It only adds the variables if they do not
;  already exist.
;
pro sdi2k_add_fitvars, ncid

       ncdf_control, ncid, /fill, oldfill=nc_nodata
       timeid = ncdf_dimid(ncid, 'Time')
       zoneid = ncdf_dimid(ncid, 'Zone')

       sdi2k_addvar, ncid, 'Peak_Position',   [zoneid, timeid], $
                           'Scan Channels',   /float
       sdi2k_addvar, ncid, 'Peak_Width',      [zoneid, timeid], $
                           'Scan Channels',   /float
       sdi2k_addvar, ncid, 'Peak_Area',       [zoneid, timeid], $
                           'Signal Counts',   /float
       sdi2k_addvar, ncid, 'Background',      [zoneid, timeid], $
                           'Signal Counts per Channel',      /float
       sdi2k_addvar, ncid, 'Sigma_Position',  [zoneid, timeid], $
                           'Scan Channels',   /float
       sdi2k_addvar, ncid, 'Sigma_Width',     [zoneid, timeid], $
                           'Scan Channels',   /float
       sdi2k_addvar, ncid, 'Sigma_Area',      [zoneid, timeid], $
                           'Signal Counts',   /float
       sdi2k_addvar, ncid, 'Sigma_Bgnd',      [zoneid, timeid], $
                           'Signal Counts per Channel',      /float
       sdi2k_addvar, ncid, 'Chi_Squared',     [zoneid, timeid], $
                           'Dimensionless',   /float
       sdi2k_addvar, ncid, 'Signal_to_Noise', [zoneid, timeid], $
                           'Dimensionless',   /float

       ncdf_control, ncid, /noverbose
       attstat = ncdf_attinq(ncid, 'Peak Fitting Time', /global)
       ncdf_control, ncid, /verbose
       
       if attstat.datatype eq 'UNKNOWN' then begin
          ncdf_control, ncid, /redef
          nowtime = dt_tm_mk(js2jd(0d)+1, dt_tm_tojs(systime()), format='0d$ n$ Y$, h$:m$')
          ncdf_attput, ncid, 'Peak Fitting Time', nowtime, /global
          ncdf_attput, ncid, 'Peak Fitting Routine', $
                             'IDL sdi2000 suite', /global
          ncdf_control, ncid, /fill, oldfill=nc_nodata
          ncdf_control, ncid, /endef
       endif
end

tt = dialog_pickfile(path='f:\users\sdi2000\data\', filter='sky*.pf')

;tt = 'f:\users\sdi2000\data\sky2000305.pf'

ncid = ncdf_open(tt, /write)

on_error, 3
on_ioerror, f1

ncdf_control, ncid, /verbose
ncdf_control, ncid, /sync

ncdf_control, ncid, /redef
f1:
ncdf_control, ncid, /abort
ncid = ncdf_open(tt, /write)
;on_ioerror, f2
ncdf_control, ncid, /redef
ncdf_control, ncid, /endef
ncdf_control, ncid, /sync
sdi2k_add_fitvars, ncid
f2:
ncdf_close, ncid
end