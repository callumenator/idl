
drive = get_drive()
settings = {file_filter: 'sky*.pf', lookback_days: 3L, lookback_years: 10L, $
            temperature_plot_range: [190., 880.], min_snr: 700., max_chisq: 1.4, $
            plot_smoothed: 1, plot_poly: 0, ps_run: 0}
obj_edt, settings

photpath = drive + '\users\conde\main\Hecht\hgip\'
fyu_flis = photpath + ['fy200222.dat', 'fy200322.dat', 'fy200422.dat']
pkr_flis = photpath + ['pk200222.dat', 'pk200322.dat', 'pk200422.dat']

read_hgip_photometers, fyu_flis, fyu_o2n2
read_hgip_photometers, pkr_flis, pkr_o2n2


;---Load NCEP data:
    read_ncep_ascii, drive + '\users\conde\main\Poker_SDI\Publications_and_Presentations\Feb2010_heating_event\ncep\ncep_data.txt', ncep
    nowarm = where(ncep.doy gt 110 and ncep.doy lt 320)
;    nc_par = (ncep.T_80N_50HPA + ncep.T_50N_50HPA )/2
    nc_par = ncep.T_55_75N_30HPA
    result = svdfit(ncep(nowarm).doy, nc_par(nowarm), 2, function_name='ncep_harmfit', yfit=yfit)

     trange = [min([fyu_o2n2.time, pkr_o2n2.time]) - 5*86400., max([fyu_o2n2.time, pkr_o2n2.time]) + 4*86400.]
     mtimes = trange
     mtimes = mtimes(0) + dindgen(2000)/2000.*(mtimes(1) - mtimes(0))

    idxdir = drive + "\users\conde\main\indices\"
    get_solterr_indices, trange, idxdir, indices


;---Fabry-Perot stuff:
    tr = [140., 900.]
    xx = dialog_pickfile(filter='*.sav', path='D:\users\conde\main\Hecht\hgip', title='Restore FPS data from save file?')
    if strlen(xx) gt 0 then restore, xx
    if strlen(xx) gt 0 then goto, skip_fps_ncload

;---Get the list of files we want:
    fdir = 'D:\sdi_archive\2002\'
    sdi3k_batch_ncquery, fdesc, path=fdir, filter=settings.file_filter, /verbose
    file_desc = fdesc
    fdir = 'D:\sdi_archive\2003\'
    sdi3k_batch_ncquery, fdesc, path=fdir, filter=settings.file_filter, /verbose
    file_desc = [file_desc, fdesc]
    fdir = 'D:\sdi_archive\2004\'
    sdi3k_batch_ncquery, fdesc, path=fdir, filter=settings.file_filter, /verbose
    file_desc = [file_desc, fdesc]

    greenz = where(abs(file_desc.metadata.wavelength_nm - 557.7) lt 1.)
    file_desc = file_desc(greenz)
    sord = sort(file_desc.sec_age)
    file_desc = file_desc(reverse(sord))

