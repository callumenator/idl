    function dir_wave, spekpar, winds, tcen, nav, wne_scnds, dx, dy

    result = fltarr(n_elements(tcen))
    hdist  = sqrt((winds(0).zonal_distances/1000. - dx)^2 + (winds(0).meridional_distances/1000. - dy)^2)
    ord    = sort(hdist)
    sel    = ord(0:nav-1)
    for j=0,nav-1 do result =  result + spekpar(sel(j),*); - mc_im_sm(spekfitz.velocity(ord(j)), n_elements(spekfitz)/10)
    result = result/nav

    print, dx, dy, sel, mean(winds(0).zone_longitudes(sel)), mean(winds(0).zone_latitudes(sel)), $
                        mean(winds(0).zonal_distances(sel)), mean(winds(0).meridional_distances(sel))

    result = result - mc_time_filter(tcen, result, wne_scnds)
    result = mc_time_filter(tcen, result, 180)
    return, result
    end


;---Main program:

    drive = get_drive()
    psplot = 0
    navt = 7
    navw=3
    didx = 4
    clr = 'green'

    doyz = indgen(120) + 1
    dates = strarr(n_elements(doyz))
    for j=0, n_elements(dates) - 1 do dates(j) = ydn2date(2010, doyz(j), format='0n$_0d$')
    mcchoice, 'Day Number?', string(doyz, format='(i3.3)'), choice

    mcchoice, 'Wavelength?', ['Red', 'Green'], ans
    clr = strlowcase(ans.name)
    mcchoice, '1/e Time Smoothing Window?', string(600*(1 + indgen(8))), ans
    wne_scnds = float(ans.name)


    fpath = 'G:\users\SDI3000\Data\Poker\'
    if clr eq 'green' then begin
       fname = fpath + 'PKR 2010_' + string(doyz(choice.index), format='(i3.3)') + $
               '_Poker_558nm_Green_Sky_Date_' + dates(choice.index) + '.nc'
    endif else begin
       fname = fpath + 'PKR 2010_' + string(doyz(choice.index), format='(i3.3)') + $
               '_Poker_630nm_Red_Sky_Date_' + dates(choice.index) + '.nc'
    endelse

    sdi3k_read_netcdf_data, fname, metadata=mm, winds=winds, spekfits=spekfitz, /close

    distz  = sqrt((winds(0).zonal_distances/1000.)^2 + (winds(0).meridional_distances/1000.)^2)
    distz  = 10*fix(distz/10)
    distz  = uniq_elz(distz)

    year      = strcompress(string(mm.year),             /remove_all)
    doy       = strcompress(string(mm.start_day_ut, format='(i3.3)'),     /remove_all)

;---Build the time information arrays:
    tcen   = (spekfitz.start_time + spekfitz.end_time)/2
    tlist  = dt_tm_mk(js2jd(0d)+1, tcen, format='y$doy$ h$:m$')
    jlo = 0
    jhi = n_elements(spekfitz) - 1

    sdi3k_remove_radial_residual, mm, spekfitz, parname='VELOCITY'
    sdi3k_remove_radial_residual, mm, spekfitz, parname='TEMPERATURE', /zero_mean
    sdi3k_remove_radial_residual, mm, spekfitz, parname='INTENSITY',   /multiplicative
    sdi3k_drift_correct, spekfitz, mm, /force, /data
    spekfitz.velocity = spekfitz.velocity*mm.channels_to_velocity

