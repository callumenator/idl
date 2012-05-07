    function dir_wave, spekpar, winds, tcen, nav, wne_scnds, dx, dy

    result = fltarr(n_elements(tcen))
    hdist  = sqrt((winds(0).zonal_distances/1000. - dx)^2 + (winds(0).meridional_distances/1000. - dy)^2)
    ord    = sort(hdist)
    sel    = ord(0:nav-1)
    for j=0,nav-1 do result =  result + spekpar(sel(j),*); - mc_im_sm(spekfitz.velocity(ord(j)), n_elements(spekfitz)/10)
    result = result/nav

    print, dx, dy, strcompress(string(sel)), mean(winds(0).zone_longitudes(sel)), mean(winds(0).zone_latitudes(sel)), $
                        mean(winds(0).zonal_distances(sel))/1000, mean(winds(0).meridional_distances(sel))/1000

    result = result - mc_time_filter(tcen, result, wne_scnds)
;    result = mc_time_filter(tcen, result, 300)
    result = mc_time_filter(tcen, result, 180)
    return, result
    end


;---Main program:

    drive = get_drive()
    psplot = 1
;    navt = 7
;    navw = 5
;    didx = 4
    navt = 7
    navw = 5
    didx = 4
    clr = 'Red'
    min_snr = 1300.
;    max_chisq = 1.6
;    min_snr = 1000.
    max_chisq = 1.6
;    wne_scnds = 5400.
    wne_scnds = 10800.
    yrange = [-260., 260.]
;    yrange = [-73., 73.]
    fpath = '\users\SDI3000\Data\poker\'
    plot_dir = 'c:\inetpub\wwwroot\conde\sdiplots\'

    xx = alldisk_findfiles(fpath + '*' + clr + '_Sky_Date_*.nc')
    flis = xx.(0)
    fbits = mc_fileparse(flis)
    mcchoice, 'Start File: ', fbits.name_only, choice, $
               heading = {text: 'File name for first day?', font: 'Helvetica*Bold*Proof*30'}
    jlo = choice.index
    mcchoice, 'End File: ', fbits.name_only, choice, $
               heading = {text: 'File name for last day?', font: 'Helvetica*Bold*Proof*30'}
    jhi = choice.index
    flis = flis(jlo:jhi)
    done = 0
 while not(done) do begin
     mcchoice, 'Action?', [flis, 'Done'], choice, help='NOTE: Clicking on a file name will remove it from the list'
     if choice.name ne 'Done' then begin
        victim = where(flis eq choice.name, nn)
        if nn ne 0 then veceldel, flis, victim(0)
     endif
     if choice.name eq 'Done' then done =1
 endwhile


;---Read College magnetometer data:
    xx = alldisk_findfiles('\Users\Conde\Main\Poker_SDI\Supporting_Data\cigo*.sav')
    mlis = xx.(0)
    restore, mlis(0)
    hrefs = uniq_elz(magdat.href)
    zrefs = uniq_elz(magdat.href)
    hdifs = abs(hrefs - mean(magdat.h))
    zdifs = abs(zrefs - mean(magdat.z))
    hrefs = hrefs(sort(hdifs))
    zrefs = zrefs(sort(zdifs))

    for fnum=0,n_elements(flis)-1 do begin
        fname = flis(fnum)
        sdi3k_read_netcdf_data, fname, metadata=mm, winds=wnd, spekfits=spkft, /close
        if n_elements(spkft) lt 5 or n_elements(wnd) lt 5 then goto, dayskip
        sdi3k_remove_radial_residual, mm, spkft, parname='VELOCITY'
        sdi3k_remove_radial_residual, mm, spkft, parname='TEMPERATURE', /zero_mean
        sdi3k_remove_radial_residual, mm, spkft, parname='INTENSITY',   /multiplicative
        sdi3k_drift_correct, spkft, mm, /force, /data
        spkft.velocity = spkft.velocity*mm.channels_to_velocity
        print, fname, '        ', mm.maxrec

;-------Signal conditioning:
        rejected = 0
        kept = 0
        tr   = [100., 2000.]
        if abs(mm.wavelength_nm - 630.) lt 1. then tr = [450., 1600.]
        if abs(mm.wavelength_nm - 558.) lt 1. then tr = [140., 900.]

        goods   = intarr(n_elements(spkft))
        temparr = fltarr(n_elements(spkft))

        for jj=0L,n_elements(spkft) - 1 do begin
            keep = where(spkft(jj).signal2noise gt min_snr and $
                         spkft(jj).chi_squared  lt max_chisq and $
                         spkft(jj).temperature  gt min(tr) and $
                         spkft(jj).temperature  lt max(tr), nnn)
            if nnn gt mm.nzones/2 then begin
               goods(jj) = 1
            endif
        endfor
        keep = where(goods eq 1)
        spkft  = spkft(keep)
        wnd    = wnd(keep)
        mm.maxrec = n_elements(keep)

        if fnum eq 0 then begin
           winds = wnd
           spekfitz = spkft
           mmlo = mm
           tidx = [min(spkft.start_time), max(spkft.end_time)]
        endif else begin
           winds = [winds, wnd]
           spekfitz = [spekfitz, spkft]
           tidx = [[tidx], [min(spkft.start_time), max(spkft.end_time)]]
        endelse
