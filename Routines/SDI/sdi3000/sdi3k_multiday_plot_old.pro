pro sdi3k_multiday_plot,  path=local_path, $
                          filter=filter, $
                          lookback_seconds=lookback_seconds, $
                          color=color
    load_pal, culz
    mc_message, title='WARNING!', heading={text: 'This program is still under construction...', font: 'Helvetica*Bold*Proof*30'}

;---Check keywords:
    if not(keyword_set(color))            then color            = 'red'
    if not(keyword_set(local_path))       then local_path       = 'd:\users\sdi3000\data\spectra\'
    if not(keyword_set(filter))           then filter           = ['*' + color + '*.pf', '*' + color + '*.nc']
    if not(keyword_set(lookback_seconds)) then lookback_seconds = 365*86400L

;---Setup MSIS and HWM specifications:
    f107 = 68.
    alt  = 240.
    msis  = {plot_msis: 1, $
                f10pt7: f107, $
                    ap: 5., $
           msis_height: alt}
    hwm   =  {plot_hwm: 1, $
                f10pt7: f107, $
                    ap: 5., $
            hwm_height: alt}

;---Get the list of files to include:
    for j=0,n_elements(local_path)-1 do begin
        sdi3k_batch_ncquery, fdesc, path=local_path(j), filter=filter, /verbose
        if j eq 0 or n_elements(file_desc) eq 0 then file_desc = fdesc else file_desc = [file_desc, fdesc]
    endfor
    file_desc = file_desc(where(file_desc.sec_age le lookback_seconds))
    skylis = file_desc(where(strupcase(file_desc.metadata.viewtype) eq 'SKY'))
    calz   = where(strupcase(file_desc.metadata.viewtype) eq 'CAL', nncal)
    if nncal gt 0 then begin
       callis = file_desc(where(strupcase(file_desc.metadata.viewtype) eq 'CAL'))
       skylis = skylis(sort(skylis.name))
       callis = callis(sort(callis.name))
    endif

    mcchoice, 'First file to process?', skylis.preferred_name, choice
    lodx = choice.index
    mcchoice, 'Last file to process?',  skylis.preferred_name, choice
    hidx = choice.index
    skylis = skylis(lodx<hidx:hidx>lodx)

    sdi3k_read_netcdf_data, skylis(0).name, metadata=mm, /close
    nz = mm.nzones

;---Make a template record:
       resrec = {valid: 0, $
                record: 0, $
            start_time: 0D, $
              end_time: 0D, $
                 scans: 0., $
              velocity: fltarr(nz), $
           temperature: fltarr(nz), $
             intensity: fltarr(nz), $
            background: fltarr(nz), $
          signal2noise: fltarr(nz), $
           chi_squared: fltarr(nz), $
        mag_zonal_wind: 0., $
   mag_meridional_wind: 0., $
        geo_zonal_wind: 0., $
   geo_meridional_wind: 0., $
         vertical_wind: 0., $
                 du_dx: 0., $
                 du_dy: 0., $
                 dv_dx: 0., $
                 dv_dy: 0., $
             vorticity: 0., $
            divergence: 0., $
      wind_chi_squared: 0., $
        sigma_velocity: fltarr(nz), $
     sigma_temperature: fltarr(nz), $
     sigma_intensities: fltarr(nz), $
      sigma_background: fltarr(nz), $
             sigmagzon: 0., $
             sigmagmer: 0., $
             siggeozon: 0., $
             siggeomer: 0., $
            sigverwind: 0., $
      units_zonal_wind: 'm/s', $
 units_meridional_wind: 'm/s', $
   units_vertical_wind: 'm/s', $
           units_du_dx: '1000/s', $
           units_du_dy: '1000/s', $
           units_dv_dx: '1000/s', $
           units_dv_dy: '1000/s', $
       units_vorticity: '1000/s', $
      units_divergence: '1000/s', $
     units_temperature: 'K', $
        units_velocity: 'm/s'}

;---Choose plot parameter:
    pars     = tag_names(resrec)
    firstpar = where(pars eq 'VELOCITY')
    lastpar  = where(pars eq 'WIND_CHI_SQUARED')
    pars = pars(firstpar(0):lastpar(0))
    mcchoice, 'Plot Parameter?', pars, choice

;---Read and merge all the specified data:
for j=0,n_elements(skylis)-1 do begin
    sdi3k_read_netcdf_data, skylis(j).name, metadata=mm, spekfits=spekfits, windpars=windpars, /close
    if n_elements(spekfits) gt 1 and n_elements(windpars) gt 1 then begin
       this_day = replicate(resrec, n_elements(spekfits))
       struct_assign, windpars, this_day
       struct_assign, spekfits, this_day
       if n_elements(alldays) eq 0 then alldays = this_day else alldays = [alldays, this_day]
    endif
endfor

;---Signal conditioning:
;    goods = where(median(alldays.signal2noise, dim=1) gt 150, ng)
;    if ng gt 0 then begin
;       alldays = alldays(goods)
;    endif
;    mm.maxrec = n_elements(alldays)

;-------Signal conditioning:
        goods = where(median(alldays.signal2noise, dim=1) gt 500, ng)
        if ng gt 0 then begin
           alldays = alldays(goods)
        endif

        chiz = fltarr(n_elements(alldays))
        for k=0, n_elements(spekfits) - 1 do begin
           chisq   = alldays(k).chi_squared
           chisq   = chisq(sort(chisq))
           chiz(k) = chisq(n_elements(chisq) - 10)
        endfor

        goods = where(chiz lt 1.8, ng)
        if ng gt 0 then begin
           alldays = alldays(goods)
        endif
        mm.maxrec = n_elements(alldays)



    sdi3k_remove_radial_residual, mm, alldays, parname='VELOCITY',    recsel=rex
    sdi3k_remove_radial_residual, mm, alldays, parname='TEMPERATURE', recsel=rex, /zero_mean
    sdi3k_remove_radial_residual, mm, alldays, parname='INTENSITY',   recsel=rex, /multiplicative
    pv = alldays.intensity
    pv = pv(sort(pv))
    nv = n_elements(pv)
    alldays.intensity = alldays.intensity - pv(0.02*nv)

;---Build the time information arrays:
    tcen   = (alldays.start_time + alldays.end_time)/2
    tlist  = dt_tm_mk(js2jd(0d)+1, tcen, format='h$:m$')

;---Setup Plotting:
    window, xsize=2000, ysize=600
    scale = {time_range: [0., 1.], yrange: [400., 1100.], auto_scale: 0}
    geo   = {xsize:  1600, ysize: 900}
    style =   {tsplot_style, charsize: 2, $
                            charthick: 2, $
                       line_thickness: 2, $
                       axis_thickness: 4, $
                    menu_configurable: 1, $
                        user_editable: [0,1,2,3]}
    tsplot_settings = {scale: scale, parameter: choice.name, zones: 'Median', black_bgnd: 1, geometry: geo, records: [0, n_elements(alldays)-1], msis: msis, hwm: hwm, style: style}
;    tsplot_settings = {scale: scale, parameter: choice.name, zones: 'Zone 0,1,2,3,4,5,6', black_bgnd: 1, geometry: geo, records: [0, n_elements(alldays)-1], msis: msis, hwm: hwm, style: style}
    sdi3k_tseries_plotter, tlist, tcen, mm, alldays, tsplot_settings, culz, /no_errors

end
