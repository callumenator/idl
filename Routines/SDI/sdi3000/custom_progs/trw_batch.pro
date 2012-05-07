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
    navw=5
    didx = 4
    clr = 'Red'
    wne_scnds = 3000.
    fpath = '\users\SDI3000\Data\Spectra\spectra_2009_spring\'
    plot_dir = 'c:\inetpub\wwwroot\conde\sdiplots\'

    xx = alldisk_findfiles(fpath + '*' + clr + '_Sky_Date_*.nc')
    flis = xx.(0)

    for fnum=0,n_elements(flis)-1 do begin
    fname = flis(fnum)
    sdi3k_read_netcdf_data, fname, metadata=mm, winds=winds, spekfits=spekfitz, /close
    if n_elements(spekfitz) lt 5 or n_elements(winds) lt 5 then goto, dayskip

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

    for j=0,n_elements(spekfitz)-1 do begin
        spekfitz(j).velocity = (spekfitz(j).velocity - spekfitz(j).velocity(0)*cos(!dtor*winds(0).zeniths))/sin(!dtor*winds(0).zeniths)
    endfor

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
    layout.position = [0.13, 0.14, 0.88, 0.96]
    layout.charscale = 1.0
    if psplot then begin
       layout.position = [0.18, 0.14, 0.90, 0.94]
       layout.charscale = 0.8
    endif
    layout.charthick = 3
    erase, color=culz.white
    layout.panels = 4
    layout.time_axis =1
    layout.xrange = [tcen(jlo), tcen(jhi)]
    layout.title  = title
    layout.erase = 0

    yinfo.range = [-89., 89.]
    if mm.start_day_ut ge 95 and mm.start_day_ut le 97 then yinfo.range = [-135., 135.]

    yinfo.charsize = 1.2
    layout.charthick = 3
    yinfo.legend.n_items = 4
    yinfo.legend.charsize = 1.8
    yinfo.legend.charthick = 3
    tclr = culz.rose
    wclr = culz.slate
    if strlowcase(clr) eq 'green' then begin
       tclr = culz.olive
       wclr = culz.slate
    endif

;---North Panel:
    yinfo.symsize = 0.3
    yinfo.symbol_color = culz.chocolate
    yinfo.title = "!8T'!3 Looking!C !C North [K]"
    yinfo.right_axis = 1
    yinfo.line_color = tclr
    layout.color = tclr
    smlos = dir_wave(spekfitz.temperature, winds, tcen, navt, wne_scnds, 0., distz(didx))
    pdata = {x: tcen, y: smlos}
    mc_npanel_plot,  layout, yinfo, pdata, panel=0
    yinfo.title = "!8U'!3 Looking!C !C North [m s!U-1!N]"
    yinfo.right_axis = 0
    yinfo.line_color = wclr
    layout.color = wclr
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
    yinfo.title = "!8T'!3 Looking!C !C South [K]"
    yinfo.right_axis = 1
    yinfo.line_color = tclr
    layout.color = tclr
    smlos = dir_wave(spekfitz.temperature, winds, tcen, navt, wne_scnds, 0., -distz(didx))
    pdata = {x: tcen, y: smlos}
    mc_npanel_plot,  layout, yinfo, pdata, panel=1
    yinfo.title = "!8U'!3 Looking!C !C South [m s!U-1!N]"
    yinfo.right_axis = 0
    yinfo.line_color = wclr
    layout.color = wclr
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
    yinfo.title = "!8T'!3 Looking!C !C East [K]"
    yinfo.right_axis = 1
    yinfo.line_color = tclr
    layout.color = tclr
    smlos = dir_wave(spekfitz.temperature, winds, tcen, navt, wne_scnds, distz(didx), 0.)
    pdata = {x: tcen, y: smlos}
    mc_npanel_plot,  layout, yinfo, pdata, panel=2
    yinfo.title = "!8U'!3 Looking!C !C East [m s!U-1!N]"
    yinfo.right_axis = 0
    yinfo.line_color = wclr
    layout.color = wclr
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
    yinfo.title = "!8T'!3 Looking!C !C West [K]"
    yinfo.right_axis = 1
    yinfo.line_color = tclr
    layout.color = tclr
    smlos = dir_wave(spekfitz.temperature, winds, tcen, navt, wne_scnds, -distz(didx), 0.)
    pdata = {x: tcen, y: smlos}
    mc_npanel_plot,  layout, yinfo, pdata, panel=3
    yinfo.title = "!8U'!3 Looking!C !C West [m s!U-1!N]"
    yinfo.right_axis = 0
    yinfo.line_color = wclr
    layout.color = wclr
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

       axis, xaxis=0, color=layout.color, charsize=layout.charsize*layout.charscale, charthick=layout.charthick, $
        xticklen=0.015/sqrt(thispos(3) - thispos(1)), xthick=layout.xthick,xtickname=replicate(' ', 30), /xstyle
       axis, xaxis=1, xtickname=replicate(' ', 30), color=layout.color, charsize=layout.charsize*layout.charscale, charthick=layout.charthick, $
        xticklen=0.015/sqrt(thispos(3) - thispos(1)), xthick=layout.xthick, /xstyle
       axis, xaxis=0, color=layout.color, charsize=layout.charsize*layout.charscale, charthick=layout.charthick, $
        xticklen=0.02, xthick=layout.xthick, xtitle=layout.xtitle, /xstyle


    if psplot then begin
       device, /close
       set_plot, 'WIN'
       ps_run = 0
    endif else begin
;       fparts = mc_fileparse(flis(fnum))
;       fout   = drive + '\Inetpub\wwwroot\conde\sdiplots\Wave_Plots_' + clr + '\' + fparts.name_only + '_Wave_Plot' + '.png'
;       gif_this, /png, file=fout
       sdi3k_batch_plotsave, plot_dir, mm, 'Wave_Plots'
    endelse
dayskip:
    wait, 0.01
    endfor
end





