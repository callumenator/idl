    function ap_xform_time, tarr, tref
       return, sqrt(sqrt(0.0001 + abs((tarr - tref)/(365.25*86400))))*(tarr - tref)/(abs(tarr - tref) + 0.0001)
    end


    drive = get_drive()
    idxdir = drive + "\users\conde\main\indices\"
    tlo = ymds2js(1940, 1, 1, 0)
    thi = ymds2js(2010, 12, 1, 0)
    get_solterr_indices, [tlo, thi], idxdir, indices
    indices = indices(0:n_elements(indices) - 16)

    thi = ymds2js(2010, 12, 1, 0)
    years = 2010.2464 + (indices.time - thi)/(365.25*86400)
    age   = ap_xform_time(indices.time, thi)

    tickyears = [1950, 1970, 1970, 1985, 1996, 2002, 2006, 2009, 2010]
    ticktimes = ap_xform_time(ymds2js(tickyears, 1+ intarr(9), 1+ intarr(9), intarr(9)), thi)
    ticklabs  = string(tickyears, format="(i4)")


;---Plotting stuff:
    psplot = 1
    load_pal, culz
    mc_npanel_plot,  layout, yinfo, /setup
    layout.charscale = 1.

    if psplot then begin
       set_plot, 'PS'
       device, /landscape, xsize=26, ysize=20
       device, bits_per_pixel=8, /color, /encapsulated
       device, filename=dialog_pickfile(path='C:\Users\Conde\Main\ampules\Ampules_II\Proposal\figures\', filter='*.eps')
       !p.charsize = 1.0
       note_size = 0.4
       layout.position = [0.13, 0.16, 0.96, 0.87]
       layout.charscale = 0.7
    endif else begin
       xsize    = 1300
       ysize    = 900
       while !d.window ge 0 do wdelete, !d.window
       window, xsize=xsize, ysize=ysize
       layout.position = [0.10, 0.12, 0.96, 0.94]
    endelse

    erase, color=culz.white
    layout.panels = 2
    layout.time_axis =0
    layout.xrange = ap_xform_time([ymds2js(1941., 1, 1, 0), thi-86400L*10], thi)
    layout.title  = ' '
    layout.erase = 0
    yinfo.charsize = 2.8
    yinfo.zero_line = 0
    layout.xtitle = 'Year'
    layout.suppress_x_axis = 1

    yinfo.symsize = 0.2
    yinfo.psym = 0
    yinfo.style = 0
;    yinfo.range = [-1, 230.]
    yinfo.range = [55, 290.]
    yinfo.right_axis = 0
;    yinfo.title = 'Daily Average!CAp Index'
    yinfo.title = '7-Day Median 10.7 cm!CSolar Flux [sfu]'
    yinfo.symbol_color = culz.black
    layout.color = culz.black
    yinfo.thickness = 2
;    smap = smooth(indices.ap, 8)
    smap = median(indices.f107, 7*8)
    mdata = {x: age, y: smap}
    mc_npanel_plot,  layout, yinfo, mdata, panel=0

    pastel_palette, factor=0.25
    shtlo   = ymds2js(2008, 12, 14, 0)
    shthi   = ymds2js(2009, 4, 30, 0)
    x_verts = ap_xform_time([shtlo, shtlo, shthi, shthi, shtlo], thi)
    y_verts = [yinfo.range(0), yinfo.range(1), yinfo.range(1), yinfo.range(0), yinfo.range(0)]
    polyfill, x_verts, y_verts, color=culz.ash
    load_pal, culz
;    mc_npanel_plot,  layout, yinfo, mdata, panel=0


    used = where(indices.time gt shtlo and indices.time lt shthi)
    mdata = {x: age(used), y: smap(used)}
    yinfo.symbol_color = culz.black
    yinfo.thickness = 2
    mc_npanel_plot,  layout, yinfo, mdata, panel=0, get_pos=thispos
    yinfo.line_color = culz.black
    yinfo.thickness = 1

    mdata = {x: layout.xrange, y: [69, 69]}
    yinfo.line_color = culz.ash
    yinfo.thickness = 2
    yinfo.style = 2
    yinfo.psym = 0
    mc_npanel_plot,  layout, yinfo, mdata, panel=0
    yinfo.line_color = culz.black
    yinfo.thickness = 2
    yinfo.style = 0


    axis, yaxis=1, color=layout.color, charsize=layout.charsize*layout.charscale, charthick=layout.charthick, $
          yticklen=0.015/sqrt(thispos(2) - thispos(0)), ytickname=replicate(' ', 30), ythick=layout.xthick, ytitle=' ', yminor=yinfo.minor_tix, /ystyle
       axis, xaxis=0, color=layout.color, charsize=layout.charsize*layout.charscale, charthick=layout.charthick, $
        xticklen=0.015/sqrt(thispos(3) - thispos(1)), xthick=layout.xthick,xtickname=replicate(' ', 30), /xstyle, xticks=8, xtickv=ticktimes , xminor=5
       axis, xaxis=1, xtickname=replicate(' ', 30), color=layout.color, charsize=layout.charsize*layout.charscale, charthick=layout.charthick, $
        xticklen=0.015/sqrt(thispos(3) - thispos(1)), xthick=layout.xthick, /xstyle, xticks=8, xtickv=ticktimes, xminor=5



    yinfo.range = [-1, 47.]
    yinfo.title = 'Monthly Average!CAp Index'
    yinfo.symbol_color = culz.black
    layout.color = culz.black
    smap = smooth(indices.ap, 240)
    mdata = {x: age(300:n_elements(years)-300), y: smap(300:n_elements(smap) - 300)}
    mdata = {x: age, y: smap}
    mc_npanel_plot,  layout, yinfo, mdata, panel=1, get_pos=thispos

    pastel_palette, factor=0.25
    shtlo   = ymds2js(2008, 12, 14, 0)
    shthi   = ymds2js(2009, 4, 30, 0)
    y_verts = [yinfo.range(0), yinfo.range(1), yinfo.range(1), yinfo.range(0), yinfo.range(0)]
    polyfill, x_verts, y_verts, color=culz.ash
    load_pal, culz
;    mc_npanel_plot,  layout, yinfo, mdata, panel=1


    mdata = {x: age(used), y: smap(used)}
    yinfo.symbol_color = culz.black
    yinfo.thickness = 2
    mc_npanel_plot,  layout, yinfo, mdata, panel=1
    yinfo.line_color = culz.black
    yinfo.thickness = 1

    mdata = {x: layout.xrange, y: [4.5, 4.5]}
    yinfo.line_color = culz.ash
    yinfo.thickness = 2
    yinfo.style = 2
    yinfo.psym = 0
    mc_npanel_plot,  layout, yinfo, mdata, panel=1
    yinfo.line_color = culz.black
    yinfo.thickness = 2


    axis, yaxis=1, color=layout.color, charsize=layout.charsize*layout.charscale, charthick=layout.charthick, $
          yticklen=0.015/sqrt(thispos(2) - thispos(0)), ytickname=replicate(' ', 30), ythick=layout.xthick, ytitle=' ', yminor=yinfo.minor_tix, /ystyle

       axis, xaxis=0, color=layout.color, charsize=layout.charsize*layout.charscale, charthick=layout.charthick, $
        xticklen=0.015/sqrt(thispos(3) - thispos(1)), xthick=layout.xthick,xtickname=replicate(' ', 30), /xstyle, xticks=8, xtickv=ticktimes , xminor=5
       axis, xaxis=1, xtickname=replicate(' ', 30), color=layout.color, charsize=layout.charsize*layout.charscale, charthick=layout.charthick, $
        xticklen=0.015/sqrt(thispos(3) - thispos(1)), xthick=layout.xthick, /xstyle, xticks=8, xtickv=ticktimes, xminor=5
       axis, xaxis=0, color=layout.color, charsize=layout.charsize*layout.charscale, charthick=layout.charthick, $
        xticklen=0.02, xthick=layout.xthick, xtitle=layout.xtitle, /xstyle, xticks=8, xtickv=ticktimes, xtickname=ticklabs, xminor=5



    if psplot then begin
       device, /close
       set_plot, 'WIN'
       ps_run = 0
    endif

    end

