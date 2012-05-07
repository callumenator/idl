
   whoami, dir, file
   pathinfo = mc_fileparse(dir + file)
   drive = str_sep(pathinfo(0).path, '\')
   drive = drive(0)

   fpath = drive + '\users\SDI3000\Data\'
   filename = dialog_pickfile(path=fpath, filter='*sky*.nc')
   sdi3k_read_netcdf_data, filename, metadata=mm, spex=spex, spekfits=spekfits

   calname  = dialog_pickfile(path=fpath, filter='*cal*.pf')
   sdi3k_read_netcdf_data, calname, metadata=lamm, spex=laspex, spekfits=laspekfits

    xxx     =   1e12*findgen(mm.scan_channels)*(mm.wavelength_nm*1e-9)^2/(2.*mm.gap_mm*1e-3*mm.scan_channels)
    xxx     = xxx - xxx(mm.scan_channels/2)
    title   = ' '

;---Build the time information arrays:
    tcen   = (spekfits.start_time + spekfits.end_time)/2
    tlist  = dt_tm_mk(js2jd(0d)+1, tcen, format='h$:m$')

    mcchoice, 'Time: ', tlist, choice, $
               heading = {text: 'Plot spectrum from what time?', font: 'Helvetica*Bold*Proof*30'}
    which = choice.index
    mcchoice, 'Zone: ', string(indgen(mm.nzones)), choice, $
               heading = {text: 'Plot spectrum at time ' + tlist(which) + ' from what zone?', font: 'Helvetica*Bold*Proof*30'}
    zone = choice.index

    mcchoice, 'Optons: ', ['Windows', 'Postscript File'], outchoice, $
               heading = {text: 'Choose an Output Type', font: 'Helvetica*Bold*Proof*30'}
    ps_run = outchoice.index

    load_pal, culz

    if ps_run then begin
       set_plot, 'PS'
       device, /landscape
       device, bits_per_pixel=8, /color, /encapsulated
       device, filename=dialog_pickfile(path=drive + 'C:\Users\Conde\Main\Poker_SDI\', filter='*.eps')
       !p.charsize = 1.0
       note_size = 0.4
    endif else begin
       canvas_size = [1600, 1000]
       xsize    = canvas_size(0)
       ysize    = canvas_size(1)
       while !d.window ge 0 do wdelete, !d.window
       window, xsize=xsize, ysize=ysize
    endelse

    mc_npanel_plot,  layout, yinfo, /setup
    erase, color=culz.white

    layout.panels    = 1
    layout.xrange    = [min(xxx), max(xxx)]
    layout.title     = title
    layout.xtitle    = 'Wavelength [pm]'
    layout.position  = [0.12, 0.15, 0.95, 0.92]
    layout.charsize  = 3.5
    layout.charthick = 4
    layout.xthick    = 6
    layout.ythick    = 6
    layout.erase     = 0

    if ps_run then begin
       layout.charscale = 0.5
       layout.position = [0.2, 0.18, 0.98, 0.85]
    endif

    yyy              = reform(spex(which).spectra(zone, *))
    pkchan           = where(median(yyy, 9) eq max(median(yyy, 9)))
    pkchan           = pkchan(0) + 2
    yyy              = shift(yyy, mm.scan_channels/2 - pkchan)
    yyy              = (yyy - min(yyy))*0.001
    yinfo.range      = 1.1*[min(yyy), max(yyy)]

    lll              = reform(laspex(0).spectra(zone, *))
    lll              = lll - 0.85*min(lll)
    lll              = 0.9*max(yyy)*lll/max(lll)
    pkchan           = where(median(lll, 5) eq max(median(lll, 5)))
    pkchan           = pkchan(0)
    lll              = shift(lll, mm.scan_channels/2 - pkchan)

    yinfo.title      = 'Intensity/1000 [dn]'
    yinfo.charsize   = 3.5
    yinfo.zero_line  = 0

    yinfo.thickness  = 2
    yinfo.line_color = culz.ash
    yinfo.style      = 2
;    mc_npanel_plot,  layout, yinfo, {x: [0.,0.], y:yinfo.range}, panel=0
    yinfo.style      = -1

    yinfo.symsize    = 0.001
    yinfo.psym       = 0
    yinfo.symbol_color = culz.ash
    yinfo.thickness  = 3
    yinfo.line_color = culz.ash
    llldata = {x: xxx, y: lll}
    mc_npanel_plot,  layout, yinfo, llldata, panel=0

    yinfo.symsize    = 1.5
    yinfo.psym       = 1
    yinfo.symbol_color = culz.black
    yinfo.thickness  = 5
    yinfo.line_color = culz.black
    spxdata = {x: xxx, y: yyy}
    mc_npanel_plot,  layout, yinfo, spxdata, panel=0


    lamlab  = '!4k!3=' + strcompress(string(mm.wavelength_nm, format='(f12.1)'), /remove_all) + ' nm'
    datelab = strcompress(dt_tm_mk(js2jd(0d)+1, mm.start_time(0), format='d$-n$-Y$'), /remove_all)
    tstrt   = dt_tm_mk(js2jd(0d)+1, spex(which).start_time, format='h$:m$:s$')
    tstop   = dt_tm_mk(js2jd(0d)+1, spex(which).end_time,   format='h$:m$:s$')
    tlab    = tstrt + ' to ' + tstop + ' UT'
    xpos    = layout.xrange(0) + 0.06*(layout.xrange(1) - layout.xrange(0))
    ytop    =  yinfo.range(0)  + 0.9*( yinfo.range(1)  -  yinfo.range(0))
    ydrop   = 0.07*( yinfo.range(1)  -  yinfo.range(0))
    xyouts, xpos, ytop,             tlab,                              charsize=2.8*layout.charscale, charthick=4, color=culz.black, align=0, /data
    xyouts, xpos, ytop - 1.*ydrop,  datelab,                           charsize=2.8*layout.charscale, charthick=4, color=culz.black, align=0, /data
    xyouts, xpos, ytop - 2.*ydrop,  lamlab,                            charsize=2.8*layout.charscale, charthick=4, color=culz.black, align=0, /data
    xyouts, xpos, ytop - 3.*ydrop, strcompress('Zone ' + choice.name), charsize=2.8*layout.charscale, charthick=4, color=culz.black, align=0, /data

;---Now fit the emission profile, for plotting purposes only:
;--Number of points per 1-D spectrum.
    npts = 128

;--Describe the instrument.  In this case we have a 20 mm etalon gap,
;  1 order scan range, npts channels in the spectrum:
    gap    = mm.gap_mm*1e-3
    lambda = mm.wavelength_nm*1e-9
    fsr    = lambda^2/(2*gap)
    cal    = {s_cal,   delta_lambda: fsr/mm.scan_channels, $
            nominal_lambda: mm.wavelength_nm*1e-9}

;--converting factor for going from peakpositions to winds:
    velcoef = ((3.e8)*fsr)/(lambda*mm.scan_channels)

;--Specify the diagnostic messages/plots that we'd like 'spek_fit' to produce:
    diagz = ['dummy']
    diagz = [diagz, 'main_print_answer']
;    diagz = [diagz, 'main_plot_pars(mcwindow, 7, xpos=600)']
;   diagz = [diagz, 'nonlin_print_lambda']
;    diagz = [diagz, 'main_plot_fitz(window, 8)']
    diagz = [diagz, 'main_loop_wait(ctlz.secwait = 0.0001)']

;--Describe the species that emitted the airglow signal that we observed:
    species = {s_spec, name: 'O', $
            mass:  16., $
            relint: 1.}
           fitpars   = [0., 0., 0., 0., 800.]
           fix_mask  = [0, 1, 0, 0, 0]
;--Now fit an emission spectrum to the sky sky spectrum, using the instrument profile obtained from the laser fringes:
           spek_fit, yyy, lll, species, cal, fix_mask, diagz, fitpars, sigpars, quality, /passive, max_iters=200, chisq_tolerance=0.001
           oplot, xxx, quality.fitfunc, color=culz.black, linestyle=2, thick=4
           chisq = quality.chisq(quality.iters-1)/quality.df

           tprlab = 'T=' + strcompress(string(fitpars(4), format='(f12.1)'), /remove_all) +' K !9+!3 ' + $
                             strcompress(string(sigpars(4), format='(f12.1)'), /remove_all) +' K'
;--Annotate the plot with the temperature fit results:
           xpos    = layout.xrange(0) + 0.94*(layout.xrange(1) - layout.xrange(0))
           xyouts, xpos, ytop, tprlab, $
                     /data, color=culz.black, charsize=2.8*layout.charscale, charthick=4, align=1
           xyouts, xpos, ytop - ydrop, '!4v!3!U2!N=' + strcompress(string(chisq, format='(f12.2)'), /remove_all), $
                     /data, color=culz.black, charsize=2.8*layout.charscale, charthick=4, align=1


    if ps_run then begin
       device, /close
       set_plot, 'WIN'
       ps_run = 0
    endif

end