dayskip:
       wait, 0.01
    endfor

    dt = tidx(1,*) - tidx(0, *)
    fractime = fltarr(n_elements(tidx(0,*)))
    for j=0,n_elements(dt)-1 do fractime(j) = total(dt(0:j))/total(dt)
    fractime = [0., fractime]


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


    for j=0,n_elements(spekfitz)-1 do begin
        spekfitz(j).velocity(1:*) = (spekfitz(j).velocity(1:*) - spekfitz(j).velocity(0)*cos(!dtor*winds(0).zeniths(1:*)))/sin(!dtor*winds(0).zeniths(1:*))
    endfor

;---Read geophysical indices:
;    idxdir = drive + "\users\conde\main\indices\"
;    get_solterr_indices, [min(tcen) - 2L*86400, max(tcen) + 2L*86400], idxdir, indices

;---Initialize plotting:
    while !d.window ge 0 do wdelete, !d.window
    load_pal, culz
    if psplot then begin
       set_plot, 'PS'
       device, /landscape, xsize=26, ysize=20
       device, bits_per_pixel=8, /color, /encapsulated
       device, filename=dialog_pickfile(path='C:\Users\Conde\Main\Poker_SDI\Publications_and_Presentations\Waves_April_2010\', filter='*.eps')
       !p.charsize = 1.0
       note_size = 0.4
    endif else begin
       canvas_size = [1800, 1200]
       xsize    = canvas_size(0)
       ysize    = canvas_size(1)
       while !d.window ge 0 do wdelete, !d.window
       window, xsize=xsize, ysize=ysize
    endelse

    lamlab  = '!4k!3=' + strcompress(string(mm.wavelength_nm, format='(f12.1)'), /remove_all) + ' nm'
    title = mm.site + ': ' + dt_tm_mk(js2jd(0d)+1, mmlo.start_time(0), format='d$-n$-Y$') + $
            ' to '  +        dt_tm_mk(js2jd(0d)+1, mm.end_time(0),     format='d$-n$-Y$') + $
            ', ' + lamlab

    mc_npanel_plot,  layout, yinfo, /setup
    layout.position = [0.08, 0.10, 0.92, 0.96]
    layout.charscale = 0.6
    if psplot then begin
       layout.position = [0.10, 0.10, 0.90, 0.94]
       layout.charscale = 0.4
    endif
    layout.charthick = 3
    erase, color=culz.white
    layout.panels = 6
    layout.time_axis =1
    layout.title  = title
    layout.erase = 0

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

for j=0,n_elements(fractime)-2 do begin
    these = where(tcen gt tidx(0,j) and tcen lt tidx(1,j))
    xlims = layout.position(0) + [fractime(j), fractime(j+1)]*(layout.position(2) - layout.position(0))
    layout.xrange = [min(tcen(these)) + 1200, max(tcen(these)) - 1200]
    layout.title = dt_tm_mk(js2jd(0d)+1, min(spekfitz(these).start_time), format='d$-n$-Y$')
    yinfo.range = yrange
    yinfo.minor_tix = 5
    yinfo.psym = 0

;---North Panel:
    yinfo.symsize = 0.1
    yinfo.symbol_color = culz.chocolate
    yinfo.title = "!8T'!3 Looking!C !C North [K]"
    if j lt n_elements(fractime) -2 then begin
       yinfo.title = ' '
       yinfo.rename_ticks = 1
    endif
    yinfo.right_axis = 1
    yinfo.line_color = tclr
    layout.color = tclr
    smlos = dir_wave(spekfitz(these).temperature, winds(these), tcen(these), navt, wne_scnds, 0., distz(didx))
    pdata = {x: tcen(these), y: smlos}
    mc_npanel_plot,  layout, yinfo, pdata, panel=0, set_x_position=xlims
    yinfo.title = "!8U'!3 Looking!C !C North [m s!U-1!N]"
    yinfo.right_axis = 0
    yinfo.rename_ticks = 0
    if j gt 0 then begin
       yinfo.title = ' '
       yinfo.rename_ticks = 1
    endif
    yinfo.line_color = wclr
    layout.color = wclr
    smlos = dir_wave(spekfitz(these).velocity, winds(these), tcen(these), navw, wne_scnds, 0., distz(didx))
    pdata = {x: tcen(these), y: smlos}
    mc_npanel_plot,  layout, yinfo, pdata, panel=0, set_x_position=xlims

    yinfo.rename_ticks = 1
    layout.color = culz.black
    yinfo.title = ' '
    mc_npanel_plot,  layout, yinfo, pdata, panel=0, /nodata, set_x_position=xlims
    yinfo.right_axis = 1
    mc_npanel_plot,  layout, yinfo, pdata, panel=0, /nodata, set_x_position=xlims
    yinfo.rename_ticks = 0

;---South Panel:
    yinfo.symsize = 0.1
    yinfo.symbol_color = culz.chocolate
    yinfo.title = "!8T'!3 Looking!C !C South [K]"
    yinfo.right_axis = 1
    if j lt n_elements(fractime) -2 then begin
       yinfo.title = ' '
       yinfo.rename_ticks = 1
    endif
    yinfo.line_color = tclr
    layout.color = tclr
    smlos = dir_wave(spekfitz(these).temperature, winds(these), tcen(these), navt, wne_scnds, 0., -distz(didx))
    pdata = {x: tcen(these), y: smlos}
    mc_npanel_plot,  layout, yinfo, pdata, panel=1, set_x_position=xlims
    yinfo.title = "!8U'!3 Looking!C !C South [m s!U-1!N]"
    yinfo.right_axis = 0
    yinfo.rename_ticks = 0
    if j gt 0 then begin
       yinfo.title = ' '
       yinfo.rename_ticks = 1
    endif
    yinfo.line_color = wclr
    layout.color = wclr
    smlos = dir_wave(-spekfitz(these).velocity, winds(these), tcen(these), navw, wne_scnds, 0., -distz(didx))
    pdata = {x: tcen(these), y: smlos}
    mc_npanel_plot,  layout, yinfo, pdata, panel=1, set_x_position=xlims

    yinfo.rename_ticks = 1
    layout.color = culz.black
    yinfo.title = ' '
    mc_npanel_plot,  layout, yinfo, pdata, panel=1, /nodata, set_x_position=xlims
    yinfo.right_axis = 1
    mc_npanel_plot,  layout, yinfo, pdata, panel=1, /nodata, set_x_position=xlims
    yinfo.rename_ticks = 0

;---East Panel:
    yinfo.symsize = 0.1
    yinfo.symbol_color = culz.chocolate
    yinfo.title = "!8T'!3 Looking!C !C East [K]"
    yinfo.right_axis = 1
    if j lt n_elements(fractime) -2 then begin
       yinfo.title = ' '
       yinfo.rename_ticks = 1
    endif
    yinfo.line_color = tclr
    layout.color = tclr
    smlos = dir_wave(spekfitz(these).temperature, winds(these), tcen(these), navt, wne_scnds, distz(didx), 0.)
    pdata = {x: tcen(these), y: smlos}
    mc_npanel_plot,  layout, yinfo, pdata, panel=2, set_x_position=xlims
    yinfo.title = "!8U'!3 Looking!C !C East [m s!U-1!N]"
    yinfo.right_axis = 0
    yinfo.rename_ticks = 0
    if j gt 0 then begin
       yinfo.title = ' '
       yinfo.rename_ticks = 1
    endif
    yinfo.line_color = wclr
    layout.color = wclr
    smlos = dir_wave(spekfitz(these).velocity, winds(these), tcen(these), navw, wne_scnds, distz(didx), 0.)
    pdata = {x: tcen(these), y: smlos}
    mc_npanel_plot,  layout, yinfo, pdata, panel=2, set_x_position=xlims

    yinfo.rename_ticks = 1
    layout.color = culz.black
    yinfo.title = ' '
    mc_npanel_plot,  layout, yinfo, pdata, panel=2, /nodata, set_x_position=xlims
    yinfo.right_axis = 1
    mc_npanel_plot,  layout, yinfo, pdata, panel=2, /nodata, set_x_position=xlims
    yinfo.rename_ticks = 0

;---West Panel:
    yinfo.symsize = 0.1
    yinfo.symbol_color = culz.chocolate
    yinfo.title = "!8T'!3 Looking!C !C West [K]"
    yinfo.right_axis = 1
    if j lt n_elements(fractime) -2 then begin
       yinfo.title = ' '
       yinfo.rename_ticks = 1
    endif
    yinfo.line_color = tclr
    layout.color = tclr
    smlos = dir_wave(spekfitz(these).temperature, winds(these), tcen(these), navt, wne_scnds, -distz(didx), 0.)
    pdata = {x: tcen(these), y: smlos}
    mc_npanel_plot,  layout, yinfo, pdata, panel=3, set_x_position=xlims
    yinfo.title = "!8U'!3 Looking!C !C West [m s!U-1!N]"
    yinfo.right_axis = 0
    yinfo.rename_ticks = 0
    if j gt 0 then begin
       yinfo.title = ' '
       yinfo.rename_ticks = 1
    endif
    yinfo.line_color = wclr
    layout.color = wclr
    smlos = dir_wave(-spekfitz(these).velocity, winds(these), tcen(these), navw, wne_scnds, -distz(didx), 0.)
    pdata = {x: tcen(these), y: smlos}
    mc_npanel_plot,  layout, yinfo, pdata, panel=3, set_x_position=xlims

    yinfo.rename_ticks = 1
    layout.color = culz.black
    yinfo.title = ' '
    mc_npanel_plot,  layout, yinfo, pdata, panel=3, /nodata, set_x_position=xlims
    yinfo.right_axis = 1
    mc_npanel_plot,  layout, yinfo, pdata, panel=3, /nodata, set_x_position=xlims
    yinfo.rename_ticks = 0

;---Zenith Panel:
    yinfo.symsize = 0.1
    yinfo.symbol_color = culz.chocolate
    yinfo.title = "!8T'!3 Looking!C !C Zenith [K]"
    yinfo.right_axis = 1
    if j lt n_elements(fractime) -2 then begin
       yinfo.title = ' '
       yinfo.rename_ticks = 1
    endif
    yinfo.line_color = tclr
    layout.color = tclr
    smlos = dir_wave(spekfitz(these).temperature, winds(these), tcen(these), 7, wne_scnds, 0., 0.)
    pdata = {x: tcen(these), y: smlos}
    mc_npanel_plot,  layout, yinfo, pdata, panel=4, set_x_position=xlims
    yinfo.title = "!8U'!3 Looking!C !C Zenith [m s!U-1!N]"
    yinfo.right_axis = 0
    yinfo.rename_ticks = 0
    if j gt 0 then begin
       yinfo.title = ' '
       yinfo.rename_ticks = 1
    endif
    yinfo.line_color = wclr
    layout.color = wclr
    smlos = dir_wave(spekfitz(these).velocity, winds(these), tcen(these), 1, wne_scnds, 0., 0.)
    pdata = {x: tcen(these), y: smlos}
    mc_npanel_plot,  layout, yinfo, pdata, panel=4, set_x_position=xlims

    yinfo.rename_ticks = 1
    layout.color = culz.black
    yinfo.title = ' '
    mc_npanel_plot,  layout, yinfo, pdata, panel=4, /nodata, set_x_position=xlims
    yinfo.right_axis = 1
    mc_npanel_plot,  layout, yinfo, pdata, panel=4, /nodata, set_x_position=xlims
    yinfo.rename_ticks = 0

;---magentic activity panel:
    yinfo.minor_tix = 5
    yinfo.zero_line = 1e-29
    yinfo.range = [-1870,370.]
    yinfo.psym = 0
    yinfo.line_color = culz.black
    yinfo.right_axis = 1
    yinfo.title = ' '
    yinfo.rename_ticks = 1
    mdata = {x: magdat.time, y: magdat.h - hrefs(0)}
    mc_npanel_plot,  layout, yinfo, mdata, panel=5, set_x_position=xlims

    yinfo.rename_ticks = 0
    yinfo.right_axis = 0
    yinfo.title = 'College Magnetometer!C !CH Trace [nT]'
    if j gt 0 then begin
       yinfo.title = ' '
       yinfo.rename_ticks = 1
    endif
    mc_npanel_plot,  layout, yinfo, mdata, panel=5, set_x_position=xlims

    xyouts, layout.position(2) + 0.01, layout.position(1) + 0.02, $
            mm.site_code, $
            charsize=layout.charsize*layout.charscale, color=layout.color, charthick=layout.xthick, align=0, /normal
    xyouts, layout.position(2) + 0.01, layout.position(1), $
            '!4k!3=' + strcompress(string(mm.wavelength_nm, format='(f12.1)'), /remove_all) + ' nm', $
            charsize=layout.charsize*layout.charscale, color=layout.color, charthick=layout.xthick, align=0, /normal
endfor

    if psplot then begin
       device, /close
       set_plot, 'WIN'
       ps_run = 0
    endif else begin
;       fparts = mc_fileparse(flis(fnum))
;       fout   = drive + '\Inetpub\wwwroot\conde\sdiplots\Wave_Plots_' + clr + '\' + fparts.name_only + '_Wave_Plot' + '.png'
;       gif_this, /png, file=fout
       dstring = dt_tm_mk(js2jd(0d)+1, mmlo.start_time(0), format='d$-n$-Y$') + '_to_' +$
                 dt_tm_mk(js2jd(0d)+1, mm.end_time(0),     format='d$-n$-Y$')
       dstring = strcompress(dstring, /remove_all)
       sdi3k_batch_plotsave, plot_dir, mm, 'Wave_Plots', doystring=dstring
    endelse
end





