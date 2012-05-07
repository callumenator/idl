
pro sdi3k_simple_cirplot, filename, plotarr, canvas_size=canvas_size, center=center, temp_range=temp_range, rgb_file=rgb_file

;---Example call: sdi3k_simple_cirplot, xx, canvas=[1800,1800], center=[0.7, 0.8], temp=[750,900], rgb=yy
;          where: xx and yy are netCDF filenames

    if keyword_set(rgb_file) then sdi3k_read_netcdf_data, rgb_file, metadata=mmrgb, spekfits=rgbspkft

    sdi3k_read_netcdf_data, filename, metadata=mm, winds=winds, spekfits=spekfits, images=images, zonemap=zonemap, zone_centers=zone_centers

    if keyword_set(rgb_file) then begin
           for k = 0, mm.nzones - 1 do begin
               ttemp = interpol(rgbspkft.temperature(k), $
                                  (rgbspkft.start_time + rgbspkft.end_time)/2, $
                                  (spekfits.start_time + spekfits.end_time)/2)
               spekfits.temperature(k) = ttemp
               tbrite = interpol(rgbspkft.intensity(k), $
                                  (rgbspkft.start_time + rgbspkft.end_time)/2, $
                                  (spekfits.start_time + spekfits.end_time)/2)
;               spekfits.intensity(k) = tbrite
           endfor
    endif

;---Determine the wavelength:
    doing_sodium = 0
    doing_red    = 0
    doing_green  = 0
    if abs(mm.wavelength_nm - 589.0) lt 5. then begin
       lamda = '5890'
       doing_sodium = 1
       lamstring = '_sodium'
    endif
    if abs(mm.wavelength_nm - 557.7) lt 5. then begin
       lamda = '5577'
       doing_green = 1
       lamstring = '_green'
    endif
    if abs(mm.wavelength_nm - 630.0) lt 5. then begin
       lamda = '6300'
       doing_red = 1
       lamstring = '_red'
    endif

    if not(keyword_set(center)) then center=[0.5, 0.5]

    while !d.window ge 0 do wdelete, !d.window

;---Initialize various data:
    load_pal, culz, proportion=0.5

    year      = strcompress(string(mm.year),             /remove_all)
    doy       = strcompress(string(mm.start_day_ut, format='(i3.3)'),     /remove_all)

;---Build the time information arrays:
    tcen   = (spekfits.start_time + spekfits.end_time)/2
    tlist  = dt_tm_mk(js2jd(0d)+1, tcen, format='h$:m$')

    mcchoice, 'Start Time: ', tlist, choice, $
               heading = {text: 'Start at What Time?', font: 'Helvetica*Bold*Proof*30'}
    jlo = choice.index
    mcchoice, 'End Time: ', tlist, choice, $
               heading = {text: 'End at What Time?', font: 'Helvetica*Bold*Proof*30'}
    jhi = choice.index

    mcchoice, 'Time Step: ', string(5*(1+indgen(12)), format='(i2)'), choice, $
               heading = {text: 'Time Step in Minutes?', font: 'Helvetica*Bold*Proof*30'}
    tstep = float(choice.name)


    marg = 16 < n_elements(resarr)/2 - 1
    if not(doing_sodium) then rex = indgen(mm.maxrec) else begin
       tsbrite = fltarr(mm.maxrec)
       tsbgnd  = fltarr(mm.maxrec)
       for j=0,mm.maxrec-1 do begin
           tsbrite(j) = median(spekfits(j).intensity)
           tsbgnd(j)  = median(spekfits(j).background)
       endfor
;      rex = where(tsbrite gt 2. and tsbrite lt 100. and tsbgnd lt 1000.)
       rex = where(tsbrite gt 100. and tsbrite lt 5e6 and tsbgnd lt 1e7)
