;======================================================================
;  This procedure checks if a variable is already defined in a netCDF
;  file and, if not, adds it to the file.

pro sdi3k_addvar, ncid, vname, dimids, units, status, byte=bt, char=ch, short=sh, $
                  long=lg, float=fl, double=db

       trycount = 0
addvar_entry:
       trycount = trycount + 1
    on_error, 3
       on_ioerror, addvar_trubble
       status = "Failure"

       ncdf_control, ncid, /noverbose
       id = ncdf_varid(ncid, vname)
       ncdf_control, ncid, /verbose

       ;if id ge 0 then return

       print, "Adding Variable: ", vname, ", with units of: ", units
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
       ncdf_control, ncid, /sync
    status = "Success"
addvar_trubble:
       if status ne "Success" then help, !ERROR_STATE, /struc
       if status ne "Success" and trycount lt 50 then goto, addvar_entry
end
