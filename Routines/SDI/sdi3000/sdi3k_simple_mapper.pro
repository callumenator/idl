
pro sdi3k_simple_mapper, filename, plotarr, canvas_size=canvas_size, what_plot=what_plot, time_smoothing=tsm, space_smoothing=ssm, yrange=yrange

    if not(keyword_set(what_plot)) then what_plot = 'WINDMAPS'
    what_plot = strupcase(what_plot)

    sdi3k_read_netcdf_data, filename, metadata=mm, winds=winds, spekfits=spekfits, images=images, zonemap=zonemap, zone_centers=zone_centers

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

;---Apply any zero-velocity offset correction maps that have been selected:
    if doing_green and getenv('SDI_GREEN_ZERO_VELOCITY_FILE') ne '' then begin
       restore, getenv('SDI_GREEN_ZERO_VELOCITY_FILE')
       print, 'Using vzero map: ', getenv('SDI_GREEN_ZERO_VELOCITY_FILE')
       for j=0,n_elements(spekfits) - 1 do begin
           spekfits(j).velocity = spekfits(j).velocity - wind_offset
       endfor
    endif
    if doing_red and getenv('SDI_RED_ZERO_VELOCITY_FILE') ne '' then begin
       restore, getenv('SDI_RED_ZERO_VELOCITY_FILE')
       print, 'Using vzero map: ', getenv('SDI_RED_ZERO_VELOCITY_FILE')
       for j=0,n_elements(spekfits) - 1 do begin
           spekfits(j).velocity = spekfits(j).velocity - wind_offset
       endfor
    endif

    sdi3k_drift_correct, spekfits, mm, /force, /data
    spekfits.velocity = spekfits.velocity*mm.channels_to_velocity

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
    if not(keyword_set(yrange)) then begin
;       if doing_red    then tprscale = [medtemp - 200. > 0, medtemp + 200.]
       if doing_red    then tprscale = [650., 900.]
;       if doing_green  then tprscale = [medtemp - 250. > 0, medtemp + 250.]
       if doing_green  then tprscale = [200, 550]
       if doing_sodium then tprscale = [medtemp - 350. > 0, medtemp + 350.]
    endif else tprscale = yrange
    f107 = 70.
    if medtemp gt 850  then f107 = 120.
    if medtemp gt 950  then f107 = 150.
    if medtemp gt 1050 then f107 = 200.
    alt = 240.
    if abs(mm.wavelength_nm - 630.03) gt 10. then alt = 120.

STAGE_SMOOTHING:
;---Now do some smoothing prior to making the maps:
    if not(keyword_set(tsm)) then begin
       if doing_red    then tsm = 1.
       if doing_green  then tsm = 0.6
       if doing_sodium then tsm = 1.5
       if doing_red and mm.year lt 2007   then tsm = 1.5
    endif
    if not(keyword_set(ssm)) then begin
       if doing_red    then ssm = 0.07
       if doing_green  then ssm = 0.03
       if doing_sodium then ssm = 0.03
       if doing_green and mm.site_code eq 'HRP' then begin
          tsm = 0.4
          ssm = 0.02
       endif
    endif

    posarr = spekfits.velocity
    print, 'Time smoothing winds...'
    sdi3k_timesmooth_fits,  posarr, tsm, mm
    print, 'Space smoothing winds...'
    sdi3k_spacesmooth_fits, posarr, ssm, mm, zone_centers
    spekfits.velocity = posarr
    if mm.maxrec gt 3 then spekfits.velocity = spekfits.velocity - total(spekfits(1:mm.maxrec-2).velocity(0))/n_elements(spekfits(1:mm.maxrec-2).velocity(0))

    if not(keyword_set(tsm)) then begin
       if doing_red    then tsm = 1.2
       if doing_green  then tsm = 0.8
       if doing_sodium then tsm = 1.2
       if doing_red and mm.year lt 2007   then tsm = 1.8
    endif
    if not(keyword_set(ssm)) then begin
       if doing_red    then ssm = 0.07
       if doing_green  then ssm = 0.05
       if doing_sodium then ssm = 0.07
       if doing_green and mm.site_code eq 'HRP' then begin
          tsm = 0.6
          ssm = 0.05
       endif
       if doing_red and mm.year lt 2007   then ssm = 0.1
    endif

    tprarr = spekfits.temperature
    print, 'Time smoothing temperatures...'
    sdi3k_timesmooth_fits,  tprarr, tsm, mm
    print, 'Space smoothing temperatures...'
    sdi3k_spacesmooth_fits, tprarr, ssm, mm, zone_centers
    spekfits.temperature = tprarr


STAGE_SKYMAPS:

;---Set the bitmap size for skymaps:
    if not(keyword_set(canvas_size)) then canvas_size = [1300, 1000]
    xsize    = canvas_size(0)
    ysize    = canvas_size(1)
    while !d.window ge 0 do wdelete, !d.window
    window, xsize=xsize, ysize=ysize
    thumsize = 0.7*sqrt(xsize*ysize/(jhi - jlo + 1))
    geo   = {xsize:  xsize, ysize: ysize}
    scale = {yrange: [-150., 150.], auto_scale: 0}
    skymap_settings = {scale: scale, parameter: 'Velocity', black_bgnd: 1, geometry: geo, records: [jlo, jhi]}

    if what_plot eq 'LOSWIND'     then goto, LOSWIND
    if what_plot eq 'TEMPERATURE' then goto, TEMPERATURE
    if what_plot eq 'INTENSITY'   then goto, INTENSITY
    if what_plot eq 'RGBMAPS'     then goto, RGBMAPS
    if what_plot eq 'WINDMAPS'    then goto, WINDMAPS

;---Map LOS winds:
LOSWIND:
    if doing_red    then scale = {yrange: [-300., 300.], auto_scale: 0}
    if doing_sodium then scale = {yrange: [-150., 150.], auto_scale: 0}
    if doing_green  then scale = {yrange: [-150., 150.], auto_scale: 0}
    sdi3k_sky_mapper, tlist, tcen, mm, spekfits, skymap_settings, culz, zonemap
    load_pal, culz
    goto, PLOTZ_DONE

;---Map temperatures:
TEMPERATURE:
    if doing_green and mm.site_code eq 'HRP' then tprscale = [150, 550.]
    skymap_settings.parameter = 'Temperature'
    skymap_settings.scale.yrange = tprscale
    sdi3k_sky_mapper, tlist, tcen, mm, spekfits, skymap_settings, culz, zonemap
    goto, PLOTZ_DONE

;---Map intensities:
INTENSITY:
    skymap_settings.parameter = 'Intensity'
    skymap_settings.scale.yrange = britescale
    sdi3k_sky_mapper, tlist, tcen, mm, spekfits, skymap_settings, culz, zonemap
    goto, PLOTZ_DONE

STAGE_RGBMAPS:
RGBMAPS:
;---Set the bitmap size for RGB skymaps:
    geo   = {xsize:  xsize, ysize: ysize}

;---Make temperature/Intensity RGB skymaps:
    yrange = [[tprscale], [britescale], [0., 4e15]]
    rgbmap_scale = {rgbmap_scale, auto_scale: 0, $
                                      yrange: yrange, $
                           menu_configurable: 1, $
                               user_editable: [0,1]}
    rgbmap_geom  = {rgbmap_geom, viewing_from_above: 0, $
                              radius_maps_to_distance: 0, $
                                       north_rotation: 0, $
                                    menu_configurable: 1, $
                                        user_editable: [0,1,2]}
    rgbmap_settings = {scale: rgbmap_scale, parameter: ['Temperature', 'Intensity', 'Background'], black_bgnd: 1, map_view: rgbmap_geom, geometry: geo, records: [jlo, jhi]}

    sdi3k_sky_rgbmap, tlist, tcen, mm, spekfits, rgbmap_settings, zonemap, culz, /no_purple
    goto, PLOTZ_DONE

STAGE_WINDMAPS:
WINDMAPS:
    if n_elements(winds) lt 3 then return

;---Setup the wind mapping:

    if doing_green  then scale = {yrange: 150., auto_scale: 0, rbscale: tprscale, gscale: britescale, pscale: [0, 9e9]}
    if doing_sodium then scale = {yrange: 200., auto_scale: 0, rbscale: tprscale, gscale: britescale, pscale: [0, 9e9]}
    if doing_red    then scale = {yrange: 250., auto_scale: 0, rbscale: tprscale, gscale: britescale, pscale: [0, 9e9]}
    if doing_green  then load_pal, culz, idl=[8,  0]
    if doing_sodium then load_pal, culz, idl=[14, 0]
    if doing_red    then load_pal, culz, idl=[3,  0]

    cadence  = fix((jhi-jlo)/100) > 1
    geo   = {xsize:  xsize, ysize: ysize}
    pp  = 'Map'
    oo  = 'Magnetic Noon at Top'
    oo  = 'Magnetic North at Top'
    windmap_settings = {scale: scale, perspective: pp, orientation: oo, black_bgnd: 1, geometry: geo, records: [jlo, jhi]}
    sdi3k_read_netcdf_data, filename, metadata=mm_dummy, images=images, cadence=cadence
    if n_elements(images) gt 2 then time_clip, images, timewin
    sdi3k_wind_mapper, tlist, tcen, mm, winds, windmap_settings, culz, spekfits, zonemap, images=images, cadence=cadence

PLOTZ_DONE:
    plotarr = tvrd(/true)

end





