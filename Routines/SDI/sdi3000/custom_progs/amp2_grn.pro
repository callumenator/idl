    drive = get_drive()
    psplot = 0

    fname = 'I:\sdi_archive\2003\SKY2003030.PF'

    sdi3k_read_netcdf_data, fname, metadata=mm, winds=winds, spekfits=spekfitz, /close

    year      = strcompress(string(mm.year),             /remove_all)
    doy       = strcompress(string(mm.start_day_ut, format='(i3.3)'),     /remove_all)

;---Build the time information arrays:
    tcen   = (spekfitz.start_time + spekfitz.end_time)/2
    tlist  = dt_tm_mk(js2jd(0d)+1, tcen, format='y$doy$ h$:m$')

    mcchoice, 'Start Time: ', tlist, choice, $
               heading = {text: 'Start at What Time?', font: 'Helvetica*Bold*Proof*30'}
    jlo = choice.index
    mcchoice, 'End Time: ', tlist, choice, $
               heading = {text: 'End at What Time?', font: 'Helvetica*Bold*Proof*30'}
    jhi = choice.index

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
       canvas_size = [1500, 1200]
       xsize    = canvas_size(0)
       ysize    = canvas_size(1)
       while !d.window ge 0 do wdelete, !d.window
       window, xsize=xsize, ysize=ysize
    endelse

    title = mm.site + ': ' + dt_tm_mk(js2jd(0d)+1, mm.start_time(0), format='d$-n$-Y$')

    mc_npanel_plot,  layout, yinfo, /setup
    layout.position = [0.16, 0.11, 0.90, 0.94]
    layout.charscale = 1.0
    if psplot then begin
       layout.position = [0.18, 0.14, 0.90, 0.94]
       layout.charscale = 0.8
    endif
    layout.charthick = 4
    erase, color=culz.white
    layout.panels = 3
    layout.time_axis =1
    layout.xrange = [tcen(jlo), tcen(jhi)]
    layout.title  = title
    layout.erase = 0

    yinfo.range = [-47., 100.]
    yinfo.charsize = 1.2
    layout.charthick = 4

;---Vertical wind panel:
    yinfo.title = ' '
    yinfo.symsize = 0.3
    yinfo.symbol_color = culz.red
    yinfo.right_axis = 1
    yinfo.rename_ticks = 0
    yinfo.thickness = 3
;    pdata = {x: tcen, y: winds.vertical_wind(0)}
    pdata = {x: tcen, y: spekfitz.velocity(0)}
    mc_npanel_plot,  layout, yinfo, pdata, panel=0
    yinfo.title = 'Vertical!C !CWind [m s!U-1!N]'
    yinfo.right_axis = 0
    yinfo.rename_ticks = 0
    mc_npanel_plot,  layout, yinfo, pdata, panel=0

;---Characteristic Energy Panel:
    nrg = fltarr(n_elements(spekfitz))
goto, no_nrg
    yinfo.title = 'Characteristic!C !CEnergy [keV]'
    yinfo.range = [0, 2.8]
    yinfo.symsize = 0.2
    yinfo.line_color = culz.slate
    layout.color = culz.slate
    yinfo.right_axis = 1
    yinfo.rename_ticks = 0
    yinfo.thickness = 3
    yinfo.zero_line = 0
    yinfo.psym = 0
    nrg_in_kev   = reverse([0.100000, 0.200000, 0.400000, 0.700000, 1.00000, 2.00000, 4.00000, 7.00000, 10.0000])
    lumtemp5577  = reverse([1098.71,  1025.73,  866.188,  645.408,  494.475, 298.237, 221.709, 201.032, 196.207])
    for j=0,n_elements(nrg) - 1 do begin
        nrg(j) = ((18.6/20.)^2)*median(spekfitz(j).temperature)
    endfor
    nrg = interpol(nrg_in_kev, lumtemp5577, nrg)
    pdata = {x: tcen, y: nrg}
    mc_npanel_plot,  layout, yinfo, pdata, panel=1

no_nrg:

