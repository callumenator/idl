 @sdi2k_ncdf.pro
 pro sdi2k_batch_ncquery, file_desc, path=path

 if not keyword_set(path) then begin
    eggs_ample = dialog_pickfile(filter='*.pf', get_path=path, /read)
 endif

 skylis = findfile(path + 'sky*.pf')
 inslis = findfile(path + 'ins*.pf')

 skylis = strupcase(skylis)
 inslis = strupcase(inslis)

 ni     = 0
 for j=0,n_elements(skylis)-1 do begin
      ncid = ncdf_open (skylis(j), /write)
      ncdf_control, ncid, /noverbose
      ppid = ncdf_varid(ncid, 'Peak_Position')
      wcid = ncdf_varid(ncid, 'Zonal_Wind')
      ncdf_diminq, ncid, ncdf_dimid(ncid, 'Time'),    dummy,  maxrec
      if maxrec lt 1 then goto, null_file
      ncdf_diminq, ncid, ncdf_dimid(ncid, 'Zone'),    dummy,  nzones
      ncdf_diminq, ncid, ncdf_dimid(ncid, 'Channel'), dummy,  nchan
      ncdf_diminq, ncid, ncdf_dimid(ncid, 'Ring'),    dummy,  nrings
      ncdf_varget, ncid, ncdf_varid(ncid, 'Start_Time'),      stime, offset=[0], count=[1]
      jsnow   = dt_tm_tojs(systime())
      sec_age = jsnow - stime

      desc = {s_sdi_ncdesc, name: skylis(j), analysis_level: 'None', insfile: 'None', $
              records: maxrec, zones: nzones, rings: nrings, sec_age: sec_age}

velcheck = 0.
      if ppid ge 0 then begin
;         sdi2k_build_fitres, ncid, resarr
;         velcheck = abs(resarr.velocity(0))
;         velcheck = velcheck(sort(velcheck))
;         velcheck = velcheck(0.8*n_elements(velcheck))
         if velcheck lt 1e5 then desc.analysis_level = 'Spectra Fitted'
      endif
      if velcheck lt 1e5 and wcid ge 0 then desc.analysis_level = 'Winds Fitted'

      time_string = strmid(skylis(j), strpos(skylis(j), 'SKY')+3, 999)
      inspos      = strpos(inslis, time_string)
      insidx      = where(inspos gt 0, ni)
      if ni gt 0 then desc.insfile = inslis(insidx(0))
      if j eq 0 then file_desc = desc else file_desc = [file_desc, desc]
;      help, desc, /struc
null_file:
      ncdf_control, ncid, /verbose
      ncdf_close, ncid
 endfor
 end
