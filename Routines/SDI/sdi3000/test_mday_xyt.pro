
pro smooth_these, timez, ydat, newtimes, smoothed, trend, order=order, iters=iters, winsize=winsize
    if not(keyword_set(order))   then order=2
    if not(keyword_set(iters))   then iters=150
    if not(keyword_set(winsize)) then winsize=25
    trange = max(timez) - min(timez)
    newtimes = min(timez) + findgen(5000)*trange/5000.
    smoothed = interpol(median(ydat, 5), timez, newtimes)
    for h=0,iters do smoothed = smooth(smoothed, winsize)
    coeffs = poly_fit(newtimes(50:4950), smoothed(50:4950), order, yfit=trend)
end

function ncep_harmfit, dd, m
         dpeak = 190.
         bases = fltarr(m)
         bases(0) = 1
         bases(1) = cos((dd-dpeak)*2*!pi/365.)
         return, bases
end


drive = get_drive()

settings = {file_filter: '*red_sky*.nc', lookback_days: 3L, lookback_years: 10L, temperature_plot_range: [510., 1080.], min_snr: 700., max_chisq: 1.4, $
            plot_smoothed: 1, plot_poly: 0, ps_run: 0}
obj_edt, settings
lookback_seconds = 86400L*366L*settings.lookback_years + 86400L*settings.lookback_days

instrument = 1

get_fps_data:
first = 1

;---Get the list of files we want:
    repeat begin
          pth  = drive + '\users\sdi3000\data\'
          fdir = dialog_pickfile(path=pth, get_path=pth, /dir, title="Instrument " + string(instrument, format="(i1)"))
          if fdir ne '' then begin
             sdi3k_batch_ncquery, fdesc, path=fdir, filter=settings.file_filter, /verbose
             fdesc = fdesc(where(fdesc.sec_age le lookback_seconds))
             if first then file_desc = fdesc else file_desc = [file_desc, fdesc]
             first = 0
          endif
    endrep until fdir eq ''
   sord = sort(file_desc.sec_age)
   file_desc = file_desc(reverse(sord))


   mcchoice, 'First instrument ' + string(instrument, format="(i1)") + 'file to process?', file_desc.preferred_name, choice
   lodx = choice.index
   mcchoice, 'Last instrument ' + string(instrument, format="(i1)") + 'file to process?', file_desc.preferred_name, choice
   hidx = choice.index
   file_desc = file_desc(lodx<hidx:hidx>lodx)

    first = 1
    for j=0,n_elements(file_desc)-1 do begin
        sdi3k_read_netcdf_data, file_desc(j).name, metadata=mm, spekfits=spkftz, /close
        if first then begin
           if n_elements(spkftz) gt 2 then begin
              spekfits = spkftz
              first = 0
           endif
        endif else begin
           if n_elements(spkftz) gt 2 then begin
              spekfits = [spekfits, spkftz]
           endif
        endelse
    endfor

;-------Signal conditioning:
        rejected = 0
        kept = 0
        tr   = [100., 2000.]
        if abs(mm.wavelength_nm - 630.) lt 1. then tr = [450., 1600.]
        if abs(mm.wavelength_nm - 558.) lt 1. then tr = [140., 900.]

        goods   = intarr(n_elements(spekfits))
        temparr = fltarr(n_elements(spekfits))

        for j=0L,n_elements(spekfits) - 1 do begin
            keep = where(spekfits(j).signal2noise gt settings.min_snr and $
                         spekfits(j).chi_squared  lt settings.max_chisq and $
                         spekfits(j).temperature  gt min(tr) and $
                         spekfits(j).temperature  lt max(tr), nnn)
            if nnn gt mm.nzones/2 then begin
               goods(j) = 1
               temparr(j) = median(spekfits(j).temperature(keep))
            endif
        endfor
        keep = where(goods eq 1)
        spekfits  = spekfits(keep)
        temparr   = temparr(keep)
        mm.maxrec = n_elements(keep)

;-------This stuff is a kludge to allow me to plot two "instruments" for comparison
        if instrument eq 2 then goto, plot_stuff
        instrument = instrument + 1
        spekfit_1 = spekfits
        mm_1 = mm
        temparr_1 = temparr
        goto, get_fps_data


plot_stuff:

;---Load NCEP data:
    read_ncep_ascii, dialog_pickfile(path = drive +'\users\conde\main\poker_sdi\', filter='*.txt', /multi, title="NCEP data Files?"), ncep
    nowarm = where(ncep.doy gt 110 and ncep.doy lt 320)
;    nc_par = (ncep.T_80N_50HPA + ncep.T_50N_50HPA )/2
    nc_par = ncep.T_55_75N_30HPA
    result = svdfit(ncep(nowarm).doy, nc_par(nowarm), 2, function_name='ncep_harmfit', yfit=yfit)

;---Build the time information arrays:
    tcen   = (spekfits.start_time  + spekfits.end_time)/2
    tcen_1 = (spekfit_1.start_time + spekfit_1.end_time)/2

    alt = 240.
    if abs(mm.wavelength_nm - 630.03) gt 10. then alt = 120.
    idxdir = drive + "\users\conde\main\indices\"
    get_solterr_indices, [min(tcen) - 100L*86400, max(tcen) + 100L*86400], idxdir, indices

;---Plotting stuff:
    load_pal, culz

    if settings.ps_run then begin
       set_plot, 'PS'
       device, /landscape
       device, bits_per_pixel=8, /color, /encapsulated
       device, filename=dialog_pickfile(path='C:\Users\Conde\Main\Poker_SDI\', filter='*.eps')
       !p.charsize = 1.0
       note_size = 0.4
    endif else begin
       xsize    = 1600
       ysize    = 1600
       while !d.window ge 0 do wdelete, !d.window
       window, xsize=xsize, ysize=ysize
    endelse

    mc_npanel_plot,  layout, yinfo, /setup
    erase, color=culz.white
    layout.position = [0.12, 0.14, 0.92, 0.96]
    if settings.ps_run then begin
       layout.charscale = 0.45
       layout.position = [0.24, 0.12, 0.98, 0.92]
    endif

    layout.panels = 4
    layout.time_axis =1
    layout.xrange = [min([tcen, tcen_1]) - 5*86400., max([tcen, tcen_1]) + 4*86400.]
    layout.title  = ' '
    layout.erase = 0
    yinfo.charsize = 1.8
    yinfo.zero_line = 0

;---NCEP panels:
    yinfo.psym = 0
    yinfo.style = 0
    yinfo.range = [200., 230.]
    yinfo.right_axis = 1
    yinfo.title = 'Avg NCEP 30 hPa [K]'
    yinfo.symbol_color = culz.slate
    layout.color = culz.slate
    yinfo.thickness = 3
    mdata = {x: ncep.time, y: result(0) + result(1)*cos((ncep.doy - 190)*2*!pi/365.)}
    mc_npanel_plot,  layout, yinfo, mdata, panel=0

    pastel_palette, factor=0.1
    shtlo   = ymds2js(2010, 1, 20, 0.)
    shthi   = ymds2js(2010, 2, 25, 0.)
    x_verts = [shtlo, shtlo, shthi, shthi, shtlo]
    y_verts = [yinfo.range(0), yinfo.range(1), yinfo.range(1), yinfo.range(0), yinfo.range(0)]
    polyfill, x_verts, y_verts, color=culz.slate
    load_pal, culz
    mc_npanel_plot,  layout, yinfo, mdata, panel=0


    yinfo.right_axis = 0
    yinfo.title = 'NCEP 30 hPa [K]'
    yinfo.symbol_color = culz.black
    layout.color = culz.black
    yinfo.thickness = 3
    mdata = {x: ncep.time, y: nc_par}
    mc_npanel_plot,  layout, yinfo, mdata, panel=0


;---FPS temperature panels:

    get_msis, tcen_1, {lon: mm_1.longitude, lat: mm_1.latitude}, alt, indices, msis_pts
    yinfo.symsize = 0.15
    yinfo.psym = 6
    yinfo.style = -1
    yinfo.range = [min(settings.temperature_plot_range), max(settings.temperature_plot_range)]
    yinfo.right_axis = 1
    yinfo.title = 'MSIS Temp [K]'
    yinfo.symbol_color = culz.rose
    layout.color = culz.rose
    yinfo.thickness = 2
    mdata = {x: msis_pts.time, y: msis_pts.tz}
    mc_npanel_plot,  layout, yinfo, mdata, panel=2

    pastel_palette, factor=0.1
    x_verts = [shtlo, shtlo, shthi, shthi, shtlo]
    y_verts = [yinfo.range(0), yinfo.range(1), yinfo.range(1), yinfo.range(0), yinfo.range(0)]
    polyfill, x_verts, y_verts, color=culz.slate
    load_pal, culz
    mc_npanel_plot,  layout, yinfo, mdata, panel=2

    layout.color = culz.black
    sname = mm_1.site
    if strpos(sname, 'Poker') ge 0 then sname = 'Poker Flat'
    if strpos(sname, 'HAARP') ge 0 then sname = 'HAARP'
    yinfo.title = sname +'!C !CNeutral Temp [K]'
    yinfo.symbol_color = culz.black
    yinfo.line_color = culz.black
    layout.color = culz.black
    yinfo.right_axis = 0
;    tndata = {x: tcen, y: median(spekfits.temperature, dim=1)}
    tndata = {x: tcen_1, y: temparr_1}
    mc_npanel_plot,  layout, yinfo, tndata, panel=2
;    smooth_these, fps.time, fps.temp_k, newtimes, smoothed, trend,order=2, winsize=25, iters=80
;    smooth_these, tcen, median(spekfits.temperature, dim=1), newtimes, smoothed, trend,order=2, winsize=7, iters=1820
    smooth_these, tcen_1, temparr_1, newtimes, smoothed, trend,order=2, winsize=7, iters=1820
    if settings.plot_smoothed then oplot, newtimes(50:4950), smoothed(50:4950), thick=5, color=culz.blue
    if settings.plot_poly     then oplot, newtimes(50:4950), trend, thick=4, color=culz.black

    get_msis, tcen, {lon: mm.longitude, lat: mm.latitude}, alt, indices, msis_pts
    yinfo.symsize = 0.15
    yinfo.psym = 6
    yinfo.style = -1
    yinfo.range = [min(settings.temperature_plot_range), max(settings.temperature_plot_range)]
    yinfo.right_axis = 1
    yinfo.title = 'MSIS Temp [K]'
    yinfo.symbol_color = culz.rose
    layout.color = culz.rose
    yinfo.thickness = 2
    mdata = {x: msis_pts.time, y: msis_pts.tz}
    mc_npanel_plot,  layout, yinfo, mdata, panel=1

    pastel_palette, factor=0.1
    x_verts = [shtlo, shtlo, shthi, shthi, shtlo]
    y_verts = [yinfo.range(0), yinfo.range(1), yinfo.range(1), yinfo.range(0), yinfo.range(0)]
    polyfill, x_verts, y_verts, color=culz.slate
    load_pal, culz
    mc_npanel_plot,  layout, yinfo, mdata, panel=1

    layout.color = culz.black
    sname = mm.site
    if strpos(sname, 'Poker') ge 0 then sname = 'Poker Flat'
    if strpos(sname, 'HAARP') ge 0 then sname = 'HAARP'
    yinfo.title = sname +'!C !CNeutral Temp [K]'
    yinfo.symbol_color = culz.black
    yinfo.line_color = culz.black
    layout.color = culz.black
    yinfo.right_axis = 0
;    tndata = {x: tcen, y: median(spekfits.temperature, dim=1)}
    tndata = {x: tcen, y: temparr}
    mc_npanel_plot,  layout, yinfo, tndata, panel=1
;    smooth_these, fps.time, fps.temp_k, newtimes, smoothed, trend,order=2, winsize=25, iters=80
;    smooth_these, tcen, median(spekfits.temperature, dim=1), newtimes, smoothed, trend,order=2, winsize=7, iters=1820
    smooth_these, tcen, temparr, newtimes, smoothed, trend,order=2, winsize=7, iters=1820
    if settings.plot_smoothed then oplot, newtimes(50:4950), smoothed(50:4950), thick=5, color=culz.blue
    if settings.plot_poly     then oplot, newtimes(50:4950), trend, thick=4, color=culz.black


;---F10.7 panel:
    yinfo.symsize = 0.2
    yinfo.psym = 0
    yinfo.style = 0
    yinfo.range = [60, max(indices.f107) + 5]
    yinfo.right_axis = 1
    yinfo.title = '10.7 cm Solar Flux'
    yinfo.symbol_color = culz.olive
    layout.color = culz.olive
    yinfo.thickness = 2
    mdata = {x: indices.time, y: indices.f107}
    mc_npanel_plot,  layout, yinfo, mdata, panel=3

    pastel_palette, factor=0.1
    x_verts = [shtlo, shtlo, shthi, shthi, shtlo]
    y_verts = [yinfo.range(0), yinfo.range(1), yinfo.range(1), yinfo.range(0), yinfo.range(0)]
    polyfill, x_verts, y_verts, color=culz.slate
    load_pal, culz
    mc_npanel_plot,  layout, yinfo, mdata, panel=3

;    yinfo.right_axis = 1
;    yinfo.title = ' '
;    mc_npanel_plot,  layout, yinfo, mdata, panel=2

;---Ap panel:
    yinfo.symsize = 0.2
    yinfo.psym = 0
    yinfo.style = 0
    yinfo.range = [-1, 37.]
    yinfo.right_axis = 0
    yinfo.title = 'Ap Index'
    yinfo.symbol_color = culz.black
    layout.color = culz.black
    yinfo.thickness = 2
    mdata = {x: indices.time, y: indices.ap}
    mc_npanel_plot,  layout, yinfo, mdata, panel=3
;    yinfo.right_axis = 1
;    yinfo.title = ' '
;    mc_npanel_plot,  layout, yinfo, mdata, panel=1


    if settings.ps_run then begin
       device, /close
       set_plot, 'WIN'
       ps_run = 0
    endif

end