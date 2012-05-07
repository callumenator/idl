    drive = get_drive()
    psplot = 1

    doyz = indgen(120) + 1
    dates = strarr(n_elements(doyz))
    for j=0, n_elements(dates) - 1 do dates(j) = ydn2date(2010, doyz(j), format='0n$_0d$')
    mcchoice, 'Day Number?', string(doyz, format='(i3.3)'), choice

    fpath = 'I:\users\SDI3000\Data\Poker\'
    fred  = 'PKR 2010_' + string(doyz(choice.index), format='(i3.3)') + $
            '_Poker_630nm_Red_Sky_Date_' + dates(choice.index) + '.nc'
    fgrn  = 'PKR 2010_' + string(doyz(choice.index), format='(i3.3)') + $
            '_Poker_558nm_green_Sky_Date_' + dates(choice.index) + '.nc'
    gflat = 'I:\users\SDI3000\Data\Poker\Wind_flat_field_PKR_5577A_created_2010_01_22_by_ conde.sav'
    setenv, 'SDI_GREEN_ZERO_VELOCITY_FILE=' + gflat

;    flats    = findfile(fpath + "Wind_flat_field_*_5577*.sav")
;    mcchoice, 'Wind flat field file for GREEN?', [flats, 'None'], choice, help='This flat field correction will only be applied to 5577 winds'
;    if choice.name ne 'None' then setenv, 'SDI_GREEN_ZERO_VELOCITY_FILE=' + choice.name
;    flats    = findfile(fpath + "\Wind_flat_field_???_6300*.sav")
;    mcchoice, 'Wind flat field file for RED?', [flats, 'None'], choice, help='This flat field correction will only be applied to 6300 winds'
;    if choice.name ne 'None' then setenv, 'SDI_RED_ZERO_VELOCITY_FILE=' + choice.name

    sdi3k_read_netcdf_data, fpath + fred, metadata=mmred, winds=redwnd, spekfits=redftz, windpars=redprz, zonemap=redzone, zone_centers=redzc, /close
    sdi3k_read_netcdf_data, fpath + fgrn, metadata=mmgrn, winds=grnwnd, spekfits=grnftz, windpars=grnprz, zonemap=grnzone, zone_centers=grnzc, /close


;---Apply any zero-velocity offset correction maps that have been selected:
    if getenv('SDI_GREEN_ZERO_VELOCITY_FILE') ne '' then begin
       restore, getenv('SDI_GREEN_ZERO_VELOCITY_FILE')
       print, 'Using vzero map: ', getenv('SDI_GREEN_ZERO_VELOCITY_FILE')
       for j=0,n_elements(grnftz) - 1 do begin
           grnftz(j).velocity = grnftz(j).velocity - wind_offset
       endfor
    endif
    if getenv('SDI_RED_ZERO_VELOCITY_FILE') ne '' then begin
       restore, getenv('SDI_RED_ZERO_VELOCITY_FILE')
       print, 'Using vzero map: ', getenv('SDI_RED_ZERO_VELOCITY_FILE')
       for j=0,n_elements(redftz) - 1 do begin
           redftz(j).velocity = redftz(j).velocity - wind_offset
       endfor
    endif

    sdi3k_drift_correct, grnftz, mmgrn, /force, /data
    grnftz.velocity = grnftz.velocity*mmgrn.channels_to_velocity
    sdi3k_drift_correct, redftz, mmred, /force, /data
    redftz.velocity = redftz.velocity*mmred.channels_to_velocity

    year      = strcompress(string(mmred.year),             /remove_all)
    doy       = strcompress(string(mmred.start_day_ut, format='(i3.3)'),     /remove_all)

;---Build the time information arrays:
    tcengrn   = (grnftz.start_time + grnftz.end_time)/2
    tlistgrn  = dt_tm_mk(js2jd(0d)+1, tcengrn, format='y$doy$ h$:m$')
    tcenred   = (redftz.start_time + redftz.end_time)/2
    tlistred  = dt_tm_mk(js2jd(0d)+1, tcenred, format='y$doy$ h$:m$')

    mcchoice, 'Start Time: ', tlistred, choice, $
               heading = {text: 'Start at What Time?', font: 'Helvetica*Bold*Proof*30'}
    jlo = choice.index
    mcchoice, 'End Time: ', tlistred, choice, $
               heading = {text: 'End at What Time?', font: 'Helvetica*Bold*Proof*30'}
    jhi = choice.index

    sdi3k_remove_radial_residual, mmgrn, grnftz, parname='VELOCITY'
    sdi3k_remove_radial_residual, mmgrn, grnftz, parname='TEMPERATURE', /zero_mean
    sdi3k_remove_radial_residual, mmgrn, grnftz, parname='INTENSITY',   /multiplicative
    sdi3k_remove_radial_residual, mmred, redftz, parname='VELOCITY'
    sdi3k_remove_radial_residual, mmred, redftz, parname='TEMPERATURE', /zero_mean
    sdi3k_remove_radial_residual, mmred, redftz, parname='INTENSITY',   /multiplicative


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
       canvas_size = [1300, 1000]
       xsize    = canvas_size(0)
       ysize    = canvas_size(1)
       while !d.window ge 0 do wdelete, !d.window
       window, xsize=xsize, ysize=ysize
    endelse

    title = mmred.site + ': ' + dt_tm_mk(js2jd(0d)+1, mmred.start_time(0), format='d$-n$-Y$')

