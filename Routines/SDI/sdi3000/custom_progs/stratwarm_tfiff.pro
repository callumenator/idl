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


;-----------------------------------------------------------------------------------
;
;  Main program starts here:

   drive = get_drive()


   mcchoice, 'Optons: ', ['Windows', 'Postscript File'], choice, $
              heading = {text: 'Choose an Output Type', font: 'Helvetica*Bold*Proof*30'}
   ps_run = choice.index

   xx = dialog_pickfile(path=drive + '\users\conde\main\Poker_SDI\Publications_and_Presentations\stratwarm\', filter='*.sav')
   restore, xx
   fps = fps(where(fps.temp_k gt 400. and fps.temp_k lt 1000.))

   msis_at_tn = interpol(msis.tn250, msis.time, fps.time)
   msis_at_ti = interpol(msis.tn250, msis.time, tion.time)

;---Plotting stuff starts here:

    load_pal, culz

    if ps_run then begin
       set_plot, 'PS'
       device, /landscape
       device, bits_per_pixel=8, /color, /encapsulated
       device, filename=dialog_pickfile(path='C:\Users\Conde\Main\Poker_SDI\Publications_and_Presentations\stratwarm\Finals\', filter='*.eps')
       !p.charsize = 1.0
       note_size = 0.4
    endif else begin
       xsize    = 1300
       ysize    = 900
       while !d.window ge 0 do wdelete, !d.window
       window, xsize=xsize, ysize=ysize
    endelse

    mc_npanel_plot,  layout, yinfo, /setup
    erase, color=culz.white
    layout.position = [0.12, 0.10, 0.90, 0.96]
    if ps_run then begin
       layout.charscale = 0.6
       layout.position = [0.18, 0.10, 0.98, 0.96]
    endif

    layout.panels = 2
    layout.time_axis =1
    layout.xrange = [min(fps.time) - 86400., max(fps.time) + 86400.]
    layout.title  = ' '
    layout.erase = 0

    yinfo.range = [-190, 190]
    yinfo.charsize = 1.8
    yinfo.style = -1
    yinfo.psym  = 6

;---Ion temperature differences:
    yinfo.right_axis = 0
    yinfo.thickness = 6
    yinfo.symsize = 0.25
    yinfo.psym = 6
    yinfo.style = -1
    yinfo.symbol_color = culz.rose
    yinfo.thickness = 2
    layout.color = culz.black
    yinfo.symsize = 0.25
    yinfo.title = 'Ion Temp Minus!C !C MSIS Temp [K]'
    ti_diff = mc_time_filter(tion.time, tion.ti_240km - msis_at_ti, 3600)
    ti_diff = ti_diff - mc_time_filter(tion.time, ti_diff, 30L*86400L)
    tidata = {x: tion.time, y: ti_diff}
    mc_npanel_plot,  layout, yinfo, tidata, panel=0
    nion = n_elements(tion)
    smooth_these, tion(0:nion-20).time, ti_diff(0:nion-20), newtimes, smoothed, trend, order=3, winsize=50, iters=40
    oplot, newtimes(50:4950), smoothed(50:4950), thick=5, color=culz.black



;---FPS temperature differences:
    yinfo.right_axis = 0
    yinfo.symbol_color = culz.cyan
    yinfo.title = 'Neutral Temp Minus!C !C MSIS Temp [K]'

    tn_diff = mc_time_filter(fps.time, fps.temp_k - msis_at_tn, 3600)
    result = poly_fit(fps.time, tn_diff, 3, yfit=tnbk)
;    tn_diff = tn_diff - mc_time_filter(fps.time, tn_diff, 30L*86400L)
    tn_diff = tn_diff - tnbk
    tndata = {x: fps.time, y: tn_diff}
    mc_npanel_plot,  layout, yinfo, tndata, panel=1
    nfps = n_elements(fps)
    smooth_these, fps(0:nfps-20).time, tn_diff(0:nfps-20), newtimes, smoothed, trend, order=3, winsize=50, iters=40
    oplot, newtimes(50:4950), smoothed(50:4950), thick=5, color=culz.black

    if ps_run then begin
       device, /close
       set_plot, 'WIN'
       ps_run = 0
    endif
end

