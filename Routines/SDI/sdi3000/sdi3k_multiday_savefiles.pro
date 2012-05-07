pro sdi3k_multiday_savefiles,  path=local_path, $
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


;---Get the list of files to include:
    sdi3k_batch_ncquery, file_desc, path=local_path, filter=filter, /verbose
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


;---Read and merge all the specified data:
time_rec = {start_time: 0D, $
              end_time: 0D, $
                  year: 0, $
                   doy: 0, $
                 month: 0, $
                   day: 0, $
                  hour: 0, $
                minute: 0, $
                second: 0., $
          decimal_hour: 0., $
         second_of_day: 0., $
       meta_data_index: 0}

    for j=0,n_elements(skylis)-1 do begin
        print, skylis(j).name
        sdi3k_read_netcdf_data, skylis(j).name, metadata=mm, spekfits=spekfits, winds=windfits, windpars=windpars, zone_centers=zone_centers, /close
        if n_elements(spekfits) gt 1 and n_elements(windfits) gt 1 and n_elements(windpars) gt 1 then begin
           if n_elements(meta_data) lt 1 then meta_data = mm else meta_data = [meta_data, mm]
           midx = n_elements(meta_data) - 1
        endif

;-------Signal conditioning:
        goods = where(median(spekfits.signal2noise, dim=1) gt 500, ng)
        if ng gt 0 then begin
           spekfits = spekfits(goods)
           windfits = windfits(goods)
           windpars = windpars(goods)
        endif else goto, skip_file

        chiz = fltarr(n_elements(spekfits))
        for k=0, n_elements(spekfits) - 1 do begin
           chisq   = spekfits(k).chi_squared
           chisq   = chisq(sort(chisq))
           chiz(k) = chisq(n_elements(chisq) - 10)
        endfor

        goods = where(chiz lt 1.8, ng)
        if ng gt 0 then begin
           spekfits = spekfits(goods)
           windfits = windfits(goods)
           windpars = windpars(goods)
        endif else goto, skip_file
        mm.maxrec = n_elements(spekfits)

        sdi3k_drift_correct, spekfits, mm, /force, /data_based
        spekfits.velocity = spekfits.velocity*mm.channels_to_velocity

        sdi3k_remove_radial_residual, mm, spekfits, parname='VELOCITY',    recsel=rex
        sdi3k_remove_radial_residual, mm, spekfits, parname='TEMPERATURE', recsel=rex, /zero_mean
        sdi3k_remove_radial_residual, mm, spekfits, parname='INTENSITY',   recsel=rex, /multiplicative
        pv = spekfits.intensity
        pv = pv(sort(pv))
        nv = n_elements(pv)
        spekfits.intensity = spekfits.intensity - pv(0.02*nv)

;-------Smoothing:
        tsm = 1.
        ssm = 0.07
        posarr = spekfits.velocity
        print, 'Time smoothing winds...'
        sdi3k_timesmooth_fits,  posarr, tsm, mm
        print, 'Space smoothing winds...'
        sdi3k_spacesmooth_fits, posarr, ssm, mm, zone_centers
        spekfits.velocity = posarr
        if mm.maxrec gt 3 then spekfits.velocity = spekfits.velocity - total(spekfits(1:mm.maxrec-2).velocity(0))/n_elements(spekfits(1:mm.maxrec-2).velocity(0))

        tsm = 1.2
        ssm = 0.07
        tprarr = spekfits.temperature
        print, 'Time smoothing temperatures...'
        sdi3k_timesmooth_fits,  tprarr, tsm, mm
        print, 'Space smoothing temperatures...'
        sdi3k_spacesmooth_fits, tprarr, ssm, mm, zone_centers
        spekfits.temperature = tprarr

;-------Build the time information array:
        tcen  = (spekfits.start_time + spekfits.end_time)/2
        times = replicate(time_rec, n_elements(spekfits))
        times.start_time      = spekfits.start_time
        times.end_time        = spekfits.end_time
        times.year            = dt_tm_mk(js2jd(0d)+1, tcen, format='Y$')
        times.doy             = dt_tm_mk(js2jd(0d)+1, tcen, format='doy$')
        times.month           = dt_tm_mk(js2jd(0d)+1, tcen, format='0n$')
        times.day             = dt_tm_mk(js2jd(0d)+1, tcen, format='0d$')
        times.hour            = dt_tm_mk(js2jd(0d)+1, tcen, format='h$')
        times.minute          = dt_tm_mk(js2jd(0d)+1, tcen, format='m$')
        times.second          = dt_tm_mk(js2jd(0d)+1, tcen, format='s$')
        times.decimal_hour    = times.hour + times.minute/60. + times.second/3600.
        times.second_of_day   = times.hour*3600. + times.minute*60. + times.second
        times.meta_data_index = midx

        if n_elements(spectral_fits) lt 1 then begin
           spectral_fits   = spekfits
           wind_fits       = windfits
           wind_parameters = windpars
           exposure_times  = times
        endif else begin
           spectral_fits   = [spectral_fits, spekfits]
           wind_fits       = [wind_fits, windfits]
           wind_parameters = [wind_parameters, windpars]
           exposure_times  = [exposure_times, times]
        endelse
skip_file:
        wait, 0.001
    endfor

;---Write the Big Honkin' save file:
    fname = dialog_pickfile(filter = 'SDI*.sav', $
                              path = 'd:\users\sdi3000\data\poker', $
                             title = 'Enter a name for the save file:', $
                              file = 'SDI_Multi_Day_Merged_Results.sav')
    save, meta_data, exposure_times, spectral_fits, wind_fits, wind_parameters, file=fname
end