;---Read in the data:
    rcd = 0L
    hgfp  = {time: 0D, $
             temperature: 0.,    intensity: 0., $
             mag_zonal_wind: 0., mag_meridional_wind: 0., $
             geo_zonal_wind: 0., geo_meridional_wind: 0., $
             vertical_wind:  0.}
    hgip_fps = replicate(hgfp, 256)
    for j=0,n_elements(file_desc)-1 do begin
        print, file_desc(j).name
        sdi3k_read_netcdf_data, file_desc(j).name, metadata=mm, spekfits=spkftz, windpars=windpars, /close
        if size(spkftz,   /type) ne 8 then goto, bad_fit
        if size(windpars, /type) ne 8 then goto, bad_fit
        for k=0,n_elements(spkftz) - 1 do begin
            keep = where(spkftz(k).signal2noise gt settings.min_snr and $
                         spkftz(k).chi_squared  lt settings.max_chisq and $
                         spkftz(k).temperature  gt min(tr) and $
                         spkftz(k).temperature  lt max(tr), nnn)
            if nnn gt 0.8*mm.nzones then begin
               hgfp.time                =  (spkftz(k).start_time + spkftz(k).end_time)/2
               hgfp.temperature         =  median(spkftz(k).temperature(keep))
               hgfp.intensity           =  median(spkftz(k).intensity(keep))
               hgfp.mag_meridional_wind =  windpars(k).mag_meridional_wind
               hgfp.mag_zonal_wind      =  windpars(k).mag_zonal_wind
               hgfp.geo_meridional_wind =  windpars(k).geo_meridional_wind
               hgfp.geo_zonal_wind      =  windpars(k).geo_zonal_wind
               hgfp.vertical_wind       =  windpars(k).vertical_wind
               if rcd ge n_elements(hgip_fps) then hgip_fps = [hgip_fps, replicate(hgfp, 256)]
               hgip_fps(rcd) = hgfp
               rcd = rcd + 1
            endif
         endfor
bad_fit:
     endfor
     mm.maxrec = n_elements(hgip_fps)

skip_fps_ncload:

;----Get a time window:
     years  = ['2002', '2003', '2004']
     months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
     mcchoice, 'Start Year: ', years, choice, $
               heading = {text: 'Start in What Year?', font: 'Helvetica*Bold*Proof*30'}
     ylo = fix(choice.name)
     mcchoice, 'Start Month: ', months, choice, $
               heading = {text: 'Start in What Month?', font: 'Helvetica*Bold*Proof*30'}
     mlo = choice.index + 1
     mcchoice, 'End Year: ', years, choice, $
               heading = {text: 'Start in What Year?', font: 'Helvetica*Bold*Proof*30'}
     yhi = fix(choice.name)
     mcchoice, 'End Month: ', months, choice, $
               heading = {text: 'End in What Month?', font: 'Helvetica*Bold*Proof*30'}
     mhi = choice.index + 1
     mhi = mhi + 1
     if mhi gt 12 then begin
        mhi = 1
        yhi = yhi + 1
     endif
     trange = [ymds2js(ylo, mlo, 0., 0.), ymds2js(yhi, mhi, 0., 0.)]


;    trange = [min(hgip_fps.time) - 10L*86400,  max(hgip_fps.time) + 10L*86400]
    idxdir = drive + "\users\conde\main\indices\"
    get_solterr_indices, [min(trange) - 100L*86400, max(trange) + 100L*86400], idxdir, indices

