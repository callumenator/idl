 pro sdi3k_batch_ncquery, file_desc, path=path, filter=filter, verbose=verbose

 if not keyword_set(path) then begin
    path = dialog_pickfile(title="Data Directory?", /directory, /read)
 endif

 if not(keyword_set(filter)) then ftr='*.nc' else ftr = filter
 if strmid(path, strlen(path)-1, 1) ne '\' then path = path + '\'
 for j=0,n_elements(filter)-1 do begin
     if strpos(ftr(j), '\') lt 0 then ftr(j) = path + ftr(j)
     alis   = findfile(ftr(j))
     if j eq 0 then flis = strupcase(alis) else flis = [flis, strupcase(alis)]
 endfor
 fparse = mc_fileparse(flis)
 ni     = 0
 for j=0,n_elements(flis)-1 do begin
      sdi3k_read_netcdf_data, flis(j), metadata=mm, /close
      if size(mm, /tname) ne 'STRUCT' then goto, null_file
      if mm.maxrec lt 1 then goto, null_file
      jsnow   = dt_tm_tojs(systime())
      sec_age = jsnow - mm.start_time

      desc = {s_sdi_desc, $
              name: flis(j), $
          metadata: mm, $
    preferred_name: 'SSS_YYYY_DDD_WWWW_VVV_Date_MM_DD.nc', $
           insfile: 'None', $
           sec_age: sec_age}
      desc.preferred_name = dt_tm_mk(js2jd(0d)+1, mm.start_time, $
                                     format = mm.viewtype + '_' + string(fix(10*mm.wavelength_nm), format='(i4.4)') + '_Y$_doy$_Date_0n$_0d$' + mm.extension)
      desc.insfile        = dt_tm_mk(js2jd(0d)+1, mm.start_time, format = 'cal_????_Y$_doy$_Date_0n$_0d$' + mm.extension)
      if j eq 0 or n_elements(file_desc) eq 0 then file_desc = desc else file_desc = [file_desc, desc]
      if keyword_set(verbose) then print, desc.preferred_name
      wait, 0.005
null_file:
 endfor
 end
