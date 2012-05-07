@read_pfisr_routines.pro

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


drive = get_drive()

settings = {file_filter: '*red_sky*.nc', lookback_days: 3L, lookback_years: 10L, temperature_plot_range: [510., 1080.], min_snr: 700., max_chisq: 1.4, $
            plot_smoothed: 1, plot_poly: 0, hilite_hotfeb: 1, ps_run: 0, read_savefile: 0}
lookback_seconds = 86400L*366L*settings.lookback_years + 86400L*settings.lookback_days

instrument = 1

;mcchoice, 'Read Save File? ', ['No', 'Yes'], choice
;if choice.index then begin
;   xx = dialog_pickfile(filter='*.sav', path='D:\users\conde\main\Poker_SDI\Publications_and_Presentations\Feb2010_heating_event')
   xx = 'c:\users\conde\main\Poker_SDI\Publications_and_Presentations\Feb2010_heating_event\hotfeb_varsave_may14_2010.sav'
   restore, xx
   settings.read_savefile = 1
;endif

obj_edt, settings
if settings.read_savefile then goto, plot_start

get_fps_data:
first = 1

;---Get the list of files we want:
          if instrument eq 1 then fdir = 'D:\users\SDI3000\Data\HAARP'
          if instrument eq 2 then fdir = 'D:\users\SDI3000\Data\Poker'

             sdi3k_batch_ncquery, fdesc, path=fdir, filter=settings.file_filter, /verbose
             fdesc = fdesc(where(fdesc.sec_age le lookback_seconds))
             if first then file_desc = fdesc else file_desc = [file_desc, fdesc]
             first = 0
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
        sdi3k_remove_radial_residual, mm, spkftz, parname='TEMPERATURE', /zero_mean
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

    sdi3k_read_netcdf_data, file_desc(0).name, metadata=mm, winds=winds, /close
    if instrument eq 1 then zone_latitudes = reform(winds(0).zone_latitudes)
    if instrument eq 2 then begin
       zone_latitudes = [[zone_latitudes], [winds.zone_latitudes]]
    endif


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
    read_ncep_ascii, 'D:\users\conde\main\Poker_SDI\Publications_and_Presentations\Feb2010_heating_event\ncep\ncep_data.txt', ncep
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
plot_start:
    load_pal, culz

    if settings.ps_run then begin
       set_plot, 'PS'
       device, /portrait, xsize=21, ysize=28
       device, bits_per_pixel=8, /color, /encapsulated
       device, filename=dialog_pickfile(path='C:\Users\Conde\Main\Poker_SDI\', filter='*.eps')
       !p.charsize = 1.0
       note_size = 0.4
    endif else begin
       xsize    = 1400
       ysize    = 800
       while !d.window ge 0 do wdelete, !d.window
       window, xsize=xsize, ysize=ysize
    endelse

    mc_npanel_plot,  layout, yinfo, /setup
    erase, color=culz.white
    layout.position = [0.12, 0.16, 0.86, 0.96]
    layout.charscale = 1.2
    if settings.ps_run then begin
       layout.charscale = 0.45
       layout.position = [0.16, 0.10, 0.86, 0.94]
    endif

    layout.panels = 1
    layout.time_axis =1
    layout.xrange = [ymds2js(2010, 1, 1, 0), ymds2js(2010, 3, 18, 0)]
    layout.title  = ' '
    layout.erase = 0
    yinfo.charsize = 1.8
    yinfo.zero_line = 0
    yinfo.range = [min(settings.temperature_plot_range), max(settings.temperature_plot_range)]

    yinfo.legend.show = 1
    yinfo.legend.n_items = 5
    yinfo.legend.text = '    MSIS!C    Temp'
    yinfo.legend.color = culz.olive
    yinfo.legend.charsize = 1.8
    yinfo.legend.charthick = 3


;---Plot Poker FPS first, mostly just to establish the scale:
    layout.color = culz.black
    sname = mm.site
    if strpos(sname, 'Poker') ge 0 then sname = 'Poker Flat '
    if strpos(sname, 'HAARP') ge 0 then sname = 'HAARP'
    yinfo.title = sname +'Temperature [K]'
    yinfo.symbol_color = culz.black
    yinfo.line_color = culz.black
    layout.color = culz.black
    yinfo.symsize = 0.3
    yinfo.psym = 6
    yinfo.style = -1
    yinfo.right_axis = 0
    tndata = {x: tcen, y: temparr}
    mc_npanel_plot,  layout, yinfo, tndata, panel=0

    pastel_palette, factor=0.15
    shtlo   = ymds2js(2010, 1, 25, 0.)
    shthi   = ymds2js(2010, 2, 25, 0.)
    x_verts = [shtlo, shtlo, shthi, shthi, shtlo]
    y_verts = [yinfo.range(0), yinfo.range(1), yinfo.range(1), yinfo.range(0), yinfo.range(0)]
    if settings.hilite_hotfeb then polyfill, x_verts, y_verts, color=culz.yellow
    load_pal, culz
    mc_npanel_plot,  layout, yinfo, tndata, panel=0
    smooth_these, tcen, temparr, newtimes, smoothed, trend,order=2, winsize=7, iters=900
    if settings.plot_smoothed then oplot, newtimes(50:4950), smoothed(50:4950), thick=5, color=culz.black
    if settings.plot_poly     then oplot, newtimes(50:4950), trend, thick=4, color=culz.black

;---MSIS plot:
    mtimes = layout.xrange
    mtimes = mtimes(0) + dindgen(2000)/2000.*(mtimes(1) - mtimes(0))

    get_msis, mtimes, {lon: mm_1.longitude, lat: mm_1.latitude}, alt, indices, msis_pts
    yinfo.symsize = 0.15
    yinfo.psym = 0
    yinfo.style = 0
    yinfo.right_axis = 0
    yinfo.title = ' '
    yinfo.symbol_color = culz.olive
    layout.color = culz.olive
    yinfo.thickness = 1
;    mdata = {x: msis_pts.time, y: msis_pts.tz}
;    mc_npanel_plot,  layout, yinfo, mdata, panel=0

;---oplot smoothed MSIS:
    smooth_these, msis_pts.time, msis_pts.tz, newtimes, smoothed, trend,order=2, winsize=7, iters=1820
    if settings.plot_smoothed then oplot, newtimes(50:4950), smoothed(50:4950), thick=8, color=culz.olive

    layout.color = culz.black
    sname = mm.site
    if strpos(sname, 'Poker') ge 0 then sname = 'Poker Flat '
    if strpos(sname, 'HAARP') ge 0 then sname = 'HAARP'
    yinfo.title = sname +'Temperature [K]'
    yinfo.symbol_color = culz.black
    yinfo.line_color = culz.black
    layout.color = culz.black
    yinfo.symsize = 0.3
    yinfo.psym = 6
    yinfo.style = -1
    yinfo.right_axis = 0
    yinfo.legend.item = 1
    yinfo.legend.text = '    FPS!C    Temp'
    yinfo.legend.color = culz.black
    tndata = {x: tcen, y: temparr}
    mc_npanel_plot,  layout, yinfo, tndata, panel=0
    smooth_these, tcen, temparr, newtimes, smoothed, trend,order=2, winsize=7, iters=900
    if settings.plot_smoothed then oplot, newtimes(50:4950), smoothed(50:4950), thick=5, color=culz.black
    if settings.plot_poly     then oplot, newtimes(50:4950), trend, thick=4, color=culz.black
    gif_this, /png, file='C:\users\conde\main\Meetings\CEDAR_2010\Stratwarm\figures\2010_teseries_sdi_msis.png'

;---FPS temperature panels:

    if not(settings.read_savefile) then mfiles = dialog_pickfile(path=drive + '\users\conde\main\Poker_SDI\Publications_and_Presentations\Feb2010_heating_event\Meriwether', get_path=pth, title="Meriwether Data?", /multi)
       if mfiles(0) ne '' then begin
          if not(settings.read_savefile) then mwx_data = mwx_read(mfiles)
          oplot, mwx_data.time, mwx_data.temperature, color=culz.orange, psym=1, symsize=0.12, thick=1
       endif
    gif_this, /png, file='C:\users\conde\main\Meetings\CEDAR_2010\Stratwarm\figures\2010_teseries_sdi_msis_clemson.png'

    layout.color = culz.black
    sname = mm.site
    if strpos(sname, 'Poker') ge 0 then sname = 'Poker Flat '
    if strpos(sname, 'HAARP') ge 0 then sname = 'HAARP'
    yinfo.title = sname +'Temperature [K]'
    yinfo.symbol_color = culz.black
    yinfo.line_color = culz.black
    layout.color = culz.black
    yinfo.symsize = 0.3
    yinfo.psym = 6
    yinfo.style = -1
    yinfo.right_axis = 0
    yinfo.legend.item = 2
    yinfo.legend.text = '    Clemson!C    Temp'
    yinfo.legend.color = culz.orange
    tndata = {x: tcen, y: temparr}
    mc_npanel_plot,  layout, yinfo, tndata, panel=0
    smooth_these, tcen, temparr, newtimes, smoothed, trend,order=2, winsize=7, iters=900
    if settings.plot_smoothed then oplot, newtimes(50:4950), smoothed(50:4950), thick=5, color=culz.black
    if settings.plot_poly     then oplot, newtimes(50:4950), trend, thick=4, color=culz.black


;---PFISR Radar panel:
    if not(settings.read_savefile) then read_pfisr_iontemps, 'D:\users\conde\main\Poker_SDI\Publications_and_Presentations\Feb2010_heating_event\PFISR\TiOut.txt', ions
    yinfo.right_axis = 0
    yinfo.title = ' '
    yinfo.symbol_color = culz.blue
    layout.color = culz.blue
    yinfo.thickness = 3
    yinfo.symsize = 0.15
    yinfo.psym = 6
    yinfo.style = -1
    yinfo.legend.item = 3
    yinfo.legend.text = '    PFISR!C    Temp'
    yinfo.legend.color = culz.blue
    mdata = {x: ions.time, y: ions.ti_240km}
    mc_npanel_plot,  layout, yinfo, mdata, panel=0

    smooth_these, ions.time, ions.ti_240km, newtimes, smoothed, trend,order=2, winsize=7, iters=1820
    if settings.plot_smoothed then oplot, newtimes(50:4950), smoothed(50:4950), thick=5, color=culz.blue
    if settings.plot_poly     then oplot, newtimes(50:4950), trend, thick=4, color=culz.black


    layout.color = culz.black
    sname = mm.site
    if strpos(sname, 'Poker') ge 0 then sname = 'Poker Flat '
    if strpos(sname, 'HAARP') ge 0 then sname = 'HAARP'
    yinfo.title = sname +'Temperature [K]'
    yinfo.symbol_color = culz.black
    yinfo.line_color = culz.black
    layout.color = culz.black
    yinfo.symsize = 0.3
    yinfo.psym = 6
    yinfo.style = -1
    yinfo.right_axis = 0
    tndata = {x: tcen, y: temparr}
    mc_npanel_plot,  layout, yinfo, tndata, panel=0
    smooth_these, tcen, temparr, newtimes, smoothed, trend,order=2, winsize=7, iters=900
    if settings.plot_smoothed then oplot, newtimes(50:4950), smoothed(50:4950), thick=5, color=culz.black
    if settings.plot_poly     then oplot, newtimes(50:4950), trend, thick=4, color=culz.black
    gif_this, /png, file='C:\users\conde\main\Meetings\CEDAR_2010\Stratwarm\figures\2010_teseries_sdi_msis_clemson_pfisr.png'


;---NCEP panels:
    yinfo.psym = 0
    yinfo.style = 0
    yinfo.range = [200., 230.]
    yinfo.range = [-3., 18.]
    yinfo.right_axis = 1
    yinfo.title = ' '
    yinfo.symbol_color = culz.rose
    layout.color = culz.rose
    yinfo.thickness = 8
    yinfo.legend.item = 4
    yinfo.legend.text = '    NCEP!C    Delta-T'
    yinfo.legend.color = culz.rose
    mdata = {x: ncep.time, y: nc_par - (result(0) + result(1)*cos((ncep.doy - 190)*2*!pi/365.))}
    mc_npanel_plot,  layout, yinfo, mdata, panel=0



    yinfo.range = [min(settings.temperature_plot_range), max(settings.temperature_plot_range)]
    layout.color = culz.black
    yinfo.thickness = 1
    sname = mm.site
    if strpos(sname, 'Poker') ge 0 then sname = 'Poker Flat '
    if strpos(sname, 'HAARP') ge 0 then sname = 'HAARP'
    yinfo.title = sname +'Temperature [K]'
    yinfo.symbol_color = culz.black
    yinfo.line_color = culz.black
    layout.color = culz.black
    yinfo.symsize = 0.3
    yinfo.psym = 6
    yinfo.style = -1
    yinfo.right_axis = 0
    tndata = {x: tcen, y: 1000+temparr}
    mc_npanel_plot,  layout, yinfo, tndata, panel=0
;    smooth_these, tcen, temparr, newtimes, smoothed, trend,order=2, winsize=7, iters=900
;    if settings.plot_smoothed then oplot, newtimes(50:4950), smoothed(50:4950), thick=5, color=culz.black
;    if settings.plot_poly     then oplot, newtimes(50:4950), trend, thick=4, color=culz.black

    gif_this, /png, file='C:\users\conde\main\Meetings\CEDAR_2010\Stratwarm\figures\2010_teseries_sdi_msis_clemson_pfisr_ncep.png'


    if settings.ps_run then begin
       device, /close
       set_plot, 'WIN'
       ps_run = 0
    endif


end