;---Initialize plotting:
    while !d.window ge 0 do wdelete, !d.window
    load_pal, culz
    if psplot then begin
       set_plot, 'PS'
       device, /landscape, xsize=26, ysize=20
       device, bits_per_pixel=8, /color, /encapsulated
       device, filename=dialog_pickfile(path='C:\Users\Conde\Main\ampules\Ampules_II\Proposal\figures\', filter='*.eps')
       !p.charsize = 1.0
       note_size = 0.4
    endif else begin
       canvas_size = [1400, 900]
       xsize    = canvas_size(0)
       ysize    = canvas_size(1)
       while !d.window ge 0 do wdelete, !d.window
       window, xsize=xsize, ysize=ysize
    endelse

    lamlab  = '!4k!3=' + strcompress(string(mm.wavelength_nm, format='(f12.1)'), /remove_all) + ' nm'
    title = mm.site + ': ' + dt_tm_mk(js2jd(0d)+1, mm.start_time(0), format='d$-n$-Y$') + ', ' + lamlab

    mc_npanel_plot,  layout, yinfo, /setup
    layout.position = [0.13, 0.14, 0.90, 0.96]
    layout.charscale = 1.0
    if psplot then begin
       layout.position = [0.18, 0.14, 0.90, 0.94]
       layout.charscale = 0.8
    endif
    layout.charthick = 4
    erase, color=culz.white
    layout.panels = 4
    layout.time_axis =1
    layout.xrange = [tcen(jlo), tcen(jhi)]
    layout.title  = title
    layout.erase = 0

    yinfo.range = [-95., 95.]
    yinfo.charsize = 1.2
    layout.charthick = 4
    yinfo.legend.n_items = 4
    yinfo.legend.charsize = 1.8
    yinfo.legend.charthick = 3

;---North Panel:
    yinfo.symsize = 0.3
    yinfo.symbol_color = culz.chocolate
    yinfo.title = 'Temp Looking!C !C North [K]'
    yinfo.right_axis = 1
    yinfo.line_color = culz.rose
    layout.color = culz.rose
    smlos = dir_wave(spekfitz.temperature, winds, tcen, navt, wne_scnds, 0., distz(didx))
    pdata = {x: tcen, y: smlos}
    mc_npanel_plot,  layout, yinfo, pdata, panel=0
    yinfo.title = 'Wind Looking!C !C North [m s!U-1!N]'
    yinfo.right_axis = 0
    yinfo.line_color = culz.cyan
    layout.color = culz.cyan
    smlos = dir_wave(spekfitz.velocity, winds, tcen, navw, wne_scnds, 0., distz(didx))
    pdata = {x: tcen, y: smlos}
    mc_npanel_plot,  layout, yinfo, pdata, panel=0

    yinfo.rename_ticks = 1
    layout.color = culz.black
    yinfo.title = ' '
    mc_npanel_plot,  layout, yinfo, pdata, panel=0, /nodata
    yinfo.right_axis = 1
    mc_npanel_plot,  layout, yinfo, pdata, panel=0, /nodata
    yinfo.rename_ticks = 0

;---South Panel:
    yinfo.symsize = 0.3
    yinfo.symbol_color = culz.chocolate
    yinfo.title = 'Temp Looking!C !C South [K]'
    yinfo.right_axis = 1
    yinfo.line_color = culz.rose
    layout.color = culz.rose
    smlos = dir_wave(spekfitz.temperature, winds, tcen, navt, wne_scnds, 0., -distz(didx))
    pdata = {x: tcen, y: smlos}
    mc_npanel_plot,  layout, yinfo, pdata, panel=1
    yinfo.title = 'Wind Looking!C !C South [m s!U-1!N]'
    yinfo.right_axis = 0
    yinfo.line_color = culz.cyan
    layout.color = culz.cyan
    smlos = dir_wave(-spekfitz.velocity, winds, tcen, navw, wne_scnds, 0., -distz(didx))
    pdata = {x: tcen, y: smlos}
    mc_npanel_plot,  layout, yinfo, pdata, panel=1

    yinfo.rename_ticks = 1
    layout.color = culz.black
    yinfo.title = ' '
    mc_npanel_plot,  layout, yinfo, pdata, panel=1, /nodata
    yinfo.right_axis = 1
    mc_npanel_plot,  layout, yinfo, pdata, panel=0, /nodata
    yinfo.rename_ticks = 0

;---East Panel:
    yinfo.symsize = 0.3
    yinfo.symbol_color = culz.chocolate
    yinfo.title = 'Temp Looking!C !C East [K]'
    yinfo.right_axis = 1
    yinfo.line_color = culz.rose
    layout.color = culz.rose
    smlos = dir_wave(spekfitz.temperature, winds, tcen, navt, wne_scnds, distz(didx), 0.)
    pdata = {x: tcen, y: smlos}
    mc_npanel_plot,  layout, yinfo, pdata, panel=2
    yinfo.title = 'Wind Looking!C !C East [m s!U-1!N]'
    yinfo.right_axis = 0
    yinfo.line_color = culz.cyan
    layout.color = culz.cyan
    smlos = dir_wave(spekfitz.velocity, winds, tcen, navw, wne_scnds, distz(didx), 0.)
    pdata = {x: tcen, y: smlos}
    mc_npanel_plot,  layout, yinfo, pdata, panel=2

    yinfo.rename_ticks = 1
    layout.color = culz.black
    yinfo.title = ' '
    mc_npanel_plot,  layout, yinfo, pdata, panel=2, /nodata
    yinfo.right_axis = 1
    mc_npanel_plot,  layout, yinfo, pdata, panel=2, /nodata
    yinfo.rename_ticks = 0

;---West Panel:
    yinfo.symsize = 0.3
    yinfo.symbol_color = culz.chocolate
    yinfo.title = 'Temp Looking!C !C West [K]'
    yinfo.right_axis = 1
    yinfo.line_color = culz.rose
    layout.color = culz.rose
    smlos = dir_wave(spekfitz.temperature, winds, tcen, navt, wne_scnds, -distz(didx), 0.)
    pdata = {x: tcen, y: smlos}
    mc_npanel_plot,  layout, yinfo, pdata, panel=3
    yinfo.title = 'Wind Looking!C !C West [m s!U-1!N]'
    yinfo.right_axis = 0
    yinfo.line_color = culz.cyan
    layout.color = culz.cyan
    smlos = dir_wave(-spekfitz.velocity, winds, tcen, navw, wne_scnds, -distz(didx), 0.)
    pdata = {x: tcen, y: smlos}
    mc_npanel_plot,  layout, yinfo, pdata, panel=3

    yinfo.rename_ticks = 1
    layout.color = culz.black
    yinfo.title = ' '
    mc_npanel_plot,  layout, yinfo, pdata, panel=3, /nodata
    yinfo.right_axis = 1
    mc_npanel_plot,  layout, yinfo, pdata, panel=3, /nodata
    yinfo.rename_ticks = 0

    if psplot then begin
       device, /close
       set_plot, 'WIN'
       ps_run = 0
    endif

end