;---Plotting stuff:
    load_pal, culz

    if settings.ps_run then begin
       set_plot, 'PS'
       device, /portrait, xsize=21, ysize=28
       device, bits_per_pixel=8, /color, /encapsulated
       device, filename=dialog_pickfile(path='C:\Users\Conde\Main\Poker_SDI\', filter='*.eps')
       !p.charsize = 1.0
       note_size = 0.4
    endif else begin
       xsize    = 1600
       ysize    = 1100
       while !d.window ge 0 do wdelete, !d.window
       window, xsize=xsize, ysize=ysize
    endelse

    mc_npanel_plot,  layout, yinfo, /setup
    erase, color=culz.white
    layout.position = [0.12, 0.08, 0.90, 0.96]
    layout.charscale = 0.8
    if settings.ps_run then begin
       layout.charscale = 0.45
       layout.position = [0.16, 0.10, 0.86, 0.94]
    endif

    layout.panels = 6
    layout.time_axis =1
    layout.xrange = trange
    layout.title  = ' '
    layout.erase = 0
    yinfo.charsize = 1.8
    yinfo.zero_line = 0

;---NCEP panels:
    yinfo.psym = 0
    yinfo.style = 0
    yinfo.range = [200., 230.]
    yinfo.right_axis = 1
    yinfo.title = '1978-2010 Avg NCEP!C !CTemp at 30 hPa [K]'
    yinfo.symbol_color = culz.slate
    layout.color = culz.slate
    yinfo.thickness = 3
    mdata = {x: ncep.time, y: result(0) + result(1)*cos((ncep.doy - 190)*2*!pi/365.)}
    mc_npanel_plot,  layout, yinfo, mdata, panel=0

    yinfo.right_axis = 0
    yinfo.title = 'NCEP Temp !C !Cat 30 hPa [K]'
    yinfo.symbol_color = culz.black
    layout.color = culz.black
    yinfo.thickness = 3
    mdata = {x: ncep.time, y: nc_par}
    mc_npanel_plot,  layout, yinfo, mdata, panel=0

;---F10.7 panel:
    yinfo.symsize = 0.2
    yinfo.psym = 0
    yinfo.style = 0
    yinfo.range = [63, max(indices.f107) + 5]
    yinfo.right_axis = 1
    yinfo.title = 'F!D10.7!N Solar Flux'
    yinfo.symbol_color = culz.rose
    layout.color = culz.rose
    yinfo.thickness = 2
    mdata = {x: indices.time, y: indices.f107}
    mc_npanel_plot,  layout, yinfo, mdata, panel=1

;---Ap panel:
    yinfo.symsize = 0.2
    yinfo.psym = 0
    yinfo.style = 0
    yinfo.range = [-1, 293.]
    yinfo.right_axis = 0
    yinfo.title = 'Ap Index'
    yinfo.symbol_color = culz.black
    layout.color = culz.black
    yinfo.thickness = 1
    mdata = {x: indices.time, y: indices.ap}
    mc_npanel_plot,  layout, yinfo, mdata, panel=1

;----MSIS panels:
    yinfo.symsize = 0.15
    yinfo.psym = 0
    yinfo.style = 0
    yinfo.range = [min(settings.temperature_plot_range), max(settings.temperature_plot_range)]
    yinfo.right_axis = 1
    yinfo.title = 'MSIS Temp [K]'
    layout.color = culz.white
    yinfo.thickness = 1
    yinfo.minor_tix = 5
    for j=0,4 do begin
        clr = culz.imgmin + j/(4.)*(culz.imgmax - culz.imgmin - 2)
        yinfo.symbol_color = clr
        get_msis, mtimes, {lon: 360. - 147.4303, lat: 65.1192}, 110. + j*10., indices, msis_pts
        mdata = {x: msis_pts.time, y: msis_pts.tz}
        mc_npanel_plot,  layout, yinfo, mdata, panel=2, get_position=thispos
    endfor
    yinfo.thickness = 1
    for j=0,4 do begin
        clr = culz.imgmin + j/(4.)*(culz.imgmax - culz.imgmin - 2)
        xyouts, thispos(2) + 0.005, thispos(1) + (j + 1)*(thispos(3) - thispos(1))/6, strcompress(string(fix(110. + j*10.)), /remove_all) + ' km', $
                align=0, color=clr, charsize=layout.charsize*layout.charscale, charthick=layout.charthick, /normal
    endfor
    yinfo.symbol_color = culz.black
    layout.color = culz.black
    get_msis, mtimes, {lon: 360. - 147.4303, lat: 65.1192}, 110., indices, msis_pts
    mdata = {x: msis_pts.time, y: msis_pts.tz}
    yinfo.right_axis = 0
    yinfo.title = 'MSIS Temp [K]'
    mc_npanel_plot,  layout, yinfo, mdata, panel=2, get_position=thispos
    yinfo.minor_tix = 0

    yinfo.right_axis = 1
    yinfo.title = 'FYU [O]/[N!D2!N]!C !C '
    yinfo.symbol_color = culz.red
    layout.color = culz.red
    yinfo.thickness = 3
    yinfo.symsize = 0.3
    yinfo.psym = 6
    yinfo.style = -1
    yinfo.range = [0., 2.83]
    mdata = {x: fyu_o2n2.time, y: fyu_o2n2.o2n2}
    mc_npanel_plot,  layout, yinfo, mdata, panel=3

;---pkr photometer panels:
;    get_msis, mtimes, {lon: 360. - 147.4303, lat: 65.1192}, 125., indices, msis_pts
;    yinfo.symsize = 0.15
;    yinfo.psym = 0
;    yinfo.style = 0
;    yinfo.range = [min(settings.temperature_plot_range), max(settings.temperature_plot_range)]
;    yinfo.right_axis = 1
;    yinfo.title = 'MSIS Temp [K]'
;    yinfo.symbol_color = culz.olive
;    layout.color = culz.olive
;    yinfo.thickness = 1
;    mdata = {x: msis_pts.time, y: msis_pts.tz}
;    mc_npanel_plot,  layout, yinfo, mdata, panel=3

    yinfo.right_axis = 0
    yinfo.title = ' !C !CPoker [O]/[N!D2!N]'
    yinfo.symbol_color = culz.black
    layout.color = culz.black
    yinfo.thickness = 3
    yinfo.symsize = 0.3
    yinfo.psym = 6
    yinfo.style = -1
    yinfo.range = [0., 2.83]
    mdata = {x: pkr_o2n2.time, y: pkr_o2n2.o2n2}
    mc_npanel_plot,  layout, yinfo, mdata, panel=3

;---PKR FPS panels - temperature & zonal wind:
    yinfo.thickness = 3
    yinfo.symsize = 0.05
    yinfo.psym = 6
    yinfo.style = -1
    yinfo.range = [min(settings.temperature_plot_range), max(settings.temperature_plot_range)]
    yinfo.right_axis = 1
    yinfo.title = 'FPS Temp [K]'
    yinfo.symbol_color = culz.olive
    layout.color = culz.olive
    yinfo.thickness = 1
    yinfo.minor_tix = 5
    mdata = {x: hgip_fps.time, y: hgip_fps.temperature}
    mc_npanel_plot,  layout, yinfo, mdata, panel=4
    yinfo.minor_tix = 0

    yinfo.right_axis = 0
    yinfo.title = 'FPS Geographic!C !CZonal Wind [m/s]'
    yinfo.symbol_color = culz.black
    layout.color = culz.black
    yinfo.thickness = 3
    yinfo.symsize = 0.05
    yinfo.psym = 6
    yinfo.style = -1
    yinfo.range = [-250., 250.]
    mdata = {x: hgip_fps.time, y: hgip_fps.geo_zonal_wind}
    mc_npanel_plot,  layout, yinfo, mdata, panel=4

;---PKR FPS panels - vertical wind & meridional wind:
    yinfo.thickness = 3
    yinfo.symsize = 0.05
    yinfo.psym = 6
    yinfo.style = -1
    yinfo.range = [-140., 140.]
    yinfo.right_axis = 1
    yinfo.title = 'FPS Vertical!C !CWind [m/s]'
    yinfo.symbol_color = culz.orange
    layout.color = culz.orange
    yinfo.thickness = 1
    yinfo.minor_tix = 5
    mdata = {x: hgip_fps.time, y: hgip_fps.vertical_wind}
    mc_npanel_plot,  layout, yinfo, mdata, panel=5
    yinfo.minor_tix = 0

    yinfo.right_axis = 0
    yinfo.title = 'FPS Geographic!C !CMeridional Wind [m/s]'
    yinfo.symbol_color = culz.black
    layout.color = culz.black
    yinfo.thickness = 3
    yinfo.symsize = 0.05
    yinfo.psym = 6
    yinfo.style = -1
    yinfo.range = [-250., 250.]
    mdata = {x: hgip_fps.time, y: hgip_fps.geo_meridional_wind}
    mc_npanel_plot,  layout, yinfo, mdata, panel=5

    if settings.ps_run then begin
       device, /close
       set_plot, 'WIN'
       ps_run = 0
    endif
end