;----MSIS panels:
    yinfo.symsize = 0.15
    yinfo.psym = 0
    yinfo.style = 0
    yinfo.range = [190, 560]
    yinfo.right_axis = 1
    yinfo.title = 'MSIS Temp [K]'
    layout.color = culz.white
    yinfo.thickness = 1
    yinfo.minor_tix = 5

    mtimes = [tcen(jlo)-10000L, tcen(jhi)+10000L]
    mtimes = mtimes(0) + dindgen(1000)/1000.*(mtimes(1) - mtimes(0))
    idxdir = drive + "\users\conde\main\indices\"
    get_solterr_indices, [tcen(jlo)- 100L*86400L, tcen(jhi) + 100L*86400L], idxdir, indices

    for j=1,4 do begin
        clr = culz.imgmin + j/(4.)*(culz.imgmax - culz.imgmin - 2)
        yinfo.symbol_color = clr
        get_msis, mtimes, {lon: 360. - 147.4303, lat: 65.1192}, 100. + j*5., indices, msis_pts
        mdata = {x: msis_pts.time, y: msis_pts.tz}
        mc_npanel_plot,  layout, yinfo, mdata, panel=1, get_position=thispos
    endfor
    yinfo.thickness = 1
    for j=1,4 do begin
        clr = culz.imgmin + j/(4.)*(culz.imgmax - culz.imgmin - 2)
        xyouts, thispos(2) + 0.005, thispos(1) + (j)*(thispos(3) - thispos(1))/6, strcompress(string(fix(100. + j*5.)), /remove_all) + ' km', $
                align=0, color=clr, charsize=layout.charsize*layout.charscale, charthick=layout.charthick, /normal
    endfor
    xyouts, thispos(2) + 0.005, thispos(1) + (5)*(thispos(3) - thispos(1))/6, 'MSIS', $
                align=0, color=culz.black, charsize=layout.charsize*layout.charscale, charthick=layout.charthick, /normal

    yinfo.title = ' '
    yinfo.symsize = 0.2
    yinfo.line_color = culz.black
    yinfo.symbol_color = culz.black
    layout.color = culz.black
    yinfo.right_axis = 1
    yinfo.rename_ticks = 0
    yinfo.thickness = 3
    yinfo.zero_line = 0
    yinfo.psym = 0
    yinfo.rename_ticks = 1
    for j=0,n_elements(nrg) - 1 do begin
        nrg(j) = ((18.6/20.)^2)*median(spekfitz(j).temperature)
    endfor
    pdata = {x: tcen, y: nrg}
    mc_npanel_plot,  layout, yinfo, pdata, panel=1

    yinfo.title = '558 nm Doppler!C !C Temperature [K]'
    yinfo.right_axis = 0
    yinfo.rename_ticks = 0
    mc_npanel_plot,  layout, yinfo, pdata, panel=1

;---CIGO Magnetometer panels:
    yinfo.zero_line = 1
    yinfo.symsize = 0.2
    yinfo.psym = 0
    yinfo.style = 0
    yinfo.range = [-1570,670.]
    yinfo.right_axis = 1
    yinfo.title = 'CIGO!C !CMag-Z [nT]'
    yinfo.symbol_color = culz.chocolate
    layout.color = culz.chocolate
    yinfo.thickness = 2
;    flis = dialog_pickfile(filter='*.dat', path=drive + '\Users\Conde\Main\Poker_SDI\Publications_and_Presentations\Feb2010_heating_event\cigo_mag', /multi)
    flis = findfile(drive + '\Users\Conde\Main\ampules\Ampules_II\Proposal\figures\*cigo*.dat')
    read_uaf_mag_ascii, flis, magdat
    hrefs = uniq_elz(magdat.href)
    zrefs = uniq_elz(magdat.zref)
    hdifs = abs(hrefs - mean(magdat.h))
    zdifs = abs(zrefs - mean(magdat.z))
    hrefs = hrefs(sort(hdifs))
    zrefs = zrefs(sort(zdifs))
    mdata = {x: magdat.time, y: magdat.z - zrefs(0)}
;    mc_npanel_plot,  layout, yinfo, mdata, panel=2

    yinfo.title = ' '
    yinfo.symbol_color = culz.black
    layout.color = culz.black
    mdata = {x: magdat.time, y: magdat.h - hrefs(0)}
    yinfo.right_axis = 1
    yinfo.rename_ticks = 0
    mc_npanel_plot,  layout, yinfo, mdata, panel=2
    yinfo.title = 'CIGO!C !CMag-H [nT]'
    yinfo.right_axis = 0
    yinfo.rename_ticks = 0
    mc_npanel_plot,  layout, yinfo, mdata, panel=2

    if psplot then begin
       device, /close
       set_plot, 'WIN'
       ps_run = 0
    endif

end