DIVOR:
    mc_npanel_plot,  layout, yinfo, /setup
    layout.position = [0.16, 0.11, 0.96, 0.94]
    layout.charscale = 1.0
    if psplot then begin
       layout.position = [0.18, 0.14, 0.94, 0.94]
       layout.charscale = 0.8
    endif
    layout.charthick = 4
    erase, color=culz.white
    layout.panels = 3
    layout.time_axis =1
    layout.xrange = [tcenred(jlo), tcenred(jhi)]
    layout.title  = title
    layout.erase = 0

    yinfo.range = [-1.4, 1.4]
    yinfo.charsize = 1.2
    layout.charthick = 4

;---Divergence panel:
    yinfo.title = ' '
    yinfo.symsize = 0.2
    yinfo.symbol_color = culz.olive
    pastel_palette, factor=0.5
    yinfo.right_axis = 1
    yinfo.rename_ticks = 1
    for j=1,mmgrn.rings-1 do begin
        yinfo.thickness = 2
        yinfo.line_color = culz.olive
        wnddata = {x: tcengrn, y: 1000*(grnwnd.dudx(j) + grnwnd.dvdy(j))}
        mc_npanel_plot,  layout, yinfo, wnddata, panel=1
    endfor
    load_pal, culz
    pastel_palette, factor=0.7, dir='dark'
    yinfo.thickness = 4
    wnddata = {x: tcengrn, y: grnprz.divergence}
    mc_npanel_plot,  layout, yinfo, wnddata, panel=1

    yinfo.title = 'Divergence!C !C[1000 x s!U-1!N]'
    yinfo.symbol_color = culz.red
    load_pal, culz
    pastel_palette, factor=0.5
    yinfo.right_axis = 0
    yinfo.rename_ticks = 0
    for j=1,mmred.rings-1 do begin
        yinfo.thickness = 2
        yinfo.line_color = culz.red
        wnddata = {x: tcenred, y: 1000*(redwnd.dudx(j) + redwnd.dvdy(j))}
        mc_npanel_plot,  layout, yinfo, wnddata, panel=1
    endfor
    load_pal, culz
    pastel_palette, factor=0.7, dir='dark'
    yinfo.thickness = 4
    wnddata = {x: tcenred, y: redprz.divergence}
    mc_npanel_plot,  layout, yinfo, wnddata, panel=1

;---Vorticity panel:
    yinfo.title = ' '
    yinfo.symsize = 0.2
    yinfo.symbol_color = culz.olive
    load_pal, culz
    pastel_palette, factor=0.5
    yinfo.right_axis = 1
    yinfo.rename_ticks = 1
    for j=1,mmgrn.rings-1 do begin
        yinfo.thickness = 2
        yinfo.line_color = culz.olive
        wnddata = {x: tcengrn, y: 1000*(grnwnd.dvdx(j) - grnwnd.dudy(j))}
        mc_npanel_plot,  layout, yinfo, wnddata, panel=0
    endfor
    load_pal, culz
    pastel_palette, factor=0.7, dir='dark'
    yinfo.thickness = 4
    wnddata = {x: tcengrn, y: grnprz.vorticity}
    mc_npanel_plot,  layout, yinfo, wnddata, panel=0

    yinfo.title = 'Vorticity!C !C[1000 x s!U-1!N]'
    yinfo.symbol_color = culz.red
    load_pal, culz
    pastel_palette, factor=0.5
    yinfo.right_axis = 0
    yinfo.rename_ticks = 0
    for j=1,mmred.rings-1 do begin
        yinfo.thickness = 2
        yinfo.line_color = culz.red
        wnddata = {x: tcenred, y: 1000*(redwnd.dvdx(j) - redwnd.dudy(j))}
        mc_npanel_plot,  layout, yinfo, wnddata, panel=0
    endfor
    load_pal, culz
    pastel_palette, factor=0.7, dir='dark'
    yinfo.thickness = 4
    wnddata = {x: tcenred, y: redprz.vorticity}
    mc_npanel_plot,  layout, yinfo, wnddata, panel=0

;---Vertical Wind Panel:
    yinfo.title = ' '
    yinfo.range = [-105, 105]
    yinfo.symsize = 0.2
    yinfo.symbol_color = culz.red
    yinfo.thickness = 4
    yinfo.line_color = culz.red
    yinfo.right_axis = 1
    yinfo.rename_ticks = 1
    wnddata = {x: tcenred, y: redwnd.vertical_wind(0)}
    mc_npanel_plot,  layout, yinfo, wnddata, panel=2

    yinfo.title = 'Vertical!C !CWind [m s!U-1!N]'
    yinfo.symbol_color = culz.olive
    yinfo.line_color = culz.olive
    yinfo.right_axis = 0
    yinfo.rename_ticks = 0
    wnddata = {x: tcengrn, y: grnwnd.vertical_wind(0)}
    mc_npanel_plot,  layout, yinfo, wnddata, panel=2

    if psplot then begin
       device, /close
       set_plot, 'WIN'
       ps_run = 0
    endif

end