;       rex = [indgen(marg), indgen(marg) + n_elements(resarr) - marg - 1]
    endelse
    if n_elements(rex) lt 2 then goto, PLOTZ_DONE
    sdi3k_remove_radial_residual, mm, spekfits, parname='VELOCITY',    recsel=rex
    sdi3k_remove_radial_residual, mm, spekfits, parname='TEMPERATURE', recsel=rex, /zero_mean
    sdi3k_remove_radial_residual, mm, spekfits, parname='INTENSITY',   recsel=rex, /multiplicative

;---Setup briteness and temperature scaling:
    britearr   = reform(spekfits.intensity)
    intord     = sort(britearr)
    britescale = [0., 1.4*britearr(intord(0.97*n_elements(intord)))]
    medtemp = median(spekfits.temperature)
    medtemp = 100*fix(medtemp/100)
;    if doing_red    then tprscale = [medtemp - 200. > 0, medtemp + 200.]
    if doing_red    then tprscale = [500., 1000.]
    if doing_green  then tprscale = [medtemp - 250. > 0, medtemp + 250.]
    if doing_sodium then tprscale = [medtemp - 350. > 0, medtemp + 350.]
    if keyword_set(temp_range) then tprscale = temp_range

    f107 = 70.
    if medtemp gt 850  then f107 = 120.
    if medtemp gt 950  then f107 = 150.
    if medtemp gt 1050 then f107 = 200.
    alt = 240.
    if abs(mm.wavelength_nm - 630.03) gt 10. then alt = 240.

STAGE_SMOOTHING:
;---Now do some smoothing prior to making the maps:

    if doing_red    then tsm = 1.2
    if doing_green  then tsm = 0.8
    if doing_sodium then tsm = 1.2
    if doing_red    then ssm = 0.07
    if doing_green  then ssm = 0.05
    if doing_sodium then ssm = 0.07
    if doing_green and mm.site_code eq 'HRP' then begin
       tsm = 0.6
       ssm = 0.05
    endif
    if doing_red and mm.year lt 2007   then tsm = 1.8
    if doing_red and mm.year lt 2007   then ssm = 0.1

    tprarr = spekfits.temperature
    print, 'Time smoothing temperatures...'
    sdi3k_timesmooth_fits,  tprarr, tsm, mm
    print, 'Space smoothing temperatures...'
    sdi3k_spacesmooth_fits, tprarr, ssm, mm, zone_centers
    spekfits.temperature = tprarr


STAGE_DIALPLOTS:
;---Setup dial plotting:
    if n_elements(winds) lt 3 then return
    if doing_green  then scale = {yrange: 150., auto_scale: 0, minute_step: tstep, magnetic_midnight: mm.magnetic_midnight, rbscale: tprscale, gscale: britescale, pscale: [0, 9e9]}
    if doing_sodium then scale = {yrange: 200., auto_scale: 0, minute_step: tstep, magnetic_midnight: mm.magnetic_midnight, rbscale: tprscale, gscale: britescale, pscale: [0, 9e9]}
    if doing_red    then scale = {yrange: 200., auto_scale: 0, minute_step: tstep, magnetic_midnight: mm.magnetic_midnight, rbscale: tprscale, gscale: britescale, pscale: [0, 9e9]}
    if doing_green  then load_pal, culz, idl=[8,  0]
    if doing_sodium then load_pal, culz, idl=[14, 0]
    if doing_red    then load_pal, culz, idl=[3,  0]

    if not(keyword_set(canvas_size)) then canvas_size=[750, 690]
    xsize = canvas_size(0)
    ysize = canvas_size(1)
    pmarg = 3
    while !d.window ge 0 do wdelete, !d.window
    window, xsize=xsize, ysize=ysize
    if n_elements(images) lt 2 then sdi3k_read_netcdf_data, filename, metadata=mm_dummy, images=images, cadence=2
    geo   = {xsize:  xsize, ysize: ysize}
    cirplot_settings = {scale: scale, black_bgnd: 1, geometry: geo, records: [jlo, jhi]}
    sdi3k_dial_mapper, tlist, tcen, mm, winds, cirplot_settings, culz, spekfits, zonemap, images=images, center=center, thick=2
    plotarr = tvrd(/true)

PLOTZ_DONE:
end





